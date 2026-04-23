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
