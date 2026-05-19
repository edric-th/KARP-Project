# Mero Palo — Hospital Queue Management Backend

A FastAPI backend for the **Mero Palo** smart hospital queue management system.
It powers patient token booking, live queue control for hospital staff,
wait-time estimation and FCM push notifications, all on top of Firebase
(Firestore + Auth + Cloud Messaging).

The data layer is **shared with the existing React admin panel** (`../admin-panel`),
so this backend uses the same Firestore collections and field names the admin
panel already writes.

---

## What the backend does

- **Patients** (mobile app) register a profile, browse hospitals/doctors, book a
  numbered token for a doctor on a date, track their live queue position and
  cancel a token while it is still waiting.
- **Staff** (admin / receptionist) create hospitals and doctors, and drive the
  live queue — calling the next patient, skipping no-shows, completing
  consultations and viewing a daily report.
- **Wait times** are estimated from each queue's rolling-average consultation
  time, which updates every time a consultation completes.
- **Notifications** are pushed via FCM when a patient's token is called.

---

## Tech stack

- Python 3.10+ (developed on 3.11)
- FastAPI + Uvicorn
- Firebase Admin SDK (Firestore, Auth, FCM)
- Pydantic v2 for request/response validation

---

## Project structure

```
backend/
├── app/
│   ├── main.py                FastAPI app, CORS, router wiring
│   ├── config.py              Settings loaded from .env
│   ├── firebase_setup.py      Firebase Admin initialization + Firestore client
│   ├── dependencies.py        verify_token / verify_staff auth dependencies
│   ├── models/                Pydantic models (user, hospital, doctor, token, queue)
│   ├── routes/                auth, hospitals, tokens, queue, admin, chatbot
│   └── services/              notification_service, wait_time_service
├── test_connection.py         Standalone Firestore connectivity smoke test
├── requirements.txt
├── .env
└── serviceAccountKey.json     (not committed — see below)
```

---

## Installation

From the `backend/` directory, with the virtual environment activated:

```bash
# Windows (PowerShell)
.\venv\Scripts\Activate.ps1

# macOS / Linux
source venv/bin/activate

pip install -r requirements.txt
```

---

## Firebase setup

### 1. Service account key

Place the Firebase service account key file at:

```
backend/serviceAccountKey.json
```

Download it from the Firebase console → **Project settings → Service accounts →
Generate new private key**. The path is configurable via the
`FIREBASE_CREDENTIALS_PATH` environment variable. **Never commit this file** —
it is already listed in `.gitignore`.

### 2. Enable Firestore

In the [Firebase console](https://console.firebase.google.com/) for your
project, go to **Build → Firestore Database → Create database**. This also
enables the Cloud Firestore API. Without this step every Firestore call fails
with `PERMISSION_DENIED: Cloud Firestore API has not been used ...`.

Verify connectivity at any time with:

```bash
python test_connection.py
```

---

## Environment variables (`.env`)

| Variable                   | Description                                    | Example |
|----------------------------|------------------------------------------------|---------|
| `FIREBASE_CREDENTIALS_PATH` | Path to the service account key                | `serviceAccountKey.json` |
| `ENVIRONMENT`               | `development` or `production`                   | `development` |
| `ALLOWED_ORIGINS`           | Comma-separated CORS origins (production)        | `http://localhost:5173,http://localhost:3000` |

In `development`, CORS allows **all origins** (so the Flutter app can connect).
In `production`, only the origins in `ALLOWED_ORIGINS` are allowed.

---

## Running locally

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- Interactive API docs (Swagger UI): <http://localhost:8000/docs>
- Alternative docs (ReDoc): <http://localhost:8000/redoc>
- Health check: <http://localhost:8000/health>

---

## Authentication

Every `/api/...` endpoint requires a **Firebase ID token** in the header:

```
Authorization: Bearer <firebase_id_token>
```

The token is obtained by the client (Flutter app or admin panel) after the user
signs in with Firebase Auth. The backend verifies it with the Firebase Admin
SDK. Staff-only endpoints additionally require the user's Firestore profile to
have a `role` of `admin` or `receptionist`.

---

## Creating a staff user

There is no public "become staff" endpoint. To create a staff account:

1. In the **Firebase console → Authentication**, add a user (email + password),
   or have them sign up through the admin panel.
2. In **Firestore → `users` collection**, open (or create) the document whose ID
   is that user's Auth UID and set:

   ```json
   {
     "name": "Front Desk",
     "phone": "+9779800000000",
     "email": "desk@hospital.com",
     "role": "admin"
   }
   ```

   Use `role: "admin"` or `role: "receptionist"`. Any other value (or a missing
   profile) is treated as a normal patient and is rejected by staff endpoints
   with `403`.

> The project also supports Firebase custom claims, but role checks in this
> backend (and in the admin panel) read the Firestore `role` field, so setting
> that field is what matters.

---

## Firestore data model

Collections are top-level and field names are camelCase, matching the admin panel.

| Collection           | Key fields |
|----------------------|------------|
| `hospitals`          | `name, address, phone, city, createdAt` |
| `doctors`            | `name, hospitalId, specialty, fee, consultationHours, availableDays, createdAt` |
| `users/{uid}`        | `name, phone, email, role, fcmToken, createdAt` |
| `bookings`           | `userId, tokenNumber, doctorId, doctorName, hospitalId, hospitalName, patientName, patientPhone, bookingType, bookingDate, status, calledAt, servedAt, createdAt` |
| `queues/{queueId}`   | `hospitalId, doctorId, date, lastIssuedToken, currentToken, calledToken, status, averageConsultationMinutes` |
| `consultations_log`  | `hospitalId, doctorId, date, tokenNumber, userId, consultationMinutes, waitedMinutes, completedAt` |

- A **token** (patient app) and a **booking** (admin panel) are the same
  `bookings` document.
- `queueId` = `{hospitalId}_{doctorId}_{YYYY-MM-DD}`.
- Booking types: `first_visit`, `follow_up`, `report`.
- Booking statuses: `pending` (waiting), `active` (being called), `served`,
  `cancelled`, `no_show`.

---

## API endpoints

All examples assume `TOKEN` holds a valid Firebase ID token.

### Health

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Service metadata |
| GET | `/health` | Health check |

### Current user — `auth`

#### `GET /api/me` — current user's profile

```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/me
```
```json
{ "uid": "abc123", "name": "Sita Rai", "phone": "+9779800000000",
  "email": "sita@example.com", "role": "patient", "fcm_token": null,
  "created_at": "2026-05-19T10:00:00Z" }
```

#### `POST /api/me/register` — create profile after Firebase signup

```bash
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"Sita Rai","phone":"+9779800000000"}' \
  http://localhost:8000/api/me/register
```
Returns the created profile (`201`). `409` if a profile already exists.

#### `POST /api/me/fcm-token` — save the device FCM token

```bash
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"fcm_token":"<device-fcm-token>"}' \
  http://localhost:8000/api/me/fcm-token
```
```json
{ "message": "FCM token saved." }
```

### Hospitals & doctors — `hospitals` (read-only)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/hospitals` | List all hospitals |
| GET | `/api/hospitals/{hospital_id}` | One hospital |
| GET | `/api/hospitals/{hospital_id}/doctors` | Doctors at a hospital |
| GET | `/api/doctors/{doctor_id}` | One doctor |

```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/hospitals
```
```json
[ { "id": "h1", "name": "Bir Hospital", "address": "Kanti Path",
    "phone": "+97714221119", "city": "Kathmandu", "created_at": "..." } ]
```

### Tokens — `tokens`

#### `POST /api/tokens/book` — book a token

```bash
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"hospital_id":"h1","doctor_id":"d1","booking_type":"first_visit","appointment_date":"2026-05-20"}' \
  http://localhost:8000/api/tokens/book
```
```json
{ "token_id": "bk_abc", "token_number": 7, "estimated_wait_minutes": 30 }
```
Rejects (`409`) if you already hold a waiting/active token for the same doctor
on the same date. The token number is issued atomically via a Firestore
transaction.

#### `GET /api/me/tokens` — list my tokens

```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/me/tokens
```

#### `GET /api/me/tokens/{token_id}` — one token with live position

```json
{ "token_id": "bk_abc", "token_number": 7, "doctor_id": "d1",
  "doctor_name": "Ram Sharma", "hospital_id": "h1", "hospital_name": "Bir Hospital",
  "booking_type": "first_visit", "appointment_date": "2026-05-20", "status": "pending",
  "current_token": 3, "queue_position": 4, "estimated_wait_minutes": 20 }
```

#### `DELETE /api/me/tokens/{token_id}` — cancel my token

```bash
curl -X DELETE -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/me/tokens/bk_abc
```
Only a `pending` token can be cancelled (otherwise `409`).

### Queue — `queue` (read-only)

#### `GET /api/queue/{hospital_id}/{doctor_id}/{date}`

```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/queue/h1/d1/2026-05-20
```
```json
{ "queue_id": "h1_d1_2026-05-20", "hospital_id": "h1", "doctor_id": "d1",
  "date": "2026-05-20", "last_issued_token": 12, "current_token": 3,
  "called_token": 3, "status": "open", "average_consultation_minutes": 5.0,
  "waiting_count": 8 }
```

### Admin — `admin` (staff only)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/admin/hospitals` | Create a hospital |
| PUT  | `/api/admin/hospitals/{hospital_id}` | Update a hospital |
| POST | `/api/admin/doctors` | Create a doctor |
| PUT  | `/api/admin/doctors/{doctor_id}` | Update a doctor |
| POST | `/api/admin/queue/{queue_id}/advance` | Call the next patient |
| POST | `/api/admin/queue/{queue_id}/skip` | Mark active patient as no-show |
| POST | `/api/admin/queue/{queue_id}/complete` | Complete active patient, don't advance |
| GET  | `/api/admin/reports/{date}` | Daily summary per doctor |

```bash
# Create a hospital
curl -X POST -H "Authorization: Bearer $STAFF_TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"Bir Hospital","address":"Kanti Path","phone":"+97714221119","city":"Kathmandu"}' \
  http://localhost:8000/api/admin/hospitals

# Create a doctor
curl -X POST -H "Authorization: Bearer $STAFF_TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"Ram Sharma","hospital_id":"h1","specialty":"Cardiology","consultation_fee":1500,"consultation_hours":"Mon-Fri 10am-2pm","available_days":["Mon","Tue","Wed"]}' \
  http://localhost:8000/api/admin/doctors

# Advance the queue
curl -X POST -H "Authorization: Bearer $STAFF_TOKEN" \
  http://localhost:8000/api/admin/queue/h1_d1_2026-05-20/advance
```
```json
{ "message": "Token #4 is now being called.", "served_token": 3,
  "called_token": 4, "current_token": 4 }
```

Daily report:
```json
{ "date": "2026-05-20", "total_bookings": 12,
  "doctors": [ { "doctor_id": "d1", "doctor_name": "Ram Sharma", "total": 12,
    "pending": 8, "active": 1, "served": 2, "cancelled": 1, "no_show": 0 } ] }
```

### Chatbot — `chatbot` (stub)

#### `POST /api/chatbot/query`

```bash
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"message":"How long is my wait?"}' \
  http://localhost:8000/api/chatbot/query
```
```json
{ "reply": "Chatbot not yet integrated.", "integrated": false }
```

---

## HTTP status codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Resource created |
| 400 | Bad request / validation error |
| 401 | Missing, invalid or expired token |
| 403 | Authenticated but not allowed (e.g. not staff) |
| 404 | Resource not found |
| 409 | Conflict (duplicate booking, profile already exists, …) |
| 503 | Firebase / Firestore temporarily unavailable |

---

## Wait-time estimation

- Each `queues` document stores `averageConsultationMinutes` (default **5**).
- Estimated wait = `(token_number − current_token) × averageConsultationMinutes`.
- When a consultation completes (`advance` / `complete`), the average updates:
  `new = old × 0.8 + actual × 0.2`.

---

## Notes

- The React **admin panel** writes to Firestore directly. The patient app
  bookings made through this backend's `/api/tokens/book` use a `queues` counter
  for atomic token numbers; walk-in bookings created in the admin panel are not
  routed through that counter. For consistent numbering, prefer routing all
  bookings through this backend.
- `test_connection.py` is a developer utility, not part of the served app.
