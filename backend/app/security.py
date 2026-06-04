"""Auth dependencies. Clients send a Firebase ID token as `Authorization:
Bearer <token>`; we verify it with the Admin SDK and load the user's role."""
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from .firebase import get_auth, get_db

_bearer = HTTPBearer(auto_error=False)


def get_current_user(creds: HTTPAuthorizationCredentials = Depends(_bearer)) -> dict:
    if creds is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization bearer token",
        )
    try:
        # Allow a small clock skew: a freshly-issued token can have an `iat`
        # a couple of seconds ahead of this server's clock, which would
        # otherwise raise "Token used too early" right after login.
        decoded = get_auth().verify_id_token(creds.credentials, clock_skew_seconds=10)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )

    uid = decoded["uid"]
    snap = get_db().collection("users").document(uid).get()
    data = snap.to_dict() if snap.exists else {}
    return {
        "uid": uid,
        "email": decoded.get("email") or (data or {}).get("email"),
        # Prefer the stored profile name; fall back to the token's display name
        # (e.g. a brand-new Google sign-in before a users/{uid} doc exists).
        "name": (data or {}).get("name") or decoded.get("name"),
        "phone": (data or {}).get("phone"),
        "role": (data or {}).get("role", "patient"),
        "picture": decoded.get("picture"),
    }


def require_role(*roles):
    def dependency(user: dict = Depends(get_current_user)) -> dict:
        if user["role"] not in roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient permissions")
        return user

    return dependency
