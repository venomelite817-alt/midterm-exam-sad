# MANDATORY TEST RESULTS (TC01-TC10)

All tests use synthetic data from seed (AY 2026-2027 Sem 1). Evidence references point to seeded records.

| Test ID | Input/Action | Expected | Actual | Pass/Fail | Evidence Reference |
| --- | --- | --- | --- | --- | --- |
| TC01 | B01: Excellence, GWA 2.00, 18 units, 0/0/0, submitted exactly at deadline 2026-11-06 17:00:00+08:00, Verified | Compliant at exact GWA and deadline boundaries | Compliant (all checks pass; deadline exact = on time) | Pass | semester_submissions(B01) + scholarship_programs(EXCELLENCE) |
| TC02 | B02: Excellence, GWA 2.01 (> 2.00 max), 18 units, Verified | With Deficiency (GWA reason) | With Deficiency - "GWA exceeds maximum for program" | Pass | semester_submissions(B02), max_gwa 2.00 |
| TC03 | B03: Access, GWA 2.50, 15 units, 0 failed, 0 INC, 1 dropped (allowed 1), Verified | Compliant (one drop allowed for Access) | Compliant (dropped_count 1 <= allowed_dropped 1) | Pass | semester_submissions(B03), ACCESS allowed_dropped 1 |
| TC04 | B04: Access, GWA 2.50, 14 units (< 15 min), 0 failed, 1 INC (> 0 allowed), Verified | With Deficiency: insufficient units AND incomplete grade | With Deficiency - "Insufficient enrolled units"; "Exceeds allowed incomplete grades" | Pass | semester_submissions(B04) |
| TC05 | B05: Excellence, GWA 1.75, 18 units, 1 failed (> 0), submitted one minute late (17:01:00 > 17:00:00), Verified | With Deficiency: failed subject AND late submission | With Deficiency - "Exceeds allowed failed subjects"; "Late submission" | Pass | semester_submissions(B05), submitted_at 2026-11-06 17:01:00+08:00 vs deadline |
| TC06 | B06: Access, Pending verification, evidence not verified | Block both evaluation and renewal approval until verified and evaluated | Evaluation/Renewal blocked when submission_status != 'Verified'; cannot approve unverified. | Pass | semester_submissions(B06), submission_status 'Pending' |
| TC07 | Submit duplicate (scholar_id, AY, Sem); GWA 0.50 (< 1.00); negative counts (e.g., units -1) | Reject duplicate semester submission, GWA 0.50, and negative counts with clear messages | Duplicate check returns "Duplicate semester submission exists"; GWA validation rejects < 1.00/>5.00; negative counts rejected | Pass | app.js validation + DB unique constraint + CHECKs |
| TC08 | Scholar attempts to read another scholar's record or perform verification (staff action) | Backend denies (RLS) | Scholar policies restrict to own records; staff-only actions blocked for scholar role by RLS/policy checks | Pass | RLS policies on semester_submissions/evaluation_history/user_profiles |
| TC09 | Return a record (Pending/Verified->Returned with reason), correct and resubmit, refresh: stays Pending verification with history preserved | Returned allows correction/resubmission; after resubmit back to Pending; history entries preserved | submission_status becomes Returned on return; resubmission creates/updates to Pending; evaluation_history logs verification actions with actor/timestamp/notes | Pass | verification workflow + history table |
| TC10 | Staff approve a compliant record and hold a deficient one; scholar cannot change the decision | Approve requires Compliant; cannot approve deficient (must Hold); scholar cannot change decision (role restricted) | approveBtn checks compliance==Compliant and blocks otherwise; hold allowed; scholar role has no staff actions; RLS prevents scholar modifying decisions | Pass | renewal logic + role checks + RLS |

## Screenshots to Capture (List)
1. submission - Scholar submission form filled
2. submission_success - Submission confirmation / My Submissions showing Pending
3. verification - Staff view with Verify/Return and reason
4. verification_return - Record marked Returned with reason
5. compliance - Evaluation showing policy checks and Compliant/With Deficiency with reasons
6. renewal_approve - Staff approving compliant record
7. renewal_hold - Staff holding deficient record
8. dashboard - Dashboard counts for selected semester
9. search_filter - Search by student ID/name and filter by program/compliance
10. role_access - Scholar cannot access another scholar's record (RLS denied / UI restricted)
11. history - Audit history showing verification/evaluation/renewal entries
