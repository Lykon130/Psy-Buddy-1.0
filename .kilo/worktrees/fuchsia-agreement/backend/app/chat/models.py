from pydantic import BaseModel
from typing import List, Literal, Optional
from datetime import datetime

class ChatMessage(BaseModel):
    username: str
    role: Literal["user", "assistant", "system"]
    content: str
    persona: str
    session_id: str
    timestamp: datetime
    emotion: Optional[str] = None
    session_title: Optional[str] = None

class Conversation(BaseModel):
    username: str
    persona: str
    messages: List[ChatMessage]

class ChatRequest(BaseModel):
    username: str
    persona: str
    message: str
    session_id: Optional[str] = None
