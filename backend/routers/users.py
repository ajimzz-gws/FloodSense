from __future__ import annotations

from typing import List
from fastapi import APIRouter, HTTPException

from models import LocationUpdate, UserProfile
from database import (
    db_create_user,
    db_get_user,
    db_update_user,
    db_update_user_location,
    db_get_all_users,
)

router = APIRouter()


@router.post("/", response_model=UserProfile, status_code=201)
def create_user(user: UserProfile):
    existing = db_get_user(user.id)
    if existing:
        raise HTTPException(status_code=409, detail="User already exists")
    created = db_create_user(user.model_dump())
    return UserProfile(**created)


@router.get("/", response_model=List[UserProfile])
def get_all_users():
    users = db_get_all_users()
    return [UserProfile(**u) for u in users]


@router.get("/{user_id}", response_model=UserProfile)
def get_user(user_id: str):
    user = db_get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserProfile(**user)


@router.put("/{user_id}", response_model=UserProfile)
def update_user(user_id: str, user: UserProfile):
    existing = db_get_user(user_id)
    if not existing:
        # Create if not exists
        created = db_create_user(user.model_dump())
        return UserProfile(**created)
    updated = db_update_user(user_id, user.model_dump())
    return UserProfile(**updated)


@router.post("/{user_id}/location", response_model=dict)
def update_location(user_id: str, location: LocationUpdate):
    res = db_update_user_location(user_id, location.lat, location.lng)
    return res
