"""Standalone smoke test: verify Firebase Admin can reach Firestore.

Run from the backend directory:  python test_connection.py
"""
from app.firebase_setup import get_db


def main() -> None:
    """Connect to Firestore and print a short summary of what was reachable."""
    db = get_db()
    # A trivial read confirms credentials, project access and network all work.
    sample = list(db.collection("hospitals").limit(1).stream())
    collections = sorted(c.id for c in db.collections())
    print("OK: connected to Firestore.")
    print(f"  hospitals sample size : {len(sample)}")
    print(f"  top-level collections : {collections or '(none yet)'}")


if __name__ == "__main__":
    main()
