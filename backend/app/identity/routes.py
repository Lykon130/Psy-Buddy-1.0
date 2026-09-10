from fastapi import APIRouter, HTTPException

from app.identity.service import get_identity_profile
from app.utils.db import get_or_create_user

router = APIRouter()


@router.get("/{username}")
def read_identity_profile(username: str):
    try:
        user_id = get_or_create_user(username)
        profile = get_identity_profile(user_id)
        return profile or {
            "communication_style": None,
            "default_persona_preference": None,
            "topics_to_avoid": [],
            "coping_preferences": [],
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fetching identity profile failed: {e}")
