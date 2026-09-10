# backend/app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.auth import routes as auth_routes
from app.chat import routes as chat_routes
from app.journal import routes as journal_routes
from app.dreams import routes as dream_routes
from app.mood import routes as mood_routes
from app.memory import routes as memory_routes
from app.mental_states import routes as mental_states_routes
from app.identity import routes as identity_routes
from app.growth import routes as growth_routes
from app.reflection import routes as reflection_routes
app = FastAPI(title="PsyBuddy API")

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routes
app.include_router(auth_routes.router, prefix="/auth", tags=["Auth"])
app.include_router(chat_routes.router, prefix="/chat", tags=["Chat"])
app.include_router(journal_routes.router, prefix="/journal", tags=["Journal"])
app.include_router(dream_routes.router, prefix="/dreams", tags=["Dreams"])
app.include_router(mood_routes.router, prefix="/mood", tags=["Mood"])
app.include_router(memory_routes.router, prefix="/memory", tags=["Memory"])
app.include_router(mental_states_routes.router, prefix="/mental-states", tags=["MentalStates"])
app.include_router(identity_routes.router, prefix="/identity", tags=["Identity"])
app.include_router(growth_routes.router, prefix="/growth", tags=["Growth"])
app.include_router(reflection_routes.router, prefix="/reflection", tags=["Reflection"])

@app.get("/")
def root():
    return {"message": "Welcome to PsyBuddy API"}
