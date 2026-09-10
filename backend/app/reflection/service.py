import re

from app.utils.config import supabase
from app.reflection.models import ResponseScore
from app.safety.service import CRISIS_RESPONSE_TEXT

# Self-reflection scoring (L12), extending the continuous_trainer.py pattern
# (proven for the emotion classifier) to dialogue quality. Heuristic-only for
# now — an async LLM-judge pass can replace/augment these once the
# heuristic's ceiling is understood. Observability only: nothing here feeds
# back into prompt/rule changes automatically yet.

EMPATHY_MARKERS = [
    "understand", "feel", "feeling", "sounds like", "i hear you",
    "that's hard", "that sounds", "i'm here", "im here", "makes sense",
    "valid", "not alone",
]


def _word_overlap_score(user_message: str, reply: str) -> float:
    user_words = set(re.findall(r"\w+", user_message.lower()))
    reply_words = set(re.findall(r"\w+", reply.lower()))
    if not user_words:
        return 0.0
    return round(len(user_words & reply_words) / len(user_words), 2)


def _empathy_score(reply: str) -> float:
    text = reply.lower()
    hits = sum(1 for marker in EMPATHY_MARKERS if marker in text)
    return min(1.0, round(hits / 2, 2))


def score_response(
    user_id: str,
    session_id: str,
    message_id: str | None,
    user_message: str,
    reply: str,
    persona: str,
    risk_flagged: bool,
) -> None:
    """Background task: score the just-generated assistant reply and store it."""
    try:
        is_error = reply.startswith("[Error]")

        protocol_adherence = None
        if risk_flagged:
            protocol_adherence = 1.0 if reply == CRISIS_RESPONSE_TEXT else 0.0

        score = ResponseScore(
            empathy_score=0.0 if is_error else _empathy_score(reply),
            relevance_score=0.0 if is_error else _word_overlap_score(user_message, reply),
            persona_consistency_score=0.0 if is_error else 1.0,
            protocol_adherence_score=protocol_adherence,
        )

        supabase.table("response_scores").insert(
            {
                "user_id": user_id,
                "session_id": session_id,
                "message_id": message_id,
                "persona": persona,
                "risk_flagged": risk_flagged,
                **score.dict(),
            }
        ).execute()
    except Exception as e:
        print("[Self-Reflection Scoring Error]", e)


def get_scores(user_id: str, limit: int = 50) -> list[dict]:
    return (
        supabase.table("response_scores")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .limit(limit)
        .execute()
        .data
    )
