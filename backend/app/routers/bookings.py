from fastapi import APIRouter, Depends, HTTPException
from firebase_admin import firestore

from .. import firestore_repo as repo
from .. import wait_time
from ..schemas import BookingCreate, RescheduleRequest
from ..security import get_current_user

router = APIRouter(prefix="/bookings", tags=["bookings"])

VALID_TYPES = ("first_visit", "follow_up", "report")


@router.post("")
def create_booking(body: BookingCreate, user: dict = Depends(get_current_user)):
    if body.booking_type not in VALID_TYPES:
        raise HTTPException(400, f"bookingType must be one of {VALID_TYPES}")

    doctor = repo.get_one("doctors", body.doctor_id)
    if not doctor:
        raise HTTPException(404, "Doctor not found")

    date = body.booking_date or repo.today_str()
    existing = repo.bookings_for_doctor(body.doctor_id, date)

    # Predict the wait BEFORE this patient is added, then lock it in.
    wait_min = wait_time.predict_wait_for_new(existing)
    token = repo.next_token_number(body.doctor_id, date)

    hospital = (
        repo.get_one("hospitals", doctor.get("hospitalId"))
        if doctor.get("hospitalId") else None
    )

    data = {
        "doctorId": body.doctor_id,
        "doctorName": doctor.get("name"),
        "hospitalId": doctor.get("hospitalId"),
        "hospitalName": hospital.get("name") if hospital else doctor.get("hospitalName", ""),
        "patientName": body.patient_name,
        "patientPhone": body.patient_phone or "",
        "patientUid": user["uid"],
        "bookingType": body.booking_type,
        "status": "pending",
        "tokenNumber": token,
        "bookingDate": date,
        "estimatedWaitMinutes": wait_min,
        "expectedCallAt": wait_time.expected_call_iso(wait_min),
        "paymentMethod": body.payment_method or "",
        "paymentStatus": body.payment_status or "pending",
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }

    ref = repo.get_db().collection("bookings").document()
    ref.set(data)

    repo.add_notification(
        user["uid"],
        "Booking confirmed",
        f"Token #{token} with {doctor.get('name')} on {date}. Estimated wait ~{wait_min} min.",
        category="booking",
        related_booking_id=ref.id,
    )
    return repo.get_one("bookings", ref.id)


@router.get("/me")
def my_bookings(user: dict = Depends(get_current_user)):
    """The signed-in patient's bookings, with live position/ETA for active ones."""
    items = repo.bookings_for_patient(user["uid"])
    status_cache: dict = {}

    for b in items:
        if b.get("status") not in ("pending", "active") or not b.get("bookingDate"):
            continue
        key = (b["doctorId"], b["bookingDate"])
        if key not in status_cache:
            status_cache[key] = wait_time.build_queue_status(
                b["doctorId"], repo.bookings_for_doctor(b["doctorId"], b["bookingDate"])
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

    existing = repo.bookings_for_doctor(doctor_id, new_date)
    wait_min = wait_time.predict_wait_for_new(existing)
    token = repo.next_token_number(doctor_id, new_date)

    update = {
        "bookingDate": new_date,
        "tokenNumber": token,
        "status": "pending",
        "estimatedWaitMinutes": wait_min,
        "expectedCallAt": wait_time.expected_call_iso(wait_min),
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }
    if body.time:
        update["preferredTime"] = body.time
    repo.get_db().collection("bookings").document(booking_id).update(update)

    when = f" at {body.time}" if body.time else ""
    repo.add_notification(
        booking.get("patientUid"),
        "Booking rescheduled",
        f"Your booking is now{when} on {new_date} — new token #{token}, ~{wait_min} min wait.",
        category="booking",
        related_booking_id=booking_id,
    )
    return repo.get_one("bookings", booking_id)
