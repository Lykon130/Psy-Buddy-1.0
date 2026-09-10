from datetime import datetime

from app.mental_states.models import MentalStateVector
from app.utils.config import supabase

STRESS_VALENCE_WEIGHT = 0.6
STRESS_AROUSAL_WEIGHT = 0.4
TREND_WINDOW = 5
TREND_THRESHOLD = 0.1


def _clamp(value: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return max(lo, min(hi, value))


def compute_trend(user_id: str, window: int = TREND_WINDOW) -> tuple[str, float]:
    """
    Rolling comparison of recent vs. older stress values for this user, over
    the last `window` mental_states rows (queried BEFORE the current turn's
    row is inserted, so trend reflects "history vs. now").
    """
    rows = (
        supabase.table("mental_states")
        .select("stress,timestamp")
        .eq("user_id", user_id)
        .order("timestamp", desc=True)
        .limit(window)
        .execute()
        .data
    )

    if len(rows) < 2:
        return "insufficient_data", 0.0

    mid = len(rows) // 2 or 1
    recent = rows[:mid]
    older = rows[mid:] or rows[mid - 1:]

    recent_avg = sum(r["stress"] for r in recent) / len(recent)
    older_avg = sum(r["stress"] for r in older) / len(older)
    delta = round(recent_avg - older_avg, 4)

    if delta > TREND_THRESHOLD:
        return "worsening", delta
    if delta < -TREND_THRESHOLD:
        return "improving", delta
    return "stable", delta


def compute_mental_state(
    user_id: str,
    session_id: str | None,
    emotion_result: dict,
    source: str = "chat",
) -> MentalStateVector:
    """
    Derives a Mental State vector from an already-computed detect_emotion()
    result (avoids a second, expensive pipeline call per turn).

    stress is a documented, tunable heuristic combining valence and arousal —
    an internal reasoning aid only, never a clinical measurement.
    """
    valence = emotion_result.get("valence", 0.0)
    arousal = emotion_result.get("arousal", 0.0)
    stress = _clamp(STRESS_VALENCE_WEIGHT * max(0.0, -valence) + STRESS_AROUSAL_WEIGHT * arousal)

    trend, trend_delta = compute_trend(user_id)

    return MentalStateVector(
        user_id=user_id,
        session_id=session_id,
        source=source,
        valence=valence,
        stress=round(stress, 4),
        arousal=arousal,
        trend=trend,
        trend_delta=trend_delta,
    )


def persist_mental_state(vector: MentalStateVector) -> dict:
    row = vector.dict(exclude={"id", "timestamp"})
    row["timestamp"] = datetime.utcnow().isoformat()
    try:
        return supabase.table("mental_states").insert(row).execute().data[0]
    except Exception as e:
        print("[Mental State Store Error]", e)
        return row
