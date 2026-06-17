"""Firebase Admin SDK initialization. Talks to the same Firestore project the
admin panel uses, so data written here shows up live in the admin UI."""
import os

import firebase_admin
from firebase_admin import credentials, firestore, auth as fb_auth
import google.auth.credentials as ga_credentials

from .config import resolve_credentials_path, FIREBASE_PROJECT_ID, USE_EMULATOR

_app = None
_db = None


class _AnonymousCredential(credentials.Base):
    """No-op credential for the local emulators. The emulators authorize every
    request as project owner, so no real service-account token is ever minted.
    Passing this (instead of letting the SDK fall back to ApplicationDefault)
    stops google.auth.default() from trying to load the nonexistent
    serviceAccountKey.json that GOOGLE_APPLICATION_CREDENTIALS still points at."""

    def get_credential(self):
        return ga_credentials.AnonymousCredentials()


def init_firebase():
    """Initialize the Admin SDK once. Raises a clear error if the key is missing."""
    global _app, _db
    if _app is not None:
        return _app

    if USE_EMULATOR:
        # The emulators accept anonymous owner access: no service-account JSON
        # and no credential object are needed. firestore.client() auto-routes
        # via FIRESTORE_EMULATOR_HOST and verify_id_token() trusts unsigned
        # emulator tokens via FIREBASE_AUTH_EMULATOR_HOST. A projectId must be
        # passed explicitly since there's no credential to infer it from.
        project_id = FIREBASE_PROJECT_ID or "hospital-queue-managemen-67208"
        _app = firebase_admin.initialize_app(
            _AnonymousCredential(), {"projectId": project_id}
        )
        _db = firestore.client()
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
