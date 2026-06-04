"""In-app notifications for the patient. Written by this API (booking
lifecycle) and by the admin panel (queue status changes); read here."""
from fastapi import APIRouter, Depends, HTTPException

from .. import firestore_repo as repo
from ..security import get_current_user

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("")
def list_notifications(user: dict = Depends(get_current_user)):
    return repo.notifications_for_patient(user["uid"])


@router.post("/{notification_id}/read")
def mark_read(notification_id: str, user: dict = Depends(get_current_user)):
    notif = repo.get_one("notifications", notification_id)
    if not notif:
        raise HTTPException(404, "Notification not found")
    if notif.get("patientUid") != user["uid"]:
        raise HTTPException(403, "Not your notification")
    repo.get_db().collection("notifications").document(notification_id).update(
        {"isRead": True}
    )
    return {"id": notification_id, "isRead": True}
