-- Seed data for Student Scholarship Monitoring and Academic Compliance System
-- AY 2026-2027, Semester 1

-- Scholarship Programs
INSERT INTO scholarship_programs (code, name, max_gwa, min_enrolled_units, allowed_failed, allowed_incomplete, allowed_dropped, evidence_required, deadline_at)
VALUES
  ('EXCELLENCE', 'Excellence Scholar', 2.00, 18, 0, 0, 0, 'Grade document reference', '2026-11-06 17:00:00+08:00'),
  ('ACCESS', 'Access Scholar', 2.50, 15, 0, 0, 1, 'Grade document reference', '2026-11-06 17:00:00+08:00')
ON CONFLICT (code) DO NOTHING;

-- Test accounts (synthetic) - auth_user_id placeholders; map to real auth.users in setup
-- Staff: staff_test@example.com / Scholar: scholar_test@example.com
INSERT INTO user_profiles (auth_user_id, role, student_id, full_name, email)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'staff', 'STAFF-001', 'Scholarship Staff Test', 'staff_test@example.com'),
  ('00000000-0000-0000-0000-000000000002', 'scholar', 'SCH-001', 'Scholar Test', 'scholar_test@example.com')
ON CONFLICT DO NOTHING;

-- Six scholars (B01-B06)
INSERT INTO user_profiles (role, student_id, full_name, email)
VALUES
  ('scholar', 'B01', 'B01 Excellence', 'b01@example.com'),
  ('scholar', 'B02', 'B02 Excellence', 'b02@example.com'),
  ('scholar', 'B03', 'B03 Access', 'b03@example.com'),
  ('scholar', 'B04', 'B04 Access', 'b04@example.com'),
  ('scholar', 'B05', 'B05 Excellence', 'b05@example.com'),
  ('scholar', 'B06', 'B06 Access', 'b06@example.com')
ON CONFLICT (student_id) DO NOTHING;

-- Assignments
WITH staff AS (SELECT id FROM user_profiles WHERE student_id='STAFF-001' LIMIT 1),
     ex AS (SELECT id FROM scholarship_programs WHERE code='EXCELLENCE' LIMIT 1),
     ac AS (SELECT id FROM scholarship_programs WHERE code='ACCESS' LIMIT 1),
     s1 AS (SELECT id FROM user_profiles WHERE student_id='B01' LIMIT 1),
     s2 AS (SELECT id FROM user_profiles WHERE student_id='B02' LIMIT 1),
     s3 AS (SELECT id FROM user_profiles WHERE student_id='B03' LIMIT 1),
     s4 AS (SELECT id FROM user_profiles WHERE student_id='B04' LIMIT 1),
     s5 AS (SELECT id FROM user_profiles WHERE student_id='B05' LIMIT 1),
     s6 AS (SELECT id FROM user_profiles WHERE student_id='B06' LIMIT 1)
INSERT INTO scholar_assignments (scholar_id, program_id, academic_year, semester, award_status, assigned_by)
SELECT s1.id, ex.id, '2026-2027', 1, 'Active', staff.id FROM s1,ex,staff
UNION ALL SELECT s2.id, ex.id, '2026-2027', 1, 'Active', staff.id FROM s2,ex,staff
UNION ALL SELECT s3.id, ac.id, '2026-2027', 1, 'Active', staff.id FROM s3,ac,staff
UNION ALL SELECT s4.id, ac.id, '2026-2027', 1, 'Active', staff.id FROM s4,ac,staff
UNION ALL SELECT s5.id, ex.id, '2026-2027', 1, 'Active', staff.id FROM s5,ex,staff
UNION ALL SELECT s6.id, ac.id, '2026-2027', 1, 'Active', staff.id FROM s6,ac,staff
ON CONFLICT DO NOTHING;

-- Submissions
-- B01: Excellence, GWA 2.00, 18 units, 0 failed, 0 INC, 0 drop, submitted exactly at deadline 2026-11-06 17:00:00+08:00
-- B02: 2.01, 18,0,0,0
-- B03: Access 2.50, 15,0,0,1 drop
-- B04: 2.50, 14,0,1 INC,0
-- B05: Excellence 1.75, 18,1 failed,0,0, submitted one minute late 2026-11-06 17:01:00+08:00
-- B06: Access 2.25, 15,0,0,0, evidence still Pending verification
WITH a1 AS (SELECT sa.id as aid, sa.scholar_id as sid FROM scholar_assignments sa JOIN user_profiles up ON up.id=sa.scholar_id WHERE up.student_id='B01' LIMIT 1),
     a2 AS (SELECT sa.id as aid, sa.scholar_id as sid FROM scholar_assignments sa JOIN user_profiles up ON up.id=sa.scholar_id WHERE up.student_id='B02' LIMIT 1),
     a3 AS (SELECT sa.id as aid, sa.scholar_id as sid FROM scholar_assignments sa JOIN user_profiles up ON up.id=sa.scholar_id WHERE up.student_id='B03' LIMIT 1),
     a4 AS (SELECT sa.id as aid, sa.scholar_id as sid FROM scholar_assignments sa JOIN user_profiles up ON up.id=sa.scholar_id WHERE up.student_id='B04' LIMIT 1),
     a5 AS (SELECT sa.id as aid, sa.scholar_id as sid FROM scholar_assignments sa JOIN user_profiles up ON up.id=sa.scholar_id WHERE up.student_id='B05' LIMIT 1),
     a6 AS (SELECT sa.id as aid, sa.scholar_id as sid FROM scholar_assignments sa JOIN user_profiles up ON up.id=sa.scholar_id WHERE up.student_id='B06' LIMIT 1),
     staff AS (SELECT id FROM user_profiles WHERE student_id='STAFF-001' LIMIT 1)
INSERT INTO semester_submissions (scholar_id, assignment_id, academic_year, semester, gwa, enrolled_units, failed_count, incomplete_count, dropped_count, evidence_reference, submitted_at, submission_status, verified_by, verified_at, verification_reason)
SELECT a1.sid, a1.aid, '2026-2027', 1, 2.00, 18, 0, 0, 0, 'B01-GRADE-DOC', '2026-11-06 17:00:00+08:00', 'Verified', staff.id, NOW(), 'Verified' FROM a1,staff
UNION ALL SELECT a2.sid, a2.aid, '2026-2027', 1, 2.01, 18, 0, 0, 0, 'B02-GRADE-DOC', '2026-11-05 10:00:00+08:00', 'Verified', staff.id, NOW(), 'Verified' FROM a2,staff
UNION ALL SELECT a3.sid, a3.aid, '2026-2027', 1, 2.50, 15, 0, 0, 1, 'B03-GRADE-DOC', '2026-11-05 11:00:00+08:00', 'Verified', staff.id, NOW(), 'Verified' FROM a3,staff
UNION ALL SELECT a4.sid, a4.aid, '2026-2027', 1, 2.50, 14, 0, 1, 0, 'B04-GRADE-DOC', '2026-11-05 12:00:00+08:00', 'Verified', staff.id, NOW(), 'Verified' FROM a4,staff
UNION ALL SELECT a5.sid, a5.aid, '2026-2027', 1, 1.75, 18, 1, 0, 0, 'B05-GRADE-DOC', '2026-11-06 17:01:00+08:00', 'Verified', staff.id, NOW(), 'Verified' FROM a5,staff
UNION ALL SELECT a6.sid, a6.aid, '2026-2027', 1, 2.25, 15, 0, 0, 0, 'B06-GRADE-DOC', '2026-11-05 13:00:00+08:00', 'Pending', NULL, NULL, NULL FROM a6
ON CONFLICT DO NOTHING;
