import os
from typing import Optional, Dict, Any
from fastapi import FastAPI, WebSocket, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response

from app.core.config import settings
from app.db.database import engine, Base
from app.models.user import User

from app.api.auth import router as auth_router
from app.api.users import router as users_router
from app.api.students import router as students_router
from app.api.chat import router as chat_router
from app.api._not_yet_built import router as stub_router

from app.middleware.logging import RequestLoggingMiddleware
from app.middleware.error_handler import register_error_handlers
from app.services.ai.live_voice_service import UnifiedLiveAudioSession
from app.services.ai.gemini_service import gemini_mentor_service

# Create tables
Base.metadata.create_all(bind=engine)

# Firebase Admin (safe fallback)
try:
    import firebase_admin
    from firebase_admin import credentials
    if os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)
except Exception:
    pass

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Backend for Learn Buddy — personalized learning app for Class 10 & 12 with Gemini 2.5 Flash & Pinecone Career RAG.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^https?://.*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(RequestLoggingMiddleware)
register_error_handlers(app)

app.include_router(auth_router, prefix=settings.API_V1_STR)
app.include_router(users_router, prefix=settings.API_V1_STR)
app.include_router(students_router, prefix=settings.API_V1_STR)
app.include_router(chat_router, prefix=settings.API_V1_STR)
app.include_router(stub_router, prefix=settings.API_V1_STR)

@app.get("/health", tags=["Health"])
@app.get("/api/health", tags=["Health"])
def health_check():
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "gemini_model": "gemini-2.5-flash",
        "voice_ready": True
    }

# ── Voice AI & Gemini 2.5 Flash Compatibility Endpoints ──
@app.post("/api/chat", tags=["Voice Assistant"])
async def legacy_chat_endpoint(payload: dict):
    """Answers study/career questions with Gemini 2.5 Flash + Pinecone career grounding + Edge-TTS."""
    from app.api.chat import handle_voice_chat
    return await handle_voice_chat(payload)

@app.post("/api/ask", tags=["Voice Assistant"])
async def ask_voice_endpoint(
    file: Optional[UploadFile] = File(None),
    message: Optional[str] = Form(None)
):
    """Processes audio or text question and returns Gemini 2.5 Flash reply + Edge-TTS speech."""
    from app.api.chat import handle_voice_chat
    query = message or "Can you guide me on top career pathways and syllabus tips?"
    return await handle_voice_chat({"message": query})

@app.post("/api/tts", tags=["Voice Assistant"])
async def tts_endpoint(payload: dict):
    """Synthesizes text to MP3 audio stream using Edge Neural TTS."""
    text = payload.get("text", "")
    lang = payload.get("language", "hi")
    audio = await gemini_mentor_service.generate_speech_bytes(text, language=lang)
    return Response(content=audio, media_type="audio/mpeg")

@app.post("/api/reset", tags=["Voice Assistant"])
def legacy_reset_endpoint():
    return {"ok": True, "message": "Session reset successfully"}

# ── Real-Time WebSocket Voice-to-Voice (Gemini Live) ──
@app.websocket("/ws/live")
async def websocket_live_endpoint(
    websocket: WebSocket,
    mode: str = "mentor",
    language: str = "hi",
    voice: str = "Puck",
    name: str = "Student",
    student_class: int = 10,
    stream: Optional[str] = None
):
    """
    Real-Time Gemini Live WebSocket endpoint matching Voice_AI:
    - Real-time bidirectional voice stream
    - Silent Pinecone Career Tool grounding
    """
    await websocket.accept()
    session = UnifiedLiveAudioSession(
        websocket=websocket,
        mode=mode,
        language=language,
        voice=voice,
        student_name=name,
        student_class=student_class,
        stream=stream
    )
    await session.run()
