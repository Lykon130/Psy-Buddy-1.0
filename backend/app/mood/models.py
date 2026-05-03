# backend/app/mood/models.py
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class MoodLogBase(BaseModel):
    emotion: str
    score: int  # 1-10 scale
    note: Optional[str] = None

class MoodLogCreate(MoodLogBase):
    pass

class MoodLog(MoodLogBase):
    id: int
    user_id: int
    timestamp: datetime

    class Config:
        orm_mode = True