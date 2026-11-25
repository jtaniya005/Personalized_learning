from fastapi import APIRouter, File, UploadFile, HTTPException, Depends, status
from sqlalchemy.orm import Session
from typing import Dict, Any, List
import difflib

from app.services.ocr_service import extract_marksheet_data, KNOWN_SUBJECTS
from app.dependencies.auth_deps import get_current_user
from app.db.database import get_db
from app.models.user import User
from app.schemas.user import MarksheetSaveRequest, UserOut
from app.services.ai.categorization_service import (
    analyze_student_marks,
    generate_study_plan,
    get_career_recommendations,
    build_category_system_prompt
)

router = APIRouter(prefix="/students", tags=["Students"])

def get_expected_subjects(student_class: int) -> list[str]:
    return KNOWN_SUBJECTS

@router.post("/me/marksheet/extract")
async def extract_marksheet(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Extracts marksheet data with validation:
    - Validates that document is a 10th/12th (or respective previous class) marksheet.
    - Rejects if for an invalid class (e.g. Class 6, 7, 8) or if not an academic marksheet.
    - Extracts subjects, marks, percentage, and detected student name.
    """
    print(f"Extracting marksheet: {file.filename}, type: {file.content_type}")
    contents = await file.read()
    if not contents or len(contents) < 100:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The uploaded file is empty or corrupted."
        )

    try:
        result = extract_marksheet_data(contents, file.filename, file.content_type)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Could not parse marksheet: {str(e)}"
        )

    detected_class = result.get("detected_class")
    marks = result.get("marks", [])

    # Validation: Must contain at least 1 recognizable subject or percentage
    if not marks and result.get("previous_class_percentage") is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid Document: No academic subjects or marks could be detected. Please ensure this is a clear marksheet."
        )

    # Validation: Marksheet must be 10th or 12th (or previous class 9/10/11)
    # If a class was detected and it is below 9 (e.g. Class 6, 7, 8), REJECT immediately!
    if detected_class is not None and detected_class < 9:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid Marksheet Rejected: Detected Class {detected_class}. Learn Buddy only supports Class 10th & 12th students. Please upload a valid 10th or 12th marksheet."
        )

    warnings = []

    # Name similarity check
    detected_name = result.get("detected_name")
    if detected_name and current_user.name and current_user.name.strip().lower() != "student":
        similarity = difflib.SequenceMatcher(
            None, detected_name.lower(), current_user.name.lower()
        ).ratio()
        if similarity < 0.5:
            warnings.append(
                f"Marksheet has name '{detected_name}', but your profile is '{current_user.name}'. Please verify this is your marksheet."
            )

    # Class compatibility check
    if detected_class is not None:
        expected_prev = 9 if current_user.student_class == 10 else 11
        valid_classes = [9, 10] if current_user.student_class == 10 else [10, 11, 12]
        if detected_class not in valid_classes:
            warnings.append(
                f"Marksheet indicates Class {detected_class}, but for Class {current_user.student_class} we expect previous Class {expected_prev} or 10th/12th."
            )

    result["warnings"] = warnings
    result["is_valid"] = True
    return result

@router.post("/me/marksheet/save")
def save_marksheet(
    payload: MarksheetSaveRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Saves confirmed/edited marksheet data, computes the 6-tier performance categorization,
    generates personalized study plan, and queries Pinecone for grounded career paths.
    """
    raw_marks = [m.dict() for m in payload.marks]
    if not raw_marks:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please provide at least one subject with marks."
        )

    # Run 6-Tier Categorization Engine
    analysis = analyze_student_marks(raw_marks, payload.percentage)

    # Generate Personalized Study Plan
    study_plan = generate_study_plan(
        student_name=current_user.name,
        student_class=current_user.student_class,
        stream=current_user.stream or "",
        analysis=analysis
    )

    # Fetch Grounded Career Recommendations from Pinecone
    career_recs = get_career_recommendations(
        student_class=current_user.student_class,
        stream=current_user.stream or "",
        analysis=analysis
    )

    # Persist in DB
    current_user.marksheet_data = {
        "percentage": analysis["overall_percentage"],
        "marks": analysis["subject_details"],
        "detected_class": payload.detected_class,
        "detected_name": payload.detected_name
    }
    current_user.performance_category = analysis["overall_category"]["id"]
    current_user.weak_subjects = analysis["weak_subjects"]
    current_user.strong_subjects = analysis["strong_subjects"]
    current_user.study_plan = study_plan
    current_user.career_recommendations = career_recs

    db.commit()
    db.refresh(current_user)

    return {
        "status": "success",
        "category": analysis["overall_category"],
        "subject_details": analysis["subject_details"],
        "weak_subjects": analysis["weak_subjects"],
        "strong_subjects": analysis["strong_subjects"],
        "study_plan": study_plan,
        "career_recommendations": career_recs,
        "user": UserOut.from_orm(current_user)
    }

@router.get("/me/study-plan")
def get_student_study_plan(current_user: User = Depends(get_current_user)):
    """Retrieve the student's personalized study plan and career recommendations."""
    return {
        "category": current_user.performance_category or "average",
        "weak_subjects": current_user.weak_subjects or [],
        "strong_subjects": current_user.strong_subjects or [],
        "study_plan": current_user.study_plan or {},
        "career_recommendations": current_user.career_recommendations or []
    }
