import os
from dotenv import load_dotenv

load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "dummy_key")
JWT_SECRET = os.getenv("JWT_SECRET", "super_secret_jwt_key_psybuddy")
JWT_ALGORITHM = "HS256"
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
