-- Seed data for Student Scholarship Monitoring and Academic Compliance System
-- AY 2026-2027, Semester 1

-- Scholarship Programs
INSERT INTO scholarship_programs (code, name, max_gwa, min_enrolled_units, allowed_failed, allowed_incomplete, allowed_dropped, evidence_required, deadline_at)
VALUES
  ('EXCELLENCE', 'Excellence Scholar', 2.00, 18, 0, 0, 0, 'Grade document reference', '2026-11-06 17:00:00+08:00'::timestamptz),
  ('ACCESS', 'Access Scholar', 2.50, 15, 0, 0, 1, 'Grade document reference', '2026-11-06 17:00:00+08:00'::timestamptz)
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
SELECT a1.sid, a1.aid, '2026-2027', 1, 2.00, 18, 0, 0, 0, 'B01-GRADE-DOC', '2026-11-06 17:00:00+08:00'::timestamptz, 'Verified', staff.id, NOW(), 'Verified' FROM a1,staff
UNION ALL SELECT a2.sid, a2.aid, '2026-2027', 1, 2.01, 18, 0, 0, 0, 'B02-GRADE-DOC', '2026-11-05 10:00:00+08:00'::timestamptz, 'Verified', staff.id, NOW(), 'Verified' FROM a2,staff
UNION ALL SELECT a3.sid, a3.aid, '2026-2027', 1, 2.50, 15, 0, 0, 1, 'B03-GRADE-DOC', '2026-11-05 11:00:00+08:00'::timestamptz, 'Verified', staff.id, NOW(), 'Verified' FROM a3,staff
UNION ALL SELECT a4.sid, a4.aid, '2026-2027', 1, 2.50, 14, 0, 1, 0, 'B04-GRADE-DOC', '2026-11-05 12:00:00+08:00'::timestamptz, 'Verified', staff.id, NOW(), 'Verified' FROM a4,staff
UNION ALL SELECT a5.sid, a5.aid, '2026-2027', 1, 1.75, 18, 1, 0, 0, 'B05-GRADE-DOC', '2026-11-06 17:01:00+08:00'::timestamptz, 'Verified', staff.id, NOW(), 'Verified' FROM a5,staff
UNION ALL SELECT a6.sid, a6.aid, '2026-2027', 1, 2.25, 15, 0, 0, 0, 'B06-GRADE-DOC', '2026-11-05 13:00:00+08:00'::timestamptz, 'Pending', NULL, NULL, NULL FROM a6
ON CONFLICT DO NOTHING;

do $$
declare r record;
begin
  for r in
    select t.tgname
    from pg_trigger t
    join pg_proc p on p.oid = t.tgfoid
    join pg_namespace n on n.oid = p.pronamespace
    where t.tgrelid = 'auth.users'::regclass
      and not t.tgisinternal
      and n.nspname = 'public'
  loop
    execute format('drop trigger if exists %I on auth.users', r.tgname);
  end loop;
end $$;

create extension if not exists pgcrypto;

do $$
declare v_uid uuid;
begin
  select id into v_uid from auth.users where email = 'staff_test@example.com';
  if v_uid is null then
    v_uid := gen_random_uuid();
    insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
    values (v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'staff_test@example.com', crypt('StaffPass123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '');
  else
    update auth.users set encrypted_password = crypt('StaffPass123!', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()) where id = v_uid;
  end if;
  update user_profiles set auth_user_id = v_uid where email = 'staff_test@example.com';
end $$;

do $$
declare v_uid uuid;
begin
  select id into v_uid from auth.users where email = 'scholar_test@example.com';
  if v_uid is null then
    v_uid := gen_random_uuid();
    insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
    values (v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'scholar_test@example.com', crypt('ScholarPass123!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), '', '', '', '');
  else
    update auth.users set encrypted_password = crypt('ScholarPass123!', gen_salt('bf')), email_confirmed_at = coalesce(email_confirmed_at, now()) where id = v_uid;
  end if;
  update user_profiles set auth_user_id = v_uid where email = 'scholar_test@example.com';
end $$;

do $$
declare v_uid uuid;
begin
  select id into v_uid from auth.users where email = 'staff_test@example.com';
  if v_uid is not null and not exists (select 1 from auth.identities where user_id = v_uid and provider = 'email') then
    if exists (select 1 from information_schema.columns where table_schema = 'auth' and table_name = 'identities' and column_name = 'provider_id') then
      insert into auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
      values (v_uid, v_uid, jsonb_build_object('sub', v_uid::text, 'email', 'staff_test@example.com'), 'email', v_uid::text, now(), now(), now());
    else
      insert into auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
      values (v_uid, v_uid, jsonb_build_object('sub', v_uid::text, 'email', 'staff_test@example.com'), 'email', now(), now(), now());
    end if;
  end if;
end $$;

do $$
declare v_uid uuid;
begin
  select id into v_uid from auth.users where email = 'scholar_test@example.com';
  if v_uid is not null and not exists (select 1 from auth.identities where user_id = v_uid and provider = 'email') then
    if exists (select 1 from information_schema.columns where table_schema = 'auth' and table_name = 'identities' and column_name = 'provider_id') then
      insert into auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
      values (v_uid, v_uid, jsonb_build_object('sub', v_uid::text, 'email', 'scholar_test@example.com'), 'email', v_uid::text, now(), now(), now());
    else
      insert into auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
      values (v_uid, v_uid, jsonb_build_object('sub', v_uid::text, 'email', 'scholar_test@example.com'), 'email', now(), now(), now());
    end if;
  end if;
end $$;
