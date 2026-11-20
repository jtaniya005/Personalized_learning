# Learn Buddy — Backend API

FastAPI backend for **Learn Buddy**, providing student authentication token verification, profile management, automated marksheet OCR processing, Pinecone vector RAG search, and educational progression tracking.

Built with Python 3.10+, FastAPI, SQLAlchemy, Supabase Postgres (with local SQLite fallback), Firebase Admin SDK, Tesseract OCR, and Pinecone.

---

## 🚀 Key Capabilities

- **Firebase Authentication & Session Management**: Validates Firebase ID tokens on incoming requests. Automatically provisions or synchronizes student profile records in PostgreSQL on first login.
- **Resilient Dual-Database Architecture**: Primary connection to **Supabase Postgres**; if the cloud database is paused or unreachable, it falls back seamlessly to a local **SQLite** (`sql_app.db`) file for uninterrupted offline development.
- **Marksheet OCR Processing**: Extracts student names, classes, subject breakdown, obtained marks, total marks, and percentages from PDF and image marksheets using Tesseract OCR, OpenCV, and PyMuPDF. Cross-checks results against the student's existing profile to flag identity discrepancies.
- **RAG Vector Search (Pinecone)**: Embeds queries using `SentenceTransformer` (`all-mpnet-base-v2`) and searches relevant Pinecone namespaces (`careers`, `colleges`, `syllabus`, `faqs`, `conversations`).
- **RESTful Architecture**: Clean modular routers (`app/api/`), Pydantic validation, middleware logging, and automated OpenAPI documentation (`/docs`).

---

## 📊 Endpoint Status

| Module | Route Prefix | Status | Description |
|---|---|:---:|---|
| **Health** | `GET /health`, `GET /api/health` | **Active** | Server heartbeat and status verification |
| **Authentication** | `POST /api/v1/auth/*` | **Active** | Token verification via Firebase Admin SDK |
| **User Profile & Settings** | `GET/PUT /api/v1/user/profile`, `PUT /api/v1/user/settings`, `DELETE /api/v1/user/account` | **Active** | Profile, class, weak subjects, study goals, UI preferences |
| **Marksheet OCR** | `POST /api/v1/students/me/marksheet/extract`, `POST /api/v1/students/me/marksheet/save` | **Active** | OCR parsing of uploaded grade cards & validation |
| **Study Material** | `/api/v1/subjects`, `/api/v1/chapters/*` | *Stub (501)* | Subject chapters, topics, curriculum content |
| **Progress & Analytics** | `/api/v1/progress/*` | *Stub (501)* | Weekly study trends, session logs, weak areas |
| **Career Guidance** | `/api/v1/careers/*` | *Stub (501)* | Roadmaps, skills, entrance exams, career quiz |
| **Notifications** | `/api/v1/notifications/*` | *Stub (501)* | Push notification device registration & preferences |
| **AI Mentor (Buddy)** | `/api/v1/chat/*` | *In Progress* | Pinecone RAG implemented; conversational agent graph pending |

---

## 🛠 System Dependencies

### 1. Tesseract OCR Engine
The marksheet extraction engine requires the Tesseract binary:
- **Windows**: Install via `winget install UB-Mannheim.TesseractOCR` or download the installer from [UB-Mannheim](https://github.com/UB-Mannheim/tesseract/wiki). Default lookup is `C:\Program Files\Tesseract-OCR\tesseract.exe`.
- **Ubuntu/Debian**:
  ```bash
  sudo apt-get update && sudo apt-get install -y tesseract-ocr
  ```
- **macOS**:
  ```bash
  brew install tesseract
  ```

---

## ⚙️ Environment Configuration

Create a `.env` file in the `learn_buddy_backend` root directory:

```ini
# Application
PROJECT_NAME="Learn Buddy API"
API_V1_STR="/api/v1"

# Database (Supabase PostgreSQL)
DATABASE_URL="postgresql://postgres.[PROJECT_REF]:[PASSWORD]@aws-0-ap-south-1.pooler.supabase.com:6543/postgres"

# Supabase Storage (Optional for file & avatar hosting)
SUPABASE_URL="https://[PROJECT_REF].supabase.co"
SUPABASE_KEY="your-supabase-service-role-key"
SUPABASE_BUCKET="avatars"

# Firebase Admin SDK (Path to service account JSON)
FIREBASE_CREDENTIALS_PATH="./firebase-service-account.json"

# Pinecone Vector DB (RAG Service)
PINECONE_API_KEY="your-pinecone-api-key"
PINECONE_INDEX_NAME="learn-buddy"

# OCR Configuration (Optional override)
# TESSERACT_CMD="C:\\Program Files\\Tesseract-OCR\\tesseract.exe"
```

> **Note on Firebase**: Download your project's service account private key from **Firebase Console -> Project Settings -> Service Accounts**, rename it to `firebase-service-account.json`, and place it in the `learn_buddy_backend` folder.

---

## 📦 Installation & Setup

```bash
# 1. Navigate to backend directory
cd learn_buddy_backend

# 2. Set up virtual environment
python -m venv venv

# Windows
.\venv\Scripts\activate
# Linux / macOS
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Verify Database connectivity
python check_db.py

# 5. Run ad-hoc schema migration (if altering existing tables)
python migrate_db.py

# 6. Start the API server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Once running, access:
- **Swagger Documentation**: `http://localhost:8000/docs`
- **ReDoc Documentation**: `http://localhost:8000/redoc`

---

## 📂 Project Architecture

```
learn_buddy_backend/
├── app/
│   ├── api/
│   │   ├── auth.py              # Firebase authentication hooks
│   │   ├── users.py             # Profile and user settings endpoints
│   │   ├── students.py          # Marksheet upload and OCR processing
│   │   └── _not_yet_built.py    # 501 stubs exposing full API surface in /docs
│   ├── constants/
│   │   └── app_constants.py     # Class definitions, tone lists, validation limits
│   ├── core/
│   │   └── config.py            # Pydantic/Environment configuration
│   ├── db/
│   │   └── database.py          # SQLAlchemy engine with SQLite auto-fallback
│   ├── dependencies/
│   │   └── auth_deps.py         # Bearer token decoding & user retrieval
│   ├── middleware/
│   │   ├── logging.py           # Request path, latency, and status logger
│   │   └── error_handler.py     # Global exception-to-JSON formatters
│   ├── models/
│   │   └── user.py              # User SQLAlchemy model
│   ├── schemas/
│   │   └── user.py              # Pydantic schemas (UserOut, UserProfileUpdate)
│   └── services/
│       ├── ocr_service.py       # Tesseract OCR & PyMuPDF marksheet parser
│       ├── supabase_storage.py  # Supabase cloud storage wrapper
│       └── ai/
│           ├── rag_service.py   # Pinecone RAG index search
│           └── README.md        # AI services roadmap
├── check_db.py                  # Database connection verification tool
├── migrate_db.py                # Safe DDL migration tool
├── seed_data.py                 # Local test data seeder
└── requirements.txt             # Project dependencies
```

---

## 🧠 Marksheet OCR Workflow

The endpoint `POST /api/v1/students/me/marksheet/extract` performs:
1. **File Parsing**: Converts incoming PDF pages to images using PyMuPDF (`fitz`), or reads direct image formats (`.jpg`, `.png`).
2. **Image Preprocessing**: Converts to grayscale, applies bilateral filtering, and uses adaptive thresholding for optimal character contrast.
3. **OCR Extraction**: Runs Tesseract with layout analysis.
4. **Data Normalization**:
   - Parses student name, previous class (e.g. Class 9 for a Class 10 student), and percentage.
   - Extracts subject names against `KNOWN_SUBJECTS` with fuzzy matching (`difflib`).
   - Normalizes marks (obtained vs total).
5. **Cross-Validation**: Compares extracted student name and class against the logged-in student's profile, generating warnings if discrepancies are found.
