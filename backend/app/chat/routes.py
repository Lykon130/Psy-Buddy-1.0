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
from app.mental_states.service import compute_mental_state, persist_mental_state
from app.context.service import build_context_packet
from app.orchestrator.service import suggest as orchestrator_suggest
from app.growth.service import get_goals
from app.intervention.service import plan as plan_intervention, STRATEGY_GUIDANCE
from app.simulation.service import simulate as simulate_tone
from app.reflection.service import score_response

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

        # Emotion detection — keep the full result dict alive (Phase 2 needs
        # valence/arousal, not just the top label) so we don't re-run the
        # (expensive) pipeline a second time downstream.
        try:
            emotion_result = detect_emotion(text=request.message)
            emotion = emotion_result.get("emotion", None)
        except Exception as e:
            emotion_result = {"emotion": None, "score": 0.0, "distribution": [], "valence": 0.0, "arousal": 0.0}
            emotion = None
            print(f"[Emotion Detection Error] {e}")

        # Get user_id from username, create lazily if missing (OAuth)
        user_id = get_or_create_user(request.username)

        # Minimal Crisis Safety Core (L17) — runs ahead of persona/LLM response
        risk = assess_risk(request.message)
        persona = request.persona

        # Mental State vector (Phase 2 L2/L4) — computed regardless of risk
        # flag so trend continuity isn't broken by crisis turns.
        mental_state = compute_mental_state(user_id, session_id, emotion_result, source="chat")
        persist_mental_state(mental_state)

        # Confirmed long-term facts, needed both for the reply prompt and
        # for Context Fusion below.
        confirmed_facts = [f["fact_text"] for f in get_facts(user_id, confirmed_only=True)]

        # Context Fusion (L2) + rule-based Orchestrator suggestion (advisory
        # only — never overrides the client-selected/crisis-forced persona).
        # Built ahead of the reply (not after, as in Phase 2) so the
        # Intervention Planner and Emotional Simulation passes below can
        # steer this turn's single LLM call.
        context_packet = build_context_packet(
            user_id, session_id, emotion_result, mental_state, risk, confirmed_facts
        )
        suggestion = orchestrator_suggest(context_packet)

        if risk.flagged:
            log_safety_event(user_id, session_id, risk)
            persona = "empath"
            reply = CRISIS_RESPONSE_TEXT
            intervention_plan = plan_intervention(context_packet, active_goals=[])
        else:
            # Background async fact extraction (structured memory)
            background_tasks.add_task(store_new_facts, user_id, session_id, request.message)

            # Intervention Planner (L8): rule-based strategy selection, and
            # Emotional Simulation (L9): a cheap tone/hedging check on the
            # manually-selected persona against the current mental state —
            # both fold their guidance into this turn's single prompt, no
            # extra LLM round-trip.
            active_goals = get_goals(user_id)
            intervention_plan = plan_intervention(context_packet, active_goals)
            simulation_note = simulate_tone(persona, context_packet)

            strategy_guidance = [STRATEGY_GUIDANCE[intervention_plan.strategy]]
            if simulation_note.mismatch and simulation_note.guidance:
                strategy_guidance.append(simulation_note.guidance)

            # Fetch only messages for exact session
            history_response = supabase.table("chats").select("*").eq("user_id", user_id).eq("session_id", session_id).order("timestamp").execute()
            all_messages = history_response.data

            history_for_gpt = [
                {"role": msg["role"], "content": msg["message"]}
                for msg in all_messages
            ]
            history_for_gpt.append({"role": "user", "content": request.message})

            # Get AI reply mapped
            reply = get_ai_response(history_for_gpt, persona, confirmed_facts, strategy_guidance)

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

        assistant_insert = supabase.table("chats").insert(assistant_doc).execute()
        assistant_message_id = assistant_insert.data[0]["id"] if assistant_insert.data else None

        # Self-reflection scoring (L12) — background, observability only.
        background_tasks.add_task(
            score_response,
            user_id, session_id, assistant_message_id,
            request.message, reply, persona, risk.flagged,
        )

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
            "risk_flagged": risk.flagged,
            "mental_state": mental_state.dict(),
            "suggested_persona": suggestion.suggested_persona,
            "suggested_retrieval_scope": suggestion.suggested_retrieval_scope,
            "intervention_strategy": intervention_plan.strategy
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
