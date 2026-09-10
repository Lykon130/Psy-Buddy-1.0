from openai import OpenAI
from app.config import OPENAI_API_KEY
from app.chat.persona_config import persona_prompts

# Initialize OpenAI client with openrouter details
# client = OpenAI(api_key=OPENAI_API_KEY)
client = OpenAI(base_url="https://openrouter.ai/api/v1", api_key=OPENAI_API_KEY)

def get_ai_response(history_messages, persona: str, memory_facts=None, strategy_guidance=None):
    """
    history_messages: List[{"role": "user"|"assistant", "content": "..."}]
    persona: string key for persona prompt
    memory_facts: list of confirmed long-term fact strings about the user
    strategy_guidance: optional list of short instruction strings from the
        Intervention Planner (L8) and Emotional Simulation (L9) passes —
        steers this single call, never adds a second one
    """
    system_prompt = persona_prompts.get(persona.lower(), persona_prompts["empath"]).copy()

    if memory_facts:
        facts_str = "\n".join(f"- {f}" for f in memory_facts)
        system_prompt["content"] += f"\n\n--- Long-term memory about this user:\n{facts_str}"

    if strategy_guidance:
        guidance_str = "\n".join(f"- {g}" for g in strategy_guidance)
        system_prompt["content"] += f"\n\n--- Guidance for this reply:\n{guidance_str}"

    messages = [system_prompt] + history_messages

    try:
        response = client.chat.completions.create(
            model="tencent/hy3-preview:free",
            messages=messages
        )
        return response.choices[0].message.content
    except Exception as e:
        return f"[Error] Failed to get AI response: {e}"
