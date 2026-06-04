"""Minimal SMTP email sender for OTP codes.

Uses STARTTLS, which works with Gmail (App Password) and most providers.
Set SMTP_HOST/PORT/USER/PASS/FROM in backend/.env. If unset, the OTP routes
fall back to a dev mode that returns the code instead of emailing it."""
import smtplib
from email.message import EmailMessage

from .config import SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM


def smtp_configured() -> bool:
    return bool(SMTP_HOST and SMTP_USER and SMTP_PASS)


def send_otp_email(to_email: str, code: str) -> None:
    """Send the 6-digit OTP. Raises on failure (caller maps to HTTP 502)."""
    sender = SMTP_FROM or SMTP_USER
    msg = EmailMessage()
    msg["Subject"] = "Your Mero Palo verification code"
    msg["From"] = sender
    msg["To"] = to_email
    msg.set_content(
        f"Your Mero Palo verification code is {code}.\n"
        "It expires in 10 minutes. If you didn't request this, ignore this email."
    )
    msg.add_alternative(
        f"""<html><body style="font-family:Arial,Helvetica,sans-serif;color:#1f2937">
          <h2 style="color:#15825F;margin:0 0 8px">Mero पालो Care</h2>
          <p style="margin:0 0 6px">Your verification code is:</p>
          <p style="font-size:30px;font-weight:800;letter-spacing:6px;color:#0C5A42;margin:8px 0">{code}</p>
          <p style="color:#6b7280;font-size:13px">This code expires in 10 minutes.</p>
        </body></html>""",
        subtype="html",
    )
    # Gmail shows App Passwords grouped as "xxxx xxxx xxxx xxxx"; strip the
    # spaces defensively so a copy-paste with spaces still authenticates.
    password = SMTP_PASS.replace(" ", "")

    # Port 465 is implicit TLS (SMTP_SSL); 587 and others use STARTTLS.
    if SMTP_PORT == 465:
        with smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT, timeout=20) as server:
            server.login(SMTP_USER, password)
            server.send_message(msg)
    else:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=20) as server:
            server.ehlo()
            server.starttls()
            server.login(SMTP_USER, password)
            server.send_message(msg)
