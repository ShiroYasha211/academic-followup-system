@extends('layouts.doctor')
@section('title', 'بدء تقييم مباشر')
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
        font-size: 1.6rem;
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
        padding: 2rem;
        max-width: 600px;
        margin: 0 auto;
    }

    .form-group {
        margin-bottom: 1.25rem;
    }

    .form-label {
        display: block;
        font-weight: 600;
        font-size: 0.9rem;
        color: var(--text-primary);
        margin-bottom: 0.45rem;
    }

    .form-select {
        width: 100%;
        padding: 0.7rem 0.85rem;
        font-size: 0.9rem;
        border: 1.5px solid #e2e8f0;
        border-radius: 10px;
        background: #f8fafc;
        font-family: inherit;
    }

    .form-select:focus {
        outline: none;
        border-color: var(--primary-color);
        background: white;
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.08);
    }

    .btn-start {
        background: linear-gradient(135deg, #059669, #10b981);
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
        box-shadow: 0 2px 8px rgba(5, 150, 105, 0.25);
        transition: all 0.2s;
    }

    .btn-start:hover {
        transform: translateY(-1px);
        box-shadow: 0 4px 14px rgba(5, 150, 105, 0.35);
    }
</style>

<div class="clinical-page-header">
    <div class="right-side">
        <h1>بدء تقييم مباشر 🎯</h1>
        <p>اختر قائمة التقييم والطالب لبدء الفحص العملي</p>
    </div>
    <div class="left-side"><a href="{{ route('doctor.clinical.evaluations.checklists') }}" class="btn-back"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg> قوائم التقييم</a></div>
</div>

<div class="card-section">
    <form action="{{ route('doctor.clinical.evaluations.live') }}" method="POST">
        @csrf
        <div class="form-group">
            <label class="form-label">نوع الإجراء <span style="color:red">*</span></label>
            <select name="procedure_type" class="form-select" required>
                <option value="history_taking">قصة مرضية (History Taking)</option>
                <option value="clinical_examination">فحص سريري (Clinical Examination)</option>
                <option value="procedure">إجراء طبي (Procedure)</option>
                <option value="communication">مهارات تواصل (Communication)</option>
            </select>
        </div>
        <div class="form-group">
            <label class="form-label">الجهاز المرضي <span style="color:red">*</span></label>
            <select name="body_system_id" class="form-select select2" required>
                <option value="">-- اختر الجهاز --</option>
                @foreach(\App\Models\Clinical\BodySystem::all() as $bs)
                <option value="{{ $bs->id }}">{{ $bs->name }}</option>
                @endforeach
            </select>
        </div>
        <div class="form-group">
            <label class="form-label">قائمة التقييم <span style="color:red">*</span></label>
            <select name="checklist_id" class="form-select select2" required>
                <option value="">-- اختر القائمة --</option>
                @foreach($checklists as $cl)
                <option value="{{ $cl->id }}">{{ $cl->title }} ({{ $cl->skill_label }} — {{ $cl->time_limit_minutes }} د)</option>
                @endforeach
            </select>
        </div>
        <div class="form-group">
            <label class="form-label">الطالب <span style="color:red">*</span></label>
            <select name="student_id" class="form-select select2" required>
                <option value="">-- ابحث عن الطالب --</option>
                @foreach($students as $s)
                <option value="{{ $s->id }}">{{ $s->name }} ({{ $s->student_number ?? '-' }})</option>
                @endforeach
            </select>
        </div>
        <div class="form-group">
            <label class="form-label">نوع التوقيت</label>
            <select name="timer_type" class="form-select">
                <option value="fixed">⏱ وقت محدد (ينتهي التقييم عند انتهاء الوقت)</option>
                <option value="open">🔓 وقت مفتوح (يُحسب الوقت فقط)</option>
            </select>
        </div>
        <div class="form-group">
            <label class="form-label">الحالة السريرية (اختياري)</label>
            <select name="clinical_case_id" class="form-select select2">
                <option value="">-- بدون حالة --</option>
                @foreach($cases as $c)
                <option value="{{ $c->id }}">{{ $c->patient_name }}</option>
                @endforeach
            </select>
        </div>
        <button type="submit" class="btn-start">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polygon points="5 3 19 12 5 21 5 3"></polygon>
            </svg>
            بدء التقييم الآن
        </button>
    </form>
</div>
@endsection

@push('scripts')
<link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet" />
<script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>
<script>
    $(document).ready(function() {
        $('.select2').select2({
            dir: "rtl",
            width: '100%'
        });
    });
</script>
@endpush