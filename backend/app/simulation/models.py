from pydantic import BaseModel
from typing import Optional


class SimulationNote(BaseModel):
    mismatch: bool = False
    reason: str = "none"
    guidance: Optional[str] = None
