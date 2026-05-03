from fastapi import APIRouter, HTTPException
from app.journal.models import JournalEntry
from app.utils.bert_emotion_api import detect_emotion
from datetime import datetime
from app.utils.config import supabase
from app.utils.db import get_or_create_user

router = APIRouter()

# 🔥 Emotion → Score Mapping for Mood Logs
emotion_to_score = {
    "happy": 0.9,
    "neutral": 0.6,
    "sad": 0.3,
    "angry": 0.2,
    "anxious": 0.25
}

@router.post("/")
def add_entry(entry: JournalEntry):
    try:
        data = entry.dict()
        
        # Add timestamp if not present
        if "timestamp" not in data or not data["timestamp"]:
            data["timestamp"] = datetime.utcnow().isoformat()
        elif isinstance(data["timestamp"], datetime):
            data["timestamp"] = data["timestamp"].isoformat()
            
        username = data.get("username")
        user_id = get_or_create_user(username)
        
        # Detect emotion from content
        emotion_data = detect_emotion(data["content"])
        emotion = emotion_data["emotion"]
        emotion_score = emotion_data["score"]
        
        # insert to journals table
        insert_data = {
            "user_id": user_id,
            "content": data.get("content", ""),
            "type": data.get("type", "general"),
            "title": data.get("title", ""),
            "emotion": emotion,
            "emotion_score": emotion_score,
            "timestamp": data["timestamp"]
        }
        
        result = supabase.table("journals").insert(insert_data).execute()
        inserted_id = result.data[0]["id"]
        
        # Update mood logs if there is an emotion
        if emotion:
            score = emotion_to_score.get(emotion, 0.5)
            supabase.table("mood_logs").insert({
                "user_id": user_id,
                "emotion": emotion,
                "score": score,
                "timestamp": data["timestamp"]
            }).execute()

        # Return complete entry for frontend mapping db keys back to frontend keys
        return {
            "_id": str(inserted_id),
            "username": username,
            "title": insert_data["title"],
            "content": insert_data["content"],
            "timestamp": insert_data["timestamp"],
            "emotion": insert_data["emotion"],
            "emotion_score": insert_data["emotion_score"]
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{username}")
def get_entries(username: str):
    try:
        user_id = get_or_create_user(username)
        
        result = supabase.table("journals").select("*").eq("user_id", user_id).order("timestamp", desc=True).execute()
        entries = result.data
        
        for e in entries:
            e["_id"] = str(e["id"])
            e["username"] = username
        return entries
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fetching journal failed: {e}")
