"""Chatbot endpoint — proxies the in-process Gemini bot, with per-user memory."""
from collections import defaultdict

from fastapi import APIRouter, Depends

from ..chatbot_engine import answer
from ..schemas import ChatQueryRequest, ChatReply
from ..security import get_current_user

router = APIRouter(prefix="/chatbot", tags=["chatbot"])

# In-memory conversation history per session key (uid by default). Capped so a
# long chat doesn't grow unbounded. Fine for a single-instance backend.
_MAX_STORED = 10
_sessions: dict[str, list[dict]] = defaultdict(list)


@router.post("/query", response_model=ChatReply)
def chat_query(body: ChatQueryRequest, user: dict = Depends(get_current_user)):
    key = body.session_id or user["uid"]
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
