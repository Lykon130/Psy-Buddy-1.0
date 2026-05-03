from openai import OpenAI
from app.config import OPENAI_API_KEY
from app.persona_config import persona_prompts

# Initialize OpenAI client
client = OpenAI(api_key=OPENAI_API_KEY)

def get_ai_response(history_messages, persona: str):
    """
    history_messages: List[{"role": "user"|"assistant", "content": "..."}]
    persona: string key for persona prompt
    """
    system_prompt = persona_prompts.get(persona.lower(), persona_prompts["empath"])
    messages = [system_prompt] + history_messages

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages
        )
        return response.choices[0].message.content
    except Exception as e:
        return f"[Error] Failed to get AI response: {e}"
