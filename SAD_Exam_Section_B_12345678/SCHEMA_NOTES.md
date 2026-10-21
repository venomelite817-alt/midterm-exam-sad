# Schema Notes

Constraints:
- user_profiles.auth_user_id UNIQUE, role CHECK (scholar|staff)
- scholarship_programs.code UNIQUE CHECK (EXCELLENCE|ACCESS)
- scholar_assignments.award_status CHECK ('Active')
- semester_submissions: gwa CHECK (1.00-5.00), counts/units CHECK >=0, submission_status CHECK (Pending|Verified|Returned), academic_compliance CHECK (Compliant|With Deficiency|UnEvaluated), renewal_decision CHECK (Pending|Approved|Held)
- UNIQUE (scholar_id, academic_year, semester) prevents duplicates
- FKs with CASCADE/RESTRICT as defined
- Separate statuses enforced (submission_status, academic_compliance, award_status); no auto-disqualification
- evaluation_history logs verification/evaluation/renewal with actor/timestamp/notes
