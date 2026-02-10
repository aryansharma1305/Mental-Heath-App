-- ============================================
-- MENTAL CAPACITY ASSESSMENT - SUPABASE SCHEMA
-- ============================================
-- Run this in Supabase SQL Editor
-- This will DELETE all existing tables and create fresh ones
-- ============================================

-- ==========================================
-- STEP 1: DROP ALL EXISTING TABLES
-- ==========================================
-- Drop in reverse order of dependencies

DROP TABLE IF EXISTS question_responses CASCADE;
DROP TABLE IF EXISTS assessment_template_questions CASCADE;
DROP TABLE IF EXISTS assessment_templates CASCADE;
DROP TABLE IF EXISTS assessments CASCADE;
DROP TABLE IF EXISTS questions CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ==========================================
-- STEP 2: CREATE TABLES
-- ==========================================

-- 1. USERS TABLE
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'doctor', 'nurse', 'staff', 'patient')),
    department TEXT,
    password_hash TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. QUESTIONS TABLE (DSM-5 questions)
CREATE TABLE questions (
    id SERIAL PRIMARY KEY,
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL CHECK (question_type IN ('single_choice', 'multiple_choice', 'text', 'scale')),
    options TEXT, -- Pipe-separated options (e.g., "Option1|||Option2|||Option3")
    required BOOLEAN DEFAULT true,
    category TEXT,
    order_index INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. ASSESSMENTS TABLE
CREATE TABLE assessments (
    id SERIAL PRIMARY KEY,
    patient_id TEXT NOT NULL,
    patient_name TEXT NOT NULL,
    patient_user_id UUID REFERENCES users(id),
    assessment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assessor_name TEXT NOT NULL,
    assessor_role TEXT NOT NULL,
    assessor_user_id UUID REFERENCES users(id),
    decision_context TEXT NOT NULL,
    responses JSONB NOT NULL DEFAULT '{}',
    overall_capacity TEXT NOT NULL,
    recommendations TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'completed', 'archived')),
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMPTZ,
    doctor_notes TEXT,
    template_id INTEGER,
    is_synced BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ASSESSMENT TEMPLATES TABLE
CREATE TABLE assessment_templates (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. ASSESSMENT TEMPLATE QUESTIONS (Junction table)
CREATE TABLE assessment_template_questions (
    id SERIAL PRIMARY KEY,
    template_id INTEGER NOT NULL REFERENCES assessment_templates(id) ON DELETE CASCADE,
    question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(template_id, question_id)
);

-- 6. QUESTION RESPONSES TABLE
CREATE TABLE question_responses (
    id SERIAL PRIMARY KEY,
    template_id INTEGER REFERENCES assessment_templates(id),
    question_id INTEGER NOT NULL REFERENCES questions(id),
    patient_user_id UUID REFERENCES users(id),
    assessment_id INTEGER REFERENCES assessments(id) ON DELETE CASCADE,
    answer TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- STEP 3: CREATE INDEXES FOR PERFORMANCE
-- ==========================================

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

CREATE INDEX idx_assessments_patient_id ON assessments(patient_id);
CREATE INDEX idx_assessments_patient_user_id ON assessments(patient_user_id);
CREATE INDEX idx_assessments_assessor_user_id ON assessments(assessor_user_id);
CREATE INDEX idx_assessments_status ON assessments(status);
CREATE INDEX idx_assessments_date ON assessments(assessment_date DESC);

CREATE INDEX idx_questions_category ON questions(category);
CREATE INDEX idx_questions_active ON questions(is_active);
CREATE INDEX idx_questions_order ON questions(order_index);

CREATE INDEX idx_question_responses_assessment ON question_responses(assessment_id);
CREATE INDEX idx_question_responses_patient ON question_responses(patient_user_id);

-- ==========================================
-- STEP 4: ENABLE ROW LEVEL SECURITY (RLS)
-- ==========================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_template_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_responses ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- STEP 5: CREATE RLS POLICIES
-- ==========================================

-- For development/testing: Allow all operations with anon key
-- In production, replace these with stricter policies

-- USERS TABLE POLICIES
CREATE POLICY "Allow anonymous read access to users" ON users
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert to users" ON users
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update to users" ON users
    FOR UPDATE USING (true);

CREATE POLICY "Allow anonymous delete to users" ON users
    FOR DELETE USING (true);

-- QUESTIONS TABLE POLICIES
CREATE POLICY "Allow anonymous read access to questions" ON questions
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert to questions" ON questions
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update to questions" ON questions
    FOR UPDATE USING (true);

CREATE POLICY "Allow anonymous delete to questions" ON questions
    FOR DELETE USING (true);

-- ASSESSMENTS TABLE POLICIES
CREATE POLICY "Allow anonymous read access to assessments" ON assessments
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert to assessments" ON assessments
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update to assessments" ON assessments
    FOR UPDATE USING (true);

CREATE POLICY "Allow anonymous delete to assessments" ON assessments
    FOR DELETE USING (true);

-- ASSESSMENT TEMPLATES TABLE POLICIES
CREATE POLICY "Allow anonymous read access to templates" ON assessment_templates
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert to templates" ON assessment_templates
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update to templates" ON assessment_templates
    FOR UPDATE USING (true);

CREATE POLICY "Allow anonymous delete to templates" ON assessment_templates
    FOR DELETE USING (true);

-- ASSESSMENT TEMPLATE QUESTIONS TABLE POLICIES
CREATE POLICY "Allow anonymous read access to template_questions" ON assessment_template_questions
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert to template_questions" ON assessment_template_questions
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update to template_questions" ON assessment_template_questions
    FOR UPDATE USING (true);

CREATE POLICY "Allow anonymous delete to template_questions" ON assessment_template_questions
    FOR DELETE USING (true);

-- QUESTION RESPONSES TABLE POLICIES
CREATE POLICY "Allow anonymous read access to responses" ON question_responses
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert to responses" ON question_responses
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update to responses" ON question_responses
    FOR UPDATE USING (true);

CREATE POLICY "Allow anonymous delete to responses" ON question_responses
    FOR DELETE USING (true);

-- ==========================================
-- STEP 6: CREATE TRIGGER FOR updated_at
-- ==========================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_questions_updated_at
    BEFORE UPDATE ON questions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assessments_updated_at
    BEFORE UPDATE ON assessments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_templates_updated_at
    BEFORE UPDATE ON assessment_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- STEP 7: INSERT DEFAULT DSM-5 QUESTIONS
-- ==========================================

INSERT INTO questions (question_text, question_type, options, required, category, order_index, is_active) VALUES
('During the past TWO (2) WEEKS, have you felt little interest or pleasure in doing things?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'I. Depression', 1, true),
('During the past TWO (2) WEEKS, have you felt down, depressed, or hopeless?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'I. Depression', 2, true),
('During the past TWO (2) WEEKS, have you felt more irritated, grouchy, or angry than usual?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'II. Anger', 3, true),
('During the past TWO (2) WEEKS, have you felt nervous, anxious, frightened, worried, or on edge?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'IV. Anxiety', 4, true),
('During the past TWO (2) WEEKS, have you felt panic or been frightened?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'IV. Anxiety', 5, true),
('During the past TWO (2) WEEKS, have you avoided situations that make you anxious?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'IV. Anxiety', 6, true),
('During the past TWO (2) WEEKS, have you been bothered by unexplained aches and pains?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'V. Somatic Symptoms', 7, true),
('During the past TWO (2) WEEKS, have you felt that your illnesses are not being taken seriously enough?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'V. Somatic Symptoms', 8, true),
('During the past TWO (2) WEEKS, have you had thoughts of actually hurting yourself?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'VI. Suicidal Ideation', 9, true),
('During the past TWO (2) WEEKS, have you heard things other people couldn''t hear, such as voices?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'VII. Psychosis', 10, true),
('During the past TWO (2) WEEKS, have you felt that someone could hear your thoughts or you could hear what another person was thinking?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'VII. Psychosis', 11, true),
('During the past TWO (2) WEEKS, have you had problems with sleep that affected your sleep quality overall?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'VIII. Sleep Problems', 12, true),
('During the past TWO (2) WEEKS, have you had problems with memory (e.g., learning new or recalling information)?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'IX. Memory', 13, true),
('During the past TWO (2) WEEKS, have you had unpleasant thoughts, urges, or images that repeatedly enter your mind?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'X. Repetitive Thoughts', 14, true),
('During the past TWO (2) WEEKS, have you felt driven to perform certain behaviors or mental acts over and over again?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'X. Repetitive Thoughts', 15, true),
('During the past TWO (2) WEEKS, have you felt detached or distant from yourself, your body, your physical surroundings, or your memories?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'XI. Dissociation', 16, true),
('During the past TWO (2) WEEKS, have you not known who you really are or what you want out of life?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'XII. Personality Functioning', 17, true),
('During the past TWO (2) WEEKS, have you not felt close to other people or not enjoyed relationships with them?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'XII. Personality Functioning', 18, true),
('During the past TWO (2) WEEKS, have you drunk at least 4 drinks of any kind of alcohol in a single day?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'XIII. Substance Use', 19, true),
('During the past TWO (2) WEEKS, have you smoked any cigarettes, a cigar, or pipe or used snuff or chewing tobacco?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'XIII. Substance Use', 20, true),
('During the past TWO (2) WEEKS, have you used any drugs like marijuana, cocaine or crack, club drugs, hallucinogens, heroin, inhalants, or methamphetamine?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'XIII. Substance Use', 21, true),
('During the past TWO (2) WEEKS, have you used any prescription medications "just for the feeling", in larger amounts than prescribed, or not taken as prescribed?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'XIII. Substance Use', 22, true),
('During the past TWO (2) WEEKS, have you slept less than usual but still had a lot of energy?', 'single_choice', 'Not at all|||Slight|||Mild|||Moderate|||Severe', true, 'III. Mania', 23, true);

-- ==========================================
-- DONE! Your database is ready.
-- ==========================================
