from fastapi import APIRouter, HTTPException, Query
from datetime import datetime, timedelta

from app.utils.config import supabase
from app.utils.db import get_or_create_user

router = APIRouter()


@router.get("/{username}")
def get_mental_states(
    username: str,
    days: int = Query(7, ge=0, le=365, description="Number of days to look back (0 = all time)"),
):
    try:
        user_id = get_or_create_user(username)

        query = supabase.table("mental_states").select("*").eq("user_id", user_id)
        if days > 0:
            cutoff_date = datetime.utcnow() - timedelta(days=days)
            query = query.gte("timestamp", cutoff_date.isoformat())

        rows = query.order("timestamp", desc=True).execute().data
        latest_trend = rows[0]["trend"] if rows else "insufficient_data"

        return {
            "entries": rows,
            "latest_trend": latest_trend,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fetching mental states failed: {e}")
