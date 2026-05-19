"""Firebase Admin SDK initialization for Firestore, Auth, and FCM."""
import logging
from functools import lru_cache

import firebase_admin
from firebase_admin import credentials, firestore

from app.config import settings

logger = logging.getLogger(__name__)


def init_firebase() -> None:
    """Initialize the Firebase Admin app exactly once.

    Safe to call multiple times; subsequent calls are no-ops. Raises
    FileNotFoundError if the service account key is missing.
    """
    if firebase_admin._apps:  # already initialized
        return

    cred_path = settings.credentials_path
    if not cred_path.exists():
        raise FileNotFoundError(
            f"Service account key not found at '{cred_path}'. "
            "Place serviceAccountKey.json in the backend directory."
        )

    cred = credentials.Certificate(str(cred_path))
    firebase_admin.initialize_app(cred)
    logger.info("Firebase Admin SDK initialized (credentials: %s)", cred_path.name)


@lru_cache(maxsize=1)
def get_db() -> firestore.firestore.Client:
    """Return a cached Firestore client, initializing Firebase if needed."""
    init_firebase()
    return firestore.client()
