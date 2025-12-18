
CREATE TABLE IF NOT EXISTS assessment_templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS assessment_template_questions (
    id SERIAL PRIMARY KEY,
    template_id INTEGER NOT NULL REFERENCES assessment_templates(id) ON DELETE CASCADE,
    question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(template_id, question_id)
);

ALTER TABLE question_responses 
ADD COLUMN IF NOT EXISTS template_id INTEGER REFERENCES assessment_templates(id);
ALTER TABLE question_responses 
ADD COLUMN IF NOT EXISTS patient_user_id UUID REFERENCES users(id);

ALTER TABLE assessments 
ADD COLUMN IF NOT EXISTS template_id INTEGER REFERENCES assessment_templates(id);

CREATE INDEX IF NOT EXISTS idx_assessment_templates_active ON assessment_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_assessment_templates_created_by ON assessment_templates(created_by);
CREATE INDEX IF NOT EXISTS idx_template_questions_template ON assessment_template_questions(template_id);
CREATE INDEX IF NOT EXISTS idx_template_questions_question ON assessment_template_questions(question_id);
CREATE INDEX IF NOT EXISTS idx_template_questions_order ON assessment_template_questions(order_index);
CREATE INDEX IF NOT EXISTS idx_question_responses_template ON question_responses(template_id);
CREATE INDEX IF NOT EXISTS idx_question_responses_patient ON question_responses(patient_user_id);
CREATE TRIGGER update_assessment_templates_updated_at BEFORE UPDATE ON assessment_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Disable RLS for assessment_templates (or create policies)
ALTER TABLE assessment_templates DISABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_template_questions DISABLE ROW LEVEL SECURITY;

-- Update question_responses RLS (allow all for now)
ALTER TABLE question_responses DISABLE ROW LEVEL SECURITY;

-- Verify tables created
SELECT 'assessment_templates' as table_name, COUNT(*) as row_count FROM assessment_templates
UNION ALL
SELECT 'assessment_template_questions', COUNT(*) FROM assessment_template_questions;

