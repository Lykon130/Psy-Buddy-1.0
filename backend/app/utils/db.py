from app.utils.config import supabase

def get_or_create_user(username: str) -> str:
    """
    Looks up a user by username in the public.users table.
    If they do not exist (e.g. they logged in via OAuth), it creates them.
    Returns the user's UUID.
    """
    user_response = supabase.table("users").select("id").eq("username", username).execute()
    if not user_response.data:
        new_user = supabase.table("users").insert({
            "username": username,
            "password_hash": "" # Empty for OAuth users
        }).execute()
        return new_user.data[0]["id"]
    return user_response.data[0]["id"]
