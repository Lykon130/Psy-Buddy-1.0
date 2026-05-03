from fastapi import APIRouter, HTTPException, Query
from collections import Counter
from datetime import datetime, timedelta
from app.utils.config import supabase

router = APIRouter()

@router.get("/{username}")
def get_mood_data(
    username: str,
    days: int = Query(7, ge=0, le=365, description="Number of days to look back (0 = all time)")
):
    try:
        user_response = supabase.table("users").select("id").eq("username", username).execute()
        if not user_response.data:
            return {
                "totals": {},
                "trend": {},
                "mood_trend": []
            }
        user_id = user_response.data[0]["id"]

        query = supabase.table("mood_logs").select("*").eq("user_id", user_id)

        if days > 0:
            cutoff_date = datetime.utcnow() - timedelta(days=days)
            query = query.gte("timestamp", cutoff_date.isoformat())

        response = query.execute()
        logs = response.data
        
        # ✅ TOTALS
        emotions = [log["emotion"] for log in logs if log.get("emotion")]
        mood_counts = dict(Counter(emotions))

        # ✅ DAILY TREND
        trend_data = {}
        for log in logs:
            if not log.get("timestamp") or not log.get("emotion"):
                continue
                
            # Keep only the YYYY-MM-DD part
            date_str = log["timestamp"].split("T")[0]
            emotion = log["emotion"]
            
            if date_str not in trend_data:
                trend_data[date_str] = {}
            if emotion not in trend_data[date_str]:
                trend_data[date_str][emotion] = 0
                
            trend_data[date_str][emotion] += 1

        # 🔥 Convert to mood score per day
        mood_trend = []
        for date, ems in trend_data.items():
            total_score = 0
            total_count = 0

            # compute avg score logically from logs instead of re-getting 'emotion_to_score' mapping here?
            # actually we can just iterate the logs for that date directly since they have `score`
            for log in logs:
                if log.get("timestamp") and log["timestamp"].split("T")[0] == date and log.get("score") is not None:
                    total_score += log["score"]
                    total_count += 1
                    
            avg_score = total_score / total_count if total_count > 0 else 0

            mood_trend.append({
                "date": date,
                "score": round(avg_score, 3)
            })
            
        # sort mood_trend by date ascending
        mood_trend.sort(key=lambda x: x["date"])

        return {
            "totals": mood_counts,
            "trend": trend_data,
            "mood_trend": mood_trend
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fetching mood data failed: {e}")