import json
from datetime import datetime

from openai import OpenAI
from app.config import OPENAI_API_KEY
from app.utils.config import supabase
from app.identity.models import IdentityProfile

client = OpenAI(base_url="https://openrouter.ai/api/v1", api_key=OPENAI_API_KEY)

AGGREGATION_PROMPT = """You maintain a stable identity/preference profile for a user of a companionship app, built only from facts they have confirmed about themselves. This is different from a raw fact list — it's a small, durable summary of who they are.

Confirmed facts about this user:
{facts}

Return a single JSON object with these fields (use null or an empty list if there isn't enough evidence yet):
{{"communication_style": "one short phrase (e.g. 'direct', 'gentle', 'humorous') or null",
"default_persona_preference": "empath|coach|friend or null",
"topics_to_avoid": ["..."],
"coping_preferences": ["..."]}}
Return ONLY the JSON object, no other text."""


def get_identity_profile(user_id: str) -> dict | None:
    result = (
        supabase.table("identity_profile")
        .select("*")
        .eq("user_id", user_id)
        .limit(1)
        .execute()
        .data
    )
    return result[0] if result else None


def aggregate_identity_profile(user_id: str) -> None:
    """
    Background task: re-derive the identity profile from this user's
    confirmed memory facts. Called whenever the confirmed-fact set changes
    (a fact is auto-confirmed on store, or a user confirms one via the
    memory settings screen) rather than on a fixed schedule.
    """
    try:
        confirmed = (
            supabase.table("memory_facts")
            .select("fact_text, category")
            .eq("user_id", user_id)
            .eq("confirmed", True)
            .execute()
            .data
        )
        if not confirmed:
            return

        facts_text = "\n".join(f"- ({f['category']}) {f['fact_text']}" for f in confirmed)
        prompt = AGGREGATION_PROMPT.format(facts=facts_text)

        response = client.chat.completions.create(
            model="tencent/hy3-preview:free",
            messages=[{"role": "user", "content": prompt}],
        )
        raw = response.choices[0].message.content.strip()
        raw = raw.removeprefix("```json").removeprefix("```").removesuffix("```").strip()
        parsed = json.loads(raw)
        profile = IdentityProfile(**parsed)

        supabase.table("identity_profile").upsert(
            {
                "user_id": user_id,
                **profile.dict(),
                "updated_at": datetime.utcnow().isoformat(),
            }
        ).execute()
    except Exception as e:
        print("[Identity Aggregation Error]", e)
