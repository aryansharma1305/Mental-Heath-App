-- Mental Capacity Assessment App - Supabase Database Schema
-- Run this SQL in Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users Table
CREATE TABLE IF NOT EXISTS users (
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

-- Create index on username and email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Questions Table (for admin management)
CREATE TABLE IF NOT EXISTS questions (
    id SERIAL PRIMARY KEY,
    question_text TEXT NOT NULL,
    question_type VARCHAR(20) NOT NULL CHECK (question_type IN ('yesNo', 'multipleChoice', 'textInput', 'scale', 'date')),
    options TEXT, -- JSON string or pipe-separated values
    required BOOLEAN DEFAULT TRUE,
    category VARCHAR(100),
    order_index INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for questions
CREATE INDEX IF NOT EXISTS idx_questions_category ON questions(category);
CREATE INDEX IF NOT EXISTS idx_questions_active ON questions(is_active);
CREATE INDEX IF NOT EXISTS idx_questions_order ON questions(order_index);

-- Assessments Table
CREATE TABLE IF NOT EXISTS assessments (
    id SERIAL PRIMARY KEY,
    patient_id TEXT NOT NULL, -- Can be UUID or text ID
    patient_name VARCHAR(255) NOT NULL,
    patient_user_id UUID REFERENCES users(id),
    assessment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    assessor_name VARCHAR(255) NOT NULL,
    assessor_role VARCHAR(20) NOT NULL,
    assessor_user_id UUID REFERENCES users(id),
    decision_context TEXT NOT NULL,
    responses JSONB NOT NULL, -- Store all responses as JSON
    overall_capacity VARCHAR(100),
    recommendations TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'completed')),
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for assessments
CREATE INDEX IF NOT EXISTS idx_assessments_patient_id ON assessments(patient_user_id);
CREATE INDEX IF NOT EXISTS idx_assessments_assessor_id ON assessments(assessor_user_id);
CREATE INDEX IF NOT EXISTS idx_assessments_status ON assessments(status);
CREATE INDEX IF NOT EXISTS idx_assessments_date ON assessments(assessment_date);

-- Question Responses Table (Normalized - optional, for detailed tracking)
CREATE TABLE IF NOT EXISTS question_responses (
    id SERIAL PRIMARY KEY,
    assessment_id INTEGER REFERENCES assessments(id) ON DELETE CASCADE,
    question_id INTEGER REFERENCES questions(id),
    answer TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for question_responses
CREATE INDEX IF NOT EXISTS idx_question_responses_assessment ON question_responses(assessment_id);
CREATE INDEX IF NOT EXISTS idx_question_responses_question ON question_responses(question_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to automatically update updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_questions_updated_at BEFORE UPDATE ON questions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assessments_updated_at BEFORE UPDATE ON assessments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS) for better security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_responses ENABLE ROW LEVEL SECURITY;

-- RLS Policies (adjust based on your security requirements)
-- Allow users to read their own data
CREATE POLICY "Users can view own data" ON users
    FOR SELECT USING (auth.uid()::text = id::text);

-- Allow authenticated users to view active questions
CREATE POLICY "Authenticated users can view active questions" ON questions
    FOR SELECT USING (is_active = TRUE);

-- Allow users to view their own assessments
CREATE POLICY "Users can view own assessments" ON assessments
    FOR SELECT USING (
        auth.uid()::text = patient_user_id::text 
        OR auth.uid()::text = assessor_user_id::text
    );

-- Allow doctors/psychiatrists to view all assessments
CREATE POLICY "Healthcare professionals can view all assessments" ON assessments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id::text = auth.uid()::text 
            AND users.role IN ('doctor', 'psychiatrist', 'admin')
        )
    );

-- Allow users to insert their own assessments
CREATE POLICY "Users can create own assessments" ON assessments
    FOR INSERT WITH CHECK (auth.uid()::text = patient_user_id::text);

-- Allow healthcare professionals to update assessments
CREATE POLICY "Healthcare professionals can update assessments" ON assessments
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id::text = auth.uid()::text 
            AND users.role IN ('doctor', 'psychiatrist', 'admin')
        )
    );

-- Note: For production, you may want to disable RLS or adjust policies
-- based on your authentication setup. The above policies assume Supabase Auth.

