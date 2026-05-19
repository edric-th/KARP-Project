"""Routes for the current user's profile and FCM token registration."""
import logging
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import firestore

from app.dependencies import verify_token
from app.firebase_setup import get_db
from app.models import MessageResponse
from app.models.user import FcmTokenRequest, RegisterRequest, UserProfile

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["auth"])


def _to_profile(uid: str, data: dict[str, Any]) -> UserProfile:
    """Map a Firestore ``users`` document to a UserProfile response model."""
    return UserProfile(
        uid=uid,
        name=data.get("name", ""),
        phone=data.get("phone", ""),
        email=data.get("email"),
        role=data.get("role", "patient"),
        fcm_token=data.get("fcmToken"),
        created_at=data.get("createdAt"),
    )


@router.get("/me", response_model=UserProfile)
async def get_me(decoded: dict = Depends(verify_token)) -> UserProfile:
    """Return the authenticated user's Firestore profile.

    Responds 404 if the user has signed up with Firebase Auth but has not yet
    created a profile via ``POST /api/me/register``.
    """
    uid = decoded["uid"]
    db = get_db()
    try:
        snapshot = db.collection("users").document(uid).get()
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to load profile for %s: %s", uid, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not load profile. Please try again later.",
        ) from exc

    if not snapshot.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No profile found. Call POST /api/me/register first.",
        )
    return _to_profile(uid, snapshot.to_dict() or {})


@router.post("/me/register", response_model=UserProfile, status_code=status.HTTP_201_CREATED)
async def register_profile(
    body: RegisterRequest,
    decoded: dict = Depends(verify_token),
) -> UserProfile:
    """Create the caller's profile after Firebase Auth signup.

    The new profile always has role ``patient``; staff roles are assigned out
    of band (see the README). Responds 409 if a profile already exists.
    """
    uid = decoded["uid"]
    db = get_db()
    doc_ref = db.collection("users").document(uid)

    try:
        if doc_ref.get().exists:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="A profile already exists for this user.",
            )
        doc_ref.set(
            {
                "name": body.name,
                "phone": body.phone,
                "email": decoded.get("email"),
                "role": "patient",
                "fcmToken": None,
                "createdAt": firestore.SERVER_TIMESTAMP,
            }
        )
        snapshot = doc_ref.get()
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to register profile for %s: %s", uid, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not create profile. Please try again later.",
        ) from exc

    logger.info("Registered new profile for user %s", uid)
    return _to_profile(uid, snapshot.to_dict() or {})


@router.post("/me/fcm-token", response_model=MessageResponse)
async def save_fcm_token(
    body: FcmTokenRequest,
    decoded: dict = Depends(verify_token),
) -> MessageResponse:
    """Save (or replace) the calling device's FCM registration token.

    The token is used to deliver "your turn" push notifications.
    """
    uid = decoded["uid"]
    db = get_db()
    doc_ref = db.collection("users").document(uid)

    try:
        if not doc_ref.get().exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No profile found. Call POST /api/me/register first.",
            )
        doc_ref.update(
            {"fcmToken": body.fcm_token, "updatedAt": firestore.SERVER_TIMESTAMP}
        )
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to save FCM token for %s: %s", uid, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not save FCM token. Please try again later.",
        ) from exc

    logger.info("Updated FCM token for user %s", uid)
    return MessageResponse(message="FCM token saved.")
