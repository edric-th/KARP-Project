"""FastAPI authentication dependencies built on Firebase Auth."""
import logging
from typing import Any

from fastapi import Depends, Header, HTTPException, status
from firebase_admin import auth as firebase_auth

from app.firebase_setup import get_db

logger = logging.getLogger(__name__)

# Firestore roles that count as "staff" for admin-only endpoints.
STAFF_ROLES = {"admin", "receptionist"}


async def verify_token(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    """Verify the Firebase ID token supplied in the Authorization header.

    Expects ``Authorization: Bearer <firebase_id_token>``. Returns the decoded
    token (a dict containing ``uid``, ``email`` and any custom claims).
    Raises HTTP 401 on any missing, malformed, invalid or expired token.
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or malformed Authorization header. Expected 'Bearer <token>'.",
        )

    id_token = authorization.split(" ", 1)[1].strip()
    if not id_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Empty bearer token.",
        )

    try:
        decoded = firebase_auth.verify_id_token(id_token)
    except Exception as exc:  # noqa: BLE001 - Firebase raises several error types
        logger.warning("ID token verification failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token.",
        ) from exc

    return decoded


async def verify_staff(decoded: dict[str, Any] = Depends(verify_token)) -> dict[str, Any]:
    """Verify the caller is authenticated AND has a staff role.

    Staff are users whose Firestore ``/users/{uid}`` profile has a ``role`` of
    ``admin`` or ``receptionist``. Raises HTTP 403 when the profile is missing
    or the role is not a staff role. The resolved role is added to the returned
    dict under the ``role`` key.
    """
    uid = decoded["uid"]
    db = get_db()

    try:
        snapshot = db.collection("users").document(uid).get()
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to read user profile for %s: %s", uid, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not verify user role. Please try again later.",
        ) from exc

    if not snapshot.exists:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No user profile found. Register a profile before using staff endpoints.",
        )

    role = (snapshot.to_dict() or {}).get("role")
    if role not in STAFF_ROLES:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Staff role (admin or receptionist) is required for this endpoint.",
        )

    decoded["role"] = role
    return decoded
