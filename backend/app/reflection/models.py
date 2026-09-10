from pydantic import BaseModel
from typing import Optional


class ResponseScore(BaseModel):
    empathy_score: Optional[float] = None
    relevance_score: Optional[float] = None
    persona_consistency_score: Optional[float] = None
    protocol_adherence_score: Optional[float] = None
