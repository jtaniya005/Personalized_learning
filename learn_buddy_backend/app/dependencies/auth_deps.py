from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional
from sqlalchemy.orm import Session

try:
    from firebase_admin import auth
except ImportError:
    auth = None

from app.db.database import get_db
from app.models.user import User
from app.core.security import decode_access_token

security = HTTPBearer(auto_error=False)

def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = credentials.credentials

    # 1. Try custom JWT first
    jwt_payload = decode_access_token(token)
    if jwt_payload and "sub" in jwt_payload:
        user_id = jwt_payload["sub"]
        user = db.query(User).filter(User.id == user_id).first()
        if user and user.is_active:
            return user
        if user and not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User account is deactivated.",
                headers={"WWW-Authenticate": "Bearer"},
            )

    # 2. Try Firebase ID token fallback
    if auth is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired access token.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    try:
        decoded_token = auth.verify_id_token(token)
        user_id = decoded_token.get("uid")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token claims: user id missing.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        email = decoded_token.get("email")
        phone = decoded_token.get("phone_number")
        name = decoded_token.get("name", "Student")

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            user = User(id=user_id, email=email, phone=phone, name=name)
            db.add(user)
            db.commit()
            db.refresh(user)
        else:
            changed = False
            if user.email != email and email:
                user.email = email
                changed = True
            if user.phone != phone and phone:
                user.phone = phone
                changed = True
            if changed:
                db.commit()
                db.refresh(user)

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Unauthorized access.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        return user
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Could not validate credentials: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )

def get_current_user_optional(
    request: Request,
    db: Session = Depends(get_db)
) -> Optional[User]:
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
    token = auth_header.split(" ")[1]

    # Try JWT
    jwt_payload = decode_access_token(token)
    if jwt_payload and "sub" in jwt_payload:
        return db.query(User).filter(User.id == jwt_payload["sub"]).first()

    # Try Firebase
    try:
        decoded_token = auth.verify_id_token(token)
        user_id = decoded_token.get("uid")
        if not user_id:
            return None
        return db.query(User).filter(User.id == user_id).first()
    except Exception:
        return None
