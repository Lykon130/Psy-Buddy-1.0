# test_supabase.py
from app.utils.config import supabase

response = supabase.table("users").select("*").execute()
print(response.data)