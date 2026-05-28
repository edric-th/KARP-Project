"""Pydantic models for doctors."""
from datetime import datetime

from pydantic import BaseModel, Field


class DoctorCreate(BaseModel):
    """Request body for creating a doctor."""

    name: str = Field(..., min_length=1, max_length=160)
    hospital_id: str = Field(..., min_length=1)
    specialty: str | None = Field(default=None, max_length=160)
    consultation_fee: float | None = Field(default=None, ge=0)
    consultation_hours: str | None = Field(default=None, max_length=160)
    available_days: list[str] = Field(default_factory=list)


class DoctorUpdate(BaseModel):
    """Request body for updating a doctor. All fields optional."""

    name: str | None = Field(default=None, min_length=1, max_length=160)
    hospital_id: str | None = Field(default=None, min_length=1)
    specialty: str | None = Field(default=None, max_length=160)
    consultation_fee: float | None = Field(default=None, ge=0)
    consultation_hours: str | None = Field(default=None, max_length=160)
    available_days: list[str] | None = None


class Doctor(BaseModel):
    """A doctor as returned by the API."""

    id: str
    name: str
    hospital_id: str | None = None
    specialty: str | None = None
    consultation_fee: float | None = None
    consultation_hours: str | None = None
    available_days: list[str] = Field(default_factory=list)
    created_at: datetime | None = None
