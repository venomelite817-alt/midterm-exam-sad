// Supabase config
const SUPABASE_URL = "https://yxfhnmlfpaccmwuxiiid.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_aETH5zve1G27qjlmMds7dg_VTQMj6t5";

const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

let currentUser = null;
let currentProfile = null;
let currentSubmission = null;

// Auth
document.getElementById('loginBtn').addEventListener('click', async () => {
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) { alert(error.message); return; }
    await loadUser();
});

document.getElementById('logoutBtn').addEventListener('click', async () => {
    await supabase.auth.signOut();
    location.reload();
});

async function loadUser() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    currentUser = user;
    let { data: profile } = await supabase.from('user_profiles').select('*').eq('auth_user_id', user.id).maybeSingle();
    if (!profile) {
        const { data: profileByEmail } = await supabase.from('user_profiles').select('*').eq('email', user.email).maybeSingle();
        if (profileByEmail) {
            await supabase.from('user_profiles').update({ auth_user_id: user.id }).eq('id', profileByEmail.id);
            profile = { ...profileByEmail, auth_user_id: user.id };
        }
    }
    if (!profile) {
        alert('No profile linked to ' + user.email + '. Make sure this email exists in user_profiles.');
        await supabase.auth.signOut();
        return;
    }
    currentProfile = profile;
    document.getElementById('loggedOut').style.display = 'none';
    document.getElementById('loggedIn').style.display = 'flex';
    document.getElementById('userInfo').textContent = profile.full_name + ' (' + profile.role + ')';
    document.getElementById('roleSection').style.display = 'block';
    if (profile.role === 'scholar') {
        document.getElementById('scholarView').style.display = 'block';
        loadMySubmissions();
    } else if (profile.role === 'staff') {
        document.getElementById('staffView').style.display = 'block';
        loadAllSubmissions();
        loadDashboard();
    }
}

supabase.auth.onAuthStateChange((_event, session) => {
    if (session) loadUser(); else location.reload();
});

// Scholar submission (insert or update returned)
document.getElementById('submissionForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    if (currentProfile.role !== 'scholar') return;
    const ay = document.getElementById('ay').value;
    const sem = parseInt(document.getElementById('sem').value);
    const gwa = parseFloat(document.getElementById('gwa').value);
    const units = parseInt(document.getElementById('units').value);
    const failed = parseInt(document.getElementById('failed').value);
    const inc = parseInt(document.getElementById('inc').value);
    const dropped = parseInt(document.getElementById('dropped').value);
    const evidence = document.getElementById('evidence').value;
    
    if (gwa < 1.00 || gwa > 5.00) { document.getElementById('subMsg').textContent = 'Invalid GWA (1.00-5.00)'; return; }
    if (units < 0 || failed < 0 || inc < 0 || dropped < 0 || isNaN(units) || isNaN(failed) || isNaN(inc) || isNaN(dropped)) { document.getElementById('subMsg').textContent = 'Negative counts not allowed'; return; }
    if (!evidence) { document.getElementById('subMsg').textContent = 'Evidence reference required'; return; }
    
    const { data: assignment } = await supabase.from('scholar_assignments').select('id').eq('scholar_id', currentProfile.id).eq('academic_year', ay).eq('semester', sem).single();
    if (!assignment) { document.getElementById('subMsg').textContent = 'No assignment found for this AY/Sem'; return; }
    
    const { data: existing } = await supabase.from('semester_submissions').select('*').eq('scholar_id', currentProfile.id).eq('academic_year', ay).eq('semester', sem).single();
    if (existing) {
        if (existing.submission_status === 'Returned') {
            const { error } = await supabase.from('semester_submissions').update({
                gwa, enrolled_units: units, failed_count: failed, incomplete_count: inc, dropped_count: dropped,
                evidence_reference: evidence,
                submission_status: 'Pending',
                verified_by: null, verified_at: null, verification_reason: null,
                academic_compliance: 'UnEvaluated',
                compliance_reasons: [], evaluated_at: null, evaluated_by: null,
                renewal_decision: 'Pending', decision_notes: null, decided_at: null, decided_by: null
            }).eq('id', existing.id);
            if (error) { document.getElementById('subMsg').textContent = error.message; return; }
            await supabase.from('evaluation_history').insert({ submission_id: existing.id, action: 'verification', actor_role: 'scholar', actor_id: currentProfile.id, from_status: 'Returned', to_status: 'Pending', notes: 'Resubmitted after correction' });
            document.getElementById('subMsg').textContent = 'Resubmitted - Pending verification';
            loadMySubmissions();
            return;
        } else {
            document.getElementById('subMsg').textContent = 'Duplicate semester submission exists';
            return;
        }
    }
    
    const { error } = await supabase.from('semester_submissions').insert({
        scholar_id: currentProfile.id,
        assignment_id: assignment.id,
        academic_year: ay,
        semester: sem,
        gwa, enrolled_units: units, failed_count: failed, incomplete_count: inc, dropped_count: dropped,
        evidence_reference: evidence,
        submission_status: 'Pending',
        academic_compliance: 'UnEvaluated',
        renewal_decision: 'Pending'
    });
    if (error) { document.getElementById('subMsg').textContent = error.message; return; }
    document.getElementById('subMsg').textContent = 'Submitted - Pending verification';
    loadMySubmissions();
});

async function loadMySubmissions() {
    const { data } = await supabase.from('semester_submissions').select('*').eq('scholar_id', currentProfile.id).order('submitted_at', { ascending: false });
    const div = document.getElementById('mySubmissions');
    div.innerHTML = '<table><tr><th>AY</th><th>Sem</th><th>GWA</th><th>Status</th><th>Compliance</th><th>Decision</th></tr>' +
        (data||[]).map(s => '<tr><td>'+s.academic_year+'</td><td>'+s.semester+'</td><td>'+s.gwa+'</td><td>'+s.submission_status+'</td><td>'+s.academic_compliance+'</td><td>'+s.renewal_decision+'</td></tr>').join('') + '</table>';
}

// Staff
document.getElementById('applyFilters').addEventListener('click', loadAllSubmissions);
document.getElementById('applyFilters').addEventListener('click', loadDashboard);

async function loadDashboard() {
    const ay = document.getElementById('staffAy').value;
    const sem = parseInt(document.getElementById('staffSem').value);
    const { data: assignments } = await supabase.from('scholar_assignments').select('scholar_id').eq('academic_year', ay).eq('semester', sem);
    const totalAssigned = assignments ? [...new Set(assignments.map(a => a.scholar_id))].length : 0;
    const { data } = await supabase.from('semester_submissions').select('*').eq('academic_year', ay).eq('semester', sem);
    const pending = data?.filter(s => s.submission_status === 'Pending').length || 0;
    const compliant = data?.filter(s => s.academic_compliance === 'Compliant').length || 0;
    const deficient = data?.filter(s => s.academic_compliance === 'With Deficiency').length || 0;
    document.getElementById('dashCounts').innerHTML = 'Assigned scholars: ' + totalAssigned + ' | Pending verification: ' + pending + ' | Compliant: ' + compliant + ' | With Deficiency: ' + deficient;
}

async function loadAllSubmissions() {
    const ay = document.getElementById('staffAy').value;
    const sem = parseInt(document.getElementById('staffSem').value);
    const search = document.getElementById('search').value.toLowerCase();
    const prog = document.getElementById('progFilter').value;
    const comp = document.getElementById('compFilter').value;
    
    let query = supabase.from('semester_submissions').select('*, user_profiles!scholar_id(student_id, full_name), scholar_assignments(program_id, scholarship_programs(code, name))').eq('academic_year', ay).eq('semester', sem);
    const { data } = await query;
    let filtered = data || [];
    if (search) filtered = filtered.filter(s => (s.user_profiles?.student_id||'').toLowerCase().includes(search) || (s.user_profiles?.full_name||'').toLowerCase().includes(search));
    if (prog) filtered = filtered.filter(s => s.scholar_assignments?.scholarship_programs?.code === prog);
    if (comp) filtered = filtered.filter(s => s.academic_compliance === comp);
    
    const div = document.getElementById('allSubmissions');
    div.innerHTML = '<table><tr><th>Student</th><th>Program</th><th>GWA</th><th>Status</th><th>Compliance</th><th>Decision</th><th>Action</th></tr>' +
        filtered.map(s => '<tr><td>'+s.user_profiles.student_id+' '+s.user_profiles.full_name+'</td><td>'+s.scholar_assignments.scholarship_programs.code+'</td><td>'+s.gwa+'</td><td>'+s.submission_status+'</td><td>'+s.academic_compliance+'</td><td>'+s.renewal_decision+'</td><td><button onclick="selectSubmission(\''+s.id+'\')">Manage</button></td></tr>').join('') + '</table>';
}

async function selectSubmission(id) {
    const { data: s } = await supabase.from('semester_submissions').select('*, user_profiles!scholar_id(*), scholar_assignments(*, scholarship_programs(*))').eq('id', id).single();
    currentSubmission = s;
    document.getElementById('verifyCard').style.display = 'block';
    document.getElementById('verifyInfo').innerHTML = 'Student: '+s.user_profiles.student_id+' '+s.user_profiles.full_name+'<br>AY:'+s.academic_year+' Sem:'+s.semester+'<br>Evidence: '+s.evidence_reference+'<br>Status: '+s.submission_status;
    document.getElementById('evalCard').style.display = 'block';
    document.getElementById('evalInfo').innerHTML = 'Program: '+s.scholar_assignments.scholarship_programs.code+'<br>GWA:'+s.gwa+', Units:'+s.enrolled_units+', Failed:'+s.failed_count+', INC:'+s.incomplete_count+', Drop:'+s.dropped_count+'<br>Compliance: '+s.academic_compliance+'<br>Decision: '+s.renewal_decision;
    document.getElementById('policyChecks').innerHTML = '';
    loadHistory(id);
}

document.getElementById('verifyBtn').addEventListener('click', async () => {
    if (!currentSubmission) return;
    const { error } = await supabase.from('semester_submissions').update({ submission_status: 'Verified', verified_by: currentProfile.id, verified_at: new Date().toISOString(), verification_reason: document.getElementById('verifyReason').value || 'Verified' }).eq('id', currentSubmission.id);
    if (error) { alert(error.message); return; }
    await supabase.from('evaluation_history').insert({ submission_id: currentSubmission.id, action: 'verification', actor_role: currentProfile.role, actor_id: currentProfile.id, from_status: currentSubmission.submission_status, to_status: 'Verified', notes: document.getElementById('verifyReason').value });
    alert('Verified');
    loadAllSubmissions();
    selectSubmission(currentSubmission.id);
});

document.getElementById('returnBtn').addEventListener('click', async () => {
    if (!currentSubmission) return;
    const reason = document.getElementById('verifyReason').value;
    if (!reason) { alert('Reason required to return'); return; }
    const { error } = await supabase.from('semester_submissions').update({ submission_status: 'Returned', verified_by: currentProfile.id, verified_at: new Date().toISOString(), verification_reason: reason }).eq('id', currentSubmission.id);
    if (error) { alert(error.message); return; }
    await supabase.from('evaluation_history').insert({ submission_id: currentSubmission.id, action: 'verification', actor_role: currentProfile.role, actor_id: currentProfile.id, from_status: currentSubmission.submission_status, to_status: 'Returned', notes: reason });
    alert('Returned');
    loadAllSubmissions();
    selectSubmission(currentSubmission.id);
});

// Evaluation
document.getElementById('evalBtn').addEventListener('click', async () => {
    if (!currentSubmission) return;
    if (currentSubmission.submission_status !== 'Verified') { alert('Missing or unverified evidence prevents final evaluation'); return; }
    await runEvaluation(currentSubmission);
    const { data: s2 } = await supabase.from('semester_submissions').select('*, user_profiles!scholar_id(*), scholar_assignments(*, scholarship_programs(*))').eq('id', currentSubmission.id).single();
    currentSubmission = s2;
    document.getElementById('evalInfo').innerHTML = 'Program: '+s2.scholar_assignments.scholarship_programs.code+'<br>GWA:'+s2.gwa+', Units:'+s2.enrolled_units+', Failed:'+s2.failed_count+', INC:'+s2.incomplete_count+', Drop:'+s2.dropped_count+'<br>Compliance: '+s2.academic_compliance+'<br>Decision: '+s2.renewal_decision;
    loadHistory(currentSubmission.id);
    loadAllSubmissions();
    loadDashboard();
});

document.getElementById('approveBtn').addEventListener('click', async () => {
    if (!currentSubmission) return;
    if (currentSubmission.submission_status !== 'Verified') { alert('Missing or unverified evidence prevents final evaluation'); return; }
    if (currentSubmission.academic_compliance !== 'Compliant') { alert('Cannot approve deficient record'); return; }
    const notes = document.getElementById('decisionNotes').value;
    const { error } = await supabase.from('semester_submissions').update({ renewal_decision: 'Approved', decision_notes: notes, decided_at: new Date().toISOString(), decided_by: currentProfile.id }).eq('id', currentSubmission.id);
    if (error) { alert(error.message); return; }
    await supabase.from('evaluation_history').insert({ submission_id: currentSubmission.id, action: 'renewal', actor_role: currentProfile.role, actor_id: currentProfile.id, to_status: 'Approved', notes });
    alert('Approved');
    loadAllSubmissions();
    loadDashboard();
    selectSubmission(currentSubmission.id);
});

document.getElementById('holdBtn').addEventListener('click', async () => {
    if (!currentSubmission) return;
    if (currentSubmission.submission_status !== 'Verified') { alert('Missing or unverified evidence prevents final evaluation'); return; }
    if (currentSubmission.academic_compliance === 'UnEvaluated') {
        await runEvaluation(currentSubmission);
        const { data: s2 } = await supabase.from('semester_submissions').select('*, user_profiles!scholar_id(*), scholar_assignments(*, scholarship_programs(*))').eq('id', currentSubmission.id).single();
        currentSubmission = s2;
    }
    const notes = document.getElementById('decisionNotes').value;
    const { error } = await supabase.from('semester_submissions').update({ renewal_decision: 'Held', decision_notes: notes, decided_at: new Date().toISOString(), decided_by: currentProfile.id }).eq('id', currentSubmission.id);
    if (error) { alert(error.message); return; }
    await supabase.from('evaluation_history').insert({ submission_id: currentSubmission.id, action: 'renewal', actor_role: currentProfile.role, actor_id: currentProfile.id, to_status: 'Held', notes });
    alert('Held');
    loadAllSubmissions();
    loadDashboard();
    selectSubmission(currentSubmission.id);
});

async function runEvaluation(s) {
    const prog = s.scholar_assignments.scholarship_programs;
    const reasons = [];
    let compliant = true;
    if (s.gwa > parseFloat(prog.max_gwa)) { reasons.push('GWA exceeds maximum for program'); compliant = false; }
    if (s.enrolled_units < prog.min_enrolled_units) { reasons.push('Insufficient enrolled units'); compliant = false; }
    if (s.failed_count > prog.allowed_failed) { reasons.push('Exceeds allowed failed subjects'); compliant = false; }
    if (s.incomplete_count > prog.allowed_incomplete) { reasons.push('Exceeds allowed incomplete grades'); compliant = false; }
    if (s.dropped_count > prog.allowed_dropped) { reasons.push('Exceeds allowed dropped subjects'); compliant = false; }
    const deadline = new Date(prog.deadline_at);
    const submitted = new Date(s.submitted_at);
    if (submitted > deadline) { reasons.push('Late submission'); compliant = false; }
    const comp = compliant ? 'Compliant' : 'With Deficiency';
    await supabase.from('semester_submissions').update({ academic_compliance: comp, compliance_reasons: reasons, evaluated_at: new Date().toISOString(), evaluated_by: currentProfile.id }).eq('id', s.id);
    await supabase.from('evaluation_history').insert({ submission_id: s.id, action: 'evaluation', actor_role: currentProfile.role, actor_id: currentProfile.id, to_status: comp, details: reasons, notes: reasons.join('; ') });
    document.getElementById('policyChecks').innerHTML = '<b>Result:</b> ' + comp + '<br><b>Policy checks & reasons:</b><br>' + (reasons.length ? reasons.map(r=>'- '+r).join('<br>') : '- All checks passed');
}

async function loadHistory(id) {
    const { data } = await supabase.from('evaluation_history').select('*').eq('submission_id', id).order('acted_at', { ascending: true });
    document.getElementById('history').innerHTML = '<ul>' + (data||[]).map(h => '<li>'+h.acted_at+': '+h.action+' -> '+(h.to_status||'')+' by '+h.actor_role+' '+(h.notes||'')+'</li>').join('') + '</ul>';
}
