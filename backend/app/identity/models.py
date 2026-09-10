from pydantic import BaseModel
from typing import List, Optional


class IdentityProfile(BaseModel):
    communication_style: Optional[str] = None
    default_persona_preference: Optional[str] = None
    topics_to_avoid: List[str] = []
    coping_preferences: List[str] = []
