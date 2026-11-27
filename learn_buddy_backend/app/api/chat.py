from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime

from app.dependencies.auth_deps import get_current_user, get_current_user_optional
from app.models.user import User
from app.services.ai.categorization_service import CATEGORIES
from app.services.ai.chroma_service import chroma_journey_service
from app.services.ai.gemini_service import gemini_mentor_service

router = APIRouter(prefix="/chat", tags=["AI Mentor Chat"])

class ChatMessageRequest(BaseModel):
    message: str
    subject: Optional[str] = "General"
    language: Optional[str] = "hi"

class ChatMessageResponse(BaseModel):
    response: str
    subject: str
    category_applied: str
    category_title: str
    timestamp: str
    context_used: List[str] = []
    audio_base64: Optional[str] = None
    tts_provider: Optional[str] = None
    career_grounded: bool = False

@router.post("/message", response_model=ChatMessageResponse)
async def send_chat_message(
    payload: ChatMessageRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Processes a student's question with personalized AI mentoring:
    - Generates response using Gemini 2.5 Flash (Vertex AI)
    - Injects category-specific persona (6 tiers)
    - Retrieves long-term memory from ChromaDB
    - Grounds career queries using Pinecone vector index
    - Generates speech audio with Microsoft Edge Neural TTS
    - Saves the interaction back to ChromaDB
    """
    query = payload.message.strip()
    if not query:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message cannot be empty."
        )

    # 1. Retrieve past context from ChromaDB
    past_context = chroma_journey_service.retrieve_past_context(
        user_id=current_user.id,
        current_query=query,
        n_results=2
    )

    # 2. Call Gemini 2.5 Flash Service
    result = await gemini_mentor_service.generate_response(
        query=query,
        user_name=current_user.name or "Student",
        student_class=current_user.student_class or 10,
        stream=current_user.stream,
        performance_category=current_user.performance_category or "average",
        weak_subjects=current_user.weak_subjects or [],
        past_interactions=past_context,
        language=payload.language or "hi",
    )

    response_text = result["reply"]

    # 3. Save interaction to ChromaDB Journey memory
    chroma_journey_service.log_interaction(
        user_id=current_user.id,
        query=query,
        response=response_text,
        subject=payload.subject or "General",
        category=current_user.performance_category or "average"
    )

    cat_id = current_user.performance_category or "average"
    cat_info = CATEGORIES.get(cat_id, CATEGORIES["average"])
    context_used_titles = [m["metadata"].get("query", "") for m in past_context if "metadata" in m]

    return ChatMessageResponse(
        response=response_text,
        subject=payload.subject or "General",
        category_applied=cat_id,
        category_title=cat_info["title"],
        timestamp=datetime.utcnow().isoformat(),
        context_used=context_used_titles,
        audio_base64=result.get("audio_base64"),
        tts_provider=result.get("tts_provider"),
        career_grounded=result.get("career_grounded", False),
    )

@router.get("/history")
def get_chat_history(
    limit: int = 30,
    current_user: User = Depends(get_current_user)
):
    """Retrieves previous chat interactions stored in ChromaDB for this student."""
    history = chroma_journey_service.get_recent_history(
        user_id=current_user.id,
        limit=limit
    )
    return {"history": history, "count": len(history)}

# Core handler callable both internally and via FastAPI route
async def handle_voice_chat(
    payload: Dict[str, Any],
    user: Optional[User] = None
) -> Dict[str, Any]:
    query = payload.get("message", "").strip()
    if not query:
        raise HTTPException(status_code=400, detail="Message is empty")

    user_id = payload.get("user_id") or (user.id if isinstance(user, User) else "guest_student")
    user_name = payload.get("name") or (user.name if isinstance(user, User) else "Student")
    student_class = payload.get("student_class") or (user.student_class if isinstance(user, User) else 10)
    stream = payload.get("stream") or (user.stream if isinstance(user, User) else None)
    performance_cat = payload.get("performance_category") or (user.performance_category if isinstance(user, User) else "average")
    weak_subs = payload.get("weak_subjects") or (user.weak_subjects if isinstance(user, User) else [])

    past_context = chroma_journey_service.retrieve_past_context(user_id, query, n_results=2)

    result = await gemini_mentor_service.generate_response(
        query=query,
        user_name=user_name,
        student_class=student_class,
        stream=stream,
        performance_category=performance_cat,
        weak_subjects=weak_subs,
        past_interactions=past_context,
        language=payload.get("language", "hi"),
    )

    # Persist in ChromaDB journey history
    chroma_journey_service.log_interaction(
        user_id,
        query,
        result["reply"],
        "General",
        performance_cat
    )

    return {
        "reply": result["reply"],
        "question": query,
        "audio_base64": result.get("audio_base64"),
        "tts_provider": result.get("tts_provider", "edge_tts"),
        "category": performance_cat,
        "career_grounded": result.get("career_grounded", False),
    }

@router.post("/voice-chat")
async def voice_chat_compat(
    payload: Dict[str, Any],
    current_user: Optional[User] = Depends(get_current_user_optional)
):
    return await handle_voice_chat(payload, user=current_user)

