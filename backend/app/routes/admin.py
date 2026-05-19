"""Staff-only routes: managing hospitals/doctors and driving the live queue."""
import logging
from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from pydantic import BaseModel

from app.dependencies import verify_staff
from app.firebase_setup import get_db
from app.models.doctor import Doctor, DoctorCreate, DoctorUpdate
from app.models.hospital import Hospital, HospitalCreate, HospitalUpdate
from app.routes.hospitals import to_doctor, to_hospital
from app.services.notification_service import send_position_update, send_token_called
from app.services.wait_time_service import (
    DEFAULT_CONSULTATION_MINUTES,
    update_rolling_average,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/admin", tags=["admin"])

# How many tokens ahead a patient is warned with a "get ready" notification.
POSITION_ALERT_OFFSET = 3


# --------------------------------------------------------------------------
# Response models specific to the admin queue + reporting endpoints.
# --------------------------------------------------------------------------
class QueueActionResponse(BaseModel):
    """Result of advancing / skipping / completing a queue."""

    message: str
    served_token: int | None = None
    called_token: int | None = None
    current_token: int


class DoctorDayReport(BaseModel):
    """Per-doctor summary of one day's bookings."""

    doctor_id: str
    doctor_name: str | None = None
    total: int
    pending: int
    active: int
    served: int
    cancelled: int
    no_show: int


class DailyReport(BaseModel):
    """Daily summary across all doctors."""

    date: str
    total_bookings: int
    doctors: list[DoctorDayReport]


# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------
def _parse_queue_id(queue_id: str) -> tuple[str, str, str]:
    """Split a ``{hospitalId}_{doctorId}_{date}`` queue ID into its parts."""
    parts = queue_id.rsplit("_", 2)
    if len(parts) != 3 or not all(parts):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="queue_id must be '{hospital_id}_{doctor_id}_{YYYY-MM-DD}'.",
        )
    return parts[0], parts[1], parts[2]


def _minutes_between(start: Any, end: Any) -> float | None:
    """Return whole-minute difference between two datetimes, or None."""
    if not start or not end:
        return None
    try:
        return max(0.0, (end - start).total_seconds() / 60.0)
    except Exception:  # noqa: BLE001
        return None


def _log_consultation(
    db: Any,
    booking: dict[str, Any],
    hospital_id: str,
    doctor_id: str,
    date: str,
) -> float:
    """Write a completed consultation to ``consultations_log``.

    Returns the consultation duration in minutes (falling back to the default
    when timestamps are unavailable) so the caller can update the average.
    """
    now = datetime.now(timezone.utc)
    consultation_minutes = _minutes_between(booking.get("calledAt"), now)
    waited_minutes = _minutes_between(
        booking.get("createdAt"), booking.get("calledAt")
    )
    duration = (
        consultation_minutes
        if consultation_minutes is not None
        else DEFAULT_CONSULTATION_MINUTES
    )
    try:
        db.collection("consultations_log").add(
            {
                "hospitalId": hospital_id,
                "doctorId": doctor_id,
                "date": date,
                "tokenNumber": int(booking.get("tokenNumber", 0) or 0),
                "userId": booking.get("userId"),
                "consultationMinutes": round(duration, 2),
                "waitedMinutes": round(waited_minutes, 2)
                if waited_minutes is not None
                else None,
                "completedAt": firestore.SERVER_TIMESTAMP,
            }
        )
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to write consultation log: %s", exc)
    return duration


# --------------------------------------------------------------------------
# Hospitals
# --------------------------------------------------------------------------
@router.post("/hospitals", response_model=Hospital, status_code=status.HTTP_201_CREATED)
async def create_hospital(
    body: HospitalCreate,
    _: dict = Depends(verify_staff),
) -> Hospital:
    """Create a new hospital (staff only)."""
    db = get_db()
    try:
        doc_ref = db.collection("hospitals").document()
        doc_ref.set(
            {
                "name": body.name,
                "address": body.address,
                "phone": body.phone,
                "city": body.city,
                "createdAt": firestore.SERVER_TIMESTAMP,
                "updatedAt": firestore.SERVER_TIMESTAMP,
            }
        )
        snapshot = doc_ref.get()
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to create hospital: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not create hospital. Please try again later.",
        ) from exc

    logger.info("Created hospital %s", doc_ref.id)
    return to_hospital(snapshot.id, snapshot.to_dict() or {})


@router.put("/hospitals/{hospital_id}", response_model=Hospital)
async def update_hospital(
    hospital_id: str,
    body: HospitalUpdate,
    _: dict = Depends(verify_staff),
) -> Hospital:
    """Update an existing hospital (staff only). Only supplied fields change."""
    db = get_db()
    doc_ref = db.collection("hospitals").document(hospital_id)
    updates = body.model_dump(exclude_none=True)
    if not updates:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields provided to update.",
        )
    try:
        if not doc_ref.get().exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Hospital '{hospital_id}' not found.",
            )
        updates["updatedAt"] = firestore.SERVER_TIMESTAMP
        doc_ref.update(updates)
        snapshot = doc_ref.get()
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to update hospital %s: %s", hospital_id, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not update hospital. Please try again later.",
        ) from exc

    logger.info("Updated hospital %s", hospital_id)
    return to_hospital(snapshot.id, snapshot.to_dict() or {})


# --------------------------------------------------------------------------
# Doctors
# --------------------------------------------------------------------------
@router.post("/doctors", response_model=Doctor, status_code=status.HTTP_201_CREATED)
async def create_doctor(
    body: DoctorCreate,
    _: dict = Depends(verify_staff),
) -> Doctor:
    """Create a new doctor attached to an existing hospital (staff only)."""
    db = get_db()
    try:
        if not db.collection("hospitals").document(body.hospital_id).get().exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Hospital '{body.hospital_id}' not found.",
            )
        doc_ref = db.collection("doctors").document()
        # 'fee' matches the field name the admin panel already uses.
        doc_ref.set(
            {
                "name": body.name,
                "hospitalId": body.hospital_id,
                "specialty": body.specialty,
                "fee": body.consultation_fee,
                "consultationHours": body.consultation_hours,
                "availableDays": body.available_days,
                "createdAt": firestore.SERVER_TIMESTAMP,
                "updatedAt": firestore.SERVER_TIMESTAMP,
            }
        )
        snapshot = doc_ref.get()
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to create doctor: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not create doctor. Please try again later.",
        ) from exc

    logger.info("Created doctor %s", doc_ref.id)
    return to_doctor(snapshot.id, snapshot.to_dict() or {})


@router.put("/doctors/{doctor_id}", response_model=Doctor)
async def update_doctor(
    doctor_id: str,
    body: DoctorUpdate,
    _: dict = Depends(verify_staff),
) -> Doctor:
    """Update an existing doctor (staff only). Only supplied fields change."""
    db = get_db()
    doc_ref = db.collection("doctors").document(doctor_id)

    raw = body.model_dump(exclude_none=True)
    if not raw:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields provided to update.",
        )
    # Map API (snake_case) field names onto the stored (camelCase) names.
    field_map = {
        "name": "name",
        "hospital_id": "hospitalId",
        "specialty": "specialty",
        "consultation_fee": "fee",
        "consultation_hours": "consultationHours",
        "available_days": "availableDays",
    }
    updates = {field_map[key]: value for key, value in raw.items()}

    try:
        if not doc_ref.get().exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Doctor '{doctor_id}' not found.",
            )
        if "hospitalId" in updates and not (
            db.collection("hospitals").document(updates["hospitalId"]).get().exists
        ):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Hospital '{updates['hospitalId']}' not found.",
            )
        updates["updatedAt"] = firestore.SERVER_TIMESTAMP
        doc_ref.update(updates)
        snapshot = doc_ref.get()
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to update doctor %s: %s", doctor_id, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not update doctor. Please try again later.",
        ) from exc

    logger.info("Updated doctor %s", doctor_id)
    return to_doctor(snapshot.id, snapshot.to_dict() or {})


# --------------------------------------------------------------------------
# Live queue control
# --------------------------------------------------------------------------
def _load_day_bookings(db: Any, doctor_id: str, date: str) -> list[Any]:
    """Return all booking snapshots for a doctor on a date."""
    return list(
        db.collection("bookings")
        .where(filter=FieldFilter("doctorId", "==", doctor_id))
        .where(filter=FieldFilter("bookingDate", "==", date))
        .stream()
    )


def _update_queue_counters(
    db: Any,
    queue_id: str,
    hospital_id: str,
    doctor_id: str,
    date: str,
    current_token: int,
    called_token: int,
    average_minutes: float,
) -> None:
    """Persist the queue document's current/called token and rolling average."""
    db.collection("queues").document(queue_id).set(
        {
            "hospitalId": hospital_id,
            "doctorId": doctor_id,
            "date": date,
            "currentToken": current_token,
            "calledToken": called_token,
            "averageConsultationMinutes": round(average_minutes, 2),
            "status": "open",
            "updatedAt": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )


@router.post("/queue/{queue_id}/advance", response_model=QueueActionResponse)
async def advance_queue(
    queue_id: str,
    _: dict = Depends(verify_staff),
) -> QueueActionResponse:
    """Call the next patient in the queue (staff only).

    Marks the currently active token as ``served`` (logging the consultation
    and updating the rolling average), promotes the lowest-numbered ``pending``
    token to ``active``, updates the queue counters and pushes an FCM "your
    turn" notification to that patient.
    """
    db = get_db()
    hospital_id, doctor_id, date = _parse_queue_id(queue_id)

    try:
        queue_ref = db.collection("queues").document(queue_id)
        queue_snap = queue_ref.get()
        qdata = queue_snap.to_dict() or {} if queue_snap.exists else {}
        avg_minutes = float(
            qdata.get("averageConsultationMinutes", DEFAULT_CONSULTATION_MINUTES)
            or DEFAULT_CONSULTATION_MINUTES
        )
        current_token = int(qdata.get("currentToken", 0) or 0)

        bookings = _load_day_bookings(db, doctor_id, date)

        # 1) Complete the patient currently being seen.
        served_token: int | None = None
        active = next(
            (b for b in bookings if (b.to_dict() or {}).get("status") == "active"),
            None,
        )
        if active is not None:
            adata = active.to_dict() or {}
            duration = _log_consultation(db, adata, hospital_id, doctor_id, date)
            avg_minutes = update_rolling_average(avg_minutes, duration)
            db.collection("bookings").document(active.id).update(
                {
                    "status": "served",
                    "servedAt": firestore.SERVER_TIMESTAMP,
                    "updatedAt": firestore.SERVER_TIMESTAMP,
                }
            )
            served_token = int(adata.get("tokenNumber", 0) or 0)

        # 2) Promote the next waiting patient.
        pending = sorted(
            (b for b in bookings if (b.to_dict() or {}).get("status") == "pending"),
            key=lambda b: int((b.to_dict() or {}).get("tokenNumber", 0) or 0),
        )
        if not pending:
            _update_queue_counters(
                db, queue_id, hospital_id, doctor_id, date,
                current_token, current_token, avg_minutes,
            )
            return QueueActionResponse(
                message="No more waiting patients in the queue.",
                served_token=served_token,
                called_token=None,
                current_token=current_token,
            )

        next_doc = pending[0]
        ndata = next_doc.to_dict() or {}
        next_token = int(ndata.get("tokenNumber", 0) or 0)
        db.collection("bookings").document(next_doc.id).update(
            {
                "status": "active",
                "calledAt": firestore.SERVER_TIMESTAMP,
                "updatedAt": firestore.SERVER_TIMESTAMP,
            }
        )
        _update_queue_counters(
            db, queue_id, hospital_id, doctor_id, date,
            next_token, next_token, avg_minutes,
        )

        # 3) Notify the called patient, and warn the one a few tokens behind.
        send_token_called(
            ndata.get("userId"), next_token, ndata.get("doctorName") or "the doctor"
        )
        upcoming = next(
            (
                b
                for b in pending[1:]
                if int((b.to_dict() or {}).get("tokenNumber", 0) or 0)
                == next_token + POSITION_ALERT_OFFSET
            ),
            None,
        )
        if upcoming is not None:
            send_position_update(
                (upcoming.to_dict() or {}).get("userId"), POSITION_ALERT_OFFSET
            )
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to advance queue %s: %s", queue_id, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not advance queue. Please try again later.",
        ) from exc

    logger.info(
        "Advanced queue %s: served=%s called=%s", queue_id, served_token, next_token
    )
    return QueueActionResponse(
        message=f"Token #{next_token} is now being called.",
        served_token=served_token,
        called_token=next_token,
        current_token=next_token,
    )


@router.post("/queue/{queue_id}/skip", response_model=QueueActionResponse)
async def skip_queue(
    queue_id: str,
    _: dict = Depends(verify_staff),
) -> QueueActionResponse:
    """Skip the patient currently being called (staff only).

    Marks the active token as ``no_show``. The queue is not advanced; call
    ``/advance`` afterwards to call the next patient.
    """
    db = get_db()
    hospital_id, doctor_id, date = _parse_queue_id(queue_id)

    try:
        bookings = _load_day_bookings(db, doctor_id, date)
        active = next(
            (b for b in bookings if (b.to_dict() or {}).get("status") == "active"),
            None,
        )
        if active is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No patient is currently being called for this queue.",
            )
        adata = active.to_dict() or {}
        db.collection("bookings").document(active.id).update(
            {
                "status": "no_show",
                "updatedAt": firestore.SERVER_TIMESTAMP,
            }
        )
        skipped_token = int(adata.get("tokenNumber", 0) or 0)
        queue_snap = db.collection("queues").document(queue_id).get()
        current_token = int((queue_snap.to_dict() or {}).get("currentToken", 0) or 0)
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to skip queue %s: %s", queue_id, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not skip patient. Please try again later.",
        ) from exc

    logger.info("Skipped token #%s on queue %s", skipped_token, queue_id)
    return QueueActionResponse(
        message=f"Token #{skipped_token} marked as no-show.",
        served_token=skipped_token,
        called_token=None,
        current_token=current_token,
    )


@router.post("/queue/{queue_id}/complete", response_model=QueueActionResponse)
async def complete_current(
    queue_id: str,
    _: dict = Depends(verify_staff),
) -> QueueActionResponse:
    """Mark the active patient as served without calling the next one (staff only).

    Logs the consultation and updates the rolling average, but leaves the queue
    idle until ``/advance`` is called.
    """
    db = get_db()
    hospital_id, doctor_id, date = _parse_queue_id(queue_id)

    try:
        queue_ref = db.collection("queues").document(queue_id)
        qdata = queue_ref.get().to_dict() or {}
        avg_minutes = float(
            qdata.get("averageConsultationMinutes", DEFAULT_CONSULTATION_MINUTES)
            or DEFAULT_CONSULTATION_MINUTES
        )
        current_token = int(qdata.get("currentToken", 0) or 0)

        bookings = _load_day_bookings(db, doctor_id, date)
        active = next(
            (b for b in bookings if (b.to_dict() or {}).get("status") == "active"),
            None,
        )
        if active is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No patient is currently being called for this queue.",
            )
        adata = active.to_dict() or {}
        duration = _log_consultation(db, adata, hospital_id, doctor_id, date)
        avg_minutes = update_rolling_average(avg_minutes, duration)
        db.collection("bookings").document(active.id).update(
            {
                "status": "served",
                "servedAt": firestore.SERVER_TIMESTAMP,
                "updatedAt": firestore.SERVER_TIMESTAMP,
            }
        )
        served_token = int(adata.get("tokenNumber", 0) or 0)
        _update_queue_counters(
            db, queue_id, hospital_id, doctor_id, date,
            current_token, current_token, avg_minutes,
        )
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to complete current on queue %s: %s", queue_id, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not complete consultation. Please try again later.",
        ) from exc

    logger.info("Completed token #%s on queue %s", served_token, queue_id)
    return QueueActionResponse(
        message=f"Token #{served_token} marked as served.",
        served_token=served_token,
        called_token=None,
        current_token=current_token,
    )


# --------------------------------------------------------------------------
# Reporting
# --------------------------------------------------------------------------
@router.get("/reports/{date}", response_model=DailyReport)
async def daily_report(
    date: str,
    _: dict = Depends(verify_staff),
) -> DailyReport:
    """Return a per-doctor summary of all bookings on the given date (staff only)."""
    db = get_db()
    try:
        docs = (
            db.collection("bookings")
            .where(filter=FieldFilter("bookingDate", "==", date))
            .stream()
        )
        per_doctor: dict[str, dict[str, Any]] = {}
        total = 0
        for doc in docs:
            data = doc.to_dict() or {}
            total += 1
            doctor_id = data.get("doctorId", "unknown")
            bucket = per_doctor.setdefault(
                doctor_id,
                {
                    "doctor_name": data.get("doctorName"),
                    "total": 0,
                    "pending": 0,
                    "active": 0,
                    "served": 0,
                    "cancelled": 0,
                    "no_show": 0,
                },
            )
            bucket["total"] += 1
            status_value = data.get("status", "")
            if status_value in bucket:
                bucket[status_value] += 1
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to build report for %s: %s", date, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not build report. Please try again later.",
        ) from exc

    doctors = [
        DoctorDayReport(
            doctor_id=doctor_id,
            doctor_name=bucket["doctor_name"],
            total=bucket["total"],
            pending=bucket["pending"],
            active=bucket["active"],
            served=bucket["served"],
            cancelled=bucket["cancelled"],
            no_show=bucket["no_show"],
        )
        for doctor_id, bucket in sorted(per_doctor.items())
    ]
    return DailyReport(date=date, total_bookings=total, doctors=doctors)
