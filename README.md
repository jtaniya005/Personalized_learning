# Personalized Learning Ecosystem (Learn Buddy)

An AI-powered, personalized learning companion ecosystem designed for Class 10 and 12 students. The platform combines proactive AI mentoring, intelligent marksheet OCR analysis, vector-based RAG knowledge retrieval, interactive study modules, brain break mini-games, and a voice assistant interface.

---

## 🏛 Architecture Overview

```
                      ┌──────────────────────────────────────┐
                      │          Flutter Clients             │
                      ├──────────────────┬───────────────────┤
                      │   learn_buddy    │voice_assistant_app│
                      │ (Main Study App) │ (Dedicated Voice) │
                      └─────────┬────────┴─────────┬─────────┘
                                │                  │
                       Firebase │ Bearer Token     │ HTTP Multipart / REST
                         Auth   │ & REST API       │ (/api/ask, /api/chat)
                                ▼                  ▼
                      ┌──────────────────────────────────────┐
                      │         FastAPI Backend              │
                      │      (learn_buddy_backend)           │
                      └───────┬────────────┬───────────┬─────┘
                              │            │           │
           ┌──────────────────┴──┐  ┌──────┴──────┐  ┌─┴────────────────┐
           │   Supabase Postgres │  │  Tesseract  │  │ Pinecone Vector  │
           │  (SQLite Fallback)  │  │   OCR Engine│  │ DB (all-mpnet-v2)│
           └─────────────────────┘  └─────────────┘  └──────────────────┘
```

The repository is organized into three core sub-projects:

1. **[`learn_buddy_backend`](./learn_buddy_backend/README.md)**: High-performance Python FastAPI backend delivering user authentication verification, student profiling, OCR marksheet analysis, vector semantic search (Pinecone RAG), and learning analytics.
2. **[`learn_buddy`](./learn_buddy/README.md)**: Main student mobile application built with Flutter featuring the signature "Notebook & Marigold" design system, proactive AI mentor ("Buddy"), marksheet scanning, study planner, progress tracker, and brain-break games.
3. **[`voice_assistant_app`](./voice_assistant_app/README.md)**: Specialized Flutter voice assistant client equipped with real-time waveform visualization, push-to-talk audio streaming, TTS playback, and flexible server endpoint configuration.

---

## 📁 Repository Structure

```
Persionalised_learning/
├── README.md                      # Monorepo Master Documentation (this file)
│
├── learn_buddy_backend/           # FastAPI Backend Service
│   ├── app/
│   │   ├── api/                   # Route handlers (auth, users, students, stubs)
│   │   ├── core/                  # Configuration & settings (.env)
│   │   ├── db/                    # SQLAlchemy engine, session, & SQLite fallback
│   │   ├── dependencies/          # Firebase Auth token verification
│   │   ├── middleware/            # Request logging & unified error handling
│   │   ├── models/                # SQLAlchemy database models
│   │   ├── schemas/               # Pydantic request/response schemas
│   │   └── services/              # OCR (Tesseract), Pinecone RAG, Cloud Storage
│   ├── check_db.py                # Database connectivity verification script
│   ├── migrate_db.py              # Lightweight database schema migration helper
│   ├── requirements.txt           # Python dependencies
│   └── README.md                  # Backend Documentation
│
├── learn_buddy/                   # Primary Flutter Student Mobile App
│   ├── lib/
│   │   ├── models/                # Data structures & mock curriculum data
│   │   ├── screens/               # App screens (Home, Study, AI Chat, Progress, Games)
│   │   │   └── games/             # Brain Break mini-games (Math, Memory, Tic-Tac-Toe)
│   │   ├── services/              # AuthService, VoiceAssistantService
│   │   ├── state/                 # Dark mode & EN/HI language notifiers
│   │   ├── theme/                 # Notebook & Marigold theme configuration
│   │   └── widgets/               # NotebookCard, VoiceAssistantModal, custom controls
│   ├── pubspec.yaml               # Flutter dependencies & assets
│   └── README.md                  # Main App Documentation
│
└── voice_assistant_app/           # Dedicated Voice Assistant Flutter App
    ├── lib/
    │   ├── controllers/           # VoiceAssistantController state machine
    │   ├── models/                # Chat messages & API response models
    │   ├── screens/               # Main voice assistant screen
    │   ├── services/              # Audio recording, playback, API client, preferences
    │   ├── theme/                 # Dark Glassmorphism theme
    │   └── widgets/               # Animated mic button, waveform visualizer, settings dialog
    ├── pubspec.yaml               # Flutter dependencies
    └── README.md                  # Voice Assistant App Documentation
```

---

## ⚡ Quick Start Guide

### Prerequisites

- **Python**: 3.10+
- **Flutter SDK**: 3.19+ (Dart 3.3+)
- **System Dependencies**: [Tesseract OCR](https://github.com/tesseract-ocr/tesseract) (required for marksheet OCR extraction)
- **Accounts / Keys (Optional for local dev, required for full cloud services)**:
  - Supabase Postgres (SQLite automatically acts as fallback if not reachable)
  - Firebase Project (service account JSON for Firebase Auth)
  - Pinecone API Key (for semantic vector search)

---

### 1. Backend Setup (`learn_buddy_backend`)

```bash
cd learn_buddy_backend

# 1. Create and activate virtual environment
python -m venv venv
# On Windows:
.\venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# 2. Install Python dependencies
pip install -r requirements.txt

# 3. Configure environment variables (.env)
# Create a .env file based on the example in learn_buddy_backend/README.md

# 4. Verify database connection
python check_db.py

# 5. Start development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The interactive OpenAPI documentation will be accessible at:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`
- **Health Check**: `http://localhost:8000/health`

---

### 2. Main Mobile App Setup (`learn_buddy`)

```bash
cd ../learn_buddy

# 1. Get Flutter dependencies
flutter pub get

# 2. Run on connected device, emulator, or Chrome
flutter run
```

> **Note for Android Emulators**: If communicating with the local FastAPI backend on your development machine, Android emulators resolve `localhost` via `http://10.0.2.2:8000`. This is configured by default in `AuthService.dart`.

---

### 3. Voice Assistant App Setup (`voice_assistant_app`)

```bash
cd ../voice_assistant_app

# 1. Get Flutter dependencies
flutter pub get

# 2. Run the application
flutter run
```

Tap the gear icon on the top right to configure the backend server URL (e.g. `http://10.0.2.2:8000` on Android emulator or `http://localhost:8000` on desktop/web) and test connectivity.

---

## 🔑 Key Features Matrix

| Feature | `learn_buddy` | `voice_assistant_app` | `learn_buddy_backend` |
|---|:---:|:---:|:---:|
| **Firebase Auth & Token Verification** | ✅ | — | ✅ |
| **Student Profile & Settings Storage** | ✅ | — | ✅ |
| **Marksheet OCR Extraction (Tesseract)** | ✅ | — | ✅ |
| **Pinecone Vector RAG Retrieval** | Ready | — | ✅ |
| **Voice Assistant Modal / Screen** | ✅ | ✅ | Planned endpoints |
| **Real-time Audio Waveform Visualizer** | ✅ | ✅ | — |
| **Brain Break Mini-Games** | ✅ | — | — |
| **Notebook & Marigold Design System** | ✅ | — | — |
| **Dark Mode & Multilingual (EN / HI)** | ✅ | UI Dark Theme | ✅ |
| **SQLite Resilient DB Fallback** | — | — | ✅ |

---

## 🛠 Tech Stack

- **Backend**: Python, FastAPI, SQLAlchemy, Supabase Postgres, SQLite fallback, Firebase Admin SDK, Pydantic, Tesseract OCR, PyMuPDF, OpenCV, Pinecone, Sentence-Transformers (`all-mpnet-base-v2`).
- **Frontend**: Flutter, Dart, Google Fonts, AudioPlayers, Record, Flutter TTS, Permission Handler, Dotted Border, Shared Preferences.

---

## 📄 License & Attribution

Internal educational technology project designed for personalized learning for Class 10 & 12 students. All rights reserved.
