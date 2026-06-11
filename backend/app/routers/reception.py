from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from firebase_admin import firestore

from .. import firestore_repo as repo
from .. import wait_time
from ..schemas import ReceptionTokenCreate
from ..security import get_current_user

router = APIRouter(tags=["reception"])


@router.post("/reception-tokens")
def create_reception_token(
    body: ReceptionTokenCreate, user: dict = Depends(get_current_user)
):
    """Reserve an ONLINE TOKEN ONLY — a reception-desk queue ticket, not tied to
    any doctor and with no payment. The patient completes the appointment
    physically at the hospital reception."""
    hospital = repo.get_one("hospitals", body.hospital_id)
    if not hospital:
        raise HTTPException(404, "Hospital not found")

    date = repo.today_str()
    existing = repo.reception_tokens_for_hospital(body.hospital_id, date)

    # Lock in the wait estimate BEFORE this patient joins, then take the number.
    wait_min = wait_time.predict_reception_wait_for_new(existing)
    token = repo.next_reception_token(body.hospital_id, date)

    data = {
        "doctorId": "",
        "doctorName": "",
        "hospitalId": body.hospital_id,
        "hospitalName": hospital.get("name", ""),
        "patientName": body.patient_name,
        "patientPhone": body.patient_phone or "",
        "patientUid": user["uid"],
        "bookingType": "first_visit",
        "bookingSource": "online_token",
        "status": "pending",
        "tokenNumber": token,
        "bookingDate": date,
        "estimatedWaitMinutes": wait_min,
        "expectedCallAt": wait_time.expected_call_iso(wait_min),
        "paymentMethod": "",
        "paymentStatus": "not_required",
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }

    ref = repo.get_db().collection("bookings").document()
    ref.set(data)
    repo.invalidate_for_booking(data)  # show this token in the reception queue now

    repo.add_notification(
        user["uid"],
        "Online token reserved",
        f"Reception token #{token} at {hospital.get('name', 'the hospital')} "
        f"on {date}. Estimated wait ~{wait_min} min. Please complete your "
        f"appointment at the reception desk.",
        category="booking",
        related_booking_id=ref.id,
    )
    return repo.get_one("bookings", ref.id)


@router.get("/reception/summary")
def reception_summary(hospitalIds: str = "", date: Optional[str] = None):
    """Lightweight reception-queue snapshot for many hospitals at once — used by
    the online-token hospital picker: waiting count + ETA for a new walk-in.

    Declared before /reception/{hospital_id} so "summary" isn't matched as an id."""
    date = date or repo.today_str()
    ids = [h.strip() for h in hospitalIds.split(",") if h.strip()]
    out = []
    for hid in ids:
        tokens = repo.reception_tokens_for_hospital(hid, date)
        pending = [t for t in tokens if t.get("status") == "pending"]
        out.append({
            "hospitalId": hid,
            "doctorId": hid,
            "waitingCount": len(pending),
            "avgServiceMinutes": float(wait_time.DEFAULT_RECEPTION_MINUTES),
            "estimatedWaitMinutes": wait_time.predict_reception_wait_for_new(tokens),
        })
    return out


@router.get("/reception/{hospital_id}")
def reception_status(hospital_id: str, date: Optional[str] = None):
    """Live reception-queue snapshot for a hospital: now-serving token, waiting
    list with per-token ETAs, and the average handling time."""
    date = date or repo.today_str()
    tokens = repo.reception_tokens_for_hospital(hospital_id, date)
    return wait_time.build_reception_status(hospital_id, tokens)
