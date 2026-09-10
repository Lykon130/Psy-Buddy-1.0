from pydantic import BaseModel
from typing import List

from app.mental_states.models import MentalStateVector


class ContextPacket(BaseModel):
    user_id: str
    session_id: str
    emotion: str | None
    emotion_score: float
    mental_state: MentalStateVector
    recent_mood_trend: List[float] = []
    recent_journal_themes: List[str] = []
    confirmed_facts: List[str] = []
    risk_flagged: bool = False
    risk_severity: str = "none"
