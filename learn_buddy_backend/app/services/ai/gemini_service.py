import os
import io
import json
import base64
import asyncio
from typing import List, Dict, Any, Optional, AsyncGenerator

from google import genai
from google.genai import types
import edge_tts

from app.core.config import settings
from app.services.ai.rag_service import rag_service
from app.services.ai.categorization_service import CATEGORIES

# Service Account credentials path
SA_PATH = os.path.abspath(
    os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))),
        "project-534aac59-9682-41a2-b0d-0ccc0840f05c.json"
    )
)
if not os.path.exists(SA_PATH):
    # Try local directory
    SA_PATH = os.path.abspath("project-534aac59-9682-41a2-b0d-0ccc0840f05c.json")

GCP_PROJECT_ID = "freekey-2026"
GCP_LOCATION = "us-central1"
GEMINI_MODEL = "gemini-2.5-flash"

# Edge-TTS voice mapping
VOICE_MAP = {
    "hi": "hi-IN-SwaraNeural",
    "hi-male": "hi-IN-MadhurNeural",
    "en": "en-US-JennyNeural",
    "en-male": "en-US-GuyNeural",
    "hinglish": "hi-IN-SwaraNeural",
}

_global_client = None

def get_gemini_client() -> genai.Client:
    """Returns singleton Google GenAI client authenticated with Vertex AI Service Account."""
    global _global_client
    if _global_client is None:
        if os.path.exists(SA_PATH):
            os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = SA_PATH
            _global_client = genai.Client(
                vertexai=True,
                project=GCP_PROJECT_ID,
                location=GCP_LOCATION,
            )
            print(f"[GeminiService] Initialized Vertex AI Client with SA: {SA_PATH}")
        else:
            api_key = os.getenv("GEMINI_API_KEY", "")
            _global_client = genai.Client(api_key=api_key)
            print("[GeminiService] Initialized Gemini Client with API Key")
    return _global_client


class GeminiStudyMentorService:
    def __init__(self):
        self.model_name = GEMINI_MODEL

    async def generate_response(
        self,
        query: str,
        user_name: str = "Student",
        student_class: int = 10,
        stream: Optional[str] = None,
        performance_category: str = "average",
        weak_subjects: Optional[List[str]] = None,
        past_interactions: Optional[List[Dict[str, Any]]] = None,
        language: str = "hi",
    ) -> Dict[str, Any]:
        """
        Generates personalized AI mentor response using Gemini 2.5 Flash,
        grounded in Pinecone vector career data and past ChromaDB memory.
        """
        client = get_gemini_client()
        cat_info = CATEGORIES.get(performance_category, CATEGORIES["average"])
        q_lower = query.lower()

        # 1. Check for career query and retrieve Pinecone vector context
        pinecone_career_context = ""
        career_keywords = [
            "career", "future", "scope", "job", "college", "course", "stream",
            "kya banu", "options", "pcm", "pcb", "commerce", "arts", "engineering",
            "doctor", "medical", "btech", "ca", "upsc", "mba", "salary",
            "iit", "jee", "neet", "nda", "cuet", "entrance", "exam", "admission",
            "study plan", "padhai", "kaise karu", "kaise padhe", "guidance",
            "target", "score", "aim", "b.tech", "diploma", "pilot", "ias", "ips"
        ]
        is_career_query = any(k in q_lower for k in career_keywords)

        if is_career_query or "suggest" in q_lower:
            try:
                # Query Pinecone namespace 'careers'
                matches = rag_service.query_namespace(query, namespace="careers", top_k=4)
                if matches:
                    items = []
                    for m in matches:
                        meta = m.get("metadata", {})
                        title = meta.get("career_name") or meta.get("career_title") or meta.get("title", "")
                        stream_tag = meta.get("stream", "")
                        min_qual = meta.get("min_qualification", "")
                        exams = meta.get("entrance_exams", "")
                        overview = meta.get("text", meta.get("description", ""))
                        items.append(
                            f"★ Career: {title} (Stream: {stream_tag} | Min Qualification: {min_qual})\n"
                            f"  Entrance Exams: {exams}\n"
                            f"  Roadmap & Details:\n{overview[:600]}"
                        )
                    pinecone_career_context = "\n\n".join(items)
            except Exception as e:
                print(f"[warn] Pinecone career query failed: {e}")

        # 2. Build past interaction memory
        memory_summary = ""
        if past_interactions:
            past_texts = [p.get("metadata", {}).get("query", "") for p in past_interactions[:3]]
            memory_summary = f"Student's recent learning questions: {', '.join(filter(None, past_texts))}"

        # 3. Construct System Prompt tailored to student tier & syllabus (Voice_AI Indian Tone)
        system_prompt = f"""You are 'Buddy', a warm, friendly, encouraging, and intelligent AI Study & Career Mentor for Indian students (Class 10 & 12), exactly like an approachable senior bhaiya/mentor who truly cares about the student's success and confidence (inspired by Voice_AI & Spurly).

STUDENT PROFILE:
- Name: {user_name}
- Current Class: Class {student_class}
- Stream: {stream or 'General'}
- Performance Category: {cat_info['title']} ({cat_info.get('title_hi', '')}) - {cat_info.get('description', '')}
- Focus Priority / Weaker Subjects: {', '.join(weak_subjects or ['None flagged'])}
{f"- Previous Doubts & Learning Journey: {memory_summary}" if memory_summary else ""}

PINECONE VERIFIED CAREER & EXAM GROUNDING DATA (Strictly use this real data for career advice):
{pinecone_career_context if pinecone_career_context else "Use standard CBSE/ICSE curriculum and verified Indian higher education paths (IIT-JEE, NEET, CUET, CA Foundation, CLAT, NDA)."}

CORE TONE & COMMUNICATION RULES (Voice_AI Indian / Hinglish Tone):
1. Language & Tone:
   - Speak in natural, conversational Hinglish (a warm, relatable blend of Hindi and English like students talk in India).
   - Address {user_name} respectfully and warmly: e.g. "Arre waah {user_name}!", "Bahut badhiya question pucha hai tumne!", "Bilkul tension mat lo, chalo ise aasan shabdo me step-by-step samajhte hain."
2. Career & Exam Questions (IIT, JEE, NEET, NDA, Engineering, Medical, Commerce):
   - Immediately acknowledge their goal with high enthusiasm!
   - Ground your answer directly in the Pinecone data above: mention required subjects (PCM/PCB), entrance exams (JEE Main & Advanced, BITSAT, etc.), eligibility, and step-by-step roadmap from Class 10/11 to college.
   - Give realistic study tips: NCERT line-by-line concept clarity, daily practice, previous 10 years question papers (PYQs), and time management.
3. Academic Doubt Solving:
   - Break complex concepts into simple, intuitive real-world analogies.
   - Explain the 'why' before formulas.
   - Guide according to student tier ({cat_info['title']}): patient and simple for weaker areas, deep and competitive-ready for strong areas.
4. Structure:
   - Use clean bullet points, bold key terms, and easy-to-read paragraphs.
   - Always end with an encouraging word motivating {user_name}!
"""

        contents = [
            types.Content(
                role="user",
                parts=[types.Part.from_text(text=query)]
            )
        ]

        config = types.GenerateContentConfig(
            system_instruction=system_prompt,
            temperature=0.7,
            max_output_tokens=900,
        )

        response_text = ""
        try:
            res = client.models.generate_content(
                model=self.model_name,
                contents=contents,
                config=config,
            )
            response_text = res.text or "I'm here to help you study! What topic would you like to explore?"
        except Exception as e:
            print(f"[GeminiService] Error calling {self.model_name}: {e}")
            # Fallback
            response_text = f"Hello {user_name}! I am your AI Mentor Buddy. Let's study together! (Error connecting to model: {e})"

        # 4. Generate Speech with Edge-TTS
        audio_base64 = None
        try:
            audio_bytes = await self.generate_speech_bytes(response_text[:350], language=language)
            if audio_bytes:
                audio_base64 = base64.b64encode(audio_bytes).decode("utf-8")
        except Exception as e:
            print(f"[GeminiService] Edge-TTS error: {e}")

        return {
            "reply": response_text,
            "audio_base64": audio_base64,
            "tts_provider": "edge_tts",
            "model_used": self.model_name,
            "career_grounded": bool(pinecone_career_context),
        }

    async def generate_speech_bytes(self, text: str, language: str = "hi") -> bytes:
        """Converts text to MP3 audio bytes using Microsoft Edge Neural TTS."""
        # Clean text from markdown asterisks and hash symbols for clean speech
        clean_text = text.replace("*", "").replace("#", "").replace("`", "").replace("•", "").strip()
        voice = VOICE_MAP.get(language, "hi-IN-SwaraNeural")
        communicate = edge_tts.Communicate(clean_text, voice)
        stream = io.BytesIO()
        async for chunk in communicate.stream():
            if chunk["type"] == "audio":
                stream.write(chunk["data"])
        return stream.getvalue()

    async def stream_response_tokens(
        self,
        messages: List[Dict[str, str]],
        language: str = "hi",
    ) -> AsyncGenerator[str, None]:
        """Streams text chunks from Gemini 2.5 Flash."""
        client = get_gemini_client()

        contents = []
        for m in messages:
            role = "user" if m.get("role") == "user" else "model"
            contents.append(
                types.Content(
                    role=role,
                    parts=[types.Part.from_text(text=m.get("content", ""))]
                )
            )

        config = types.GenerateContentConfig(
            system_instruction="You are Buddy, a friendly AI Study & Career Mentor for Class 10 & 12 students in India. Respond in conversational Hindi / Hinglish with clear, helpful points.",
            temperature=0.7,
            max_output_tokens=800,
        )

        try:
            response = client.models.generate_content_stream(
                model=self.model_name,
                contents=contents,
                config=config,
            )
            for chunk in response:
                if chunk.text:
                    yield chunk.text
        except Exception as e:
            yield f"Error: {e}"


gemini_mentor_service = GeminiStudyMentorService()
