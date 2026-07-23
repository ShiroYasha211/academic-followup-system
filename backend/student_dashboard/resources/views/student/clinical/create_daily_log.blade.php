@extends('layouts.student')
@section('title', 'تسجيل بيانات اليوم')
@section('content')
<style>
    .clinical-page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.75rem;
        flex-wrap: wrap;
        gap: 1rem;
    }

    .clinical-page-header .right-side h1 {
        font-size: 1.5rem;
        font-weight: 800;
        color: var(--text-primary);
        margin: 0 0 0.15rem 0;
    }

    .clinical-page-header .right-side p {
        color: var(--text-secondary);
        font-size: 0.9rem;
        margin: 0;
    }

    .btn-back {
        background: white;
        color: var(--text-secondary);
        border: 1.5px solid #e2e8f0;
        padding: 0.55rem 1.1rem;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.88rem;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
        transition: all 0.2s;
    }

    .btn-back:hover {
        border-color: #cbd5e1;
        background: #f8fafc;
        color: var(--text-primary);
        text-decoration: none;
    }

    .card-section {
        background: white;
        border-radius: 18px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
        margin-bottom: 1.25rem;
    }

    .card-section h3 {
        font-size: 1rem;
        font-weight: 700;
        color: var(--text-primary);
        margin: 0 0 1rem 0;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .auto-fields {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
        gap: 0.75rem;
        background: #f0fdf4;
        padding: 1rem;
        border-radius: 12px;
        border: 1px solid #bbf7d0;
        margin-bottom: 1rem;
    }

    .auto-field {
        text-align: center;
    }

    .auto-field .label {
        font-size: 0.78rem;
        color: #065f46;
        font-weight: 600;
    }

    .auto-field .value {
        font-size: 1.1rem;
        font-weight: 800;
        color: #047857;
    }

    .form-group {
        margin-bottom: 1rem;
    }

    .form-label {
        display: block;
        font-weight: 600;
        font-size: 0.88rem;
        color: var(--text-primary);
        margin-bottom: 0.4rem;
    }

    .form-select,
    .form-control {
        width: 100%;
        padding: 0.6rem 0.85rem;
        font-size: 0.9rem;
        border: 1.5px solid #e2e8f0;
        border-radius: 10px;
        background: #f8fafc;
        font-family: inherit;
        box-sizing: border-box;
    }

    .form-select:focus,
    .form-control:focus {
        outline: none;
        border-color: var(--primary-color);
        background: white;
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.08);
    }

    .form-row {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1rem;
    }

    @media (max-width: 768px) {
        .form-row {
            grid-template-columns: 1fr;
        }
    }

    .activity-section {
        border: 1.5px solid #e2e8f0;
        border-radius: 14px;
        padding: 1.25rem;
        margin-bottom: 1rem;
    }

    .activity-section.history {
        border-color: #bfdbfe;
        background: #f8faff;
    }

    .activity-section.exam {
        border-color: #fbcfe8;
        background: #fdf2f8;
    }

    .activity-section.round {
        border-color: #d1fae5;
        background: #f0fdf4;
    }

    .activity-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 0.75rem;
    }

    .activity-header h4 {
        font-weight: 700;
        font-size: 0.95rem;
        margin: 0;
    }

    .activity-header .count-badge {
        background: white;
        border: 1px solid #e2e8f0;
        padding: 0.2rem 0.6rem;
        border-radius: 6px;
        font-weight: 700;
        font-size: 0.85rem;
    }

    .activity-item {
        display: flex;
        gap: 0.75rem;
        align-items: center;
        margin-bottom: 0.5rem;
    }

    .activity-item select {
        flex: 1;
    }

    .activity-item .num {
        min-width: 24px;
        font-weight: 700;
        color: var(--text-secondary);
        text-align: center;
        font-size: 0.85rem;
    }

    .btn-add {
        background: white;
        border: 1.5px dashed #cbd5e1;
        color: var(--primary-color);
        padding: 0.5rem;
        border-radius: 8px;
        width: 100%;
        font-weight: 600;
        font-size: 0.85rem;
        cursor: pointer;
        transition: all 0.2s;
    }

    .btn-add:hover {
        background: #f8fafc;
        border-color: var(--primary-color);
    }

    .btn-remove {
        width: 30px;
        height: 30px;
        border-radius: 7px;
        background: #fef2f2;
        color: #ef4444;
        border: none;
        cursor: pointer;
        font-size: 1rem;
        flex: none;
    }

    .round-check {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        padding: 0.75rem;
        background: #f0fdf4;
        border-radius: 10px;
        border: 1px solid #bbf7d0;
        margin-bottom: 0.75rem;
    }

    .round-check input[type="checkbox"] {
        width: 18px;
        height: 18px;
        accent-color: #059669;
    }

    .round-check label {
        font-weight: 600;
        color: #065f46;
        font-size: 0.9rem;
        cursor: pointer;
    }

    .btn-submit {
        background: linear-gradient(135deg, #4f46e5, #6366f1);
        color: white;
        border: none;
        padding: 0.85rem;
        border-radius: 12px;
        font-weight: 700;
        font-size: 1rem;
        cursor: pointer;
        width: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        box-shadow: 0 2px 8px rgba(79, 70, 229, 0.25);
        transition: all 0.2s;
    }

    .btn-submit:hover {
        transform: translateY(-1px);
        box-shadow: 0 4px 14px rgba(79, 70, 229, 0.35);
    }

    .error-box {
        background: #fee2e2;
        border: 1px solid #fca5a5;
        border-radius: 12px;
        padding: 1rem;
        margin-bottom: 1rem;
        color: #991b1b;
        font-size: 0.88rem;
    }
</style>

<div class="clinical-page-header">
    <div class="right-side">
        <h1>📝 تسجيل بيانات اليوم</h1>
        <p>عبّئ بيانات اليوم السريري كاملة ثم أنشئ الباركود للتوقيع</p>
    </div>
    <div class="left-side"><a href="{{ route('student.clinical.index') }}" class="btn-back"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg> القسم العملي</a></div>
</div>

@if ($errors->any())
<div class="error-box">@foreach ($errors->all() as $error)<div>⚠️ {{ $error }}</div>@endforeach</div>
@endif

<form action="{{ route('student.clinical.daily-log.store') }}" method="POST" id="dailyLogForm">
    @csrf

    {{-- Auto Fields --}}
    <div class="card-section">
        <h3>📅 البيانات التلقائية</h3>
        <div class="auto-fields">
            <div class="auto-field">
                <div class="label">التاريخ</div>
                <div class="value">{{ now()->format('Y-m-d') }}</div>
            </div>
            <div class="auto-field">
                <div class="label">اليوم</div>
                <div class="value">{{ now()->locale('ar')->dayName }}</div>
            </div>
            <div class="auto-field">
                <div class="label">الوقت</div>
                <div class="value">{{ now()->format('H:i') }}</div>
            </div>
        </div>
    </div>

    {{-- Basic Info --}}
    <div class="card-section">
        <h3>🏥 معلومات التدريب</h3>
        <div class="form-row">
            <div class="form-group">
                <label class="form-label">المركز التدريبي <span style="color:red">*</span></label>
                <select name="training_center_id" class="form-select" required>
                    <option value="">-- اختر المركز --</option>
                    @foreach($centers as $c)<option value="{{ $c->id }}">{{ $c->name }}</option>@endforeach
                </select>
            </div>
            <div class="form-group">
                <label class="form-label">القسم <span style="color:red">*</span></label>
                <select name="department_id" class="form-select" required>
                    <option value="">-- اختر القسم --</option>
                    @foreach($departments as $d)<option value="{{ $d->id }}">{{ $d->name }}</option>@endforeach
                </select>
            </div>
        </div>
        <div class="form-group">
            <label class="form-label">الدكتور المشرف <span style="color:red">*</span></label>
            <select name="doctor_id" class="form-select" required>
                <option value="">-- اختر الدكتور --</option>
                @foreach($doctors as $doc)<option value="{{ $doc->id }}">د. {{ $doc->name }}</option>@endforeach
            </select>
        </div>
    </div>

    {{-- History Taking --}}
    <div class="card-section">
        <div class="activity-section history">
            <div class="activity-header">
                <h4>📋 القصص المرضية (History Taking)</h4>
                <span class="count-badge" id="historyCount">0</span>
            </div>
            <div id="histories-container"></div>
            <button type="button" class="btn-add" onclick="addHistory()">+ إضافة قصة مرضية</button>
        </div>
    </div>

    {{-- Clinical Examination --}}
    <div class="card-section">
        <div class="activity-section exam">
            <div class="activity-header">
                <h4>🩺 الفحوصات السريرية (Clinical Examination)</h4>
                <span class="count-badge" id="examCount">0</span>
            </div>
            <div id="exams-container"></div>
            <button type="button" class="btn-add" onclick="addExam()">+ إضافة فحص سريري</button>
        </div>
    </div>

    {{-- Round --}}
    <div class="card-section">
        <div class="activity-section round">
            <div class="activity-header">
                <h4>🔄 المرور (Round)</h4>
            </div>
            <div class="round-check">
                <input type="checkbox" name="did_round" id="didRound" value="1" onchange="toggleRound()">
                <label for="didRound">نعم، قمت بالمرور (Round) اليوم</label>
            </div>
            <div id="rounds-section" style="display:none;">
                <div id="rounds-container"></div>
                <button type="button" class="btn-add" onclick="addRound()">+ إضافة حالة شوهدت في المرور</button>
                <div class="form-group" style="margin-top:0.75rem;">
                    <label class="form-label">ملاحظات المرور</label>
                    <textarea name="round_notes" class="form-control" rows="2" placeholder="ملاحظات إضافية عن المرور..."></textarea>
                </div>
            </div>
        </div>
    </div>

    <button type="submit" class="btn-submit">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="3" width="7" height="7"></rect>
            <rect x="14" y="3" width="7" height="7"></rect>
            <rect x="3" y="14" width="7" height="7"></rect>
            <rect x="14" y="14" width="7" height="7"></rect>
        </svg>
        إنشاء الباركود والتوقيع
    </button>
</form>
@endsection

@push('scripts')
@php $bodySysJson = $bodySystems->toArray(); @endphp
<script>
    const bodySystems = @json($bodySysJson);
    let historyIdx = 0,
        examIdx = 0,
        roundIdx = 0;

    function createSystemSelect(name) {
        let opts = '<option value="">-- اختر الجهاز --</option>';
        bodySystems.forEach(s => opts += `<option value="${s.id}">${s.name}</option>`);
        return `<select name="${name}" class="form-select" required>${opts}</select>`;
    }

    function addHistory() {
        const c = document.getElementById('histories-container');
        const d = document.createElement('div');
        d.className = 'activity-item';
        d.innerHTML = `<span class="num">${historyIdx+1}</span>${createSystemSelect('histories['+historyIdx+'][body_system_id]')}<button type="button" class="btn-remove" onclick="this.parentElement.remove();updateCounts()">×</button>`;
        c.appendChild(d);
        historyIdx++;
        updateCounts();
    }

    function addExam() {
        const c = document.getElementById('exams-container');
        const d = document.createElement('div');
        d.className = 'activity-item';
        d.innerHTML = `<span class="num">${examIdx+1}</span>${createSystemSelect('exams['+examIdx+'][body_system_id]')}<button type="button" class="btn-remove" onclick="this.parentElement.remove();updateCounts()">×</button>`;
        c.appendChild(d);
        examIdx++;
        updateCounts();
    }

    function addRound() {
        const c = document.getElementById('rounds-container');
        const d = document.createElement('div');
        d.className = 'activity-item';
        d.innerHTML = `<span class="num">${roundIdx+1}</span><input type="text" name="rounds[${roundIdx}][case_name]" class="form-control" placeholder="اسم الحالة التي شوهدت..." required><button type="button" class="btn-remove" onclick="this.parentElement.remove()">×</button>`;
        c.appendChild(d);
        roundIdx++;
    }

    function toggleRound() {
        document.getElementById('rounds-section').style.display = document.getElementById('didRound').checked ? 'block' : 'none';
    }

    function updateCounts() {
        document.getElementById('historyCount').textContent = document.getElementById('histories-container').children.length;
        document.getElementById('examCount').textContent = document.getElementById('exams-container').children.length;
    }
</script>
@endpush