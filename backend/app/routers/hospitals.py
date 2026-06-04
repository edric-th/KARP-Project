from fastapi import APIRouter, HTTPException

from .. import firestore_repo as repo

router = APIRouter(prefix="/hospitals", tags=["hospitals"])


@router.get("")
def list_hospitals():
    return repo.get_all("hospitals")


@router.get("/{hospital_id}")
def get_hospital(hospital_id: str):
    hospital = repo.get_one("hospitals", hospital_id)
    if not hospital:
        raise HTTPException(404, "Hospital not found")
    return hospital
