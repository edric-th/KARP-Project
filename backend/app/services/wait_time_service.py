"""Wait time estimation and rolling-average consultation time helpers."""
import logging

logger = logging.getLogger(__name__)

# Default consultation time used when a queue has no recorded average yet.
DEFAULT_CONSULTATION_MINUTES: float = 5.0


def queue_position(token_number: int, current_token: int) -> int:
    """Return how many patients are ahead of ``token_number``.

    Position = token_number - current_token. A value of 0 or below means it is
    the holder's turn (or already passed), so the position is clamped to 0.
    """
    return max(token_number - current_token, 0)


def estimate_wait_minutes(
    token_number: int,
    current_token: int,
    average_minutes: float,
) -> int:
    """Estimate the minutes until ``token_number`` is called.

    Wait = position-in-queue * average consultation minutes, rounded to the
    nearest minute. Returns 0 when it is already the holder's turn.
    """
    position = queue_position(token_number, current_token)
    if position <= 0:
        return 0
    average = average_minutes if average_minutes > 0 else DEFAULT_CONSULTATION_MINUTES
    return int(round(position * average))


def update_rolling_average(old_average: float, consultation_minutes: float) -> float:
    """Blend a new consultation duration into the rolling average.

    Uses the exponential formula ``new = old * 0.8 + sample * 0.2`` so recent
    consultations are weighted more heavily. The result is rounded to two
    decimals before being stored back on the queue document.
    """
    base = old_average if old_average > 0 else DEFAULT_CONSULTATION_MINUTES
    # Guard against absurd samples (e.g. clock skew) before blending.
    sample = max(0.0, min(consultation_minutes, 180.0))
    new_average = (base * 0.8) + (sample * 0.2)
    return round(new_average, 2)
