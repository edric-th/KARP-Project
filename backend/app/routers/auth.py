import random
import traceback
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException

from .. import auth_service, email_service
from ..config import OTP_TTL_MINUTES
from ..firebase import get_db
from ..schemas import (
    SignupRequest, LoginRequest, RefreshRequest, AuthResponse, UserOut,
    SendOtpRequest, VerifyOtpRequest, ChangePasswordRequest,
)
from ..security import get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])


def _otp_key(email: str) -> str:
    return email.strip().lower().replace("/", "_")


def _auth_response(uid, email, name, phone, role, tokens) -> AuthResponse:
    return AuthResponse(
        id_token=tokens["idToken"],
        refresh_token=tokens["refreshToken"],
        expires_in=int(tokens.get("expiresIn", 3600)),
        user=UserOut(uid=uid, email=email, name=name, phone=phone, role=role),
    )


def _require_verified_email(email: str):
    """Block signup unless this email completed OTP verification (see /verify-otp).

    Returns the OTP doc ref so the caller can consume it after a successful
    signup. Raises 403 when no verified OTP exists for the email."""
    ref = get_db().collection("email_otps").document(_otp_key(email))
    snap = ref.get()
    data = snap.to_dict() if snap.exists else None
    if not data or not data.get("verified"):
        raise HTTPException(
            403, "Please verify your email with the code we sent before signing up"
        )
    return ref


@router.post("/signup", response_model=AuthResponse)
async def signup(body: SignupRequest):
    otp_ref = _require_verified_email(body.email)
    uid, tokens = await auth_service.sign_up(body.name, body.email, body.password, body.phone)
    otp_ref.delete()  # consume the verification only after a successful signup
    return _auth_response(uid, body.email, body.name, body.phone, "patient", tokens)


@router.post("/login", response_model=AuthResponse)
async def login(body: LoginRequest):
    tokens = await auth_service.login(body.email, body.password)
    uid = tokens["localId"]
    snap = get_db().collection("users").document(uid).get()
    data = snap.to_dict() if snap.exists else {}
    return _auth_response(
        uid,
        data.get("email", body.email),
        data.get("name"),
        data.get("phone"),
        data.get("role", "patient"),
        tokens,
    )


@router.post("/refresh", response_model=AuthResponse)
async def refresh(body: RefreshRequest):
    tokens = await auth_service.refresh_id_token(body.refresh_token)
    uid = tokens["user_id"]
    snap = get_db().collection("users").document(uid).get()
    data = snap.to_dict() if snap.exists else {}
    return AuthResponse(
        id_token=tokens["id_token"],
        refresh_token=tokens["refresh_token"],
        expires_in=int(tokens.get("expires_in", 3600)),
        user=UserOut(
            uid=uid,
            email=data.get("email"),
            name=data.get("name"),
            phone=data.get("phone"),
            role=data.get("role", "patient"),
        ),
    )


@router.post("/change-password")
async def change_password(
    body: ChangePasswordRequest, user: dict = Depends(get_current_user)
):
    if len(body.new_password) < 6:
        raise HTTPException(400, "New password must be at least 6 characters")
    if body.new_password == body.current_password:
        raise HTTPException(400, "New password must be different from the current one")
    await auth_service.change_password(
        user["uid"], user.get("email"), body.current_password, body.new_password
    )
    return {"ok": True}


@router.post("/verify-email")
def verify_email(user: dict = Depends(get_current_user)):
    """Flag the signed-in user's email as verified, once they've completed the
    OTP for their own address (via /send-otp + /verify-otp)."""
    email = (user.get("email") or "").strip().lower()
    if not email:
        raise HTTPException(400, "This account has no email on file")
    ref = get_db().collection("email_otps").document(_otp_key(email))
    snap = ref.get()
    data = snap.to_dict() if snap.exists else None
    if not data or not data.get("verified"):
        raise HTTPException(400, "Please verify the code sent to your email first")
    get_db().collection("users").document(user["uid"]).set(
        {"emailVerified": True}, merge=True
    )
    ref.delete()  # consume the OTP
    return {"emailVerified": True}


@router.get("/me", response_model=UserOut)
async def me(user: dict = Depends(get_current_user)):
    return UserOut(
        uid=user["uid"], email=user["email"], name=user.get("name"),
        phone=user.get("phone"), role=user["role"],
    )


# ---- Email OTP (registration verification) ----------------------------------

@router.post("/send-otp")
def send_otp(body: SendOtpRequest):
    email = body.email.strip().lower()
    if "@" not in email or "." not in email:
        raise HTTPException(400, "Please enter a valid email address")

    ref = get_db().collection("email_otps").document(_otp_key(email))
    now = datetime.now(timezone.utc)

    snap = ref.get()
    if snap.exists:
        last = (snap.to_dict() or {}).get("lastSentAt")
        if last:
            try:
                if (now - datetime.fromisoformat(last)).total_seconds() < 30:
                    raise HTTPException(
                        429, "Please wait a few seconds before requesting another code"
                    )
            except HTTPException:
                raise
            except Exception:
                pass

    code = f"{random.randint(0, 999999):06d}"
    ref.set({
        "email": email,
        "code": code,
        "attempts": 0,
        "verified": False,
        "expiresAt": (now + timedelta(minutes=OTP_TTL_MINUTES)).isoformat(),
        "lastSentAt": now.isoformat(),
        "createdAt": now.isoformat(),
    })

    resp = {"sent": True}
    if email_service.smtp_configured():
        try:
            email_service.send_otp_email(email, code)
        except Exception as e:
            # Log the real cause server-side — the HTTP detail alone is easy to miss.
            traceback.print_exc()
            print(f"[OTP][error] send failed for {email}: {type(e).__name__}: {e}")
            raise HTTPException(502, f"Could not send the verification email: {e}")
    else:
        # Dev fallback: no SMTP configured — surface the code so it's testable.
        print(f"[OTP][dev] {email} -> {code}")
        resp["devCode"] = code
    return resp


@router.post("/verify-otp")
def verify_otp(body: VerifyOtpRequest):
    email = body.email.strip().lower()
    ref = get_db().collection("email_otps").document(_otp_key(email))
    snap = ref.get()
    if not snap.exists:
        raise HTTPException(400, "Please request a code first")
    data = snap.to_dict() or {}

    exp = data.get("expiresAt")
    if exp:
        try:
            if datetime.fromisoformat(exp) < datetime.now(timezone.utc):
                raise HTTPException(400, "That code has expired — request a new one")
        except HTTPException:
            raise
        except Exception:
            pass

    attempts = int(data.get("attempts", 0))
    if attempts >= 5:
        raise HTTPException(429, "Too many attempts — request a new code")

    if str(body.code).strip() != str(data.get("code")):
        ref.update({"attempts": attempts + 1})
        raise HTTPException(400, "Incorrect code, please try again")

    ref.update({"verified": True})
    return {"verified": True}


# ---- Google sign-in (client obtains a Firebase idToken, we upsert profile) ---

@router.post("/google", response_model=UserOut)
def google_upsert(user: dict = Depends(get_current_user)):
    """Called right after a Google sign-in (Bearer = Firebase idToken).
    Ensures a users/{uid} patient profile exists, backfilling name/email."""
    db = get_db()
    ref = db.collection("users").document(user["uid"])
    snap = ref.get()
    if not snap.exists:
        ref.set({
            "email": user.get("email") or "",
            "name": user.get("name") or "",
            "role": "patient",
            "photoUrl": user.get("picture") or "",
            "createdAt": datetime.now(timezone.utc).isoformat(),
        })
        role, name = "patient", user.get("name")
    else:
        data = snap.to_dict() or {}
        patch = {}
        if not data.get("email") and user.get("email"):
            patch["email"] = user["email"]
        if not data.get("name") and user.get("name"):
            patch["name"] = user["name"]
        if patch:
            ref.set(patch, merge=True)
        role = data.get("role", "patient")
        name = data.get("name") or user.get("name")

    return UserOut(
        uid=user["uid"], email=user.get("email"), name=name,
        phone=user.get("phone"), role=role,
    )
