# SAD_Exam_Section_B_StudentID

## Project
Student Scholarship Monitoring and Academic Compliance System (Systems Analysis and Design Laboratory Exam)

## Tech Stack
HTML, CSS, JavaScript, Supabase (Postgres, Auth, Row Level Security), GitHub. Browser-based. Can run locally if hosting fails.

## Setup

### Prerequisites
- Supabase project (hosted) OR local Supabase (CLI/Docker)
- Modern browser

### Environment Variables (names only)
Set these in `app.js` or your environment setup:
- `SUPABASE_URL` (name only)
- `SUPABASE_ANON_KEY` (name only)

Update `app.js` with your values when running locally.

### Database Setup
1. Create a Supabase project
2. Run `supabase_schema.sql` in SQL Editor
3. Run `supabase_seed.sql` in SQL Editor (creates programs, test accounts placeholders, B01-B06 assignments and submissions)
4. Create auth users in Supabase Auth for test accounts as needed:
   - staff_test@example.com
   - scholar_test@example.com
   - Map to `user_profiles.auth_user_id` or ensure profiles exist

### Run Steps
#### Option 1: Hosted Supabase
1. Configure `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `app.js`
2. Open `index.html` in browser (or serve via local server)

#### Option 2: Local (if hosting fails)
1. Install Supabase CLI and Docker
2. Run `supabase start` locally
3. Get local URL and anon key
4. Update `app.js` with local values
5. Serve files locally (e.g., `python -m http.server` or `npx serve`)

## Features
- Role-based access (Scholar/Staff) enforced by RLS
- Scholar submits semester summary with evidence reference (validation + duplicate prevention)
- Staff verifies (Verified/Returned) with reason; returned can be corrected/resubmitted (back to Pending)
- Compliance evaluation using policy thresholds from program record; reasons recorded
- Renewal decisions (Approved/Held); approval requires Compliant; staff may hold deficient (cannot approve)
- Three separate statuses maintained; award stays Active; no auto-disqualification
- Dashboard counts, search by student ID/name, filter by program/compliance
- Audit history for verification/evaluation/renewal

## Test Accounts (synthetic)
- Staff: staff_test@example.com (STAFF-001)
- Scholar: scholar_test@example.com (SCH-001)
- Seeded scholars: B01-B06 (see seed data)

## Mandatory Tests (TC01-TC10)
See `TEST_RESULTS.md` for results table and evidence references.

## Screenshots to Capture
- submission form and submission success
- scholar view of own submissions
- staff verification (verify/return)
- compliance evaluation with reasons
- renewal decision (approve/hold)
- dashboard with counts
- role access (scholar cannot see others/staff actions blocked)

## Known Defects
- Evaluation UI in this MVP triggers on Hold action if not evaluated; production would have explicit Evaluate button
- History display is basic
- Auth mapping assumes auth_user_id linked to profiles; setup required
- Policy deadline stored as timestamp; comparison uses JS Date
- Some RLS helper functions assume auth context

## Files
- `PART_I_Analysis_Design.md` - Part I (A1-A6, UML, detailed UCs, ERD, traceability)
- `supabase_schema.sql` - Schema + RLS
- `supabase_seed.sql` - Seed data
- `index.html`, `style.css`, `app.js` - Frontend
- `TEST_RESULTS.md` - TC01-TC10 results
- `README.md` - This file
