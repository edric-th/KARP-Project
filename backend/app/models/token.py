"""Pydantic models for tokens (stored in the ``bookings`` collection).

The Firestore data layer is shared with the admin panel, so a "token" the
patient app books is the same document the admin panel calls a "booking".
"""
import re
from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field, field_validator

_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


class BookingType(str, Enum):
    """Reason for the visit. Matches the values used by the admin panel."""

    first_visit = "first_visit"
    follow_up = "follow_up"
    report = "report"


class BookingStatus(str, Enum):
    """Lifecycle status of a token. Matches the values used by the admin panel."""

    pending = "pending"      # waiting in the queue
    active = "active"        # currently being called / served
    served = "served"        # consultation completed
    cancelled = "cancelled"  # cancelled by the patient
    no_show = "no_show"      # skipped because the patient was absent


class BookTokenRequest(BaseModel):
    """Request body for booking a token."""

    hospital_id: str = Field(..., min_length=1)
    doctor_id: str = Field(..., min_length=1)
    booking_type: BookingType = BookingType.first_visit
    appointment_date: str = Field(..., description="Appointment date, YYYY-MM-DD")

    @field_validator("appointment_date")
    @classmethod
    def _validate_date(cls, value: str) -> str:
        """Ensure the date is in YYYY-MM-DD form."""
        if not _DATE_RE.match(value):
            raise ValueError("appointment_date must be in YYYY-MM-DD format")
        return value


class BookTokenResponse(BaseModel):
    """Response returned after successfully booking a token."""

    token_id: str
    token_number: int
    estimated_wait_minutes: int


class Token(BaseModel):
    """A booked token as returned by the API."""

    token_id: str
    token_number: int
    doctor_id: str
    doctor_name: str | None = None
    hospital_id: str
    hospital_name: str | None = None
    booking_type: str
    appointment_date: str
    status: str
    created_at: datetime | None = None
    completed_at: datetime | None = None


class TokenWithPosition(Token):
    """A token enriched with live queue position and wait estimate."""

    current_token: int
    queue_position: int
    estimated_wait_minutes: int
