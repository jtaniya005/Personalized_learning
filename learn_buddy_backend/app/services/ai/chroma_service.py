import os
import uuid
from datetime import datetime
from typing import List, Dict, Any, Optional
import chromadb
from app.core.config import settings

class ChromaJourneyService:
    _instance = None

    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super(ChromaJourneyService, cls).__new__(cls, *args, **kwargs)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if self._initialized:
            return

        persist_dir = settings.CHROMA_PERSIST_DIR or "./chroma_data"
        os.makedirs(persist_dir, exist_ok=True)
        print(f"ChromaJourneyService: Initializing ChromaDB at {persist_dir}...")
        self.client = chromadb.PersistentClient(path=persist_dir)
        self.collection = self.client.get_or_create_collection(
            name="student_learning_journey",
            metadata={"description": "Stores student chats, learning milestones, and doubt history"}
        )
        self._initialized = True
        print(f"ChromaJourneyService: Initialized successfully with {self.collection.count()} records.")

    def log_interaction(
        self,
        user_id: str,
        query: str,
        response: str,
        subject: Optional[str] = None,
        category: Optional[str] = None
    ) -> str:
        """Stores a chat exchange in the student's journey memory."""
        doc_id = f"{user_id}_{int(datetime.utcnow().timestamp() * 1000)}_{uuid.uuid4().hex[:6]}"
        content = f"Student: {query}\nMentor: {response}"
        metadata = {
            "user_id": str(user_id),
            "subject": str(subject or "General"),
            "category": str(category or "General"),
            "timestamp": datetime.utcnow().isoformat(),
            "query": query[:500],
            "response": response[:1000]
        }

        self.collection.add(
            documents=[content],
            metadatas=[metadata],
            ids=[doc_id]
        )
        return doc_id

    def retrieve_past_context(
        self,
        user_id: str,
        current_query: str,
        n_results: int = 3
    ) -> List[Dict[str, Any]]:
        """Retrieves relevant past doubts/interactions for this student."""
        try:
            total_records = self.collection.count()
            if total_records == 0:
                return []

            results = self.collection.query(
                query_texts=[current_query],
                n_results=min(n_results, total_records),
                where={"user_id": str(user_id)}
            )

            matches = []
            if results and results.get("documents") and results["documents"][0]:
                for idx, doc in enumerate(results["documents"][0]):
                    meta = results["metadatas"][0][idx] if results.get("metadatas") else {}
                    matches.append({
                        "id": results["ids"][0][idx],
                        "interaction": doc,
                        "metadata": meta
                    })
            return matches
        except Exception as e:
            print(f"ChromaJourneyService Error querying context: {e}")
            return []

    def get_recent_history(self, user_id: str, limit: int = 20) -> List[Dict[str, Any]]:
        """Retrieves the recent history of the student."""
        try:
            results = self.collection.get(
                where={"user_id": str(user_id)},
                limit=limit
            )
            chats = []
            if results and results.get("ids"):
                for idx, doc_id in enumerate(results["ids"]):
                    meta = results["metadatas"][idx] if results.get("metadatas") else {}
                    chats.append({
                        "id": doc_id,
                        "query": meta.get("query", ""),
                        "response": meta.get("response", ""),
                        "timestamp": meta.get("timestamp", ""),
                        "subject": meta.get("subject", "General")
                    })
            # Sort by timestamp
            chats.sort(key=lambda x: x.get("timestamp", ""), reverse=False)
            return chats
        except Exception as e:
            print(f"ChromaJourneyService Error retrieving history: {e}")
            return []

chroma_journey_service = ChromaJourneyService()
