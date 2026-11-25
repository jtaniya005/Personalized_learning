import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserRegister, UserLogin, UserDetailsUpdate, TokenResponse, UserOut
from app.core.security import hash_password, verify_password, create_access_token
from app.dependencies.auth_deps import get_current_user

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(payload: UserRegister, db: Session = Depends(get_db)):
    """Register a new student with unique ID, credentials, and academic profile."""
    # Check if email is already taken
    existing = db.query(User).filter(User.email == payload.email.lower()).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A student with this email address already exists. Please login instead."
        )

    # Generate unique user id
    user_id = f"usr_{uuid.uuid4().hex[:12]}"
    pwd_hash = hash_password(payload.password)

    new_user = User(
        id=user_id,
        name=payload.name,
        email=payload.email.lower(),
        password_hash=pwd_hash,
        student_class=payload.student_class,
        school=payload.school,
        board=payload.board,
        stream=payload.stream,
        subjects=payload.subjects or [],
        weak_subjects=[],
        strong_subjects=[],
        marksheet_data={},
        study_plan={},
        career_recommendations=[]
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # Create access token
    access_token = create_access_token(data={"sub": new_user.id, "email": new_user.email})

    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=UserOut.from_orm(new_user)
    )

@router.post("/login", response_model=TokenResponse)
def login(payload: UserLogin, db: Session = Depends(get_db)):
    """Login with registered email and password."""
    user = db.query(User).filter(User.email == payload.email.lower()).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password. Please check your credentials."
        )

    if not user.password_hash or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password. Please check your credentials."
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your account has been deactivated."
        )

    access_token = create_access_token(data={"sub": user.id, "email": user.email})
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=UserOut.from_orm(user)
    )

@router.put("/details", response_model=UserOut)
def update_student_details(
    payload: UserDetailsUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update student onboarding details: name, class, school, board, stream, subjects."""
    for field, value in payload.dict(exclude_unset=True).items():
        if value is not None:
            setattr(current_user, field, value)

    db.commit()
    db.refresh(current_user)
    return current_user

@router.get("/me", response_model=UserOut)
def get_current_user_profile(current_user: User = Depends(get_current_user)):
    """Get current authenticated user info."""
    return current_user
