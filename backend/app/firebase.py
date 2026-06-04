"""Firebase Admin SDK initialization. Talks to the same Firestore project the
admin panel uses, so data written here shows up live in the admin UI."""
import os

import firebase_admin
from firebase_admin import credentials, firestore, auth as fb_auth

from .config import resolve_credentials_path, FIREBASE_PROJECT_ID

_app = None
_db = None


def init_firebase():
    """Initialize the Admin SDK once. Raises a clear error if the key is missing."""
    global _app, _db
    if _app is not None:
        return _app

    cred_path = resolve_credentials_path()
    if not os.path.exists(cred_path):
        raise RuntimeError(
            f"Service account key not found at '{cred_path}'.\n"
            "Download it from Firebase Console > Project settings > Service "
            "accounts > Generate new private key, then save it there "
            "(or set GOOGLE_APPLICATION_CREDENTIALS in backend/.env)."
        )

    cred = credentials.Certificate(cred_path)
    options = {"projectId": FIREBASE_PROJECT_ID} if FIREBASE_PROJECT_ID else None
    _app = firebase_admin.initialize_app(cred, options)
    _db = firestore.client()
    return _app


def get_db():
    if _db is None:
        init_firebase()
    return _db


def get_auth():
    if _app is None:
        init_firebase()
    return fb_auth
