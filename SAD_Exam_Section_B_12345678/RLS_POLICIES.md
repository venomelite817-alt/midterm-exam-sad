# RLS Policies Summary

Tables with RLS enabled: user_profiles, scholarship_programs, scholar_assignments, semester_submissions, evaluation_history

## user_profiles
- staff read all profiles (SELECT)
- user read own profile (SELECT, by auth_user_id)
- staff manage profiles (ALL)

## scholarship_programs
- authenticated read programs (SELECT)

## scholar_assignments
- staff all assignments (ALL)
- scholar read own assignments (SELECT, where scholar_id matches own profile)

## semester_submissions
- scholar own submissions (ALL, own records only)
- staff all submissions (ALL)

## evaluation_history
- scholar read own history (SELECT, via submission owned by scholar)
- staff all history (ALL)

## Functions
- get_user_role() returns role from user_profiles for current auth.uid() (SECURITY DEFINER)

Note: Enforced in backend/database (not UI-only). TC08 validates scholar cannot read others' records or perform verification.
