"""Patient profile: the full sign-up / edit-profile dataset plus computed
visit stats. name/phone live at the top of users/{uid}; everything else is
merged under a nested `profile` map so partial updates are safe."""
from fastapi import APIRouter, Depends
from firebase_admin import firestore

from .. import firestore_repo as repo
from ..schemas import ProfileUpdate
from ..security import get_current_user

router = APIRouter(prefix="/profile", tags=["profile"])

_TOP_LEVEL = {"name", "phone"}


def _compute_stats(uid: str) -> dict:
    bookings = repo.bookings_for_patient(uid)
    completed = [b for b in bookings if b.get("status") == "served"]
    waits = [
        b["estimatedWaitMinutes"]
        for b in bookings
        if isinstance(b.get("estimatedWaitMinutes"), (int, float))
    ]
    avg_wait = round(sum(waits) / len(waits)) if waits else 0
    return {
        "totalVisits": len(bookings),
        "completed": len(completed),
        "avgWaitMinutes": avg_wait,
    }


@router.get("")
def get_profile(user: dict = Depends(get_current_user)):
    doc = repo.get_one("users", user["uid"]) or {}
    doc.setdefault("uid", user["uid"])
    doc.setdefault("email", user.get("email"))
    doc.setdefault("role", user.get("role", "patient"))
    doc["stats"] = _compute_stats(user["uid"])
    return doc


@router.put("")
def update_profile(body: ProfileUpdate, user: dict = Depends(get_current_user)):
    payload = body.model_dump(exclude_none=True, by_alias=True)

    top = {k: v for k, v in payload.items() if k in _TOP_LEVEL}
    nested = {k: v for k, v in payload.items() if k not in _TOP_LEVEL}

    update_doc = {**top, "updatedAt": firestore.SERVER_TIMESTAMP}
    if nested:
        update_doc["profile"] = nested

    # merge=True deep-merges the nested `profile` map, preserving untouched keys.
    repo.get_db().collection("users").document(user["uid"]).set(update_doc, merge=True)

    return get_profile(user)
