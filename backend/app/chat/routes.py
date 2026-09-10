from fastapi import APIRouter, HTTPException, BackgroundTasks
from datetime import datetime
import uuid

from .models import ChatRequest
from app.utils.bert_emotion_api import detect_emotion
from app.chat.gpt_service import get_ai_response
from app.utils.config import supabase
from app.utils.db import get_or_create_user
from app.memory.service import get_facts, store_new_facts
from app.safety.service import assess_risk, log_safety_event, CRISIS_RESPONSE_TEXT

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
def chat(request: ChatRequest, background_tasks: BackgroundTasks):
    try:
        session_id = request.session_id or str(uuid.uuid4())

        # Emotion detection
        try:
            emotion_result = detect_emotion(text=request.message)
            emotion = emotion_result.get("emotion", None)
        except Exception as e:
            emotion = None
            print(f"[Emotion Detection Error] {e}")

        # Get user_id from username, create lazily if missing (OAuth)
        user_id = get_or_create_user(request.username)

        # Minimal Crisis Safety Core (L17) — runs ahead of persona/LLM response
        risk = assess_risk(request.message)
        persona = request.persona

        if risk.flagged:
            log_safety_event(user_id, session_id, risk)
            persona = "empath"
            reply = CRISIS_RESPONSE_TEXT
        else:
            # Background async fact extraction (structured memory)
            background_tasks.add_task(store_new_facts, user_id, session_id, request.message)

            # Confirmed long-term facts to inject as context
            confirmed_facts = [f["fact_text"] for f in get_facts(user_id, confirmed_only=True)]

            # Fetch only messages for exact session
            history_response = supabase.table("chats").select("*").eq("user_id", user_id).eq("session_id", session_id).order("timestamp").execute()
            all_messages = history_response.data

            history_for_gpt = [
                {"role": msg["role"], "content": msg["message"]}
                for msg in all_messages
            ]
            history_for_gpt.append({"role": "user", "content": request.message})

            # Get AI reply mapped
            reply = get_ai_response(history_for_gpt, persona, confirmed_facts)

        # If session is new, generate title
        existing_session_response = supabase.table("chats").select("id").eq("user_id", user_id).eq("session_id", session_id).limit(1).execute()
        session_title = None
        if not existing_session_response.data:
            session_title = request.message[:40] + ("..." if len(request.message) > 40 else "")
        else:
            # retrieve existing session title so we can persist it down (or we could store it just once, but usually it's replicated or fetched)
            existing_title_resp = supabase.table("chats").select("session_title").eq("user_id", user_id).eq("session_id", session_id).limit(1).execute()
            if existing_title_resp.data:
                session_title = existing_title_resp.data[0].get("session_title")

        # Save user message
        user_doc = {
            "user_id": user_id,
            "role": "user",
            "message": request.message,
            "emotion": emotion,
            "persona": persona,
            "session_id": session_id,
            "timestamp": datetime.utcnow().isoformat()
        }
        if session_title:
            user_doc["session_title"] = session_title

        supabase.table("chats").insert(user_doc).execute()

        # Save assistant reply
        assistant_doc = {
            "user_id": user_id,
            "role": "assistant",
            "message": reply,
            "persona": persona,
            "session_id": session_id,
            "timestamp": datetime.utcnow().isoformat()
        }
        if session_title:
            assistant_doc["session_title"] = session_title
            
        supabase.table("chats").insert(assistant_doc).execute()

        # Update mood logs if there is an emotion (skip for crisis-flagged messages)
        if emotion and not risk.flagged:
            score = emotion_to_score.get(emotion, 0.5)
            supabase.table("mood_logs").insert({
                "user_id": user_id,
                "emotion": emotion,
                "score": score,
                "timestamp": datetime.utcnow().isoformat()
            }).execute()

        return {
            "reply": reply,
            "emotion": emotion,
            "session_id": session_id,
            "persona": persona,
            "risk_flagged": risk.flagged
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Chat failed: {e}")


@router.get("/history/{username}")
def get_all_history(username: str):
    try:
        user_id = get_or_create_user(username)
        
        # Filter out the underlying system 'global_memory' session so it never renders in UI logs
        history_response = supabase.table("chats").select("*").eq("user_id", user_id).neq("session_id", "global_memory").order("timestamp", desc=True).execute()
        all_msgs = history_response.data

        sessions = {}
        for m in all_msgs:
            sid = m.get("session_id")
            if not sid:
                continue
                
            if sid not in sessions:
                sessions[sid] = {
                    "session_id": sid,
                    "messages": [],
                    "last_updated": m["timestamp"],
                    "title": m.get("session_title") or f"Chat {sid[:6]}"
                }
            # Remap for frontend compatibility
            frontend_msg = dict(m)
            frontend_msg["_id"] = frontend_msg["id"]
            frontend_msg["content"] = frontend_msg["message"]
            frontend_msg["username"] = username
            sessions[sid]["messages"].insert(0, frontend_msg) # order is inverted because we fetched desc=True
            
            # Since fetched descending, the first message processed for a session is its last_updated
            if m["timestamp"] > sessions[sid]["last_updated"]:
                sessions[sid]["last_updated"] = m["timestamp"]

        # Convert back to list and sort
        session_list = list(sessions.values())
        session_list.sort(key=lambda x: x["last_updated"], reverse=True)
        return session_list

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fetching history failed: {e}")


@router.get("/history/{username}/{session_id}")
def get_session_history(username: str, session_id: str):
    try:
        user_id = get_or_create_user(username)

        history_response = supabase.table("chats").select("*").eq("user_id", user_id).eq("session_id", session_id).order("timestamp").execute()
        
        messages = history_response.data
        for m in messages:
            m["_id"] = m["id"]
            m["content"] = m["message"]
            m["username"] = username
            
        return messages
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fetching session history failed: {e}")
