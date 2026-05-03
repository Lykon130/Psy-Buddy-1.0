from openai import OpenAI
from app.config import OPENAI_API_KEY
from app.chat.persona_config import persona_prompts

# Initialize OpenAI client with openrouter details
# client = OpenAI(api_key=OPENAI_API_KEY)
client = OpenAI(base_url="https://openrouter.ai/api/v1", api_key=OPENAI_API_KEY)

def get_ai_response(history_messages, persona: str, global_memory: str = ""):
    """
    history_messages: List[{"role": "user"|"assistant", "content": "..."}]
    persona: string key for persona prompt
    global_memory: persistent user traits
    """
    system_prompt = persona_prompts.get(persona.lower(), persona_prompts["empath"]).copy()
    
    if global_memory.strip():
        system_prompt["content"] += f"\n\n--- Long-term memory about this user:\n{global_memory}"

    messages = [system_prompt] + history_messages

    try:
        response = client.chat.completions.create(
            model="tencent/hy3-preview:free",
            messages=messages
        )
        return response.choices[0].message.content
    except Exception as e:
        return f"[Error] Failed to get AI response: {e}"

def extract_new_memory(current_memory: str, new_user_message: str):
    """Asks GPT to extract any new persistent facts about the user from their latest message."""
    prompt = f"Current User Memory:\n{current_memory}\n\nLatest user message:\n{new_user_message}\n\nIf the user stated facts about themselves (name, hobbies, struggles, preferences, etc), update the memory concisely. If no new facts, return the original memory exactly."
    
    try:
        response = client.chat.completions.create(
            model="tencent/hy3-preview:free",
            messages=[{"role": "user", "content": prompt}]
        )
        return response.choices[0].message.content.strip()
    except:
        return current_memory
