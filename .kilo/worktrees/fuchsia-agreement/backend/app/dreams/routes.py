from fastapi import APIRouter, HTTPException
from app.dreams.models import DreamEntry
from app.utils.bert_emotion_api import detect_emotion
from datetime import datetime
from app.utils.config import supabase

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
def add_dream(entry: DreamEntry):
    try:
        # ✅ Emotion detection
        try:
            emotion_result = detect_emotion(text=entry.content)
            emotion = emotion_result.get("emotion", None)
            emotion_score = emotion_result.get("score", None)
        except Exception:
            emotion = None
            emotion_score = None

        username = entry.username
        user_response = supabase.table("users").select("id").eq("username", username).execute()
        if not user_response.data:
            raise HTTPException(status_code=404, detail="User not found")
        user_id = user_response.data[0]["id"]
        timestamp = datetime.utcnow().isoformat()

        insert_data = {
            "user_id": user_id,
            "content": entry.content,
            "emotion": emotion,
            "emotion_score": emotion_score,
            "timestamp": timestamp
        }

        result = supabase.table("dreams").insert(insert_data).execute()
        inserted_id = result.data[0]["id"]
        
        # Log to mood_logs
        if emotion:
            score = emotion_to_score.get(emotion, 0.5)
            supabase.table("mood_logs").insert({
                "user_id": user_id,
                "emotion": emotion,
                "score": score,
                "timestamp": timestamp
            }).execute()

        dream_doc = insert_data.copy()
        dream_doc["_id"] = str(inserted_id)
        dream_doc["username"] = username
        return dream_doc
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Saving dream failed: {e}")


@router.get("/{username}")
def get_dreams(username: str):
    try:
        user_response = supabase.table("users").select("id").eq("username", username).execute()
        if not user_response.data:
            return []
        user_id = user_response.data[0]["id"]

        result = supabase.table("dreams").select("*").eq("user_id", user_id).order("timestamp", desc=True).execute()
        entries = result.data
        
        for e in entries:
            e["_id"] = str(e["id"])
            e["username"] = username
        return entries
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fetching dreams failed: {e}")
