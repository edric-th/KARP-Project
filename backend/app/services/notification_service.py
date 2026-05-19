"""Firebase Cloud Messaging (FCM) push notification helpers."""
import logging

from firebase_admin import messaging

from app.firebase_setup import get_db

logger = logging.getLogger(__name__)


def _get_fcm_token(user_id: str) -> str | None:
    """Return the stored FCM token for a user, or None if unavailable."""
    db = get_db()
    try:
        snapshot = db.collection("users").document(user_id).get()
    except Exception as exc:  # noqa: BLE001
        logger.error("Could not load FCM token for user %s: %s", user_id, exc)
        return None
    if not snapshot.exists:
        return None
    return (snapshot.to_dict() or {}).get("fcmToken")


def _send(title: str, body: str, fcm_token: str, data: dict | None = None) -> bool:
    """Send a single FCM notification. Returns True on success."""
    message = messaging.Message(
        token=fcm_token,
        notification=messaging.Notification(title=title, body=body),
        data={key: str(value) for key, value in (data or {}).items()},
    )
    try:
        messaging.send(message)
        logger.info("FCM notification sent: %s", title)
        return True
    except Exception as exc:  # noqa: BLE001
        logger.error("FCM send failed: %s", exc)
        return False


def send_token_called(user_id: str | None, token_number: int, doctor_name: str) -> bool:
    """Notify a patient that their token is being called.

    No-ops gracefully (returning False) when the user has no profile or no
    registered FCM token - e.g. walk-in bookings created from the admin panel.
    """
    if not user_id:
        return False
    fcm_token = _get_fcm_token(user_id)
    if not fcm_token:
        logger.info("No FCM token for user %s; skipping 'called' notification", user_id)
        return False
    return _send(
        title="It's your turn!",
        body=f"Token #{token_number} for Dr. {doctor_name} is being called now.",
        fcm_token=fcm_token,
        data={"type": "token_called", "token_number": token_number},
    )


def send_position_update(user_id: str | None, position: int) -> bool:
    """Notify a patient that they are getting close (within a few tokens)."""
    if not user_id:
        return False
    fcm_token = _get_fcm_token(user_id)
    if not fcm_token:
        logger.info("No FCM token for user %s; skipping position update", user_id)
        return False
    return _send(
        title="Almost your turn",
        body=f"You are {position} token(s) away. Please be ready.",
        fcm_token=fcm_token,
        data={"type": "position_update", "position": position},
    )
