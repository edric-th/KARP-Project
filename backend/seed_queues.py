"""Reset the demo queues in the Firestore emulator.

Clears ALL bookings + counters, then seeds two live queues for today:
  • an appointment queue for Dr. Anita Sharma (Bir Hospital)
  • an online-token (reception) queue for Bir Hospital

Booking docs mirror the shapes written by the backend (routers/bookings.py and
routers/reception.py): createdAt/updatedAt are real Firestore timestamps, while
calledAt/servedAt/expectedCallAt are ISO strings (matching the admin panel).
bookingDate is today in Nepal time so the queues render right away.

Run against a RUNNING emulator from the backend/ directory:
    python seed_queues.py
"""
import os
import sys
from datetime import datetime, timedelta, timezone

from firebase_admin import firestore

from app.firebase import init_firebase, get_db
from app import firestore_repo as repo

BIR_ID = "hosp_bir"
BIR_NAME = "Bir Hospital"
ANITA_ID = "doc_anita_sharma"
ANITA_NAME = "Anita Sharma"


def _require_emulator() -> None:
    if not (os.getenv("FIRESTORE_EMULATOR_HOST") and os.getenv("FIREBASE_AUTH_EMULATOR_HOST")):
        sys.exit(
            "Refusing to run: FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST "
            "are not set (check backend/.env)."
        )


def _ago(minutes: int) -> str:
    return (datetime.now(timezone.utc) - timedelta(minutes=minutes)).isoformat()


def _ahead(minutes: int) -> str:
    return (datetime.now(timezone.utc) + timedelta(minutes=minutes)).isoformat()


def _clear(db, collection: str) -> int:
    n = 0
    for snap in db.collection(collection).stream():
        snap.reference.delete()
        n += 1
    return n


# (token, status, name, phone, bookingType, est, calledAgo, servedAgo)
_APPTS = [
    (1, "served",  "Ram Bahadur",   "+977 9801 000001", "first_visit",  0, 35, 22),
    (2, "active",  "Sita Devi",     "+977 9801 000002", "follow_up",    0, 6,  None),
    (3, "pending", "Hari Prasad",   "+977 9801 000003", "first_visit",  4,  None, None),
    (4, "pending", "Gita Sharma",   "+977 9801 000004", "report",       17, None, None),
    (5, "pending", "Bikash Tamang", "+977 9801 000005", "follow_up",    25, None, None),
    (6, "pending", "Anjali Rai",    "+977 9801 000006", "first_visit",  31, None, None),
]

# (token, status, name, phone, est, calledAgo)
_ONLINE = [
    (1, "active",  "Maya Gurung",  "+977 9802 000001", 0,  3),
    (2, "pending", "Suresh Thapa", "+977 9802 000002", 1,  None),
    (3, "pending", "Kabita Lama",  "+977 9802 000003", 5,  None),
    (4, "pending", "Dipak Karki",  "+977 9802 000004", 9,  None),
    (5, "pending", "Rita Magar",   "+977 9802 000005", 13, None),
]


def _base(date: str) -> dict:
    return {
        "patientUid": "",
        "bookingDate": date,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }


def seed_appointments(db, date: str) -> None:
    for tok, status, name, phone, btype, est, called, served in _APPTS:
        doc = {
            **_base(date),
            "doctorId": ANITA_ID,
            "doctorName": ANITA_NAME,
            "hospitalId": BIR_ID,
            "hospitalName": BIR_NAME,
            "patientName": name,
            "patientPhone": phone,
            "bookingType": btype,
            "bookingSource": "appointment",
            "status": status,
            "tokenNumber": tok,
            "estimatedWaitMinutes": est,
            "expectedCallAt": _ahead(est),
            "paymentMethod": "cash",
            "paymentStatus": "paid" if status in ("served", "active") else "pending",
        }
        if called is not None:
            doc["calledAt"] = _ago(called)
        if served is not None:
            doc["servedAt"] = _ago(served)
        db.collection("bookings").document().set(doc)
    print(f"[+] Seeded {len(_APPTS)} appointment tokens for Dr. {ANITA_NAME} ({BIR_NAME})")


def seed_online(db, date: str) -> None:
    for tok, status, name, phone, est, called in _ONLINE:
        doc = {
            **_base(date),
            "doctorId": "",
            "doctorName": "",
            "hospitalId": BIR_ID,
            "hospitalName": BIR_NAME,
            "patientName": name,
            "patientPhone": phone,
            "bookingType": "first_visit",
            "bookingSource": "online_token",
            "status": status,
            "tokenNumber": tok,
            "estimatedWaitMinutes": est,
            "expectedCallAt": _ahead(est),
            "paymentMethod": "",
            "paymentStatus": "not_required",
        }
        if called is not None:
            doc["calledAt"] = _ago(called)
        db.collection("bookings").document().set(doc)
    print(f"[+] Seeded {len(_ONLINE)} online tokens for {BIR_NAME} reception queue")


def main() -> None:
    _require_emulator()
    init_firebase()
    db = get_db()
    date = repo.today_str()

    cleared_b = _clear(db, "bookings")
    cleared_c = _clear(db, "counters")
    print(f"[i] Cleared {cleared_b} bookings and {cleared_c} counters")
    print(f"[i] Seeding queues for {date}")

    seed_appointments(db, date)
    seed_online(db, date)
    print("\nDone. Open the admin panel Queue / Board to see them.")


if __name__ == "__main__":
    main()
