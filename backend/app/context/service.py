from app.context.models import ContextPacket
from app.mental_states.models import MentalStateVector
from app.utils.config import supabase

RECENT_TREND_LIMIT = 5
RECENT_JOURNAL_LIMIT = 3


def build_context_packet(
    user_id: str,
    session_id: str,
    emotion_result: dict,
    mental_state: MentalStateVector,
    risk,
    confirmed_facts: list[str],
) -> ContextPacket:
    """
    Assembles the per-turn fused context packet: current emotion + mental
    state vector + recent journal themes/mood history + confirmed memory
    facts + risk flag, as one object.
    """
    trend_rows = (
        supabase.table("mental_states")
        .select("stress")
        .eq("user_id", user_id)
        .order("timestamp", desc=True)
        .limit(RECENT_TREND_LIMIT)
        .execute()
        .data
    )
    recent_mood_trend = [r["stress"] for r in trend_rows][::-1]

    journal_rows = (
        supabase.table("journals")
        .select("emotion")
        .eq("user_id", user_id)
        .order("timestamp", desc=True)
        .limit(RECENT_JOURNAL_LIMIT)
        .execute()
        .data
    )
    recent_journal_themes = [j["emotion"] for j in journal_rows if j.get("emotion")]

    return ContextPacket(
        user_id=user_id,
        session_id=session_id,
        emotion=emotion_result.get("emotion"),
        emotion_score=emotion_result.get("score", 0.0),
        mental_state=mental_state,
        recent_mood_trend=recent_mood_trend,
        recent_journal_themes=recent_journal_themes,
        confirmed_facts=confirmed_facts,
        risk_flagged=risk.flagged,
        risk_severity=risk.severity,
    )
