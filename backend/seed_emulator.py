"""Seed the Firebase Auth + Firestore emulators with an admin user plus a sample
catalog (hospitals + doctors) so the admin panel and patient app are ready to
test.

The emulators start empty on every boot, and the admin panel's
onAuthStateChanged gate requires the signed-in user to have a users/{uid}
Firestore doc whose `role` is one of admin / receptionist / doctor. This script
creates that user in the Auth emulator and writes the matching profile doc, then
fills the hospitals + doctors collections with realistic sample data.

Run from the backend/ directory with the emulators running:

    python seed_emulator.py

Importing app.config triggers load_dotenv(backend/.env), which sets
FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST before init_firebase()
runs, so it enters emulator mode (no service-account JSON needed). The script is
idempotent: re-runs reuse the existing user and refresh the profile doc.

Override the defaults with env vars: ADMIN_EMAIL, ADMIN_PASSWORD, ADMIN_NAME,
ADMIN_PHONE, ADMIN_ROLE.
"""
import os
import sys

# Importing from app.* runs app/config.py, which calls load_dotenv(backend/.env)
# at import time, populating the emulator host env vars before we initialize.
from app.config import FIREBASE_PROJECT_ID
from app.firebase import init_firebase, get_db, get_auth

from firebase_admin import auth as admin_auth, firestore


ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "admin@meropalo.local")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "admin123")
ADMIN_NAME = os.getenv("ADMIN_NAME", "Admin")
ADMIN_PHONE = os.getenv("ADMIN_PHONE", "")
ADMIN_ROLE = os.getenv("ADMIN_ROLE", "admin")  # admin | receptionist | doctor


def _require_emulator() -> None:
    """Refuse to run unless pointed at the emulators (never touch production)."""
    fs = os.getenv("FIRESTORE_EMULATOR_HOST")
    au = os.getenv("FIREBASE_AUTH_EMULATOR_HOST")
    if not (fs and au):
        sys.exit(
            "Refusing to seed: FIRESTORE_EMULATOR_HOST and "
            "FIREBASE_AUTH_EMULATOR_HOST must be set (check backend/.env).\n"
            f"  FIRESTORE_EMULATOR_HOST={fs!r}\n"
            f"  FIREBASE_AUTH_EMULATOR_HOST={au!r}"
        )


def _get_or_create_user(auth):
    """Create the admin auth user, or reuse the existing one (idempotent)."""
    try:
        user = auth.create_user(
            email=ADMIN_EMAIL,
            password=ADMIN_PASSWORD,
            display_name=ADMIN_NAME,
            email_verified=True,
        )
        print(f"[+] Created auth user  uid={user.uid}  email={ADMIN_EMAIL}")
        return user
    except admin_auth.EmailAlreadyExistsError:
        user = auth.get_user_by_email(ADMIN_EMAIL)
        # Reset the password so the documented default always works on re-seed.
        auth.update_user(
            user.uid,
            password=ADMIN_PASSWORD,
            display_name=ADMIN_NAME,
            email_verified=True,
        )
        print(
            f"[=] Auth user already existed  uid={user.uid}  email={ADMIN_EMAIL} "
            "(password reset to ADMIN_PASSWORD)"
        )
        return user


# ---- Sample catalog (hospitals + doctors) -----------------------------------
# Deterministic doc IDs keep re-seeding idempotent: set(merge=True) updates the
# same docs instead of creating duplicates. Doctors reference a hospital by
# hospitalId only; the backend denormalizes hospitalName at read time
# (routers/doctors.py:_with_hospital_names), so it isn't stored here.

HOSPITALS = [
    {
        "id": "hosp_bir",
        "name": "Bir Hospital",
        "city": "Kathmandu",
        "address": "Mahaboudha, Kathmandu 44600",
        "phone": "+977 1 4221119",
        "openHours": "24 Hours",
        "specialties": ["General", "Cardiology", "Orthopedics", "ENT"],
        "latitude": 27.7045,
        "longitude": 85.3145,
        "rating": 4.4,
        "reviewCount": 132,
    },
    {
        "id": "hosp_grande",
        "name": "Grande International Hospital",
        "city": "Kathmandu",
        "address": "Dhapasi, Tokha Road, Kathmandu",
        "phone": "+977 1 5159266",
        "openHours": "24 Hours",
        "specialties": ["Pediatrics", "Dermatology", "Neurology", "Cardiology"],
        "latitude": 27.7505,
        "longitude": 85.3294,
        "rating": 4.7,
        "reviewCount": 210,
    },
    {
        "id": "hosp_bnb",
        "name": "B&B Hospital",
        "city": "Lalitpur",
        "address": "Gwarko, Lalitpur 44700",
        "phone": "+977 1 5531933",
        "openHours": "8:00 AM - 8:00 PM",
        "specialties": ["Gynecology", "General", "Orthopedics"],
        "latitude": 27.6585,
        "longitude": 85.3296,
        "rating": 4.5,
        "reviewCount": 98,
    },
]

# Nepal's work week runs Sun-Fri (Sat is the weekly holiday). Day labels match
# the admin panel's WEEKDAYS and the Flutter availabilityDaysLabel.
_DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri"]
_MORNING = ["10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM", "12:00 PM"]
_AFTERNOON = ["1:00 PM", "1:30 PM", "2:00 PM", "2:30 PM", "3:00 PM"]

DOCTORS = [
    {
        "id": "doc_anita_sharma", "name": "Anita Sharma", "specialty": "Cardiology",
        "hospitalId": "hosp_bir", "fee": 1200, "experience": 14,
        "consultationHours": "10:00 AM - 1:00 PM",
        "bio": "Senior consultant cardiologist focused on preventive heart care.",
        "availableSlots": _MORNING, "availabilityDays": _DAYS,
        "availabilityStart": "10:00", "availabilityEnd": "13:00",
        "rating": 4.8, "reviewCount": 41,
    },
    {
        "id": "doc_rajesh_thapa", "name": "Rajesh Thapa", "specialty": "Orthopedics",
        "hospitalId": "hosp_bir", "fee": 1000, "experience": 11,
        "consultationHours": "1:00 PM - 4:00 PM",
        "bio": "Orthopedic surgeon specializing in sports injuries and joint care.",
        "availableSlots": _AFTERNOON, "availabilityDays": _DAYS,
        "availabilityStart": "13:00", "availabilityEnd": "16:00",
        "rating": 4.6, "reviewCount": 33,
    },
    {
        "id": "doc_kabita_rai", "name": "Kabita Rai", "specialty": "ENT",
        "hospitalId": "hosp_bir", "fee": 900, "experience": 8,
        "consultationHours": "11:00 AM - 2:00 PM",
        "bio": "ENT specialist treating sinus, hearing and throat conditions.",
        "availableSlots": _MORNING, "availabilityDays": ["Sun", "Tue", "Thu"],
        "availabilityStart": "11:00", "availabilityEnd": "14:00",
        "rating": 4.5, "reviewCount": 19,
    },
    {
        "id": "doc_sita_gurung", "name": "Sita Gurung", "specialty": "Pediatrics",
        "hospitalId": "hosp_grande", "fee": 1100, "experience": 12,
        "consultationHours": "10:00 AM - 1:00 PM",
        "bio": "Pediatrician caring for newborns, children and adolescents.",
        "availableSlots": _MORNING, "availabilityDays": _DAYS,
        "availabilityStart": "10:00", "availabilityEnd": "13:00",
        "rating": 4.9, "reviewCount": 57,
    },
    {
        "id": "doc_bikash_shrestha", "name": "Bikash Shrestha", "specialty": "Dermatology",
        "hospitalId": "hosp_grande", "fee": 1300, "experience": 9,
        "consultationHours": "1:00 PM - 4:00 PM",
        "bio": "Dermatologist handling skin, hair and cosmetic concerns.",
        "availableSlots": _AFTERNOON, "availabilityDays": ["Mon", "Wed", "Fri"],
        "availabilityStart": "13:00", "availabilityEnd": "16:00",
        "rating": 4.7, "reviewCount": 28,
    },
    {
        "id": "doc_niraj_maharjan", "name": "Niraj Maharjan", "specialty": "Neurology",
        "hospitalId": "hosp_grande", "fee": 1500, "experience": 16,
        "consultationHours": "10:30 AM - 1:30 PM",
        "bio": "Neurologist with expertise in headache, stroke and epilepsy care.",
        "availableSlots": _MORNING, "availabilityDays": _DAYS,
        "availabilityStart": "10:30", "availabilityEnd": "13:30",
        "rating": 4.8, "reviewCount": 36,
    },
    {
        "id": "doc_pooja_karki", "name": "Pooja Karki", "specialty": "Gynecology",
        "hospitalId": "hosp_bnb", "fee": 1200, "experience": 13,
        "consultationHours": "1:00 PM - 4:00 PM",
        "bio": "Gynecologist providing women's health and prenatal care.",
        "availableSlots": _AFTERNOON, "availabilityDays": _DAYS,
        "availabilityStart": "13:00", "availabilityEnd": "16:00",
        "rating": 4.7, "reviewCount": 44,
    },
    {
        "id": "doc_suman_adhikari", "name": "Suman Adhikari", "specialty": "General Physician",
        "hospitalId": "hosp_bnb", "fee": 700, "experience": 6,
        "consultationHours": "10:00 AM - 1:00 PM",
        "bio": "General physician for everyday illnesses and routine check-ups.",
        "availableSlots": _MORNING, "availabilityDays": _DAYS,
        "availabilityStart": "10:00", "availabilityEnd": "13:00",
        "rating": 4.4, "reviewCount": 22,
    },
]


def seed_catalog(db) -> None:
    """Write the sample hospitals + doctors (idempotent via deterministic IDs)."""
    for h in HOSPITALS:
        data = {k: v for k, v in h.items() if k != "id"}
        data["photoUrl"] = data.get("photoUrl", "")
        data["createdAt"] = firestore.SERVER_TIMESTAMP
        data["updatedAt"] = firestore.SERVER_TIMESTAMP
        db.collection("hospitals").document(h["id"]).set(data, merge=True)
    print(f"[+] Seeded {len(HOSPITALS)} hospitals")

    for d in DOCTORS:
        data = {k: v for k, v in d.items() if k != "id"}
        data["isAvailable"] = True
        data["photoUrl"] = data.get("photoUrl", "")
        data["userEmail"] = data.get("userEmail", "")
        data["createdAt"] = firestore.SERVER_TIMESTAMP
        data["updatedAt"] = firestore.SERVER_TIMESTAMP
        db.collection("doctors").document(d["id"]).set(data, merge=True)
    print(f"[+] Seeded {len(DOCTORS)} doctors")


def main() -> None:
    _require_emulator()
    init_firebase()  # emulator mode

    project = FIREBASE_PROJECT_ID or "hospital-queue-managemen-67208"
    print(f"[i] Seeding emulators for project '{project}'")
    print(
        f"    Firestore: {os.getenv('FIRESTORE_EMULATOR_HOST')}  "
        f"Auth: {os.getenv('FIREBASE_AUTH_EMULATOR_HOST')}"
    )

    auth = get_auth()
    db = get_db()

    user = _get_or_create_user(auth)

    # users/{uid} doc shape mirrors auth_service.sign_up so the admin panel's
    # onAuthStateChanged role gate ({admin, receptionist, doctor}) passes.
    db.collection("users").document(user.uid).set(
        {
            "email": ADMIN_EMAIL,
            "name": ADMIN_NAME,
            "phone": ADMIN_PHONE,
            "role": ADMIN_ROLE,
            "emailVerified": True,
            "createdAt": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )
    print(f"[+] Wrote users/{user.uid} -> role={ADMIN_ROLE!r}")

    seed_catalog(db)

    print("\nDone. Log into the admin panel with:")
    print(f"    email:    {ADMIN_EMAIL}")
    print(f"    password: {ADMIN_PASSWORD}")
    print(f"    role:     {ADMIN_ROLE}")


if __name__ == "__main__":
    main()
