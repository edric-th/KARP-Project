"""In-process bridge to the standalone Chatbot package (repo-root Chatbot/bot.py).

Rather than running the chatbot as a second FastAPI service (which would collide
on port 8000), we add the Chatbot/ directory to sys.path and reuse its
Gemini-powered get_response(message, history). The app therefore exposes a
single backend. GEMINI_API_KEY must be present in the backend environment; if
it's missing, bot.py degrades gracefully to canned fallback replies.
"""
import os
import sys

from .config import GEMINI_API_KEY

# bot.py reads os.environ["GEMINI_API_KEY"] at import time. config.py has already
# loaded backend/.env, so surface the key to the imported module regardless of cwd.
if GEMINI_API_KEY:
    os.environ.setdefault("GEMINI_API_KEY", GEMINI_API_KEY)

_CHATBOT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "Chatbot",
)
if _CHATBOT_DIR not in sys.path:
    sys.path.insert(0, _CHATBOT_DIR)

from bot import get_response as _get_response  # noqa: E402


def answer(message: str, history=None) -> dict:
    """Run one chatbot turn. Returns bot.py's structured dict (response,
    intent_category, is_emergency, disclaimer_added, confidence_score, ...)."""
    return _get_response(message, history or [])
