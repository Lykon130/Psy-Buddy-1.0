from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class JournalEntry(BaseModel):
    username: str
    title: Optional[str] = None
    content: str
    timestamp: datetime = datetime.utcnow()
