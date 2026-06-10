"""Unified, adaptive, booking-type-aware queue wait-time prediction.

This is the single source of truth for "how long until token #N is called".
It mirrors (and extends) admin-panel/src/lib/waitTime.js so the admin board,
the doctor screen and the patient app all agree.

Model
-----
1. Learn a per-doctor base service time from recently *served* bookings
   (time between `calledAt` and `servedAt`), clamped to 1..60 min, needing at
   least MIN_SAMPLES samples before trusting it (else DEFAULT_SERVICE_MINUTES).
2. Make it booking-type aware: "first_visit" patients take longer than
   "follow_up"/"report". Use the per-type learned average where we have enough
   data, otherwise scale the base time by a per-type factor.
3. A waiting patient's ETA = remaining time of the in-progress consult
   + the summed expected durations of everyone ahead of them.
"""
from datetime import datetime, timedelta, timezone

from .config import DEFAULT_SERVICE_MINUTES, DEFAULT_RECEPTION_MINUTES

MIN_SAMPLES = 3
RECENT_WINDOW = 10

# Relative cost of each booking type vs. the learned base time.
TYPE_RELATIVE = {
    "first_visit": 1.3,
    "follow_up": 0.6,
    "report": 0.8,
}


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _parse(value):
    """Parse an ISO string / Firestore datetime into an aware datetime."""
    if not value:
        return None
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    try:
        dt = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
    except Exception:
        return None


def _served_durations(bookings):
    out = []
    for b in bookings:
        if b.get("status") != "served":
            continue
        called, served = _parse(b.get("calledAt")), _parse(b.get("servedAt"))
        if not called or not served:
            continue
        minutes = (served - called).total_seconds() / 60.0
        out.append((served, min(max(minutes, 1), 60)))
    out.sort(key=lambda x: x[0], reverse=True)
    return [m for _, m in out[:RECENT_WINDOW]]


def calculate_avg_service_time(bookings) -> float:
    """Overall learned base service time (minutes) for a doctor's queue."""
    durations = _served_durations(bookings)
    if len(durations) < MIN_SAMPLES:
        return float(DEFAULT_SERVICE_MINUTES)
    return round(sum(durations) / len(durations), 1)


def per_type_averages(bookings, base):
    """Expected minutes per booking type (learned where possible)."""
    averages = {}
    for btype, factor in TYPE_RELATIVE.items():
        durations = _served_durations(
            [b for b in bookings if b.get("bookingType") == btype]
        )
        if len(durations) >= MIN_SAMPLES:
            averages[btype] = round(sum(durations) / len(durations), 1)
        else:
            averages[btype] = round(base * factor, 1)
    return averages


def _duration_for(booking, type_averages, base):
    return type_averages.get(booking.get("bookingType"), base)


def _remaining_active(active, type_averages, base) -> float:
    if not active:
        return 0.0
    full = _duration_for(active, type_averages, base)
    called = _parse(active.get("calledAt"))
    if called:
        elapsed = (_now() - called).total_seconds() / 60.0
        return max(0.0, full - elapsed)
    return full


def _iso_from_now(minutes) -> str:
    return (_now() + timedelta(minutes=minutes)).isoformat()


def build_queue_status(doctor_id, bookings) -> dict:
    """Full live snapshot of a doctor's queue with per-token ETAs."""
    base = calculate_avg_service_time(bookings)
    type_averages = per_type_averages(bookings, base)

    active = next((b for b in bookings if b.get("status") == "active"), None)
    pending = sorted(
        [b for b in bookings if b.get("status") == "pending"],
        key=lambda b: b.get("tokenNumber") or 0,
    )

    cumulative = _remaining_active(active, type_averages, base)
    waiting = []
    for idx, b in enumerate(pending):
        wait = round(cumulative)
        waiting.append({
            **b,
            "position": idx + 1,
            "estimatedWaitMinutes": wait,
            "expectedCallAt": _iso_from_now(wait),
        })
        cumulative += _duration_for(b, type_averages, base)

    return {
        "doctorId": doctor_id,
        "nowServing": active,
        "waiting": waiting,
        "waitingCount": len(pending),
        "servedCount": len([b for b in bookings if b.get("status") == "served"]),
        "avgServiceMinutes": base,
        "typeAverages": type_averages,
    }


def predict_wait_for_new(bookings) -> int:
    """ETA (minutes) for a brand-new patient joining at the end of the queue."""
    base = calculate_avg_service_time(bookings)
    type_averages = per_type_averages(bookings, base)
    active = next((b for b in bookings if b.get("status") == "active"), None)
    total = _remaining_active(active, type_averages, base)
    for b in bookings:
        if b.get("status") == "pending":
            total += _duration_for(b, type_averages, base)
    return round(total)


def expected_call_iso(minutes) -> str:
    return _iso_from_now(minutes)


# ---- Reception (online-token) queue -----------------------------------------
# A hospital-level walk-in queue handled by the reception desk. There is no
# per-doctor service learning here — every token takes roughly the same fixed
# handling time, so the ETA is simply position * DEFAULT_RECEPTION_MINUTES on
# top of whatever remains of the token currently being served.

def _reception_remaining(active) -> float:
    per = float(DEFAULT_RECEPTION_MINUTES)
    if not active:
        return 0.0
    called = _parse(active.get("calledAt"))
    if called:
        elapsed = (_now() - called).total_seconds() / 60.0
        return max(0.0, per - elapsed)
    return per


def build_reception_status(hospital_id, tokens) -> dict:
    """Live snapshot of a hospital's reception queue. Mirrors the shape of
    build_queue_status so the patient app can reuse the same model."""
    per = float(DEFAULT_RECEPTION_MINUTES)
    active = next((t for t in tokens if t.get("status") == "active"), None)
    pending = sorted(
        [t for t in tokens if t.get("status") == "pending"],
        key=lambda t: t.get("tokenNumber") or 0,
    )

    cumulative = _reception_remaining(active)
    waiting = []
    for idx, t in enumerate(pending):
        wait = round(cumulative)
        waiting.append({
            **t,
            "position": idx + 1,
            "estimatedWaitMinutes": wait,
            "expectedCallAt": _iso_from_now(wait),
        })
        cumulative += per

    return {
        # `doctorId` is reused as the queue key on the client model; carry the
        # hospital id in both so existing parsing keeps working.
        "doctorId": hospital_id,
        "hospitalId": hospital_id,
        "nowServing": active,
        "waiting": waiting,
        "waitingCount": len(pending),
        "servedCount": len([t for t in tokens if t.get("status") == "served"]),
        "avgServiceMinutes": per,
        "typeAverages": {},
    }


def predict_reception_wait_for_new(tokens) -> int:
    """ETA (minutes) for a brand-new walk-in joining the reception queue now."""
    per = float(DEFAULT_RECEPTION_MINUTES)
    active = next((t for t in tokens if t.get("status") == "active"), None)
    total = _reception_remaining(active)
    total += per * len([t for t in tokens if t.get("status") == "pending"])
    return round(total)
