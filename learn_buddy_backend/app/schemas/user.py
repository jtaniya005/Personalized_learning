from pydantic import BaseModel, EmailStr
from typing import List, Optional, Dict, Any
from datetime import datetime

class UserRegister(BaseModel):
    name: str
    email: EmailStr
    password: str
    student_class: int = 10
    school: Optional[str] = None
    board: Optional[str] = None
    stream: Optional[str] = None
    subjects: Optional[List[str]] = []

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserDetailsUpdate(BaseModel):
    name: Optional[str] = None
    student_class: Optional[int] = None
    school: Optional[str] = None
    board: Optional[str] = None
    stream: Optional[str] = None
    subjects: Optional[List[str]] = None
    avatar_index: Optional[int] = None
    profile_photo: Optional[str] = None
    daily_goal_minutes: Optional[int] = None

class SubjectMark(BaseModel):
    subject: str
    marks_obtained: float
    total_marks: float = 100.0

class MarksheetSaveRequest(BaseModel):
    marks: List[SubjectMark]
    percentage: Optional[float] = None
    detected_class: Optional[int] = None
    detected_name: Optional[str] = None

class UserOut(BaseModel):
    id: str
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    student_class: int
    school: Optional[str] = None
    board: Optional[str] = None
    stream: Optional[str] = None
    subjects: List[str] = []
    avatar_index: int = 0
    profile_photo: Optional[str] = None
    daily_goal_minutes: int = 30
    streak_days: int = 0
    
    # Categorization & AI data
    performance_category: Optional[str] = None
    weak_subjects: List[str] = []
    strong_subjects: List[str] = []
    marksheet_data: Optional[Dict[str, Any]] = {}
    study_plan: Optional[Dict[str, Any]] = {}
    career_recommendations: Optional[List[Dict[str, Any]]] = []

    # Settings
    dark_mode: bool = False
    language: str = "en"
    buddy_tone: str = "friendly"

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut

class UserProfileUpdate(BaseModel):
    name: Optional[str] = None
    avatar_index: Optional[int] = None
    profile_photo: Optional[str] = None
    student_class: Optional[int] = None
    school: Optional[str] = None
    board: Optional[str] = None
    stream: Optional[str] = None
    subjects: Optional[List[str]] = None
    weak_subjects: Optional[List[str]] = None
    daily_goal_minutes: Optional[int] = None

class UserSettingsUpdate(BaseModel):
    dark_mode: Optional[bool] = None
    language: Optional[str] = None
    buddy_tone: Optional[str] = None
    daily_goal_minutes: Optional[int] = None
    daily_reminder_on: Optional[bool] = None
    reminder_time: Optional[str] = None
    streak_alert_on: Optional[bool] = None
