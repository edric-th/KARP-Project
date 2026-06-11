"""Thin data-access helpers over Firestore. Uses single-field queries plus
in-memory filtering/sorting so no composite indexes are required."""
import time
from datetime import datetime, timedelta, timezone

import google.cloud.firestore_v1 as fsv1
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter

from .config import QUERY_CACHE_TTL_SECONDS
from .firebase import get_db

# Nepal has a fixed +05:45 offset (no DST). Anchoring "today" to Nepal time keeps
# the booking date stable regardless of where the server is hosted, so it always
# matches the admin panel (which uses the browser's local Nepal date).
NEPAL_TZ = timezone(timedelta(hours=5, minutes=45))

# ---- Short-TTL read cache for hot queue queries -----------------------------
# The patient app and admin panel poll the same doctor/hospital queues every few
# seconds, and each poll reads every matching booking doc. Caching the result
# for a few seconds collapses those identical reads into one Firestore query per
# window so the free-tier read quota lasts. Writes invalidate the affected key
# (see invalidate_for_booking) so a new/cancelled booking shows up immediately.
_QUERY_CACHE: dict = {}


def _cached(key: tuple, loader):
    """Reuse [loader]'s last result for this [key] while it's younger than the
    configured TTL, returning a per-call shallow copy so callers that mutate
    booking dicts in place (e.g. /bookings/me) can't corrupt the cache."""
    if QUERY_CACHE_TTL_SECONDS <= 0:
        return loader()
    now = time.monotonic()
    hit = _QUERY_CACHE.get(key)
    if hit is None or (now - hit[0]) >= QUERY_CACHE_TTL_SECONDS:
        hit = (now, loader())
        _QUERY_CACHE[key] = hit
    return [dict(b) for b in hit[1]]


def invalidate_for_booking(booking: dict) -> None:
    """Drop any cached queue list a write to [booking] would make stale."""
    if not booking:
        return
    date = booking.get("bookingDate")
    if not date:
        return
    if booking.get("doctorId"):
        _QUERY_CACHE.pop(("doctor", booking["doctorId"], date), None)
    if booking.get("hospitalId"):
        _QUERY_CACHE.pop(("reception", booking["hospitalId"], date), None)


def _epoch(value) -> float:
    """Sortable epoch seconds from a Firestore timestamp / datetime (else 0)."""
    if hasattr(value, "timestamp"):
        try:
            return value.timestamp()
        except Exception:
            return 0.0
    return 0.0


def today_str() -> str:
    n = datetime.now(NEPAL_TZ)
    return f"{n.year}-{n.month:02d}-{n.day:02d}"


def doc_to_dict(snap) -> dict:
    data = snap.to_dict() or {}
    data["id"] = snap.id
    return data


def get_all(collection: str) -> list:
    return [doc_to_dict(s) for s in get_db().collection(collection).stream()]


def get_one(collection: str, doc_id: str):
    snap = get_db().collection(collection).document(doc_id).get()
    return doc_to_dict(snap) if snap.exists else None


def query_eq(collection: str, field: str, value) -> list:
    q = get_db().collection(collection).where(filter=FieldFilter(field, "==", value))
    return [doc_to_dict(s) for s in q.stream()]


def bookings_for_doctor(doctor_id: str, date: str) -> list:
    def _load():
        items = query_eq("bookings", "doctorId", doctor_id)
        items = [b for b in items if b.get("bookingDate") == date]
        items.sort(key=lambda b: b.get("tokenNumber") or 0)
        return items

    return _cached(("doctor", doctor_id, date), _load)


def bookings_for_patient(uid: str) -> list:
    items = query_eq("bookings", "patientUid", uid)
    items.sort(key=lambda b: b.get("bookingDate") or "", reverse=True)
    return items


def next_token_number(doctor_id: str, date: str) -> int:
    """Race-safe per-doctor/per-day ticket number using a counter doc + txn.

    Seeds the counter from any existing tokens (e.g. created by the admin panel)
    so app-created and admin-created tokens never collide.
    """
    db = get_db()
    ref = db.collection("counters").document(f"{doctor_id}_{date}")

    if not ref.get().exists:
        existing = bookings_for_doctor(doctor_id, date)
        max_token = max([b.get("tokenNumber") or 0 for b in existing], default=0)
        ref.set({"doctorId": doctor_id, "date": date, "lastToken": max_token}, merge=True)

    transaction = db.transaction()

    @fsv1.transactional
    def _increment(txn):
        snap = ref.get(transaction=txn)
        last = (snap.to_dict() or {}).get("lastToken", 0) if snap.exists else 0
        new_value = int(last) + 1
        txn.set(ref, {"doctorId": doctor_id, "date": date, "lastToken": new_value}, merge=True)
        return new_value

    return _increment(transaction)


# ---- Reception (online-token) queue -----------------------------------------
# Online tokens are a hospital-level queue served by the reception desk — they
# are NOT tied to a doctor. They live in the same `bookings` collection with an
# empty doctorId and bookingSource == "online_token", so doctor queues (which
# filter by doctorId) never pick them up.

def reception_tokens_for_hospital(hospital_id: str, date: str) -> list:
    def _load():
        items = query_eq("bookings", "hospitalId", hospital_id)
        items = [
            b for b in items
            if b.get("bookingSource") == "online_token"
            and b.get("bookingDate") == date
        ]
        items.sort(key=lambda b: b.get("tokenNumber") or 0)
        return items

    return _cached(("reception", hospital_id, date), _load)


def next_reception_token(hospital_id: str, date: str) -> int:
    """Race-safe per-hospital/per-day reception ticket number (counter + txn)."""
    db = get_db()
    ref = db.collection("counters").document(f"reception_{hospital_id}_{date}")

    if not ref.get().exists:
        existing = reception_tokens_for_hospital(hospital_id, date)
        max_token = max([b.get("tokenNumber") or 0 for b in existing], default=0)
        ref.set(
            {"hospitalId": hospital_id, "date": date, "lastToken": max_token},
            merge=True,
        )

    transaction = db.transaction()

    @fsv1.transactional
    def _increment(txn):
        snap = ref.get(transaction=txn)
        last = (snap.to_dict() or {}).get("lastToken", 0) if snap.exists else 0
        new_value = int(last) + 1
        txn.set(
            ref,
            {"hospitalId": hospital_id, "date": date, "lastToken": new_value},
            merge=True,
        )
        return new_value

    return _increment(transaction)


# ---- Notifications ----------------------------------------------------------

def notifications_for_patient(uid: str) -> list:
    items = query_eq("notifications", "patientUid", uid)
    items.sort(key=lambda n: _epoch(n.get("createdAt")), reverse=True)
    return items


def add_notification(patient_uid, title, body, category="general", related_booking_id=None):
    """Fire-and-forget notification doc the patient app reads. No-op if no uid."""
    if not patient_uid:
        return
    get_db().collection("notifications").add({
        "patientUid": patient_uid,
        "title": title,
        "body": body,
        "category": category,
        "relatedBookingId": related_booking_id,
        "isRead": False,
        "createdAt": firestore.SERVER_TIMESTAMP,
    })


# ---- Reviews ----------------------------------------------------------------

def reviews_for_doctor(doctor_id: str) -> list:
    items = query_eq("reviews", "doctorId", doctor_id)
    items.sort(key=lambda r: _epoch(r.get("createdAt")), reverse=True)
    return items


def recompute_doctor_rating(doctor_id: str) -> dict:
    """Average the doctor's reviews back onto the doctor doc (rating/reviewCount)."""
    reviews = reviews_for_doctor(doctor_id)
    ratings = [r.get("rating") for r in reviews if isinstance(r.get("rating"), (int, float))]
    count = len(ratings)
    avg = round(sum(ratings) / count, 1) if count else 0
    get_db().collection("doctors").document(doctor_id).update({
        "rating": avg,
        "reviewCount": count,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    })
    return {"rating": avg, "reviewCount": count}


# ---- Derived hospital queue size --------------------------------------------

def hospital_queue_count(hospital_id: str, date: str) -> int:
    """Live waiting+active count across all of a hospital's doctors for a date."""
    total = 0
    for d in query_eq("doctors", "hospitalId", hospital_id):
        bookings = bookings_for_doctor(d["id"], date)
        total += len([b for b in bookings if b.get("status") in ("pending", "active")])
    return total
