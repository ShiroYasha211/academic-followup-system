@php
    $layout = 'layouts.doctor';
    if (request()->is('delegate/*')) $layout = 'layouts.delegate';
    elseif (request()->is('student/*')) $layout = 'layouts.student';
@endphp
@extends($layout)

@section('title', 'إدراج حالة سريرية جديدة')

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

    .form-control,
    .form-select {
        width: 100%;
        padding: 0.75rem 1rem;
        font-size: 0.95rem;
        border: 1px solid #cbd5e1;
        border-radius: 10px;
        background: #f8fafc;
        transition: all 0.2s;
        font-family: inherit;
    }

    .form-control:focus,
    .form-select:focus {
        outline: none;
        border-color: var(--primary-color);
        background: white;
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
    }

    .form-control.is-invalid,
    .form-select.is-invalid {
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
        text-decoration: none;
    }

    .error-msg {
        color: #ef4444;
        font-size: 0.8rem;
        margin-top: 0.25rem;
        display: block;
    }
</style>

<div class="dashboard-header">
    <div class="welcome-text">
        <h1>إدراج مريض / حالة جديدة</h1>
        <p>إضافة بيانات مريض جديد إلى القسم السريري لغايات التدريب</p>
    </div>
</div>

<div class="card-section">
    @php
        $routePrefix = request()->is('student/*') ? 'student' : (request()->is('delegate/*') ? 'delegate' : 'doctor');
    @endphp
    <form action="{{ route($routePrefix . '.clinical.cases.store') }}" method="POST">
        @csrf

        <div class="row">
            <div class="col-md-6 mb-3">
                <div class="form-group">
                    <label class="form-label">اسم الحالة / المريض <span style="color:red">*</span></label>
                    <input type="text" name="patient_name" class="form-control @error('patient_name') is-invalid @enderror" value="{{ old('patient_name') }}" required placeholder="الاسم الكامل أو اسم مستعار">
                    @error('patient_name') <span class="error-msg">{{ $message }}</span> @enderror
                </div>
            </div>

            <div class="col-md-3 mb-3">
                <div class="form-group">
                    <label class="form-label">العمر (اختياري)</label>
                    <input type="number" name="age" class="form-control" value="{{ old('age') }}" placeholder="أدخل ارقام فقط">
                </div>
            </div>

            <div class="col-md-3 mb-3">
                <div class="form-group">
                    <label class="form-label">الجنس</label>
                    <select name="gender" class="form-select">
                        <option value="">- غير محدد -</option>
                        <option value="male" {{ old('gender') == 'male' ? 'selected' : '' }}>ذكر</option>
                        <option value="female" {{ old('gender') == 'female' ? 'selected' : '' }}>أنثى</option>
                    </select>
                </div>
            </div>

            <div class="col-md-4 mb-3">
                <div class="form-group">
                    <label class="form-label">المركز التدريبي / المستشفى <span style="color:red">*</span></label>
                    <select name="training_center_id" class="form-select select2 @error('training_center_id') is-invalid @enderror" required>
                        <option value="">-- اختر المركز --</option>
                        @foreach($centers as $c)
                        <option value="{{ $c->id }}" {{ old('training_center_id') == $c->id ? 'selected' : '' }}>{{ $c->name }}</option>
                        @endforeach
                    </select>
                    @error('training_center_id') <span class="error-msg">{{ $message }}</span> @enderror
                </div>
            </div>

            <div class="col-md-4 mb-3">
                <div class="form-group">
                    <label class="form-label">القسم الطبي <span style="color:red">*</span></label>
                    <select name="clinical_department_id" class="form-select select2 @error('clinical_department_id') is-invalid @enderror" required>
                        <option value="">-- اختر القسم --</option>
                        @foreach($departments as $d)
                        <option value="{{ $d->id }}" {{ old('clinical_department_id') == $d->id ? 'selected' : '' }}>{{ $d->name }}</option>
                        @endforeach
                    </select>
                    @error('clinical_department_id') <span class="error-msg">{{ $message }}</span> @enderror
                </div>
            </div>

            <div class="col-md-4 mb-3">
                <div class="form-group">
                    <label class="form-label">الجهاز المرضي (Body System) <span style="color:red">*</span></label>
                    <select name="body_system_id" class="form-select select2 @error('body_system_id') is-invalid @enderror" required>
                        <option value="">-- اختر الجهاز --</option>
                        @foreach($systems as $s)
                        <option value="{{ $s->id }}" {{ old('body_system_id') == $s->id ? 'selected' : '' }}>{{ $s->name }}</option>
                        @endforeach
                    </select>
                    @error('body_system_id') <span class="error-msg">{{ $message }}</span> @enderror
                </div>
            </div>

            <div class="col-md-8 mb-3">
                <div class="form-group">
                    <label class="form-label">التشخيص الأولي / وصف الحالة الطبي (اختياري)</label>
                    <textarea name="diagnosis_or_description" class="form-control" placeholder="اكتب التشخيص أو العلامات الحيوية البارزة...">{{ old('diagnosis_or_description') }}</textarea>
                </div>
            </div>

            <div class="col-md-4 mb-3">
                <div class="form-group">
                    <label class="form-label">حالة المريض <span style="color:red">*</span></label>
                    <select name="status" class="form-select" required>
                        <option value="active" {{ old('status', 'active') == 'active' ? 'selected' : '' }}>نشطة في القسم</option>
                        <option value="discharged" {{ old('status') == 'discharged' ? 'selected' : '' }}>خرج (Discharged)</option>
                        <option value="transferred" {{ old('status') == 'transferred' ? 'selected' : '' }}>مُحول لقسم/مستشفى آخر</option>
                    </select>
                </div>
            </div>
        </div>

        <div style="display: flex; gap: 1rem; margin-top: 1.5rem; padding-top: 1.5rem; border-top: 1px solid #f1f5f9;">
            <button type="submit" class="btn-submit">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                    <polyline points="17 21 17 13 7 13 7 21"></polyline>
                    <polyline points="7 3 7 8 15 8"></polyline>
                </svg>
                إدراج الحالة
            </button>
            <a href="{{ route($routePrefix . '.clinical.cases.index') }}" class="btn-cancel">إلغاء</a>
        </div>
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