from openai import OpenAI
from app.config import OPENAI_API_KEY
from app.chat.persona_config import persona_prompts

# Initialize OpenAI client with openrouter details
# client = OpenAI(api_key=OPENAI_API_KEY)
client = OpenAI(base_url="https://openrouter.ai/api/v1", api_key=OPENAI_API_KEY)

def get_ai_response(history_messages, persona: str, memory_facts=None, context=None):
    """
    history_messages: List[{"role": "user"|"assistant", "content": "..."}]
    persona: string key for persona prompt
    memory_facts: list of confirmed long-term fact strings about the user
    context: optional app.context.models.ContextPacket — reserved for
        Phase 3's Intervention Planner, not used in prompt construction yet
    """
    system_prompt = persona_prompts.get(persona.lower(), persona_prompts["empath"]).copy()

    if memory_facts:
        facts_str = "\n".join(f"- {f}" for f in memory_facts)
        system_prompt["content"] += f"\n\n--- Long-term memory about this user:\n{facts_str}"

    messages = [system_prompt] + history_messages

    try:
        response = client.chat.completions.create(
            model="tencent/hy3-preview:free",
            messages=messages
        )
        return response.choices[0].message.content
    except Exception as e:
        return f"[Error] Failed to get AI response: {e}"
