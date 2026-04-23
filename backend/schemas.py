from pydantic import BaseModel, EmailStr, ConfigDict
from uuid import UUID
from typing import List, Optional
from datetime import datetime

class UserBase(BaseModel):
    name: str
    email: EmailStr

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(UserBase):
    id: UUID
    
    model_config = ConfigDict(from_attributes=True)

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class QuestionResponse(BaseModel):
    id: UUID
    content: str
    order_num: int
    
    model_config = ConfigDict(from_attributes=True)

class AnswerBase(BaseModel):
    user_answer: str

class AnswerCreate(AnswerBase):
    question_id: UUID

class AnswerResponse(AnswerBase):
    ai_feedback: Optional[str] = None
    ai_score: Optional[int] = None
    
    model_config = ConfigDict(from_attributes=True)

class QuestionWithAnswerResponse(QuestionResponse):
    answer: Optional[AnswerResponse] = None

class SessionBase(BaseModel):
    role: str
    difficulty: str

class SessionCreate(SessionBase):
    pass

class SessionResponse(SessionBase):
    id: UUID
    overall_score: Optional[int] = None
    created_at: datetime
    questions: List[QuestionResponse] = []
    
    model_config = ConfigDict(from_attributes=True)

class SessionResultsResponse(SessionBase):
    session_id: UUID
    overall_score: Optional[int] = None
    created_at: datetime
    questions: List[QuestionWithAnswerResponse] = []
    
    model_config = ConfigDict(from_attributes=True)
