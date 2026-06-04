from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from firebase_admin import firestore

from .. import firestore_repo as repo
from ..schemas import ReviewCreate
from ..security import get_current_user

router = APIRouter(prefix="/doctors", tags=["doctors"])


def _with_hospital_names(doctors: list) -> list:
    """Denormalize hospitalName onto each doctor so the app needn't join."""
    names = {h["id"]: h.get("name") for h in repo.get_all("hospitals")}
    for d in doctors:
        if not d.get("hospitalName"):
            d["hospitalName"] = names.get(d.get("hospitalId"), "")
    return doctors


@router.get("")
def list_doctors(hospital_id: Optional[str] = None):
    docs = (
        repo.query_eq("doctors", "hospitalId", hospital_id)
        if hospital_id else repo.get_all("doctors")
    )
    return _with_hospital_names(docs)


@router.get("/{doctor_id}")
def get_doctor(doctor_id: str):
    doctor = repo.get_one("doctors", doctor_id)
    if not doctor:
        raise HTTPException(404, "Doctor not found")
    if not doctor.get("hospitalName") and doctor.get("hospitalId"):
        h = repo.get_one("hospitals", doctor["hospitalId"])
        doctor["hospitalName"] = h.get("name") if h else ""
    return doctor


@router.get("/{doctor_id}/reviews")
def list_reviews(doctor_id: str):
    return repo.reviews_for_doctor(doctor_id)


@router.post("/{doctor_id}/reviews")
def add_review(doctor_id: str, body: ReviewCreate, user: dict = Depends(get_current_user)):
    doctor = repo.get_one("doctors", doctor_id)
    if not doctor:
        raise HTTPException(404, "Doctor not found")

    rating = max(1.0, min(5.0, float(body.rating)))
    ref = repo.get_db().collection("reviews").document()
    ref.set({
        "doctorId": doctor_id,
        "patientUid": user["uid"],
        "patientName": user.get("name") or "Patient",
        "rating": rating,
        "text": body.text or "",
        "createdAt": firestore.SERVER_TIMESTAMP,
    })
    agg = repo.recompute_doctor_rating(doctor_id)
    return {"id": ref.id, **agg}
