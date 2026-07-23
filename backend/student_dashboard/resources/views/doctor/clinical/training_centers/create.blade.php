@extends('layouts.doctor')

@section('title', 'إضافة مركز تدريب سريري')

@section('content')

<style>
    .dashboard-header {
        margin-bottom: 2rem;
    }

    .welcome-text h1 {
        font-size: 1.75rem;
        font-weight: 800;
        color: var(--text-primary);
        margin-bottom: 0.25rem;
    }

    .card-section {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        padding: 2rem;
        max-width: 800px;
        margin: 0 auto;
    }

    .form-group {
        margin-bottom: 1.5rem;
    }

    .form-label {
        display: block;
        font-weight: 600;
        font-size: 0.9rem;
        color: var(--text-primary);
        margin-bottom: 0.5rem;
    }

    .form-control {
        width: 100%;
        padding: 0.75rem 1rem;
        font-size: 0.95rem;
        border: 1px solid #cbd5e1;
        border-radius: 10px;
        background: #f8fafc;
        transition: all 0.2s;
        font-family: inherit;
    }

    .form-control:focus {
        outline: none;
        border-color: var(--primary-color);
        background: white;
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
    }

    .form-control.is-invalid {
        border-color: #ef4444;
        background: #fef2f2;
    }

    textarea.form-control {
        resize: vertical;
        min-height: 100px;
    }

    .btn-submit {
        background: var(--primary-color);
        color: white;
        border: none;
        padding: 0.75rem 2rem;
        border-radius: 10px;
        font-weight: 600;
        font-size: 1rem;
        cursor: pointer;
        transition: all 0.2s;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
    }

    .btn-submit:hover {
        background: #4338ca;
        transform: translateY(-1px);
    }

    .btn-cancel {
        background: #f1f5f9;
        color: var(--text-secondary);
        text-decoration: none;
        padding: 0.75rem 1.5rem;
        border-radius: 10px;
        font-weight: 600;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        transition: all 0.2s;
    }

    .btn-cancel:hover {
        background: #e2e8f0;
        color: var(--text-primary);
    }

    .error-msg {
        color: #ef4444;
        font-size: 0.8rem;
        margin-top: 0.25rem;
        display: block;
    }
</style>

<div class="dashboard-header" style="max-width: 800px; margin-left: auto; margin-right: auto;">
    <div class="welcome-text">
        <h1>إضافة مركز جديد</h1>
    </div>
</div>

<div class="card-section">
    <form action="{{ route('doctor.clinical.training-centers.store') }}" method="POST">
        @csrf

        <div class="form-group">
            <label class="form-label">اسم المركز / المستشفى <span style="color:red">*</span></label>
            <input type="text" name="name" class="form-control @error('name') is-invalid @enderror" value="{{ old('name') }}" placeholder="مثال: مستشفى الجامعة" required>
            @error('name') <span class="error-msg">{{ $message }}</span> @enderror
        </div>

        <div class="form-group">
            <label class="form-label">الموقع (اختياري)</label>
            <input type="text" name="location" class="form-control" value="{{ old('location') }}" placeholder="المدينة، الشارع..">
        </div>

        <div class="form-group">
            <label class="form-label">وصف المركز (اختياري)</label>
            <textarea name="description" class="form-control" placeholder="معلومات عن المركز أو الأقسام المتاحة فيه...">{{ old('description') }}</textarea>
        </div>

        <div style="display: flex; gap: 1rem; margin-top: 2rem;">
            <button type="submit" class="btn-submit">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                    <polyline points="17 21 17 13 7 13 7 21"></polyline>
                    <polyline points="7 3 7 8 15 8"></polyline>
                </svg>
                حفظ المركز
            </button>
            <a href="{{ route('doctor.clinical.training-centers.index') }}" class="btn-cancel">
                إلغاء
            </a>
        </div>
    </form>
</div>
@endsection