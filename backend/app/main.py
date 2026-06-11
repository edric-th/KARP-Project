from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from google.api_core import exceptions as gcloud_exc

from .config import CORS_ORIGINS
from .firebase import init_firebase
from .routers import (
    auth, hospitals, doctors, bookings, queue, profile, notifications, chatbot,
    reception,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        init_firebase()
        print("[startup] Firebase Admin initialized.")
    except Exception as e:
        # The server still boots so /health and docs work; Firebase calls will
        # 500 until the service account key is provided.
        print(f"[startup][WARN] Firebase not initialized: {e}")
    yield


app = FastAPI(title="Mero Palo API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

for r in (
    auth.router, hospitals.router, doctors.router, bookings.router,
    queue.router, reception.router, profile.router, notifications.router,
    chatbot.router,
):
    app.include_router(r, prefix="/api")


@app.exception_handler(gcloud_exc.ResourceExhausted)
async def _firestore_quota_handler(request: Request, exc: Exception):
    """Firestore daily/free-tier quota is exhausted (gRPC RESOURCE_EXHAUSTED).
    Return a clean 503 instead of letting it bubble up as an ASGI 500 crash so
    the client can show a sensible message and back off. Quota resets daily."""
    print(f"[firestore][quota] {request.method} {request.url.path}: {exc}")
    return JSONResponse(
        status_code=503,
        content={
            "detail": "The service is temporarily over its database quota. "
            "Please try again in a little while."
        },
        headers={"Retry-After": "60"},
    )


@app.exception_handler(gcloud_exc.ServiceUnavailable)
async def _firestore_unavailable_handler(request: Request, exc: Exception):
    """Transient Firestore unavailability — surface as a retryable 503."""
    print(f"[firestore][unavailable] {request.method} {request.url.path}: {exc}")
    return JSONResponse(
        status_code=503,
        content={"detail": "The database is temporarily unavailable. Please retry."},
        headers={"Retry-After": "15"},
    )


@app.get("/")
def root():
    return {"service": "Mero Palo API", "status": "ok", "docs": "/docs"}


@app.get("/health")
def health():
    return {"status": "ok"}
