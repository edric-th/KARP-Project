"""Doctor availability schedule maths — a faithful port of the Dart
DoctorModel availability helpers in frontend/lib/models/models.dart.

A doctor's schedule is stored on the doctor doc as:
  • availabilityDays   – list like ["Mon", "Tue", ...]
  • availabilityStart  – "HH:mm" 24h, Nepal-local (e.g. "10:00")
  • availabilityEnd    – "HH:mm" 24h, Nepal-local (e.g. "14:00")

All day/time reasoning happens in Nepal local time (fixed +05:45, no DST) so it
matches the admin panel and the patient app, which both use Nepal-local hours.
Callers pass an aware datetime already in NEPAL_TZ and convert results back to
UTC for storage themselves.
"""
from datetime import datetime, timedelta

from .firestore_repo import NEPAL_TZ

# Mon=1 .. Sun=7 — identical to Dart DateTime.weekday and Python isoweekday().
_DAY_ABBR = {1: "Mon", 2: "Tue", 3: "Wed", 4: "Thu", 5: "Fri", 6: "Sat", 7: "Sun"}


def _days(doctor) -> list:
    raw = doctor.get("availabilityDays") if doctor else None
    return [str(d) for d in raw] if isinstance(raw, list) else []


def _start(doctor) -> str:
    return str(doctor.get("availabilityStart") or "") if doctor else ""


def _end(doctor) -> str:
    return str(doctor.get("availabilityEnd") or "") if doctor else ""


def has_availability(doctor) -> bool:
    """True only when days + a time range have been configured."""
    return bool(_days(doctor)) and bool(_start(doctor)) and bool(_end(doctor))


def _is_available_day(doctor, d_local: datetime) -> bool:
    days = _days(doctor)
    if not days:
        return True
    abbr = _DAY_ABBR[d_local.isoweekday()].lower()
    return any(str(x).strip().lower().startswith(abbr) for x in days)


def _time_on(day_local: datetime, hhmm: str):
    """A Nepal-local aware datetime at HH:mm on the given calendar day, or None."""
    parts = (hhmm or "").split(":")
    if len(parts) < 2:
        return None
    try:
        h, m = int(parts[0]), int(parts[1])
    except (TypeError, ValueError):
        return None
    return datetime(day_local.year, day_local.month, day_local.day, h, m, tzinfo=NEPAL_TZ)


def _start_on(doctor, day_local: datetime):
    s = _start(doctor)
    return _time_on(day_local, s) if s else None


def _end_on(doctor, day_local: datetime):
    e = _end(doctor)
    return _time_on(day_local, e) if e else None


def available_now(doctor, now_local: datetime) -> bool:
    """Whether the doctor is consultable at now_local (right day + within hours).
    Falls back to the simple isAvailable flag when no schedule is set."""
    is_available = bool(doctor.get("isAvailable", True)) if doctor else True
    if not is_available:
        return False
    if not has_availability(doctor):
        return is_available
    if not _is_available_day(doctor, now_local):
        return False
    s = _start_on(doctor, now_local)
    e = _end_on(doctor, now_local)
    if s is None or e is None:
        return True
    return now_local >= s and now_local < e


def effective_start_local(doctor, from_local: datetime) -> datetime:
    """The moment the doctor's queue effectively begins serving, relative to
    from_local (Nepal-local aware). Mirrors Dart effectiveStartFrom:
      • no schedule set        -> from_local (serve immediately);
      • before today's opening -> today's opening time;
      • within hours today     -> from_local (now);
      • after close / off-day  -> the next available day's opening time.
    Returns from_local if no opening can be resolved within a week."""
    if not has_availability(doctor):
        return from_local
    start_of_from = from_local.replace(hour=0, minute=0, second=0, microsecond=0)
    for i in range(8):
        day = start_of_from + timedelta(days=i)
        if not _is_available_day(doctor, day):
            continue
        open_dt = _start_on(doctor, day)
        if open_dt is None:
            return from_local
        if i == 0:
            close_dt = _end_on(doctor, day)
            if close_dt is not None and from_local >= close_dt:
                continue  # past close -> next available day
            return open_dt if from_local < open_dt else from_local
        return open_dt  # a future available day -> its opening
    return from_local


def days_label(doctor) -> str:
    """e.g. "Mon–Fri" / "Mon, Wed, Fri" — empty when no days configured.
    Mirrors Dart availabilityDaysLabel (groups consecutive weekdays into ranges)."""
    days = _days(doctor)
    if not days:
        return ""
    ints = set()
    for d in days:
        t = str(d).strip().lower()
        for k, v in _DAY_ABBR.items():
            if t.startswith(v.lower()):
                ints.add(k)
    sorted_ints = sorted(ints)
    if not sorted_ints:
        return ", ".join(days)
    parts = []
    run_start = sorted_ints[0]
    prev = sorted_ints[0]
    for i in range(1, len(sorted_ints) + 1):
        cur = sorted_ints[i] if i < len(sorted_ints) else -99
        if cur == prev + 1:
            prev = cur
            continue
        parts.append(
            _DAY_ABBR[run_start]
            if run_start == prev
            else f"{_DAY_ABBR[run_start]}–{_DAY_ABBR[prev]}"
        )
        run_start = cur
        prev = cur
    return ", ".join(parts)
