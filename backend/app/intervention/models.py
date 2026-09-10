from pydantic import BaseModel
from typing import Literal, Optional

Strategy = Literal[
    "reflective_listening",
    "grounding_exercise",
    "goal_check_in",
    "reframe",
    "validate_and_normalize",
    "psychoeducation_light",
]


class InterventionPlan(BaseModel):
    strategy: Strategy
    rationale: str
    focus: Optional[str] = None
