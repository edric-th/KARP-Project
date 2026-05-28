"""Pydantic models for user profiles."""
from datetime import datetime

from pydantic import BaseModel, Field


class RegisterRequest(BaseModel):
    """Request body for creating a profile after Firebase signup."""

    name: str = Field(..., min_length=1, max_length=120)
    phone: str = Field(..., min_length=3, max_length=30)


class FcmTokenRequest(BaseModel):
    """Request body for saving a device's FCM registration token."""

    fcm_token: str = Field(..., min_length=1)


class UserProfile(BaseModel):
    """A user profile as returned by the API."""

    uid: str
    name: str
    phone: str
    email: str | None = None
    role: str
    fcm_token: str | None = None
    created_at: datetime | None = None
