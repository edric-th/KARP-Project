"""Routes for booking, viewing and cancelling patient tokens.

A "token" is stored as a document in the shared ``bookings`` collection so the
data is interoperable with the admin panel.
"""
import logging
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter

from app.dependencies import verify_token
from app.firebase_setup import get_db
from app.models import MessageResponse
from app.models.token import (
    BookTokenRequest,
    BookTokenResponse,
    Token,
    TokenWithPosition,
)
from app.services.wait_time_service import (
    DEFAULT_CONSULTATION_MINUTES,
    estimate_wait_minutes,
    queue_position,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["tokens"])

# Statuses for which a patient still occupies a slot in the queue.
LIVE_STATUSES = {"pending", "active"}


def build_queue_id(hospital_id: str, doctor_id: str, date: str) -> str:
    """Build the deterministic queue document ID for a doctor on a date."""
    return f"{hospital_id}_{doctor_id}_{date}"


def to_token(doc_id: str, data: dict[str, Any]) -> Token:
    """Map a Firestore ``bookings`` document to a Token response model."""
    return Token(
        token_id=doc_id,
        token_number=int(data.get("tokenNumber", 0) or 0),
        doctor_id=data.get("doctorId", ""),
        doctor_name=data.get("doctorName"),
        hospital_id=data.get("hospitalId", ""),
        hospital_name=data.get("hospitalName"),
        booking_type=data.get("bookingType", ""),
        appointment_date=data.get("bookingDate", ""),
        status=data.get("status", ""),
        created_at=data.get("createdAt"),
        completed_at=data.get("servedAt"),
    )


@router.post(
    "/tokens/book",
    response_model=BookTokenResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["tokens"],
)
async def book_token(
    body: BookTokenRequest,
    decoded: dict = Depends(verify_token),
) -> BookTokenResponse:
    """Book a token for the authenticated patient.

    Validates the doctor/hospital, rejects a duplicate live booking for the
    same doctor on the same date (409), then atomically increments the queue's
    issued-token counter inside a Firestore transaction so two concurrent
    bookings can never receive the same token number.
    """
    uid = decoded["uid"]
    db = get_db()

    try:
        # --- Load the patient profile (name/phone are copied onto the booking).
        user_snap = db.collection("users").document(uid).get()
        if not user_snap.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No profile found. Call POST /api/me/register first.",
            )
        user = user_snap.to_dict() or {}

        # --- Validate the doctor and that it belongs to the given hospital.
        doctor_snap = db.collection("doctors").document(body.doctor_id).get()
        if not doctor_snap.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Doctor '{body.doctor_id}' not found.",
            )
        doctor = doctor_snap.to_dict() or {}
        if doctor.get("hospitalId") != body.hospital_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This doctor does not belong to the given hospital.",
            )

        hospital_snap = db.collection("hospitals").document(body.hospital_id).get()
        if not hospital_snap.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Hospital '{body.hospital_id}' not found.",
            )
        hospital = hospital_snap.to_dict() or {}

        # --- Reject a duplicate live booking for the same doctor + date.
        existing = (
            db.collection("bookings")
            .where(filter=FieldFilter("userId", "==", uid))
            .where(filter=FieldFilter("doctorId", "==", body.doctor_id))
            .where(filter=FieldFilter("bookingDate", "==", body.appointment_date))
            .stream()
        )
        for doc in existing:
            if (doc.to_dict() or {}).get("status") in LIVE_STATUSES:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="You already have an active token for this doctor on this date.",
                )

        # --- Atomically issue the next token number.
        queue_id = build_queue_id(body.hospital_id, body.doctor_id, body.appointment_date)
        queue_ref = db.collection("queues").document(queue_id)
        booking_ref = db.collection("bookings").document()
        transaction = db.transaction()

        @firestore.transactional
        def _issue(txn: Any) -> tuple[int, int, float]:
            """Increment the queue counter and create the booking atomically."""
            queue_snap = queue_ref.get(transaction=txn)
            if queue_snap.exists:
                qdata = queue_snap.to_dict() or {}
                last = int(qdata.get("lastIssuedToken", 0) or 0)
                current = int(qdata.get("currentToken", 0) or 0)
                called = int(qdata.get("calledToken", 0) or 0)
                avg = float(
                    qdata.get("averageConsultationMinutes", DEFAULT_CONSULTATION_MINUTES)
                    or DEFAULT_CONSULTATION_MINUTES
                )
                queue_status = qdata.get("status", "open")
            else:
                last, current, called = 0, 0, 0
                avg = DEFAULT_CONSULTATION_MINUTES
                queue_status = "open"

            new_token = last + 1
            txn.set(
                queue_ref,
                {
                    "hospitalId": body.hospital_id,
                    "doctorId": body.doctor_id,
                    "date": body.appointment_date,
                    "lastIssuedToken": new_token,
                    "currentToken": current,
                    "calledToken": called,
                    "status": queue_status,
                    "averageConsultationMinutes": avg,
                    "updatedAt": firestore.SERVER_TIMESTAMP,
                },
                merge=True,
            )
            txn.set(
                booking_ref,
                {
                    "userId": uid,
                    "tokenNumber": new_token,
                    "doctorId": body.doctor_id,
                    "doctorName": doctor.get("name"),
                    "hospitalId": body.hospital_id,
                    "hospitalName": hospital.get("name"),
                    "patientName": user.get("name"),
                    "patientPhone": user.get("phone"),
                    "bookingType": body.booking_type.value,
                    "bookingDate": body.appointment_date,
                    "status": "pending",
                    "calledAt": None,
                    "servedAt": None,
                    "createdAt": firestore.SERVER_TIMESTAMP,
                    "updatedAt": firestore.SERVER_TIMESTAMP,
                },
            )
            return new_token, current, avg

        token_number, current_token, avg_minutes = _issue(transaction)
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to book token for %s: %s", uid, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not book token. Please try again later.",
        ) from exc

    wait = estimate_wait_minutes(token_number, current_token, avg_minutes)
    logger.info(
        "Booked token #%s (%s) for user %s, doctor %s",
        token_number,
        booking_ref.id,
        uid,
        body.doctor_id,
    )
    return BookTokenResponse(
        token_id=booking_ref.id,
        token_number=token_number,
        estimated_wait_minutes=wait,
    )


@router.get("/me/tokens", response_model=list[Token])
async def list_my_tokens(decoded: dict = Depends(verify_token)) -> list[Token]:
    """List every token booked by the authenticated patient (newest first)."""
    uid = decoded["uid"]
    db = get_db()
    try:
        docs = (
            db.collection("bookings")
            .where(filter=FieldFilter("userId", "==", uid))
            .stream()
        )
        tokens = [to_token(doc.id, doc.to_dict() or {}) for doc in docs]
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to list tokens for %s: %s", uid, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not load your tokens. Please try again later.",
        ) from exc

    # Sort newest-first; tokens created in this request may have no timestamp yet.
    tokens.sort(key=lambda t: (t.created_at is not None, t.created_at), reverse=True)
    return tokens


@router.get("/me/tokens/{token_id}", response_model=TokenWithPosition)
async def get_my_token(
    token_id: str,
    decoded: dict = Depends(verify_token),
) -> TokenWithPosition:
    """Return one of the caller's tokens with its live queue position."""
    uid = decoded["uid"]
    db = get_db()
    try:
        snapshot = db.collection("bookings").document(token_id).get()
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to load token %s: %s", token_id, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not load token. Please try again later.",
        ) from exc

    if not snapshot.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Token '{token_id}' not found.",
        )
    data = snapshot.to_dict() or {}
    if data.get("userId") != uid:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This token belongs to another user.",
        )

    token = to_token(snapshot.id, data)

    # Look up the matching queue document for the live current token.
    current_token = 0
    avg_minutes = DEFAULT_CONSULTATION_MINUTES
    queue_id = build_queue_id(
        token.hospital_id, token.doctor_id, token.appointment_date
    )
    try:
        queue_snap = db.collection("queues").document(queue_id).get()
        if queue_snap.exists:
            qdata = queue_snap.to_dict() or {}
            current_token = int(qdata.get("currentToken", 0) or 0)
            avg_minutes = float(
                qdata.get("averageConsultationMinutes", DEFAULT_CONSULTATION_MINUTES)
                or DEFAULT_CONSULTATION_MINUTES
            )
    except Exception as exc:  # noqa: BLE001
        logger.warning("Could not load queue %s for position: %s", queue_id, exc)

    return TokenWithPosition(
        **token.model_dump(),
        current_token=current_token,
        queue_position=queue_position(token.token_number, current_token),
        estimated_wait_minutes=estimate_wait_minutes(
            token.token_number, current_token, avg_minutes
        ),
    )


@router.delete("/me/tokens/{token_id}", response_model=MessageResponse)
async def cancel_my_token(
    token_id: str,
    decoded: dict = Depends(verify_token),
) -> MessageResponse:
    """Cancel one of the caller's tokens.

    Only tokens still in the ``pending`` (waiting) state can be cancelled;
    tokens that are active, served, etc. respond 409.
    """
    uid = decoded["uid"]
    db = get_db()
    doc_ref = db.collection("bookings").document(token_id)
    try:
        snapshot = doc_ref.get()
        if not snapshot.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Token '{token_id}' not found.",
            )
        data = snapshot.to_dict() or {}
        if data.get("userId") != uid:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="This token belongs to another user.",
            )
        if data.get("status") != "pending":
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Only a waiting (pending) token can be cancelled.",
            )
        doc_ref.update(
            {"status": "cancelled", "updatedAt": firestore.SERVER_TIMESTAMP}
        )
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to cancel token %s: %s", token_id, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not cancel token. Please try again later.",
        ) from exc

    logger.info("User %s cancelled token %s", uid, token_id)
    return MessageResponse(message="Token cancelled.")
