"""Stub route for the (not yet integrated) queue assistant chatbot."""
import logging

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.dependencies import verify_token

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["chatbot"])


class ChatbotQuery(BaseModel):
    """Request body for a chatbot question."""

    message: str = Field(..., min_length=1, max_length=1000)


class ChatbotResponse(BaseModel):
    """Chatbot reply payload."""

    reply: str
    integrated: bool


@router.post("/chatbot/query", response_model=ChatbotResponse)
async def chatbot_query(
    body: ChatbotQuery,
    _: dict = Depends(verify_token),
) -> ChatbotResponse:
    """Placeholder chatbot endpoint.

    Accepts a user message and currently returns a fixed message. Wire a real
    NLP / LLM backend in here later; the request/response contract can stay.
    """
    logger.info("Chatbot query received (stub): %s", body.message[:80])
    return ChatbotResponse(
        reply="Chatbot not yet integrated.",
        integrated=False,
    )
