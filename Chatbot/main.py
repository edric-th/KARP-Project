"""
Hospital Queue Chatbot — FastAPI application.

Endpoints:
    POST /chatbot/query    — send a user message, get a bot response
    POST /chatbot/reset    — clear a session's conversation history
    GET  /chatbot/health   — liveness check
    GET  /chatbot/intents  — list all loaded intents (debug)
"""

from collections import defaultdict
from typing import Any

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from bot import get_all_intents, get_response

# ── App setup ──────────────────────────────────────────────────────────────────
app = FastAPI(
    title="Hospital Queue Chatbot API",
    description=(
        "AI-powered chatbot for the Hospital Queue Management App (Nepal). "
        "Handles app-usage questions and provides medical triage guidance, "
        "routing patients to the right specialist. "
        "Powered by Google Gemini. "
        "⚠️ Medical responses are for general guidance only — always consult a qualified doctor."
    ),
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory session store: session_id → list of {role, content} dicts
# Each list holds at most 10 entries (5 turns × 2 roles).
_sessions: dict[str, list[dict[str, str]]] = defaultdict(list)
_MAX_STORED_TURNS = 10


# ── Pydantic models ────────────────────────────────────────────────────────────
class QueryRequest(BaseModel):
    message: str = Field(
        ...,
        min_length=1,
        max_length=1000,
        description="The user's message to the chatbot.",
        examples=["How do I book a token?"],
    )
    session_id: str | None = Field(
        default=None,
        description="Optional session ID for multi-turn conversation memory.",
    )


class QueryResponse(BaseModel):
    response: str = Field(description="The chatbot's reply.")
    matched_intent_name: str | None = Field(
        description="Short label for the matched intent or topic."
    )
    intent_category: str = Field(
        description="Category: 'app', 'medical', 'general', or 'out_of_scope'."
    )
    confidence_score: float = Field(description="Confidence score (0–100).")
    is_emergency: bool = Field(
        description="True when the response is for a medical emergency."
    )
    disclaimer_added: bool = Field(
        description="True when the medical disclaimer was appended to the response."
    )


class ResetRequest(BaseModel):
    session_id: str = Field(description="Session ID whose history should be cleared.")


class ResetResponse(BaseModel):
    cleared: bool
    session_id: str


class IntentSummary(BaseModel):
    name: str
    category: str
    example_count: int
    is_emergency: bool


class IntentsResponse(BaseModel):
    total: int
    intents: list[IntentSummary]


class HealthResponse(BaseModel):
    status: str
    intents_loaded: int
    version: str


# ── Routes ─────────────────────────────────────────────────────────────────────
@app.post(
    "/chatbot/query",
    response_model=QueryResponse,
    summary="Send a message to the chatbot",
    tags=["Chatbot"],
)
async def query(request: QueryRequest) -> QueryResponse:
    """
    Send a user message and receive a structured chatbot response.

    Pass an optional **session_id** to enable multi-turn conversation memory
    (the bot will remember the last 5 turns of the conversation).

    The bot uses Google Gemini to understand natural language across three categories:
    - **app** — queue management, booking, notifications, etc.
    - **medical** — symptom triage, emergency routing
    - **general** — greetings, help, fallback
    - **out_of_scope** — topics outside health or the app

    Emergency medical responses will have `is_emergency: true`.
    """
    try:
        session_id = request.session_id
        history = _sessions[session_id] if session_id else []

        result: dict[str, Any] = get_response(request.message, history)

        # Update session history
        if session_id:
            _sessions[session_id].append({"role": "user", "content": request.message})
            _sessions[session_id].append(
                {"role": "assistant", "content": result["response"]}
            )
            # Keep only the last N entries to cap memory usage
            if len(_sessions[session_id]) > _MAX_STORED_TURNS:
                _sessions[session_id] = _sessions[session_id][-_MAX_STORED_TURNS:]

        return QueryResponse(**result)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"An unexpected error occurred: {exc}",
        ) from exc


@app.post(
    "/chatbot/reset",
    response_model=ResetResponse,
    summary="Clear a session's conversation history",
    tags=["Chatbot"],
)
async def reset_session(request: ResetRequest) -> ResetResponse:
    """Clear the stored conversation history for the given session_id."""
    existed = request.session_id in _sessions
    if existed:
        del _sessions[request.session_id]
    return ResetResponse(cleared=existed, session_id=request.session_id)


@app.get(
    "/chatbot/health",
    response_model=HealthResponse,
    summary="Health check",
    tags=["System"],
)
async def health() -> HealthResponse:
    """Returns the service status and the number of intents currently loaded."""
    intents = get_all_intents()
    return HealthResponse(
        status="ok",
        intents_loaded=len(intents),
        version="2.0.0",
    )


@app.get(
    "/chatbot/intents",
    response_model=IntentsResponse,
    summary="List all loaded intents",
    tags=["System"],
)
async def list_intents() -> IntentsResponse:
    """
    Returns a summary of every intent in the reference JSON files.
    These are now used as context for Gemini rather than hard matching rules.
    """
    intents = get_all_intents()
    return IntentsResponse(
        total=len(intents),
        intents=[IntentSummary(**i) for i in intents],
    )
