from typing import Optional

from fastapi import APIRouter

from .. import firestore_repo as repo
from .. import wait_time

router = APIRouter(prefix="/queue", tags=["queue"])


@router.get("/summary")
def queue_summary(doctorIds: str = "", date: Optional[str] = None):
    """Lightweight per-doctor queue snapshot for many doctors at once — used by
    the booking doctor-picker. For each id: waiting count, learned average
    service time, and the ETA for a brand-new patient joining now.

    Declared before /{doctor_id} so "summary" isn't matched as a doctor id."""
    date = date or repo.today_str()
    ids = [d.strip() for d in doctorIds.split(",") if d.strip()]
    out = []
    for doctor_id in ids:
        bookings = repo.bookings_for_doctor(doctor_id, date)
        doctor = repo.get_one("doctors", doctor_id)
        pending = [b for b in bookings if b.get("status") == "pending"]
        out.append({
            "doctorId": doctor_id,
            "waitingCount": len(pending),
            "avgServiceMinutes": wait_time.calculate_avg_service_time(bookings),
            # estimatedWaitMinutes + expectedCallAt + doctorAvailableNow + availableFrom
            **wait_time.predict_summary_for_new(bookings, doctor),
        })
    return out


@router.get("/{doctor_id}")
def queue_status(doctor_id: str, date: Optional[str] = None):
    """Live queue snapshot for a doctor: now-serving, waiting list with per-token
    predicted wait times, and the learned average service time."""
    date = date or repo.today_str()
    bookings = repo.bookings_for_doctor(doctor_id, date)
    doctor = repo.get_one("doctors", doctor_id)
    return wait_time.build_queue_status(doctor_id, bookings, doctor)
