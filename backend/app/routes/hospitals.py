"""Read-only routes for browsing hospitals and doctors."""
import logging
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from google.cloud.firestore_v1.base_query import FieldFilter

from app.dependencies import verify_token
from app.firebase_setup import get_db
from app.models.doctor import Doctor
from app.models.hospital import Hospital

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["hospitals"])


def to_hospital(doc_id: str, data: dict[str, Any]) -> Hospital:
    """Map a Firestore ``hospitals`` document to a Hospital response model."""
    return Hospital(
        id=doc_id,
        name=data.get("name", ""),
        address=data.get("address"),
        phone=data.get("phone"),
        city=data.get("city"),
        created_at=data.get("createdAt"),
    )


def to_doctor(doc_id: str, data: dict[str, Any]) -> Doctor:
    """Map a Firestore ``doctors`` document to a Doctor response model.

    The admin panel stores the consultation fee under ``fee``; this also
    accepts ``consultationFee`` for forward compatibility.
    """
    return Doctor(
        id=doc_id,
        name=data.get("name", ""),
        hospital_id=data.get("hospitalId"),
        specialty=data.get("specialty"),
        consultation_fee=data.get("fee", data.get("consultationFee")),
        consultation_hours=data.get("consultationHours"),
        available_days=data.get("availableDays", []) or [],
        created_at=data.get("createdAt"),
    )


@router.get("/hospitals", response_model=list[Hospital])
async def list_hospitals(_: dict = Depends(verify_token)) -> list[Hospital]:
    """List every hospital in the system."""
    db = get_db()
    try:
        docs = db.collection("hospitals").stream()
        return [to_hospital(doc.id, doc.to_dict() or {}) for doc in docs]
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to list hospitals: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not load hospitals. Please try again later.",
        ) from exc


@router.get("/hospitals/{hospital_id}", response_model=Hospital)
async def get_hospital(hospital_id: str, _: dict = Depends(verify_token)) -> Hospital:
    """Return a single hospital by its document ID."""
    db = get_db()
    try:
        snapshot = db.collection("hospitals").document(hospital_id).get()
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to load hospital %s: %s", hospital_id, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not load hospital. Please try again later.",
        ) from exc

    if not snapshot.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Hospital '{hospital_id}' not found.",
        )
    return to_hospital(snapshot.id, snapshot.to_dict() or {})


@router.get("/hospitals/{hospital_id}/doctors", response_model=list[Doctor])
async def list_hospital_doctors(
    hospital_id: str,
    _: dict = Depends(verify_token),
) -> list[Doctor]:
    """List all doctors that belong to the given hospital."""
    db = get_db()
    try:
        if not db.collection("hospitals").document(hospital_id).get().exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Hospital '{hospital_id}' not found.",
            )
        docs = (
            db.collection("doctors")
            .where(filter=FieldFilter("hospitalId", "==", hospital_id))
            .stream()
        )
        return [to_doctor(doc.id, doc.to_dict() or {}) for doc in docs]
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to list doctors for hospital %s: %s", hospital_id, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not load doctors. Please try again later.",
        ) from exc


@router.get("/doctors/{doctor_id}", response_model=Doctor)
async def get_doctor(doctor_id: str, _: dict = Depends(verify_token)) -> Doctor:
    """Return a single doctor's details by document ID."""
    db = get_db()
    try:
        snapshot = db.collection("doctors").document(doctor_id).get()
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to load doctor %s: %s", doctor_id, exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not load doctor. Please try again later.",
        ) from exc

    if not snapshot.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Doctor '{doctor_id}' not found.",
        )
    return to_doctor(snapshot.id, snapshot.to_dict() or {})
