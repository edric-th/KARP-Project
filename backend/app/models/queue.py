"""Pydantic models for queue state."""
from pydantic import BaseModel


class QueueState(BaseModel):
    """Live state of a single doctor's queue for one day."""

    queue_id: str
    hospital_id: str
    doctor_id: str
    date: str
    last_issued_token: int
    current_token: int
    called_token: int
    status: str
    average_consultation_minutes: float
    waiting_count: int
