from pydantic import BaseModel
from typing import Literal, Optional


class GoalCreate(BaseModel):
    title: str
    description: Optional[str] = None
    target_date: Optional[str] = None


class GoalUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[Literal["active", "completed", "archived"]] = None
    target_date: Optional[str] = None
    confirmed: Optional[bool] = None


class MilestoneCreate(BaseModel):
    description: str
    achieved_at: Optional[str] = None


class MilestoneUpdate(BaseModel):
    description: Optional[str] = None
    achieved_at: Optional[str] = None
