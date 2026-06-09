"""Firebase Auth helpers.

Sign-up uses the Admin SDK (so we control the uid and write the users/{uid}
profile doc atomically). Sign-in uses the Firebase Auth REST API to obtain an
ID token / refresh token to hand back to the client."""
import httpx
from fastapi import HTTPException
from firebase_admin import auth as admin_auth, firestore

from .config import FIREBASE_API_KEY
from .firebase import get_auth, get_db

_REST = "https://identitytoolkit.googleapis.com/v1/accounts"
_SECURE_TOKEN = "https://securetoken.googleapis.com/v1/token"

_FRIENDLY = {
    "EMAIL_NOT_FOUND": "No account found with that email",
    "INVALID_PASSWORD": "Incorrect password",
    "INVALID_LOGIN_CREDENTIALS": "Incorrect email or password",
    "USER_DISABLED": "This account has been disabled",
    "MISSING_PASSWORD": "Password is required",
}


async def _rest_sign_in(email: str, password: str) -> dict:
    if not FIREBASE_API_KEY:
        raise HTTPException(500, "FIREBASE_API_KEY is not configured on the server")
    async with httpx.AsyncClient(timeout=20) as client:
        resp = await client.post(
            f"{_REST}:signInWithPassword",
            params={"key": FIREBASE_API_KEY},
            json={"email": email, "password": password, "returnSecureToken": True},
        )
    if resp.status_code != 200:
        code = resp.json().get("error", {}).get("message", "AUTH_FAILED")
        raise HTTPException(401, _FRIENDLY.get(code, "Login failed"))
    return resp.json()


async def sign_up(name: str, email: str, password: str, phone: str | None):
    auth = get_auth()
    try:
        user = auth.create_user(email=email, password=password, display_name=name)
    except admin_auth.EmailAlreadyExistsError:
        raise HTTPException(409, "An account with this email already exists")
    except ValueError as e:
        raise HTTPException(400, f"Invalid signup details: {e}")
    except Exception as e:
        raise HTTPException(400, f"Could not create account: {e}")

    get_db().collection("users").document(user.uid).set({
        "email": email,
        "name": name,
        "phone": phone or "",
        "role": "patient",
        # Sign-up requires completing the email OTP (see auth router), so the
        # email is verified by the time we reach here.
        "emailVerified": True,
        "createdAt": firestore.SERVER_TIMESTAMP,
    })

    tokens = await _rest_sign_in(email, password)
    return user.uid, tokens


async def change_password(uid: str, email: str | None, current_password: str,
                          new_password: str) -> None:
    """Verify the current password, then set a new one for this account."""
    if not email:
        raise HTTPException(400, "This account has no email/password login")
    # Re-authenticate to confirm the current password (raises 401 if wrong).
    await _rest_sign_in(email, current_password)
    try:
        get_auth().update_user(uid, password=new_password)
    except Exception as e:
        raise HTTPException(400, f"Could not update password: {e}")


async def login(email: str, password: str) -> dict:
    return await _rest_sign_in(email, password)


async def refresh_id_token(refresh_token: str) -> dict:
    """Exchange a refresh token for a fresh ID token. Note: this endpoint
    returns snake_case keys (id_token, refresh_token, expires_in, user_id)."""
    if not FIREBASE_API_KEY:
        raise HTTPException(500, "FIREBASE_API_KEY is not configured on the server")
    async with httpx.AsyncClient(timeout=20) as client:
        resp = await client.post(
            _SECURE_TOKEN,
            params={"key": FIREBASE_API_KEY},
            data={"grant_type": "refresh_token", "refresh_token": refresh_token},
        )
    if resp.status_code != 200:
        raise HTTPException(401, "Could not refresh session; please sign in again")
    return resp.json()
