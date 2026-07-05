from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from firebase_admin import firestore

from .. import availability
from .. import firestore_repo as repo
from .. import wait_time
from ..schemas import BookingCreate, FeedbackCreate, RescheduleRequest
from ..security import get_current_user

router = APIRouter(prefix="/bookings", tags=["bookings"])

VALID_TYPES = ("first_visit", "follow_up", "report")


def _human_turn(iso: str) -> str:
    """Format an ISO instant as a Nepal-local day + 12h clock, e.g. "Mon 10:00 AM".
    Built without platform-specific strftime directives so it works on Windows."""
    try:
        dt = datetime.fromisoformat(iso).astimezone(repo.NEPAL_TZ)
    except (TypeError, ValueError):
        return ""
    hour = dt.hour % 12 or 12
    return f"{dt.strftime('%a')} {hour}:{dt.strftime('%M %p')}"


@router.post("")
def create_booking(body: BookingCreate, user: dict = Depends(get_current_user)):
    if body.booking_type not in VALID_TYPES:
        raise HTTPException(400, f"bookingType must be one of {VALID_TYPES}")

    doctor = repo.get_one("doctors", body.doctor_id)
    if not doctor:
        raise HTTPException(404, "Doctor not found")

    # A patient may hold only one unserved appointment per doctor at a time:
    # they must wait until their current booking is served (or cancel it) before
    # booking the same doctor again. Online tokens are a separate queue — skip.
    if (body.booking_source or "appointment") != "online_token":
        if any(
            b.get("doctorId") == body.doctor_id
            and b.get("status") in ("pending", "active", "on_hold")
            for b in repo.bookings_for_patient(user["uid"])
        ):
            raise HTTPException(
                409,
                "You already have an active booking with this doctor. "
                "Please wait until it is served before booking again.",
            )

    date = body.booking_date or repo.today_str()
    existing = repo.bookings_for_doctor(body.doctor_id, date)

    # Predict the wait BEFORE this patient is added, then lock it in. The turn
    # time is anchored to the doctor's availability, so a booking made while the
    # doctor is closed gets a real future expectedCallAt (their next opening),
    # not a misleading "a few minutes from now".
    wait_min, expected_iso = wait_time.predict_turn_for_new(existing, doctor)
    token = repo.next_token_number(body.doctor_id, date)

    hospital = (
        repo.get_one("hospitals", doctor.get("hospitalId"))
        if doctor.get("hospitalId") else None
    )

    # An "online_token" reservation is a queue ticket only — the patient books the
    # physical appointment at reception, so no online payment is collected.
    source = body.booking_source or "appointment"
    is_token_only = source == "online_token"

    data = {
        "doctorId": body.doctor_id,
        "doctorName": doctor.get("name"),
        "hospitalId": doctor.get("hospitalId"),
        "hospitalName": hospital.get("name") if hospital else doctor.get("hospitalName", ""),
        "patientName": body.patient_name,
        "patientPhone": body.patient_phone or "",
        "patientUid": user["uid"],
        "bookingType": body.booking_type,
        "bookingSource": source,
        "status": "pending",
        "tokenNumber": token,
        "bookingDate": date,
        "problem": body.problem or "",
        "notes": body.notes or "",
        "estimatedWaitMinutes": wait_min,
        "expectedCallAt": expected_iso,
        "paymentMethod": body.payment_method or "",
        "paymentStatus": body.payment_status or ("not_required" if is_token_only else "pending"),
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }

    ref = repo.get_db().collection("bookings").document()
    ref.set(data)
    repo.invalidate_for_booking(data)  # this booking must show in the queue now

    # Tailor the confirmation: a normal appointment with an open doctor shows the
    # minute estimate; an appointment booked while the doctor is closed shows the
    # real next-available day + clock time so "~5 min" can't mislead.
    name = doctor.get("name")
    now_local = datetime.now(timezone.utc).astimezone(repo.NEPAL_TZ)
    doctor_open = (
        not availability.has_availability(doctor)
        or availability.available_now(doctor, now_local)
    )
    if is_token_only:
        body_text = (
            f"Token #{token} with {name} on {date}. Estimated turn ~{wait_min} min."
            " Please complete your appointment at the reception."
        )
    elif doctor_open:
        body_text = f"Token #{token} with {name} on {date}. Estimated turn ~{wait_min} min."
    else:
        days = availability.days_label(doctor)
        avail = f" available {days}" if days else " available soon"
        body_text = (
            f"Token #{token} with {name} on {date}. {name} is next{avail}"
            f" — your turn is around {_human_turn(expected_iso)}."
        )

    repo.add_notification(
        user["uid"],
        "Online token reserved" if is_token_only else "Booking confirmed",
        body_text,
        category="booking",
        related_booking_id=ref.id,
    )
    return repo.get_one("bookings", ref.id)


@router.get("/me")
def my_bookings(user: dict = Depends(get_current_user)):
    """The signed-in patient's bookings, with live position/ETA for active ones."""
    items = repo.bookings_for_patient(user["uid"])
    status_cache: dict = {}
    doctor_cache: dict = {}

    def _doctor(did):
        if did not in doctor_cache:
            doctor_cache[did] = repo.get_one("doctors", did)
        return doctor_cache[did]

    for b in items:
        if b.get("status") not in ("pending", "active") or not b.get("bookingDate"):
            continue
        # Online tokens live in a hospital-level reception queue; appointments
        # live in their doctor's queue. Resolve the right snapshot for each.
        if b.get("bookingSource") == "online_token":
            hospital_id = b.get("hospitalId") or ""
            key = ("reception", hospital_id, b["bookingDate"])
            if key not in status_cache:
                status_cache[key] = wait_time.build_reception_status(
                    hospital_id,
                    repo.reception_tokens_for_hospital(hospital_id, b["bookingDate"]),
                )
        else:
            key = ("doctor", b["doctorId"], b["bookingDate"])
            if key not in status_cache:
                status_cache[key] = wait_time.build_queue_status(
                    b["doctorId"],
                    repo.bookings_for_doctor(b["doctorId"], b["bookingDate"]),
                    _doctor(b["doctorId"]),
                )
        snapshot = status_cache[key]

        match = next((w for w in snapshot["waiting"] if w["id"] == b["id"]), None)
        if match:
            b["position"] = match["position"]
            b["estimatedWaitMinutes"] = match["estimatedWaitMinutes"]
            b["expectedCallAt"] = match["expectedCallAt"]
        elif snapshot["nowServing"] and snapshot["nowServing"]["id"] == b["id"]:
            b["position"] = 0
            b["estimatedWaitMinutes"] = 0

    return items


@router.get("/{booking_id}")
def get_booking(booking_id: str, user: dict = Depends(get_current_user)):
    booking = repo.get_one("bookings", booking_id)
    if not booking:
        raise HTTPException(404, "Booking not found")
    if user["role"] == "patient" and booking.get("patientUid") != user["uid"]:
        raise HTTPException(403, "Not your booking")
    return booking


@router.post("/{booking_id}/return")
def mark_returned(booking_id: str, user: dict = Depends(get_current_user)):
    """The patient signals they're back from an X-ray / another department so the
    doctor can call them off hold. Only the booking's owner may flag it, and only
    while it is actually on hold. The doctor/reception panels watch this flag live
    and surface a "back with report" badge — no push is needed here."""
    booking = repo.get_one("bookings", booking_id)
    if not booking:
        raise HTTPException(404, "Booking not found")
    if user["role"] == "patient" and booking.get("patientUid") != user["uid"]:
        raise HTTPException(403, "Not your booking")
    if booking.get("status") != "on_hold":
        raise HTTPException(409, "This booking is not on hold.")

    repo.get_db().collection("bookings").document(booking_id).update(
        {
            "returned": True,
            "returnedAt": datetime.now(timezone.utc).isoformat(),
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }
    )
    repo.invalidate_for_booking(booking)
    return {"id": booking_id, "returned": True}


@router.post("/{booking_id}/cancel")
def cancel_booking(booking_id: str, user: dict = Depends(get_current_user)):
    booking = repo.get_one("bookings", booking_id)
    if not booking:
        raise HTTPException(404, "Booking not found")
    if user["role"] == "patient" and booking.get("patientUid") != user["uid"]:
        raise HTTPException(403, "Not your booking")

    repo.get_db().collection("bookings").document(booking_id).update(
        {"status": "cancelled", "updatedAt": firestore.SERVER_TIMESTAMP}
    )
    repo.invalidate_for_booking(booking)  # drop it from the cached queue at once
    repo.add_notification(
        booking.get("patientUid"),
        "Booking cancelled",
        f"Your booking (token #{booking.get('tokenNumber')}) has been cancelled.",
        category="booking",
        related_booking_id=booking_id,
    )
    return {"id": booking_id, "status": "cancelled"}


@router.post("/{booking_id}/reschedule")
def reschedule_booking(
    booking_id: str, body: RescheduleRequest, user: dict = Depends(get_current_user)
):
    booking = repo.get_one("bookings", booking_id)
    if not booking:
        raise HTTPException(404, "Booking not found")
    if user["role"] == "patient" and booking.get("patientUid") != user["uid"]:
        raise HTTPException(403, "Not your booking")

    doctor_id = booking["doctorId"]
    # The appointment day is fixed — only the time slot may change. Keep the
    # existing booking date and reject any attempt to move to a different day.
    current_date = booking.get("bookingDate") or repo.today_str()
    if body.booking_date and body.booking_date != current_date:
        raise HTTPException(400, "The appointment day cannot be changed, only the time")
    new_date = current_date

    doctor = repo.get_one("doctors", doctor_id)
    existing = repo.bookings_for_doctor(doctor_id, new_date)
    wait_min, expected_iso = wait_time.predict_turn_for_new(existing, doctor)
    token = repo.next_token_number(doctor_id, new_date)

    update = {
        "bookingDate": new_date,
        "tokenNumber": token,
        "status": "pending",
        "estimatedWaitMinutes": wait_min,
        "expectedCallAt": expected_iso,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }
    if body.time:
        update["preferredTime"] = body.time
    repo.get_db().collection("bookings").document(booking_id).update(update)
    repo.invalidate_for_booking(booking)  # reflect the new token/time at once

    when = f" at {body.time}" if body.time else ""
    repo.add_notification(
        booking.get("patientUid"),
        "Booking rescheduled",
        f"Your booking is now{when} on {new_date} — new token #{token}, ~{wait_min} min wait.",
        category="booking",
        related_booking_id=booking_id,
    )
    return repo.get_one("bookings", booking_id)


def _clamp_rating(value) -> float:
    return max(1.0, min(5.0, float(value)))


@router.post("/{booking_id}/feedback")
def submit_feedback(
    booking_id: str, body: FeedbackCreate, user: dict = Depends(get_current_user)
):
    """Post-consultation feedback: rate the doctor and the hospital (1..5) with an
    optional shared comment. Writes one review doc per target so each aggregate
    counts only its own field, then marks the booking reviewed so it can't be
    submitted twice."""
    booking = repo.get_one("bookings", booking_id)
    if not booking:
        raise HTTPException(404, "Booking not found")
    if booking.get("patientUid") != user["uid"]:
        raise HTTPException(403, "Not your booking")
    if booking.get("status") != "served":
        raise HTTPException(400, "You can only review a completed consultation")
    if booking.get("reviewed"):
        raise HTTPException(400, "This visit has already been reviewed")

    db = repo.get_db()
    patient_name = booking.get("patientName") or user.get("name") or "Patient"
    text = (body.text or "").strip()

    doctor_id = booking.get("doctorId")
    if doctor_id:
        db.collection("reviews").document().set({
            "doctorId": doctor_id,
            "patientUid": user["uid"],
            "patientName": patient_name,
            "rating": _clamp_rating(body.doctor_rating),
            "text": text,
            "bookingId": booking_id,
            "createdAt": firestore.SERVER_TIMESTAMP,
        })
        repo.recompute_doctor_rating(doctor_id)

    hospital_id = booking.get("hospitalId")
    if hospital_id:
        db.collection("reviews").document().set({
            "hospitalId": hospital_id,
            "patientUid": user["uid"],
            "patientName": patient_name,
            "rating": _clamp_rating(body.hospital_rating),
            "text": text,
            "bookingId": booking_id,
            "createdAt": firestore.SERVER_TIMESTAMP,
        })
        repo.recompute_hospital_rating(hospital_id)

    db.collection("bookings").document(booking_id).update({
        "reviewed": True,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    })
    return repo.get_one("bookings", booking_id)
