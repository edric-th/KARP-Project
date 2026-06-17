"""Chatbot endpoint — proxies the in-process Gemini bot, with per-user memory.

Queue-status questions ("when is my turn?", "when will my online token be
called?") are answered deterministically from the user's live bookings BEFORE
Gemini is consulted, so the reply is a real clock time computed from the queue's
estimated wait — not a generic "open the app to see your wait" instruction.
"""
from collections import defaultdict
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends

from ..chatbot_engine import answer
from .. import firestore_repo as repo
from .. import wait_time
from ..schemas import ChatQueryRequest, ChatReply
from ..security import get_current_user

router = APIRouter(prefix="/chatbot", tags=["chatbot"])

# In-memory conversation history per session key (uid by default). Capped so a
# long chat doesn't grow unbounded. Fine for a single-instance backend.
_MAX_STORED = 10
_sessions: dict[str, list[dict]] = defaultdict(list)


# ── Queue-status intent (answered from live data, not Gemini) ────────────────

# Phrases that clearly ask about the user's OWN current place in a queue.
_STATUS_PHRASES = (
    "my turn", "is it my turn", "when is my turn", "when's my turn",
    "when will my turn", "my turn yet", "called yet", "my wait", "wait time",
    "how long until", "how long till", "how long more", "how much longer",
    "my position", "people ahead", "ahead of me", "how many ahead",
    "my queue", "queue status", "token status", "when will i be called",
    "when will i get called", "when will i be seen", "when will my token",
    "when is my token", "token be called",
)

# Don't hijack "how do I book a token" style questions.
_BOOK_PHRASES = (
    "how do i book", "how to book", "how can i book", "want to book",
    "book a", "book an", "book my", "how do i get a token", "how to get a token",
)


def _is_status_question(message: str) -> bool:
    m = message.lower()
    if any(p in m for p in _BOOK_PHRASES):
        return False
    if any(p in m for p in _STATUS_PHRASES):
        return True
    # "when ... turn/token/queue/called" or "how long ... turn/token/..."
    if ("when" in m or "how long" in m) and any(
        k in m for k in ("turn", "token", "queue", "called", "seen")
    ):
        return True
    return False


def _now_np() -> datetime:
    return datetime.now(repo.NEPAL_TZ)


def _fmt_clock(dt: datetime) -> str:
    h = dt.hour % 12 or 12
    ampm = "AM" if dt.hour < 12 else "PM"
    return f"{h}:{dt.minute:02d} {ampm}"


def _ahead_phrase(n: int) -> str:
    if n <= 0:
        return "no one ahead of you"
    return f"{n} {'person' if n == 1 else 'people'} ahead of you"


def _entry_eta(snapshot: dict, booking: dict):
    """(is_now, wait_minutes, people_ahead) for `booking` in its queue snapshot."""
    now_serving = snapshot.get("nowServing")
    if now_serving and now_serving.get("id") == booking.get("id"):
        return True, 0, 0
    match = next(
        (w for w in snapshot.get("waiting", []) if w.get("id") == booking.get("id")),
        None,
    )
    if match:
        wait = match.get("estimatedWaitMinutes") or 0
        ahead = (match.get("position") or 1) - 1 + (1 if now_serving else 0)
        return False, wait, ahead
    return False, booking.get("estimatedWaitMinutes") or 0, 0


def _appointment_line(b: dict) -> str:
    date = b.get("bookingDate")
    snapshot = wait_time.build_queue_status(
        b.get("doctorId"), repo.bookings_for_doctor(b.get("doctorId"), date)
    )
    is_now, wait, ahead = _entry_eta(snapshot, b)
    name = (b.get("doctorName") or "your doctor").strip()
    who = name if name.lower().startswith("dr") else f"Dr. {name}"
    tok = b.get("tokenNumber")
    if is_now:
        return f"It's your turn now with {who} — please proceed to the consultation room (token #{tok})."
    if wait <= 0:
        return f"You're next with {who} (token #{tok}) — your turn will be any moment now."
    clock = _fmt_clock(_now_np() + timedelta(minutes=wait))
    return (
        f"Your turn with {who} (token #{tok}) will be at around {clock} "
        f"— about {wait} min from now, with {_ahead_phrase(ahead)}."
    )


def _online_token_line(b: dict) -> str:
    date = b.get("bookingDate")
    hosp_id = b.get("hospitalId") or ""
    snapshot = wait_time.build_reception_status(
        hosp_id, repo.reception_tokens_for_hospital(hosp_id, date)
    )
    is_now, wait, ahead = _entry_eta(snapshot, b)
    hosp = b.get("hospitalName") or "the hospital"
    tok = b.get("tokenNumber")
    if is_now:
        return f"Your online token #{tok} is being called now — please go to the {hosp} reception desk."
    if wait <= 0:
        return f"Your online token #{tok} at {hosp} will be called any moment now."
    clock = _fmt_clock(_now_np() + timedelta(minutes=wait))
    return (
        f"Your online token #{tok} at {hosp} will be called at around {clock} "
        f"— about {wait} min from now, with {_ahead_phrase(ahead)}."
    )


def _queue_status_reply(uid: str, message: str):
    """A real-time answer for queue/turn questions, or None to defer to Gemini."""
    if not _is_status_question(message):
        return None

    date = repo.today_str()
    mine = [
        b
        for b in repo.bookings_for_patient(uid)
        if b.get("bookingDate") == date and b.get("status") in ("pending", "active")
    ]
    appointments = [b for b in mine if b.get("bookingSource") != "online_token"]
    tokens = [b for b in mine if b.get("bookingSource") == "online_token"]

    if not appointments and not tokens:
        return (
            "You haven't booked any doctor appointment or online token yet. "
            "Once you book one, I can tell you exactly when your turn will be."
        )

    m = message.lower()
    wants_online = ("online" in m or "reception" in m) and "appointment" not in m
    wants_appt = ("appointment" in m or "doctor" in m) and "online" not in m

    show_appt = bool(appointments) and not wants_online
    show_token = bool(tokens) and not wants_appt
    if not show_appt and not show_token:  # asked for a kind they don't have
        show_appt, show_token = bool(appointments), bool(tokens)

    lines = []
    if show_appt:
        lines.append(_appointment_line(appointments[0]))
    if show_token:
        lines.append(_online_token_line(tokens[0]))
    return "\n\n".join(lines)


@router.post("/query", response_model=ChatReply)
def chat_query(body: ChatQueryRequest, user: dict = Depends(get_current_user)):
    key = body.session_id or user["uid"]

    status_reply = _queue_status_reply(user["uid"], body.message)
    if status_reply is not None:
        result = {
            "response": status_reply,
            "intent_category": "app",
            "is_emergency": False,
            "disclaimer_added": False,
            "confidence_score": 95.0,
            "matched_intent_name": "queue_status",
        }
    else:
        result = answer(body.message, list(_sessions[key]))

    _sessions[key].append({"role": "user", "content": body.message})
    _sessions[key].append({"role": "assistant", "content": result.get("response", "")})
    if len(_sessions[key]) > _MAX_STORED:
        _sessions[key] = _sessions[key][-_MAX_STORED:]

    return ChatReply(**result)


@router.post("/reset")
def chat_reset(user: dict = Depends(get_current_user)):
    """Forget the current user's conversation history."""
    _sessions.pop(user["uid"], None)
    return {"cleared": True}
