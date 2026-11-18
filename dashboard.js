const SUPABASE_URL = "https://xcxwjpyqvjpnoiwlnqlx.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_jLGhGLxVj-OQiO6p2xyUtA_Ou3IMXel";

const loginMsg = document.getElementById('loginMsg');
if (!window.supabase || typeof window.supabase.createClient !== 'function') {
    if (loginMsg) loginMsg.textContent = 'Could not load the Supabase library. Check your connection and reload.';
    throw new Error('Supabase library not loaded');
}

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

let currentProfile = null;

function escapeHtml(value) {
    return String(value ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

function statHtml(items) {
    return items.map(([label, value]) => '<div class="stat"><span>' + escapeHtml(label) + '</span><b>' + value + '</b></div>').join('');
}

function barsHtml(items, total) {
    const max = Math.max(1, total);
    return items.map(([label, value]) => '<div class="bar-row"><span class="bar-label">' + escapeHtml(label) + '</span><span class="bar-track"><span class="bar-fill" style="width:' + (value / max * 100) + '%"></span></span><span class="bar-value">' + value + '</span></div>').join('');
}

function tableHtml(headers, rows) {
    return '<table><tr>' + headers.map(h => '<th>' + escapeHtml(h) + '</th>').join('') + '</tr>' +
        rows.map(row => '<tr>' + row.map(cell => '<td>' + escapeHtml(cell) + '</td>').join('') + '</tr>').join('') + '</table>';
}

document.getElementById('loginBtn').addEventListener('click', async () => {
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    if (loginMsg) loginMsg.textContent = 'Signing in...';
    try {
        const { error } = await supabaseClient.auth.signInWithPassword({ email, password });
        if (error) { if (loginMsg) loginMsg.textContent = error.message; else alert(error.message); return; }
        await loadUser();
    } catch (err) {
        if (loginMsg) loginMsg.textContent = 'Cannot reach the server. Check the Supabase URL and your connection.';
        else alert(err.message);
    }
});

document.getElementById('logoutBtn').addEventListener('click', async () => {
    await supabaseClient.auth.signOut();
    location.reload();
});

document.getElementById('dashApply').addEventListener('click', renderStaffDashboard);

supabaseClient.auth.onAuthStateChange((_event, session) => {
    if (session) loadUser();
});

async function loadUser() {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) return;
    let { data: profile } = await supabaseClient.from('user_profiles').select('*').eq('auth_user_id', user.id).maybeSingle();
    if (!profile) {
        const { data: profileByEmail } = await supabaseClient.from('user_profiles').select('*').eq('email', user.email).maybeSingle();
        if (profileByEmail) {
            await supabaseClient.from('user_profiles').update({ auth_user_id: user.id }).eq('id', profileByEmail.id);
            profile = { ...profileByEmail, auth_user_id: user.id };
        }
    }
    if (!profile) {
        if (loginMsg) loginMsg.textContent = 'No profile linked to ' + user.email + '.';
        await supabaseClient.auth.signOut();
        return;
    }
    currentProfile = profile;
    document.getElementById('loggedOut').style.display = 'none';
    document.getElementById('loggedIn').style.display = 'flex';
    document.getElementById('userInfo').textContent = profile.full_name + ' (' + profile.role + ')';
    document.getElementById('roleSection').style.display = 'block';
    if (profile.role === 'scholar') {
        document.getElementById('scholarDash').style.display = 'block';
        await renderScholarDashboard();
    } else if (profile.role === 'staff') {
        document.getElementById('staffDash').style.display = 'block';
        await renderStaffDashboard();
    }
}

async function renderScholarDashboard() {
    if (!currentProfile || currentProfile.role !== 'scholar') return;
    const { data } = await supabaseClient.from('semester_submissions').select('*').eq('scholar_id', currentProfile.id).order('submitted_at', { ascending: false });
    const rows = data || [];
    const count = (field, value) => rows.filter(s => s[field] === value).length;
    document.getElementById('scholarStats').innerHTML = statHtml([
        ['Total submissions', rows.length],
        ['Pending verification', count('submission_status', 'Pending')],
        ['Verified', count('submission_status', 'Verified')],
        ['Returned', count('submission_status', 'Returned')],
        ['Compliant', count('academic_compliance', 'Compliant')],
        ['With deficiency', count('academic_compliance', 'With Deficiency')],
        ['Approved', count('renewal_decision', 'Approved')],
        ['Held', count('renewal_decision', 'Held')]
    ]);
    document.getElementById('scholarBars').innerHTML =
        '<h3>Submission status</h3>' + barsHtml([
            ['Pending', count('submission_status', 'Pending')],
            ['Verified', count('submission_status', 'Verified')],
            ['Returned', count('submission_status', 'Returned')]
        ], rows.length) +
        '<h3>Compliance</h3>' + barsHtml([
            ['UnEvaluated', count('academic_compliance', 'UnEvaluated')],
            ['Compliant', count('academic_compliance', 'Compliant')],
            ['With Deficiency', count('academic_compliance', 'With Deficiency')]
        ], rows.length) +
        '<h3>Renewal decision</h3>' + barsHtml([
            ['Pending', count('renewal_decision', 'Pending')],
            ['Approved', count('renewal_decision', 'Approved')],
            ['Held', count('renewal_decision', 'Held')]
        ], rows.length);
    document.getElementById('scholarTable').innerHTML = tableHtml(
        ['AY', 'Sem', 'GWA', 'Status', 'Compliance', 'Decision', 'Submitted'],
        rows.map(s => [s.academic_year, s.semester, s.gwa, s.submission_status, s.academic_compliance, s.renewal_decision, (s.submitted_at || '').slice(0, 10)])
    );
}

async function renderStaffDashboard() {
    if (!currentProfile || currentProfile.role !== 'staff') return;
    const ay = document.getElementById('dashAy').value;
    const sem = parseInt(document.getElementById('dashSem').value, 10);
    const { data: assignments } = await supabaseClient.from('scholar_assignments').select('scholar_id, scholarship_programs(code)').eq('academic_year', ay).eq('semester', sem);
    const { data } = await supabaseClient.from('semester_submissions').select('*, user_profiles!scholar_id(student_id, full_name), scholar_assignments(program_id, scholarship_programs(code, name))').eq('academic_year', ay).eq('semester', sem).order('submitted_at', { ascending: false });
    const assigned = assignments || [];
    const rows = data || [];
    const count = (field, value) => rows.filter(s => s[field] === value).length;
    const assignedScholars = new Set(assigned.map(a => a.scholar_id)).size;
    const programs = [...new Set(assigned.map(a => a.scholarship_programs?.code).filter(Boolean))];
    document.getElementById('staffStats').innerHTML = statHtml([
        ['Assigned scholars', assignedScholars],
        ['Submissions', rows.length],
        ['Pending verification', count('submission_status', 'Pending')],
        ['Verified', count('submission_status', 'Verified')],
        ['Returned', count('submission_status', 'Returned')],
        ['Compliant', count('academic_compliance', 'Compliant')],
        ['With deficiency', count('academic_compliance', 'With Deficiency')],
        ['UnEvaluated', count('academic_compliance', 'UnEvaluated')],
        ['Approved', count('renewal_decision', 'Approved')],
        ['Held', count('renewal_decision', 'Held')]
    ]);
    document.getElementById('staffBars').innerHTML =
        '<h3>Submission status</h3>' + barsHtml([
            ['Pending', count('submission_status', 'Pending')],
            ['Verified', count('submission_status', 'Verified')],
            ['Returned', count('submission_status', 'Returned')]
        ], rows.length) +
        '<h3>Compliance</h3>' + barsHtml([
            ['UnEvaluated', count('academic_compliance', 'UnEvaluated')],
            ['Compliant', count('academic_compliance', 'Compliant')],
            ['With Deficiency', count('academic_compliance', 'With Deficiency')]
        ], rows.length) +
        '<h3>Renewal decision</h3>' + barsHtml([
            ['Pending', count('renewal_decision', 'Pending')],
            ['Approved', count('renewal_decision', 'Approved')],
            ['Held', count('renewal_decision', 'Held')]
        ], rows.length) +
        '<h3>Submissions by program</h3>' + barsHtml(programs.map(code => [code, rows.filter(s => s.scholar_assignments?.scholarship_programs?.code === code).length]), rows.length);
    document.getElementById('staffTable').innerHTML = tableHtml(
        ['Student', 'Program', 'GWA', 'Status', 'Compliance', 'Decision', 'Submitted'],
        rows.slice(0, 10).map(s => [
            (s.user_profiles?.student_id || '') + ' ' + (s.user_profiles?.full_name || ''),
            s.scholar_assignments?.scholarship_programs?.code || '',
            s.gwa, s.submission_status, s.academic_compliance, s.renewal_decision, (s.submitted_at || '').slice(0, 10)
        ])
    );
}
