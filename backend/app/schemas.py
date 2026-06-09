"""Request/response models. Fields are snake_case in Python but serialize to
camelCase (idToken, doctorId, ...) to match Firestore and the JS clients."""
from typing import List, Optional

from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel


class CamelModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


# ---- Auth -------------------------------------------------------------------

class SignupRequest(CamelModel):
    name: str
    email: str
    password: str
    phone: Optional[str] = None


class LoginRequest(CamelModel):
    email: str
    password: str


class RefreshRequest(CamelModel):
    refresh_token: str


class SendOtpRequest(CamelModel):
    email: str


class VerifyOtpRequest(CamelModel):
    email: str
    code: str


class ChangePasswordRequest(CamelModel):
    current_password: str
    new_password: str


# ---- Chatbot ----------------------------------------------------------------

class ChatQueryRequest(CamelModel):
    message: str
    session_id: Optional[str] = None


class ChatReply(CamelModel):
    response: str
    intent_category: str = "general"
    is_emergency: bool = False
    disclaimer_added: bool = False
    confidence_score: float = 0.0
    matched_intent_name: Optional[str] = None


class UserOut(CamelModel):
    uid: str
    email: Optional[str] = None
    name: Optional[str] = None
    phone: Optional[str] = None
    role: str = "patient"


class AuthResponse(CamelModel):
    id_token: str
    refresh_token: str
    expires_in: int
    user: UserOut


# ---- Bookings ---------------------------------------------------------------

class BookingCreate(CamelModel):
    doctor_id: str
    patient_name: str
    patient_phone: Optional[str] = None
    booking_type: str  # first_visit | follow_up | report
    booking_date: Optional[str] = None  # YYYY-MM-DD; defaults to today
    payment_method: Optional[str] = None  # esewa | khalti | imepay | bank | cash
    payment_status: Optional[str] = None  # paid | pending


class RescheduleRequest(CamelModel):
    booking_date: Optional[str] = None  # YYYY-MM-DD; day cannot change
    time: Optional[str] = None  # patient-chosen slot label, e.g. "10:30 AM"


# ---- Profile ----------------------------------------------------------------

class EmergencyContact(CamelModel):
    name: Optional[str] = None
    relation: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None


class FamilyDoctor(CamelModel):
    name: Optional[str] = None
    specialty: Optional[str] = None
    clinic_phone: Optional[str] = None
    clinic_name: Optional[str] = None


class ProfileUpdate(CamelModel):
    """Everything the multi-step sign-up / edit-profile screens can send.
    All optional so partial updates are merged. name/phone are stored at the
    top level of users/{uid}; the rest is merged under a nested `profile` map."""
    # top-level (mirror users doc)
    name: Optional[str] = None
    phone: Optional[str] = None
    # personal
    photo_url: Optional[str] = None
    date_of_birth: Optional[str] = None  # YYYY-MM-DD
    age: Optional[int] = None
    gender: Optional[str] = None
    nationality: Optional[str] = None
    national_id: Optional[str] = None
    alternate_phone: Optional[str] = None
    address: Optional[str] = None
    marital_status: Optional[str] = None
    # medical
    blood_group: Optional[str] = None
    height: Optional[float] = None
    weight: Optional[float] = None
    allergies: Optional[List[str]] = None
    chronic_conditions: Optional[List[str]] = None
    past_surgeries: Optional[str] = None
    current_medications: Optional[List[dict]] = None  # [{name, dose}]
    vaccinations: Optional[List[str]] = None
    smoking_status: Optional[str] = None
    alcohol_consumption: Optional[str] = None
    # emergency
    primary_contact: Optional[EmergencyContact] = None
    secondary_contact: Optional[EmergencyContact] = None
    family_doctor: Optional[FamilyDoctor] = None


# ---- Reviews ----------------------------------------------------------------

class ReviewCreate(CamelModel):
    rating: float  # 1..5
    text: Optional[str] = None
