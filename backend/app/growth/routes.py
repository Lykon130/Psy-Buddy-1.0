from fastapi import APIRouter, HTTPException, Query

from app.growth.models import GoalCreate, GoalUpdate, MilestoneCreate, MilestoneUpdate
from app.growth import service
from app.utils.db import get_or_create_user

router = APIRouter()


@router.get("/{username}/goals")
def list_goals(username: str, include_drafts: bool = Query(False)):
    try:
        user_id = get_or_create_user(username)
        return service.get_goals(user_id, include_drafts=include_drafts)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fetching goals failed: {e}")


@router.post("/{username}/goals")
def create_goal(username: str, goal: GoalCreate):
    try:
        user_id = get_or_create_user(username)
        return service.create_goal(user_id, goal.title, goal.description, goal.target_date)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Creating goal failed: {e}")


@router.patch("/{username}/goals/{goal_id}")
def update_goal(username: str, goal_id: str, update: GoalUpdate):
    try:
        user_id = get_or_create_user(username)
        data = {k: v for k, v in update.dict().items() if v is not None}
        if not data:
            raise HTTPException(status_code=400, detail="No fields to update")
        result = service.update_goal(user_id, goal_id, data)
        if not result:
            raise HTTPException(status_code=404, detail="Goal not found")
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Updating goal failed: {e}")


@router.delete("/{username}/goals/{goal_id}")
def delete_goal(username: str, goal_id: str):
    try:
        user_id = get_or_create_user(username)
        if not service.delete_goal(user_id, goal_id):
            raise HTTPException(status_code=404, detail="Goal not found")
        return {"deleted": True, "id": goal_id}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Deleting goal failed: {e}")


@router.post("/{username}/goals/{goal_id}/milestones")
def add_milestone(username: str, goal_id: str, milestone: MilestoneCreate):
    try:
        user_id = get_or_create_user(username)
        result = service.add_milestone(user_id, goal_id, milestone.description, milestone.achieved_at)
        if not result:
            raise HTTPException(status_code=404, detail="Goal not found")
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Adding milestone failed: {e}")


@router.patch("/{username}/milestones/{milestone_id}")
def update_milestone(username: str, milestone_id: str, update: MilestoneUpdate):
    try:
        user_id = get_or_create_user(username)
        data = {k: v for k, v in update.dict().items() if v is not None}
        if not data:
            raise HTTPException(status_code=400, detail="No fields to update")
        result = service.update_milestone(user_id, milestone_id, data)
        if not result:
            raise HTTPException(status_code=404, detail="Milestone not found")
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Updating milestone failed: {e}")


@router.delete("/{username}/milestones/{milestone_id}")
def delete_milestone(username: str, milestone_id: str):
    try:
        user_id = get_or_create_user(username)
        if not service.delete_milestone(user_id, milestone_id):
            raise HTTPException(status_code=404, detail="Milestone not found")
        return {"deleted": True, "id": milestone_id}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Deleting milestone failed: {e}")
