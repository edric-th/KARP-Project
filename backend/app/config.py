import os
from dotenv import load_dotenv

# Load backend/.env regardless of the current working directory.
_BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
load_dotenv(os.path.join(_BACKEND_DIR, ".env"))

FIREBASE_API_KEY = os.getenv("FIREBASE_API_KEY", "")
FIREBASE_PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID", "")
GOOGLE_APPLICATION_CREDENTIALS = os.getenv(
    "GOOGLE_APPLICATION_CREDENTIALS", "./serviceAccountKey.json"
)
CORS_ORIGINS = [
    o.strip()
    for o in os.getenv("CORS_ORIGINS", "http://localhost:5173,http://localhost:3000").split(",")
    if o.strip()
]
DEFAULT_SERVICE_MINUTES = int(os.getenv("DEFAULT_SERVICE_MINUTES", "10"))
# Average minutes a receptionist spends registering/handling one online-token
# walk-in. Used to estimate reception-queue wait times (no doctor involved).
DEFAULT_RECEPTION_MINUTES = int(os.getenv("DEFAULT_RECEPTION_MINUTES", "4"))

# ---- Email / OTP (Gmail SMTP by default) ------------------------------------
SMTP_HOST = os.getenv("SMTP_HOST", "")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASS = os.getenv("SMTP_PASS", "")
SMTP_FROM = os.getenv("SMTP_FROM", "") or SMTP_USER
OTP_TTL_MINUTES = int(os.getenv("OTP_TTL_MINUTES", "10"))

# ---- Chatbot (Gemini, in-process via Chatbot/bot.py) ------------------------
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")


def resolve_credentials_path() -> str:
    """Absolute path to the service-account JSON (relative paths resolve to backend/)."""
    path = GOOGLE_APPLICATION_CREDENTIALS
    if not os.path.isabs(path):
        path = os.path.join(_BACKEND_DIR, path)
    return path
