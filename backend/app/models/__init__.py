"""Pydantic models for request and response bodies."""
from pydantic import BaseModel


class MessageResponse(BaseModel):
    """Generic success message returned by mutating endpoints."""

    message: str
