import json

from openai import OpenAI
from app.config import OPENAI_API_KEY
from app.utils.config import supabase
from app.memory.models import MemoryFact

client = OpenAI(base_url="https://openrouter.ai/api/v1", api_key=OPENAI_API_KEY)

CONFIRM_THRESHOLD = 0.8

EXTRACTION_PROMPT = """You extract durable facts about a user from a chat message, for a long-term memory store.

Existing known facts about this user:
{existing}

Latest user message:
{message}

If the message states or clearly implies a new, durable fact about the user (name, hobbies, struggles, preferences, goals, identity), return a JSON array of objects: [{{"fact_text": "...", "category": "preference|struggle|identity|goal|other", "confidence": 0.0-1.0}}].
Do not repeat facts already in the existing list. If there is nothing new, return an empty JSON array: [].
Return ONLY the JSON array, no other text."""


def extract_facts(message: str, existing_facts: list[str]) -> list[MemoryFact]:
    """Asks the LLM to pull structured, durable facts out of a single user message."""
    prompt = EXTRACTION_PROMPT.format(
        existing="\n".join(f"- {f}" for f in existing_facts) or "(none yet)",
        message=message,
    )

    try:
        response = client.chat.completions.create(
            model="tencent/hy3-preview:free",
            messages=[{"role": "user", "content": prompt}],
        )
        raw = response.choices[0].message.content.strip()
        raw = raw.removeprefix("```json").removeprefix("```").removesuffix("```").strip()
        items = json.loads(raw)
    except Exception as e:
        print("[Memory Extraction Error]", e)
        return []

    facts = []
    for item in items:
        try:
            confidence = float(item.get("confidence", 0.5))
            facts.append(
                MemoryFact(
                    fact_text=item["fact_text"],
                    category=item.get("category", "other"),
                    confidence=confidence,
                    source="inferred",
                    confirmed=confidence >= CONFIRM_THRESHOLD,
                )
            )
        except Exception:
            continue
    return facts


def get_facts(user_id: str, confirmed_only: bool = False) -> list[dict]:
    query = supabase.table("memory_facts").select("*").eq("user_id", user_id)
    if confirmed_only:
        query = query.eq("confirmed", True)
    return query.order("created_at", desc=True).execute().data


def store_new_facts(user_id: str, session_id: str, message: str) -> None:
    """Background task: extract facts from a message and persist any new ones."""
    try:
        existing = [f["fact_text"] for f in get_facts(user_id)]
        new_facts = extract_facts(message, existing)
        for fact in new_facts:
            supabase.table("memory_facts").insert(
                {
                    "user_id": user_id,
                    "fact_text": fact.fact_text,
                    "category": fact.category,
                    "confidence": fact.confidence,
                    "source": fact.source,
                    "session_id": session_id,
                    "confirmed": fact.confirmed,
                }
            ).execute()
    except Exception as e:
        print("[Memory Store Error]", e)
