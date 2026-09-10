from fastapi import APIRouter, HTTPException, BackgroundTasks

from app.memory.models import MemoryFactUpdate
from app.memory.service import get_facts
from app.identity.service import aggregate_identity_profile
from app.utils.config import supabase
from app.utils.db import get_or_create_user

router = APIRouter()


@router.get("/{username}")
def list_facts(username: str):
    try:
        user_id = get_or_create_user(username)
        return get_facts(user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fetching memory failed: {e}")


@router.patch("/{username}/{fact_id}")
def update_fact(username: str, fact_id: str, update: MemoryFactUpdate, background_tasks: BackgroundTasks):
    try:
        user_id = get_or_create_user(username)
        data = {k: v for k, v in update.dict().items() if v is not None}
        if not data:
            raise HTTPException(status_code=400, detail="No fields to update")

        result = (
            supabase.table("memory_facts")
            .update(data)
            .eq("id", fact_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=404, detail="Memory fact not found")

        if data.get("confirmed") is True:
            background_tasks.add_task(aggregate_identity_profile, user_id)

        return result.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Updating memory failed: {e}")


@router.delete("/{username}/{fact_id}")
def delete_fact(username: str, fact_id: str):
    try:
        user_id = get_or_create_user(username)
        result = (
            supabase.table("memory_facts")
            .delete()
            .eq("id", fact_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=404, detail="Memory fact not found")
        return {"deleted": True, "id": fact_id}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Deleting memory failed: {e}")
