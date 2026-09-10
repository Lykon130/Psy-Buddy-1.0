from fastapi import APIRouter, HTTPException, Query

from app.reflection.service import get_scores
from app.utils.db import get_or_create_user

router = APIRouter()


@router.get("/{username}")
def read_scores(username: str, limit: int = Query(50, ge=1, le=200)):
    try:
        user_id = get_or_create_user(username)
        return get_scores(user_id, limit=limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fetching response scores failed: {e}")
