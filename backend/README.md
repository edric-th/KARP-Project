# Mero Palo — FastAPI backend

REST API for the Mero Palo hospital queue system. It uses the **Firebase Admin
SDK** to read/write the same Cloud Firestore project the admin panel
(`admin-panel/`) already uses, so anything created through this API appears live
in the admin's Live Queue / Board, and vice-versa.

It is the API layer the **Flutter patient app** (`frontend/`) talks to:
authentication, browsing hospitals/doctors, booking a token, and live queue
tracking with predicted wait times.

## What it provides

- **Auth** (Firebase Auth, email/password) — patients sign up / log in and get a
  Firebase ID token. Staff accounts (admin / receptionist / doctor) are still
  managed from the admin panel; this API only *creates* `patient` accounts.
- **Shared schema** — the exact Firestore collections the admin panel defines:
  `users`, `hospitals`, `doctors`, `bookings` (plus a `counters` helper).
- **Unified wait-time prediction** — one adaptive, booking-type-aware formula
  (`app/wait_time.py`) used for every ETA.

## Data model (Firestore)

| collection | key fields |
|------------|-----------|
| `users`    | `email`, `name`, `phone`, `role` (`admin`/`receptionist`/`doctor`/`patient`), `createdAt` — doc id = Firebase Auth uid |
| `hospitals`| `name`, `address`, `city`, `phone` |
| `doctors`  | `name`, `specialty`, `hospitalId`, `fee`, `consultationHours`, `userEmail` |
| `bookings` | `doctorId`, `doctorName`, `hospitalId`, `hospitalName`, `patientName`, `patientPhone`, **`patientUid`**, `bookingType` (`first_visit`/`follow_up`/`report`), `status` (`pending`/`active`/`served`/`no_show`/`cancelled`), `tokenNumber`, `bookingDate` (`YYYY-MM-DD`), `estimatedWaitMinutes`, `expectedCallAt`, `calledAt`, `servedAt`, `createdAt` |
| `counters` | `lastToken` per `{doctorId}_{date}` (race-safe token numbers) |

> `patientUid` is added so a patient can fetch only their own bookings. It is
> additive — the admin panel keeps working unchanged.

## Endpoints

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/api/auth/signup` | – | Create a patient account, returns ID token |
| POST | `/api/auth/login` | – | Email/password login, returns ID token |
| GET  | `/api/auth/me` | Bearer | Current user profile |
| GET  | `/api/hospitals` · `/api/hospitals/{id}` | – | List / get hospitals |
| GET  | `/api/doctors?hospitalId=` · `/api/doctors/{id}` | – | List / get doctors |
| POST | `/api/bookings` | Bearer | Create a booking (assigns token + ETA) |
| GET  | `/api/bookings/me` | Bearer | My bookings, with live position/ETA |
| GET  | `/api/bookings/{id}` | Bearer | Get a booking |
| POST | `/api/bookings/{id}/cancel` | Bearer | Cancel a booking |
| GET  | `/api/queue/{doctorId}?date=` | – | Live queue + per-token wait times |

Send the token as `Authorization: Bearer <idToken>`.

## Setup

1. **Service account key** — Firebase Console → Project settings → Service
   accounts → *Generate new private key*. Save it as
   `backend/serviceAccountKey.json` (gitignored).
2. **Env** — `backend/.env` is already filled in with the project's web API key
   and project id (copy `.env.example` if you need to recreate it).
3. **Run** (the `venv/` already has the dependencies):

   ```powershell
   cd backend
   .\venv\Scripts\python.exe run.py
   ```

   Or: `.\venv\Scripts\python.exe -m uvicorn app.main:app --reload`

4. Open Swagger UI at <http://localhost:8000/docs>.

## Wait-time formula

`app/wait_time.py` learns each doctor's base service time from recently *served*
bookings (`calledAt → servedAt`, last 10, clamped 1–60 min, needs ≥3 samples
else falls back to `DEFAULT_SERVICE_MINUTES`). It then weights by booking type
(`first_visit` longer, `follow_up`/`report` shorter — learned per-type where
there's enough data) and computes a token's ETA as the remaining time of the
in-progress consult plus the summed expected durations of everyone ahead.
