"""Read-only route exposing the live state of a doctor's queue."""
import logging

from fastapi import APIRouter, Depends, HTTPException, status
from google.cloud.firestore_v1.base_query import FieldFilter

from app.dependencies import verify_token
from app.firebase_setup import get_db
from app.models.queue import QueueState
from app.routes.tokens import build_queue_id
from app.services.wait_time_service import DEFAULT_CONSULTATION_MINUTES

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["queue"])


@router.get("/queue/{hospital_id}/{doctor_id}/{date}", response_model=QueueState)
async def get_queue_state(
    hospital_id: str,
    doctor_id: str,
    date: str,
    _: dict = Depends(verify_token),
) -> QueueState:
    """Return the live queue state for a doctor on a given date (YYYY-MM-DD).

    If no token has been booked yet there is no queue document, so a zeroed
    "open" state is returned instead of a 404. ``waiting_count`` is always
    computed live from the ``bookings`` collection.
    """
    db = get_db()
    queue_id = build_queue_id(hospital_id, doctor_id, date)

    try:
        queue_snap = db.collection("queues").document(queue_id).get()
        if queue_snap.exists:
            qdata = queue_snap.to_dict() or {}
            last_issued = int(qdata.get("lastIssuedToken", 0) or 0)
            current_token = int(qdata.get("currentToken", 0) or 0)
            called_token = int(qdata.get("calledToken", 0) or 0)
            queue_status = qdata.get("status", "open")
            avg_minutes = float(
                qdata.get("averageConsultationMinutes", DEFAULT_CONSULTATION_MINUTES)
                or DEFAULT_CONSULTATION_MINUTES
            )
        else:
            last_issued = current_token = called_token = 0
            queue_status = "open"
            avg_minutes = DEFAULT_CONSULTATION_MINUTES

        # Count tokens still waiting (pending) live from bookings.
        booking_docs = (
            db.collection("bookings")
            .where(filter=FieldFilter("doctorId", "==", doctor_id))
            .where(filter=FieldFilter("bookingDate", "==", date))
            .stream()
        )
        waiting_count = sum(
            1
            for doc in booking_docs
            if (doc.to_dict() or {}).get("status") == "pending"
        )
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to load queue %s: %s", queue_id, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not load queue state. Please try again later.",
        ) from exc

    return QueueState(
        queue_id=queue_id,
        hospital_id=hospital_id,
        doctor_id=doctor_id,
        date=date,
        last_issued_token=last_issued,
        current_token=current_token,
        called_token=called_token,
        status=queue_status,
        average_consultation_minutes=avg_minutes,
        waiting_count=waiting_count,
    )
