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

# ---- Firebase emulator (local dev) ------------------------------------------
# When either host is set the backend talks to the local Auth/Firestore
# emulators (firebase.json: Auth 9099, Firestore 8020) instead of production.
# The Admin SDK auto-routes Firestore via FIRESTORE_EMULATOR_HOST and trusts
# unsigned emulator ID tokens via FIREBASE_AUTH_EMULATOR_HOST; init_firebase()
# skips the service-account key, and auth_service points its sign-in/refresh
# REST calls at the Auth emulator. Clear both to use production Firebase.
FIRESTORE_EMULATOR_HOST = os.getenv("FIRESTORE_EMULATOR_HOST", "")
FIREBASE_AUTH_EMULATOR_HOST = os.getenv("FIREBASE_AUTH_EMULATOR_HOST", "")
USE_EMULATOR = bool(FIRESTORE_EMULATOR_HOST or FIREBASE_AUTH_EMULATOR_HOST)
CORS_ORIGINS = [
    o.strip()
    for o in os.getenv("CORS_ORIGINS", "http://localhost:5173,http://localhost:3000").split(",")
    if o.strip()
]
DEFAULT_SERVICE_MINUTES = int(os.getenv("DEFAULT_SERVICE_MINUTES", "10"))
# Average minutes a receptionist spends registering/handling one online-token
# walk-in. Used to estimate reception-queue wait times (no doctor involved).
DEFAULT_RECEPTION_MINUTES = int(os.getenv("DEFAULT_RECEPTION_MINUTES", "4"))

# How long (seconds) to reuse a queue's booking list across repeated reads. The
# patient app and admin panel poll the same doctor/hospital queues every few
# seconds; caching collapses those identical reads into one Firestore query per
# window, which keeps free-tier read quota from being exhausted. Writes
# (book/cancel/reschedule) invalidate the relevant key so changes show at once.
# Set to 0 to disable caching entirely.
QUERY_CACHE_TTL_SECONDS = float(os.getenv("QUERY_CACHE_TTL_SECONDS", "12"))

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
