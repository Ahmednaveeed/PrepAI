# AI Mock Interviewer

A full-stack AI-powered mock interview platform where users can practice job interviews, get instant AI feedback on their answers, and track their progress over time.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js 14 (App Router), Tailwind CSS |
| Backend | FastAPI (Python 3.11) |
| Database | PostgreSQL 15 |
| AI | OpenAI GPT-4o API |
| Auth | JWT (python-jose) + bcrypt password hashing |
| Local Dev | Docker Compose |

---

## Project Structure

```
ai-mock-interviewer/
│
├── frontend/                        ← Next.js app
│   ├── Dockerfile
│   ├── package.json
│   ├── tailwind.config.js
│   ├── next.config.js
│   └── src/
│       ├── app/
│       │   ├── page.js              ← Landing page
│       │   ├── login/page.js        ← Login page
│       │   ├── signup/page.js       ← Signup page
│       │   ├── dashboard/page.js    ← User dashboard (past interviews + start new)
│       │   ├── interview/
│       │   │   └── [id]/page.js     ← Active interview screen
│       │   └── results/
│       │       └── [id]/page.js     ← Results + feedback screen
│       ├── components/
│       │   ├── Navbar.js
│       │   ├── InterviewCard.js     ← Past interview summary card
│       │   ├── QuestionCard.js      ← Single question + answer input
│       │   ├── FeedbackCard.js      ← AI feedback display
│       │   └── ScoreBadge.js        ← Animated score display
│       └── lib/
│           ├── api.js               ← All fetch calls to backend
│           └── auth.js              ← JWT storage and auth helpers
│
├── backend/                         ← FastAPI app
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── main.py                      ← App entry point, route registration
│   ├── database.py                  ← SQLAlchemy engine + session
│   ├── models.py                    ← ORM models (User, Session, Question, Answer)
│   ├── schemas.py                   ← Pydantic request/response schemas
│   ├── auth.py                      ← JWT creation, password hashing, auth dependency
│   ├── openai_service.py            ← OpenAI API calls (question gen + answer eval)
│   └── routers/
│       ├── auth_router.py           ← POST /auth/signup, POST /auth/login
│       ├── sessions_router.py       ← POST /sessions, GET /sessions/{id}, GET /sessions/{id}/results
│       └── answers_router.py        ← POST /answers
│
├── database/
│   └── init.sql                     ← Table creation SQL
│
├── docker-compose.yml               ← Local development orchestration
└── README.md
```

---

## Database Schema

```sql
-- Users table
CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(255) UNIQUE NOT NULL,
    hashed_password TEXT NOT NULL,
    created_at    TIMESTAMP DEFAULT NOW()
);

-- Interview sessions
CREATE TABLE sessions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID REFERENCES users(id) ON DELETE CASCADE,
    role          VARCHAR(100) NOT NULL,
    difficulty    VARCHAR(20) NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    overall_score INTEGER,
    created_at    TIMESTAMP DEFAULT NOW()
);

-- Questions per session (5 per interview)
CREATE TABLE questions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id    UUID REFERENCES sessions(id) ON DELETE CASCADE,
    content       TEXT NOT NULL,
    order_num     INTEGER NOT NULL
);

-- User answers + AI feedback
CREATE TABLE answers (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id   UUID REFERENCES questions(id) ON DELETE CASCADE,
    user_answer   TEXT NOT NULL,
    ai_feedback   TEXT,
    ai_score      INTEGER CHECK (ai_score BETWEEN 0 AND 10),
    created_at    TIMESTAMP DEFAULT NOW()
);
```

---

## API Endpoints

### Auth
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/auth/signup` | Register new user | No |
| POST | `/auth/login` | Login, returns JWT token | No |

### Sessions
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/sessions` | Start new interview, generates 5 questions via AI | Yes |
| GET | `/sessions/{id}` | Get session details + all questions | Yes |
| GET | `/sessions/{id}/results` | Get full results with answers + feedback | Yes |
| GET | `/sessions` | Get all past sessions for logged-in user | Yes |

### Answers
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/answers` | Submit answer for a question, returns AI feedback instantly | Yes |

### Health
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check (used by Kubernetes) |

---

## Request / Response Examples

### POST /auth/signup
**Request:**
```json
{
  "name": "Ahmed Naveed",
  "email": "ahmed@example.com",
  "password": "securepassword123"
}
```
**Response:**
```json
{
  "id": "uuid",
  "name": "Ahmed Naveed",
  "email": "ahmed@example.com"
}
```

### POST /auth/login
**Request:**
```json
{
  "email": "ahmed@example.com",
  "password": "securepassword123"
}
```
**Response:**
```json
{
  "access_token": "eyJ...",
  "token_type": "bearer"
}
```

### POST /sessions
**Request:**
```json
{
  "role": "Frontend Developer",
  "difficulty": "medium"
}
```
**Response:**
```json
{
  "session_id": "uuid",
  "role": "Frontend Developer",
  "difficulty": "medium",
  "questions": [
    { "id": "uuid", "content": "Explain the difference between...", "order_num": 1 },
    { "id": "uuid", "content": "What is React's virtual DOM?", "order_num": 2 }
  ]
}
```

### POST /answers
**Request:**
```json
{
  "question_id": "uuid",
  "user_answer": "The virtual DOM is a lightweight copy of..."
}
```
**Response:**
```json
{
  "answer_id": "uuid",
  "ai_feedback": "Good answer! You correctly identified the concept. To improve, mention reconciliation...",
  "ai_score": 8
}
```

### GET /sessions/{id}/results
**Response:**
```json
{
  "session_id": "uuid",
  "role": "Frontend Developer",
  "difficulty": "medium",
  "overall_score": 76,
  "created_at": "2026-04-23T10:00:00",
  "questions": [
    {
      "id": "uuid",
      "content": "What is React's virtual DOM?",
      "order_num": 1,
      "answer": {
        "user_answer": "The virtual DOM is...",
        "ai_feedback": "Good answer! You correctly...",
        "ai_score": 8
      }
    }
  ]
}
```

---

## OpenAI Prompts

### Question Generation (openai_service.py)
```
You are an expert technical interviewer. Generate exactly 5 {difficulty} level interview 
questions for a {role} position. 

Rules:
- Questions should be practical and realistic
- Mix conceptual and problem-solving questions  
- Each question should be answerable in 3-5 sentences
- Return ONLY a JSON array of 5 strings, no numbering, no extra text

Example output format:
["Question 1 here", "Question 2 here", "Question 3 here", "Question 4 here", "Question 5 here"]
```

### Answer Evaluation (openai_service.py)
```
You are an expert technical interviewer evaluating a candidate's answer.

Question: {question}
Candidate's Answer: {answer}

Evaluate the answer and respond with ONLY a JSON object in this exact format:
{
  "score": <integer 0-10>,
  "feedback": "<2-3 sentences: what was good, what was missing, how to improve>"
}

Scoring guide:
- 9-10: Excellent, comprehensive answer
- 7-8: Good answer with minor gaps  
- 5-6: Adequate but missing key concepts
- 3-4: Partial understanding shown
- 0-2: Incorrect or very incomplete
```

---

## Environment Variables

### Backend (.env)
```
DATABASE_URL=postgresql://postgres:password@db:5432/mockinterview
OPENAI_API_KEY=sk-your-key-here
SECRET_KEY=your-jwt-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
```

### Frontend (.env.local)
```
NEXT_PUBLIC_API_URL=http://localhost:8000
```

---

## Docker Compose (Local Development)

```yaml
version: '3.8'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mockinterview
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"

  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://postgres:password@db:5432/mockinterview
      OPENAI_API_KEY: ${OPENAI_API_KEY}
      SECRET_KEY: ${SECRET_KEY}
      ALGORITHM: HS256
      ACCESS_TOKEN_EXPIRE_MINUTES: 1440
    depends_on:
      - db

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:8000
    depends_on:
      - backend

volumes:
  postgres_data:
```

---

## UI Design Guidelines

### Color Palette — Warm & Lively
- **Primary background:** Warm off-white `#fdf8f3`
- **Accent / brand color:** Warm amber-orange `#f59e0b`
- **Secondary accent:** Deep teal `#0d9488`
- **Cards/surfaces:** Soft cream `#fef3e2`
- **Text primary:** Rich dark brown `#1c1917`
- **Text muted:** Warm gray `#78716c`
- **Success:** Emerald green `#10b981`
- **Error:** Warm red `#ef4444`

### Pages & Components

#### Landing Page (`/`)
- Full-screen hero with headline: **"Practice. Get Feedback. Get Hired."**
- Animated typewriter effect cycling through job roles
- Two CTA buttons: "Start Practicing" (primary) and "Login"
- Three feature cards below: Smart Questions / Instant Feedback / Track Progress
- Warm gradient background (amber to orange tones)

#### Dashboard (`/dashboard`)
- Greeting: "Welcome back, {name} 👋"
- **Start New Interview** card — prominent, with role selector dropdown and difficulty toggle (Easy / Medium / Hard)
- **Past Interviews** section — cards showing: role, date, overall score with colored badge (green ≥70, yellow 50–69, red <50)
- Empty state illustration when no interviews yet

#### Interview Screen (`/interview/[id]`)
- Progress bar at top showing "Question 3 of 5"
- Role and difficulty badge
- Question displayed in a large warm card
- Textarea for answer with character count
- "Submit Answer" button — shows loading spinner while AI evaluates
- After submission: AI feedback slides in below with score badge
- "Next Question" button appears after feedback

#### Results Screen (`/results/[id]`)
- Animated score reveal (count-up animation to final score)
- Overall score as a large circular progress ring
- Each question expanded with: question text, user's answer, AI feedback, score out of 10
- Color-coded score badges per question
- "Try Again" and "Back to Dashboard" buttons

### UX Interactions
- Smooth page transitions
- Textarea auto-expands as user types
- Score badges animate in on results page
- Toast notifications for errors (wrong password, API failure)
- Loading skeletons while fetching data
- Hover effects on all clickable cards

---

## Python Dependencies (requirements.txt)

```
fastapi==0.111.0
uvicorn==0.29.0
sqlalchemy==2.0.30
psycopg2-binary==2.9.9
pydantic==2.7.1
pydantic-settings==2.2.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.9
openai==1.30.1
python-dotenv==1.0.1
httpx==0.27.0
```

---

## Frontend Dependencies (package.json key packages)

```json
{
  "dependencies": {
    "next": "14.2.3",
    "react": "^18",
    "react-dom": "^18",
    "tailwindcss": "^3.4.1",
    "axios": "^1.6.8",
    "react-hot-toast": "^2.4.1",
    "framer-motion": "^11.1.7",
    "lucide-react": "^0.378.0"
  }
}
```

---

## Local Development Setup

```bash
# 1. Clone the repo
git clone https://github.com/yourusername/ai-mock-interviewer
cd ai-mock-interviewer

# 2. Add your OpenAI API key
echo "OPENAI_API_KEY=sk-your-key" > .env
echo "SECRET_KEY=your-random-secret" >> .env

# 3. Start everything
docker-compose up --build

# 4. Open in browser
# Frontend: http://localhost:3000
# Backend API docs: http://localhost:8000/docs
```

---

*README covers application layer only. Deployment documentation (Docker, Terraform, Ansible, Kubernetes, CI/CD) is maintained separately.*
