from pydantic import BaseModel
from typing import Literal


class OrchestratorSuggestion(BaseModel):
    suggested_persona: Literal["empath", "coach", "friend"]
    suggested_retrieval_scope: Literal["minimal", "standard", "deep"]
    reason: str
