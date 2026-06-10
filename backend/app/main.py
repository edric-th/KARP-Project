from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

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


@app.get("/")
def root():
    return {"service": "Mero Palo API", "status": "ok", "docs": "/docs"}


@app.get("/health")
def health():
    return {"status": "ok"}
