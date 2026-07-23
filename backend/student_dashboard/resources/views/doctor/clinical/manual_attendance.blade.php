@extends('layouts.doctor')
@section('title', 'تحضير يدوي')
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
        text-decoration: none;
    }

    .card-section {
        background: white;
        border-radius: 18px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
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
        padding: 0.65rem 0.85rem;
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

    .btn-submit {
        background: linear-gradient(135deg, #059669, #10b981);
        color: white;
        border: none;
        padding: 0.75rem 2rem;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.95rem;
        cursor: pointer;
        box-shadow: 0 2px 8px rgba(5, 150, 105, 0.25);
    }

    .btn-submit:hover {
        transform: translateY(-1px);
    }

    .alert-success {
        background: #d1fae5;
        color: #065f46;
        border: 1px solid #a7f3d0;
        padding: 0.85rem 1rem;
        border-radius: 10px;
        margin-bottom: 1rem;
        font-weight: 600;
    }
</style>

<div class="clinical-page-header">
    <div class="right-side">
        <h1>✍ تحضير يدوي</h1>
        <p>تسجيل حضور طالب بدون مسح الباركود</p>
    </div>
    <div class="left-side"><a href="{{ route('doctor.clinical.scanner') }}" class="btn-back"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg> ماسح QR</a></div>
</div>

@if(session('success'))
<div class="alert-success">{{ session('success') }}</div>
@endif

<div class="card-section">
    <form action="{{ route('doctor.clinical.manual-attendance.store') }}" method="POST">
        @csrf
        <div class="form-group">
            <label class="form-label">الطالب <span style="color:red">*</span></label>
            <select name="student_id" class="form-select" required>
                <option value="">-- اختر الطالب --</option>
                @foreach($students as $s)<option value="{{ $s->id }}">{{ $s->name }} ({{ $s->student_number ?? '-' }})</option>@endforeach
            </select>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label class="form-label">المركز التدريبي <span style="color:red">*</span></label>
                <select name="training_center_id" class="form-select" required>
                    <option value="">-- اختر --</option>
                    @foreach($trainingCenters as $c)<option value="{{ $c->id }}">{{ $c->name }}</option>@endforeach
                </select>
            </div>
            <div class="form-group">
                <label class="form-label">القسم <span style="color:red">*</span></label>
                <select name="department_id" class="form-select" required>
                    <option value="">-- اختر --</option>
                    @foreach($departments as $d)<option value="{{ $d->id }}">{{ $d->name }}</option>@endforeach
                </select>
            </div>
        </div>
        <div class="form-group">
            <label class="form-label">ملاحظات (اختياري)</label>
            <textarea name="doctor_notes" class="form-control" rows="2" placeholder="ملاحظات..."></textarea>
        </div>
        <button type="submit" class="btn-submit">✅ تسجيل الحضور يدوياً</button>
    </form>
</div>
@endsection