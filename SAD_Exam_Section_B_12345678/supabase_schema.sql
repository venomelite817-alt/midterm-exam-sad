-- Schema for Student Scholarship Monitoring and Academic Compliance System
-- Part II: Supabase SQL (Postgres) with RLS

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- USER PROFILES
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_user_id UUID UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('scholar','staff')),
  student_id TEXT UNIQUE,
  full_name TEXT NOT NULL,
  email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- SCHOLARSHIP PROGRAMS (policies)
CREATE TABLE IF NOT EXISTS scholarship_programs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL CHECK (code IN ('EXCELLENCE','ACCESS')),
  name TEXT NOT NULL,
  max_gwa DECIMAL(3,2) NOT NULL,
  min_enrolled_units INTEGER NOT NULL,
  allowed_failed INTEGER NOT NULL,
  allowed_incomplete INTEGER NOT NULL,
  allowed_dropped INTEGER NOT NULL,
  evidence_required TEXT NOT NULL,
  deadline_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- SCHOLAR ASSIGNMENTS
CREATE TABLE IF NOT EXISTS scholar_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  scholar_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  program_id UUID NOT NULL REFERENCES scholarship_programs(id) ON DELETE RESTRICT,
  academic_year TEXT NOT NULL,
  semester INTEGER NOT NULL,
  award_status TEXT NOT NULL DEFAULT 'Active' CHECK (award_status IN ('Active')),
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  assigned_by UUID REFERENCES user_profiles(id)
);

-- SEMESTER SUBMISSIONS
CREATE TABLE IF NOT EXISTS semester_submissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  scholar_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  assignment_id UUID NOT NULL REFERENCES scholar_assignments(id) ON DELETE RESTRICT,
  academic_year TEXT NOT NULL,
  semester INTEGER NOT NULL,
  gwa DECIMAL(3,2) NOT NULL CHECK (gwa >= 1.00 AND gwa <= 5.00),
  enrolled_units INTEGER NOT NULL CHECK (enrolled_units >= 0),
  failed_count INTEGER NOT NULL CHECK (failed_count >= 0),
  incomplete_count INTEGER NOT NULL CHECK (incomplete_count >= 0),
  dropped_count INTEGER NOT NULL CHECK (dropped_count >= 0),
  evidence_reference TEXT NOT NULL,
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  submission_status TEXT NOT NULL DEFAULT 'Pending' CHECK (submission_status IN ('Pending','Verified','Returned')),
  verified_by UUID REFERENCES user_profiles(id),
  verified_at TIMESTAMPTZ,
  verification_reason TEXT,
  academic_compliance TEXT DEFAULT 'UnEvaluated' CHECK (academic_compliance IN ('Compliant','With Deficiency','UnEvaluated')),
  compliance_reasons JSONB DEFAULT '[]'::jsonb,
  evaluated_at TIMESTAMPTZ,
  evaluated_by UUID REFERENCES user_profiles(id),
  renewal_decision TEXT DEFAULT 'Pending' CHECK (renewal_decision IN ('Pending','Approved','Held')),
  decision_notes TEXT,
  decided_at TIMESTAMPTZ,
  decided_by UUID REFERENCES user_profiles(id),
  CONSTRAINT unique_scholar_ay_sem UNIQUE (scholar_id, academic_year, semester)
);

-- EVALUATION HISTORY
CREATE TABLE IF NOT EXISTS evaluation_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  submission_id UUID NOT NULL REFERENCES semester_submissions(id) ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (action IN ('verification','evaluation','renewal')),
  actor_role TEXT NOT NULL,
  actor_id UUID REFERENCES user_profiles(id),
  from_status TEXT,
  to_status TEXT,
  details JSONB,
  notes TEXT,
  acted_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE scholarship_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE scholar_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE semester_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE evaluation_history ENABLE ROW LEVEL SECURITY;

-- Helper to get role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
  SELECT role FROM user_profiles WHERE auth_user_id = auth.uid() LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER;

-- Policies
-- user_profiles: staff can read all, users can read own
CREATE POLICY "staff read all profiles" ON user_profiles FOR SELECT USING (get_user_role() = 'staff');
CREATE POLICY "user read own profile" ON user_profiles FOR SELECT USING (auth_user_id = auth.uid());
CREATE POLICY "staff manage profiles" ON user_profiles FOR ALL USING (get_user_role() = 'staff');

-- programs: readable by all authenticated
CREATE POLICY "authenticated read programs" ON scholarship_programs FOR SELECT USING (auth.role() = 'authenticated');

-- assignments: staff all, scholar own
CREATE POLICY "staff all assignments" ON scholar_assignments FOR ALL USING (get_user_role() = 'staff');
CREATE POLICY "scholar read own assignments" ON scholar_assignments FOR SELECT USING (
  scholar_id IN (SELECT id FROM user_profiles WHERE auth_user_id = auth.uid())
);

-- submissions: scholar own only, staff all
CREATE POLICY "scholar own submissions" ON semester_submissions FOR ALL USING (
  scholar_id IN (SELECT id FROM user_profiles WHERE auth_user_id = auth.uid())
);
CREATE POLICY "staff all submissions" ON semester_submissions FOR ALL USING (get_user_role() = 'staff');

-- history: scholar own via submission, staff all
CREATE POLICY "scholar read own history" ON evaluation_history FOR SELECT USING (
  submission_id IN (
    SELECT id FROM semester_submissions WHERE scholar_id IN (SELECT id FROM user_profiles WHERE auth_user_id = auth.uid())
  )
);
CREATE POLICY "staff all history" ON evaluation_history FOR ALL USING (get_user_role() = 'staff');

-- Triggers for updated_at if desired (simple)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
