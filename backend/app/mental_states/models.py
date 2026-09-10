from pydantic import BaseModel
from typing import Literal, Optional
from datetime import datetime


class MentalStateVector(BaseModel):
    id: Optional[str] = None
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    source: Literal["chat", "journal"] = "chat"
    valence: float = 0.0
    stress: float = 0.0
    arousal: float = 0.0
    trend: Literal["improving", "worsening", "stable", "insufficient_data"] = "insufficient_data"
    trend_delta: float = 0.0
    timestamp: Optional[datetime] = None
