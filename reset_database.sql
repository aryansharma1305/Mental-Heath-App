
-- Step 1: Drop existing tables (in correct order due to foreign keys)
DROP TABLE IF EXISTS question_responses CASCADE;
DROP TABLE IF EXISTS assessment_template_questions CASCADE;
DROP TABLE IF EXISTS assessment_templates CASCADE;
DROP TABLE IF EXISTS assessments CASCADE;
DROP TABLE IF EXISTS questions CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Step 2: Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Step 3: Create Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('patient', 'doctor', 'psychiatrist', 'admin')),
    department VARCHAR(100),
    password_hash VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster lookups
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Step 4: Create Questions Table
CREATE TABLE questions (
    id SERIAL PRIMARY KEY,
    question_text TEXT NOT NULL,
    question_type VARCHAR(20) NOT NULL CHECK (question_type IN ('yesNo', 'multipleChoice', 'textInput', 'scale', 'date')),
    options TEXT,
    required BOOLEAN DEFAULT TRUE,
    category VARCHAR(100),
    order_index INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_questions_category ON questions(category);
CREATE INDEX idx_questions_active ON questions(is_active);
CREATE INDEX idx_questions_order ON questions(order_index);

-- Step 5: Create Assessments Table
CREATE TABLE assessments (
    id SERIAL PRIMARY KEY,
    patient_id TEXT NOT NULL,
    patient_name VARCHAR(255) NOT NULL,
    patient_user_id UUID REFERENCES users(id),
    assessment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    assessor_name VARCHAR(255) NOT NULL,
    assessor_role VARCHAR(20) NOT NULL,
    assessor_user_id UUID REFERENCES users(id),
    decision_context TEXT NOT NULL,
    responses JSONB NOT NULL,
    overall_capacity VARCHAR(100),
    recommendations TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'completed')),
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    doctor_notes TEXT,
    template_id INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_assessments_patient_id ON assessments(patient_user_id);
CREATE INDEX idx_assessments_assessor_id ON assessments(assessor_user_id);
CREATE INDEX idx_assessments_status ON assessments(status);
CREATE INDEX idx_assessments_date ON assessments(assessment_date);

-- Step 6: Create Question Responses Table
CREATE TABLE question_responses (
    id SERIAL PRIMARY KEY,
    assessment_id INTEGER REFERENCES assessments(id) ON DELETE CASCADE,
    question_id INTEGER REFERENCES questions(id),
    answer TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_question_responses_assessment ON question_responses(assessment_id);
CREATE INDEX idx_question_responses_question ON question_responses(question_id);

-- Step 7: Create Assessment Templates Table
CREATE TABLE assessment_templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 8: Create Assessment Template Questions Junction Table
CREATE TABLE assessment_template_questions (
    id SERIAL PRIMARY KEY,
    template_id INTEGER REFERENCES assessment_templates(id) ON DELETE CASCADE,
    question_id INTEGER REFERENCES questions(id) ON DELETE CASCADE,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 9: Create trigger function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Step 10: Create triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_questions_updated_at BEFORE UPDATE ON questions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assessments_updated_at BEFORE UPDATE ON assessments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assessment_templates_updated_at BEFORE UPDATE ON assessment_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Step 11: Disable Row Level Security for easier testing
-- (You can enable it later for production)
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE questions DISABLE ROW LEVEL SECURITY;
ALTER TABLE assessments DISABLE ROW LEVEL SECURITY;
ALTER TABLE question_responses DISABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_templates DISABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_template_questions DISABLE ROW LEVEL SECURITY;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check that all tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Verify tables are empty
SELECT 'users' as table_name, COUNT(*) as row_count FROM users
UNION ALL
SELECT 'questions', COUNT(*) FROM questions
UNION ALL
SELECT 'assessments', COUNT(*) FROM assessments
UNION ALL
SELECT 'question_responses', COUNT(*) FROM question_responses
UNION ALL
SELECT 'assessment_templates', COUNT(*) FROM assessment_templates;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
-- If you see this, all tables were created successfully!
-- Now you can register doctors through the app.
-- The app will automatically save to this database.
-- ============================================
