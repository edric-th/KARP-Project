"""Pydantic models for hospitals."""
from datetime import datetime

from pydantic import BaseModel, Field


class HospitalCreate(BaseModel):
    """Request body for creating a hospital."""

    name: str = Field(..., min_length=1, max_length=200)
    address: str | None = Field(default=None, max_length=300)
    phone: str | None = Field(default=None, max_length=40)
    city: str | None = Field(default=None, max_length=120)


class HospitalUpdate(BaseModel):
    """Request body for updating a hospital. All fields optional."""

    name: str | None = Field(default=None, min_length=1, max_length=200)
    address: str | None = Field(default=None, max_length=300)
    phone: str | None = Field(default=None, max_length=40)
    city: str | None = Field(default=None, max_length=120)


class Hospital(BaseModel):
    """A hospital as returned by the API."""

    id: str
    name: str
    address: str | None = None
    phone: str | None = None
    city: str | None = None
    created_at: datetime | None = None
