from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime

from app.dependencies.auth_deps import get_current_user, get_current_user_optional
from app.models.user import User
from app.services.ai.categorization_service import (
    build_category_system_prompt,
    CATEGORIES
)
from app.services.ai.chroma_service import chroma_journey_service
from app.services.ai.rag_service import rag_service

router = APIRouter(prefix="/chat", tags=["AI Mentor Chat"])

class ChatMessageRequest(BaseModel):
    message: str
    subject: Optional[str] = "General"

class ChatMessageResponse(BaseModel):
    response: str
    subject: str
    category_applied: str
    category_title: str
    timestamp: str
    context_used: List[str] = []

def generate_mentor_response(
    query: str,
    subject: str,
    user: User,
    past_interactions: List[Dict[str, Any]],
    rag_context: List[Dict[str, Any]]
) -> str:
    """
    Generates a personalized response aligned with the student's academic category,
    weak subjects, and past journey memory.
    """
    cat_id = user.performance_category or "average"
    cat_info = CATEGORIES.get(cat_id, CATEGORIES["average"])
    name = user.name or "Student"
    q_lower = query.lower()

    # Prefix context if student is in a specific tier
    tone_greeting = ""
    if cat_id in ["weak", "struggling"]:
        tone_greeting = f"Don't worry, {name}! Learning takes patience, and we'll break this down step-by-step together. 😊\n\n"
    elif cat_id in ["top", "strong"]:
        tone_greeting = f"Great question, {name}! Let's dive deep into the underlying mechanics of this concept. 🚀\n\n"
    else:
        tone_greeting = f"Hello {name}! Let's master this topic with clear, structured logic. 📚\n\n"

    # Reference past context if relevant
    past_memory_mention = ""
    if past_interactions:
        past_item = past_interactions[0]["metadata"].get("query", "")
        if past_item:
            past_memory_mention = f"*(Connecting this to your earlier question about '{past_item[:40]}...'):*\n\n"

    # Check for career / stream queries with Pinecone grounding
    if any(k in q_lower for k in ["career", "future", "college", "job", "options", "what should i do", "branch", "engineering", "medical", "ca"]):
        if rag_context:
            career_details = []
            for item in rag_context[:3]:
                meta = item.get("metadata", {})
                title = meta.get("career_title", meta.get("title", "Career Pathway"))
                desc = meta.get("description", meta.get("text", ""))
                career_details.append(f"• **{title}**: {desc[:150]}...")
            
            grounded_text = "\n".join(career_details)
            return (
                f"{tone_greeting}"
                f"Based on your Class {user.student_class} ({user.stream or 'curriculum'}) profile and performance tier (**{cat_info['title']}**), here are top grounded pathways:\n\n"
                f"{grounded_text}\n\n"
                f"**Personalized Advice**: With your strengths in {', '.join(user.strong_subjects or ['your subjects'])}, focusing on consistent test series and strategic entrance exam prep will give you a major competitive edge!"
            )

    # Conceptual academic explanation based on category
    if cat_id in ["weak", "struggling"]:
        explanation = (
            f"{tone_greeting}{past_memory_mention}"
            f"### 💡 Simple 3-Step Explanation:\n"
            f"1. **What is it simply?**: Let's imagine this with a daily life example. Whenever you study **{query}**, think of it as building blocks.\n"
            f"2. **Key Rule to Remember**: Always remember the core definition first before solving problems. Avoid confusing formulas!\n"
            f"3. **Quick Check**: Can you tell me in one line what you understood from this, or should we solve a basic 2-minute example together?"
        )
    elif cat_id in ["average", "moderate"]:
        explanation = (
            f"{tone_greeting}{past_memory_mention}"
            f"### 🎯 Conceptual Breakdown & Scoring Points:\n"
            f"• **Core Formula / Concept**: Focus on the NCERT standard derivation for **{query}**.\n"
            f"• **Common Trap**: Students often lose marks on units or sign conventions here. Double-check your intermediate steps!\n"
            f"• **Exam Tip**: In your Class {user.student_class} board exam, this is typically asked as a 3-mark conceptual or numerical question.\n\n"
            f"Would you like to try 2 practice questions from moderate difficulty level?"
        )
    else: # top or strong
        explanation = (
            f"{tone_greeting}{past_memory_mention}"
            f"### ⚡ Advanced Conceptual Analysis & Edge Cases:\n"
            f"• **Theoretical Mechanics**: Regarding **{query}**, notice how higher-order boundary conditions and symmetry alter standard results.\n"
            f"• **Competitive Edge (JEE / NEET / Olympiad)**: Standard textbook derivations make simplifications; in entrance tests, watch for multi-concept coupling.\n"
            f"• **Challenge Problem**: What happens to this system if initial equilibrium conditions are perturbed dynamically? Give it a thought and share your logic!"
        )

    return explanation

@router.post("/message", response_model=ChatMessageResponse)
def send_chat_message(
    payload: ChatMessageRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Processes a student's question with personalized AI mentoring:
    - Injects category-specific persona
    - Retrieves memory from ChromaDB
    - Grounds with Pinecone vector DB
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

    # 2. Query Pinecone if career or syllabus related
    rag_context = []
    if any(k in query.lower() for k in ["career", "exam", "college", "syllabus", "stream"]):
        rag_context = rag_service.query_namespace(query, namespace="careers", top_k=3)

    # 3. Generate response using category tone
    response_text = generate_mentor_response(
        query=query,
        subject=payload.subject or "General",
        user=current_user,
        past_interactions=past_context,
        rag_context=rag_context
    )

    # 4. Save to ChromaDB Journey memory
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
        context_used=context_used_titles
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

# Compatibility routes for Flutter Voice / Text Chat client (/api/chat, /api/reset)
@router.post("/voice-chat")
def voice_chat_compat(
    payload: Dict[str, Any],
    current_user: Optional[User] = Depends(get_current_user_optional)
):
    query = payload.get("message", "").strip()
    if not query:
        raise HTTPException(status_code=400, detail="Message is empty")

    user = current_user or User(id="guest_student", name="Student", student_class=10, performance_category="average")
    past_context = chroma_journey_service.retrieve_past_context(user.id, query, n_results=2)
    rag_context = rag_service.query_namespace(query, namespace="careers", top_k=2) if "career" in query.lower() else []
    
    reply = generate_mentor_response(query, "General", user, past_context, rag_context)
    chroma_journey_service.log_interaction(user.id, query, reply, "General", user.performance_category or "average")

    return {
        "reply": reply,
        "question": query,
        "audio_base64": None,
        "tts_provider": "flutter_tts",
        "category": user.performance_category or "average"
    }

