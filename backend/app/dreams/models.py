# backend/app/dreams/models.py
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class DreamEntry(BaseModel):
    username: str
    title: str
    content: str
    emotion: Optional[str] = None   # ✅ store detected emotion
    timestamp: datetime = datetime.utcnow()
