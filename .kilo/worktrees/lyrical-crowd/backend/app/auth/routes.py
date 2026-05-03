# backend/app/auth/routes.py
from fastapi import APIRouter, HTTPException
from passlib.hash import bcrypt
from jose import jwt
from datetime import datetime, timedelta

from app.utils.config import supabase
from app.auth.models import UserRegister

# JWT settings
SECRET_KEY = "your_secret_key"  # 🔹 Change this to something secure
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

router = APIRouter()

# ---------------------------
# Register Route
# ---------------------------
@router.post("/register")
def register(user: UserRegister):
    try:
        # Check if username exists
        response = supabase.table("users").select("*").eq("username", user.username).execute()
        if response.data:
            raise HTTPException(status_code=400, detail="Username already exists.")

        # Hash password before saving
        hashed_password = bcrypt.hash(user.password)
        supabase.table("users").insert({
            "username": user.username,
            "password_hash": hashed_password
        }).execute()

        return {"message": "User registered successfully."}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {e}")


# ---------------------------
# Login Route
# ---------------------------
@router.post("/login")
def login(user: UserRegister):
    try:
        # Find user
        response = supabase.table("users").select("*").eq("username", user.username).execute()
        db_users = response.data
        if not db_users or not bcrypt.verify(user.password, db_users[0]["password_hash"]):
            raise HTTPException(status_code=401, detail="Invalid username or password.")

        # Create JWT token
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        payload = {
            "sub": user.username,
            "exp": expire
        }
        token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

        return {
            "access_token": token,
            "token_type": "bearer",
            "username": user.username
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {e}")
