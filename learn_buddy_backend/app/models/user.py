from sqlalchemy import Column, Integer, String, Boolean, DateTime, JSON, Text
from datetime import datetime
from app.db.database import Base

class User(Base):
    __tablename__ = "users"

    # Unique user ID (generated UUID or Firebase UID)
    id = Column(String, primary_key=True, index=True)

    # Core identity
    name = Column(String, nullable=False, default="Student")
    email = Column(String, unique=True, index=True, nullable=True)
    phone = Column(String, unique=True, index=True, nullable=True)
    password_hash = Column(String, nullable=True)

    # Student Academic Details
    student_class = Column(Integer, nullable=False, default=10)  # 10 or 12
    school = Column(String, nullable=True)
    board = Column(String, nullable=True)                        # CBSE, ICSE, State, etc.
    stream = Column(String, nullable=True)                       # Science (PCM/PCB), Commerce, Arts
    subjects = Column(JSON, nullable=False, default=list)        # Enrolled subjects list

    # Profile & Preferences
    avatar_index = Column(Integer, nullable=False, default=0)
    profile_photo = Column(Text, nullable=True)                  # Avatar or base64/URL
    daily_goal_minutes = Column(Integer, nullable=False, default=30)
    
    # Marksheet Analysis & Performance Categorization
    marksheet_data = Column(JSON, nullable=False, default=dict)  # Extracted & confirmed marks
    performance_category = Column(String, nullable=True)        # top, strong, moderate, average, struggling, weak
    weak_subjects = Column(JSON, nullable=False, default=list)   # Subjects needing special attention
    strong_subjects = Column(JSON, nullable=False, default=list) # Subjects with high scores
    
    # AI Generated Study Plan & Career Guidance
    study_plan = Column(JSON, nullable=False, default=dict)
    career_recommendations = Column(JSON, nullable=False, default=list)

    # Settings screen
    dark_mode = Column(Boolean, nullable=False, default=False)
    language = Column(String, nullable=False, default="en")  # 'en' | 'hi'
    buddy_tone = Column(String, nullable=False, default="friendly")  # friendly | strict | motivational
    daily_reminder_on = Column(Boolean, nullable=False, default=True)
    reminder_time = Column(String, nullable=False, default="19:00")
    streak_alert_on = Column(Boolean, nullable=False, default=True)

    # Gamification & Progress
    streak_days = Column(Integer, nullable=False, default=0)

    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
