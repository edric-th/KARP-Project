"""FastAPI application entry point for the hospital queue management backend."""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.firebase_setup import init_firebase
from app.routes import admin, auth, chatbot, hospitals, queue, tokens

# --- Logging: INFO level for important events, no print statements anywhere.
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI):
    """Initialize Firebase on startup so the first request is not delayed."""
    logger.info("Starting hospital queue backend (environment=%s)", settings.environment)
    init_firebase()
    yield
    logger.info("Hospital queue backend shutting down")


app = FastAPI(
    title="Hospital Queue Management API",
    description=(
        "Backend for the Mero Palo smart hospital queue system. Handles patient "
        "token booking, live queue control for staff, wait-time estimation and "
        "FCM push notifications. All endpoints require a Firebase ID token."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

# --- CORS: allow the admin panel dev origins; allow everything in development
#     so the Flutter app (which has no fixed origin) can also connect.
if settings.is_development:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,  # cannot use credentials with a wildcard origin
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["*"],
    )
else:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["*"],
    )

# --- Routers
app.include_router(auth.router)
app.include_router(hospitals.router)
app.include_router(tokens.router)
app.include_router(queue.router)
app.include_router(admin.router)
app.include_router(chatbot.router)


@app.get("/", tags=["health"])
async def root() -> dict:
    """Root endpoint - basic service metadata."""
    return {
        "service": "Hospital Queue Management API",
        "version": "1.0.0",
        "docs": "/docs",
    }


@app.get("/health", tags=["health"])
async def health() -> dict:
    """Lightweight health check for uptime monitoring."""
    return {"status": "ok", "environment": settings.environment}
