# AI Mentor (Buddy) Services

This package contains the AI and retrieval components for the Learn Buddy platform.

## Modules

- **`rag_service.py` (Implemented)**:
  - Vector search service powered by **Pinecone** and **Sentence-Transformers** (`all-mpnet-base-v2`).
  - Supports query retrieval across multiple namespaces: `careers`, `colleges`, `syllabus`, `faqs`, and `conversations`.
  - Configurable via `PINECONE_API_KEY` and `PINECONE_INDEX_NAME` in `.env`.

- **`langgraph_agent.py` (Planned)**:
  - Conversational LangGraph workflow for Buddy.
  - Multi-node graph:
    1. **Proactive Check-In Node**: Reads student profile, streak, last-studied chapters, and weak areas to generate timely study nudges.
    2. **Reactive Q&A Node**: Contextual RAG question answering combining syllabus retrieval with conversational history.

- **`prompts.py` (Planned)**:
  - Tone-specific system prompts dynamically selected based on student preference (`User.buddy_tone`: *friendly*, *strict*, *motivational*).
