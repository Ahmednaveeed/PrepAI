from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
import models
import schemas
from auth import get_current_user
from database import get_db
from openai_service import generate_questions

router = APIRouter(prefix="/sessions", tags=["sessions"])

@router.post("", response_model=schemas.SessionResponse)
def create_session(session: schemas.SessionCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # 1. Generate questions via AI
    try:
        questions_list = generate_questions(session.role, session.difficulty)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate questions: {str(e)}")

    if len(questions_list) != 5:
        raise HTTPException(status_code=500, detail="AI did not return exactly 5 questions")

    # 2. Save Session
    new_session = models.Session(
        user_id=current_user.id,
        role=session.role,
        difficulty=session.difficulty
    )
    db.add(new_session)
    db.commit()
    db.refresh(new_session)

    # 3. Save Questions
    db_questions = []
    for idx, q_text in enumerate(questions_list):
        new_question = models.Question(
            session_id=new_session.id,
            content=q_text,
            order_num=idx + 1
        )
        db.add(new_question)
        db_questions.append(new_question)
    
    db.commit()

    return schemas.SessionResponse(
        id=new_session.id,
        role=new_session.role,
        difficulty=new_session.difficulty,
        overall_score=new_session.overall_score,
        created_at=new_session.created_at,
        questions=[
            schemas.QuestionResponse(id=q.id, content=q.content, order_num=q.order_num)
            for q in db_questions
        ]
    )

@router.get("", response_model=List[schemas.SessionResponse])
def get_sessions(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    sessions = db.query(models.Session).filter(models.Session.user_id == current_user.id).all()
    return sessions

@router.get("/{id}", response_model=schemas.SessionResponse)
def get_session(id: UUID, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    session = db.query(models.Session).filter(models.Session.id == id, models.Session.user_id == current_user.id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    return session

@router.get("/{id}/results", response_model=schemas.SessionResultsResponse)
def get_session_results(id: UUID, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    session = db.query(models.Session).filter(models.Session.id == id, models.Session.user_id == current_user.id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    questions = db.query(models.Question).filter(models.Question.session_id == session.id).order_by(models.Question.order_num).all()
    
    response_q = []
    for q in questions:
        answer = None
        if q.answer:
            answer = schemas.AnswerResponse(
                user_answer=q.answer.user_answer,
                ai_feedback=q.answer.ai_feedback,
                ai_score=q.answer.ai_score
            )
        response_q.append(schemas.QuestionWithAnswerResponse(
            id=q.id,
            content=q.content,
            order_num=q.order_num,
            answer=answer
        ))
    
    return schemas.SessionResultsResponse(
        session_id=session.id,
        role=session.role,
        difficulty=session.difficulty,
        overall_score=session.overall_score,
        created_at=session.created_at,
        questions=response_q
    )
