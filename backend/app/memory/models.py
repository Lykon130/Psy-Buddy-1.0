from pydantic import BaseModel
from typing import Literal, Optional


class MemoryFact(BaseModel):
    id: Optional[str] = None
    fact_text: str
    category: Literal["preference", "struggle", "identity", "goal", "other"] = "other"
    confidence: float = 0.5
    source: Literal["user_stated", "inferred"] = "inferred"
    session_id: Optional[str] = None
    confirmed: bool = False


class MemoryFactUpdate(BaseModel):
    fact_text: Optional[str] = None
    confirmed: Optional[bool] = None
