from datetime import datetime

from app.utils.config import supabase

MAX_DRAFT_TITLE_LEN = 60


def create_draft_goal(user_id: str, memory_fact_id: str | None, fact_text: str) -> None:
    """
    Background task: a `category="goal"` memory fact seeds a draft goal —
    confirmed=False regardless of the memory fact's own confidence, so it
    only becomes a real, visible goal once the user explicitly promotes it
    in the Growth Timeline screen (separate consent step from confirming
    the underlying memory fact).
    """
    try:
        title = fact_text if len(fact_text) <= MAX_DRAFT_TITLE_LEN else fact_text[: MAX_DRAFT_TITLE_LEN - 3] + "..."
        supabase.table("goals").insert(
            {
                "user_id": user_id,
                "title": title,
                "description": fact_text,
                "status": "active",
                "source": "inferred",
                "confirmed": False,
                "memory_fact_id": memory_fact_id,
            }
        ).execute()
    except Exception as e:
        print("[Growth Timeline Draft Goal Error]", e)


def get_goals(user_id: str, include_drafts: bool = False) -> list[dict]:
    query = supabase.table("goals").select("*").eq("user_id", user_id)
    if not include_drafts:
        query = query.eq("confirmed", True)
    goals = query.order("created_at", desc=True).execute().data

    if not goals:
        return []

    goal_ids = [g["id"] for g in goals]
    milestones = (
        supabase.table("milestones")
        .select("*")
        .in_("goal_id", goal_ids)
        .order("created_at")
        .execute()
        .data
    )
    by_goal: dict[str, list[dict]] = {}
    for m in milestones:
        by_goal.setdefault(m["goal_id"], []).append(m)

    for g in goals:
        g["milestones"] = by_goal.get(g["id"], [])
    return goals


def create_goal(user_id: str, title: str, description: str | None, target_date: str | None) -> dict:
    result = (
        supabase.table("goals")
        .insert(
            {
                "user_id": user_id,
                "title": title,
                "description": description,
                "status": "active",
                "source": "user_stated",
                "confirmed": True,
                "target_date": target_date,
            }
        )
        .execute()
    )
    return result.data[0]


def update_goal(user_id: str, goal_id: str, data: dict) -> dict | None:
    data["updated_at"] = datetime.utcnow().isoformat()
    result = (
        supabase.table("goals")
        .update(data)
        .eq("id", goal_id)
        .eq("user_id", user_id)
        .execute()
    )
    return result.data[0] if result.data else None


def delete_goal(user_id: str, goal_id: str) -> bool:
    result = (
        supabase.table("goals")
        .delete()
        .eq("id", goal_id)
        .eq("user_id", user_id)
        .execute()
    )
    return bool(result.data)


def add_milestone(user_id: str, goal_id: str, description: str, achieved_at: str | None) -> dict | None:
    owns_goal = (
        supabase.table("goals")
        .select("id")
        .eq("id", goal_id)
        .eq("user_id", user_id)
        .limit(1)
        .execute()
        .data
    )
    if not owns_goal:
        return None

    result = (
        supabase.table("milestones")
        .insert(
            {
                "goal_id": goal_id,
                "user_id": user_id,
                "description": description,
                "source": "user_stated",
                "achieved_at": achieved_at,
            }
        )
        .execute()
    )
    return result.data[0]


def update_milestone(user_id: str, milestone_id: str, data: dict) -> dict | None:
    result = (
        supabase.table("milestones")
        .update(data)
        .eq("id", milestone_id)
        .eq("user_id", user_id)
        .execute()
    )
    return result.data[0] if result.data else None


def delete_milestone(user_id: str, milestone_id: str) -> bool:
    result = (
        supabase.table("milestones")
        .delete()
        .eq("id", milestone_id)
        .eq("user_id", user_id)
        .execute()
    )
    return bool(result.data)
