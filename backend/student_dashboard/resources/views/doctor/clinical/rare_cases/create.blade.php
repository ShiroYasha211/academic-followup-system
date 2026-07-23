@extends('layouts.doctor')

@section('title', 'إعلان حالة نادرة جديدة')

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
        padding: 2.5rem;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .form-group {
        margin-bottom: 1.5rem;
    }

    .form-label {
        display: block;
        font-weight: 700;
        font-size: 0.95rem;
        color: var(--text-primary);
        margin-bottom: 0.75rem;
    }

    .form-control,
    .form-select {
        width: 100%;
        padding: 0.85rem 1.25rem;
        font-size: 1rem;
        border: 1.5px solid #e2e8f0;
        border-radius: 12px;
        background: #fdfdfd;
        transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .form-control:focus,
    .form-select:focus {
        outline: none;
        border-color: var(--primary-color);
        background: white;
        box-shadow: 0 0 0 4px rgba(79, 70, 229, 0.1);
    }

    .form-control.is-invalid {
        border-color: #ef4444;
        background: #fef2f2;
    }

    textarea.form-control {
        min-height: 120px;
    }

    .file-upload-wrapper {
        position: relative;
        border: 2px dashed #e2e8f0;
        border-radius: 12px;
        padding: 2rem;
        text-align: center;
        background: #f8fafc;
        transition: all 0.2s;
        cursor: pointer;
    }

    .file-upload-wrapper:hover {
        border-color: var(--primary-color);
        background: #f0f4ff;
    }

    .file-upload-input {
        position: absolute;
        inset: 0;
        opacity: 0;
        cursor: pointer;
    }

    .upload-icon {
        font-size: 2.5rem;
        color: #94a3b8;
        margin-bottom: 1rem;
    }

    .btn-submit {
        background: var(--primary-color);
        color: white;
        border: none;
        padding: 1rem 2.5rem;
        border-radius: 12px;
        font-weight: 700;
        font-size: 1.1rem;
        cursor: pointer;
        transition: all 0.3s;
        display: inline-flex;
        align-items: center;
        gap: 0.75rem;
        box-shadow: 0 4px 6px rgba(79, 70, 229, 0.2);
    }

    .btn-submit:hover {
        background: #4338ca;
        transform: translateY(-2px);
        box-shadow: 0 6px 12px rgba(79, 70, 229, 0.3);
    }

    .btn-cancel {
        background: #f1f5f9;
        color: var(--text-secondary);
        padding: 1rem 1.5rem;
        border-radius: 12px;
        font-weight: 600;
        text-decoration: none;
        transition: all 0.2s;
    }

    .btn-cancel:hover {
        background: #e2e8f0;
        color: var(--text-primary);
    }

    .required-star {
        color: #ef4444;
        margin-right: 4px;
    }

    .category-title {
        color: var(--primary-color);
        font-weight: 800;
        font-size: 1.1rem;
        margin-bottom: 1.5rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        border-bottom: 2px solid #f1f5f9;
        padding-bottom: 0.75rem;
    }
</style>

<div class="dashboard-header">
    <div class="welcome-text">
        <h1>إعلان حالة نادرة <span class="badge bg-danger ms-2" style="font-size: 0.8rem; vertical-align: middle; border-radius: 8px; padding: 5px 12px;">ميزة جديدة</span></h1>
        <p>قم بمشاركة الحالات السريرية النادرة مع الطلاب لتحسين جودة التدريب الميداني</p>
    </div>
</div>

<div class="card-section">
    <form action="{{ route('doctor.clinical.rare-cases.store') }}" method="POST" enctype="multipart/form-data">
        @csrf

        <div class="category-title">
            <i class="fa-solid fa-hospital-user"></i>
            المعلومات الأساسية وموقع الحالة
        </div>

        <div class="row">
            <div class="col-md-6">
                <div class="form-group">
                    <label class="form-label">اسم المريض (اختياري)</label>
                    <input type="text" name="patient_name" class="form-control" value="{{ old('patient_name') }}" placeholder="مثلاً: مريض ع.أ">
                </div>
            </div>
            <div class="col-md-6">
                <div class="form-group">
                    <label class="form-label">المستشفى / المركز التدريبي <span class="required-star">*</span></label>
                    <input type="text" name="hospital" class="form-control @error('hospital') is-invalid @enderror" value="{{ old('hospital') }}" required placeholder="أدخل اسم المنشأة الصحية">
                    @error('hospital') <p class="text-danger mt-1 small">{{ $message }}</p> @enderror
                </div>
            </div>
            <div class="col-md-6">
                <div class="form-group">
                    <label class="form-label">القسم الطبي <span class="required-star">*</span></label>
                    <input type="text" name="department" class="form-control @error('department') is-invalid @enderror" value="{{ old('department') }}" required placeholder="مثلاً: الباطنة، الجراحة، الطوارئ">
                    @error('department') <p class="text-danger mt-1 small">{{ $message }}</p> @enderror
                </div>
            </div>
            <div class="col-md-6">
                <div class="form-group">
                    <label class="form-label">رقم الغرفة (اختياري)</label>
                    <input type="text" name="room_number" class="form-control" value="{{ old('room_number') }}" placeholder="أدخل رقم الغرفة أو الطابق">
                </div>
            </div>
        </div>

        <div class="category-title mt-4">
            <i class="fa-solid fa-stethoscope"></i>
            التفاصيل الطبية والصور
        </div>

        <div class="row">
            <div class="col-md-12">
                <div class="form-group">
                    <label class="form-label">التشخيص (Diagnosis) <span class="required-star">*</span></label>
                    <input type="text" name="diagnosis" class="form-control @error('diagnosis') is-invalid @enderror" value="{{ old('diagnosis') }}" required placeholder="أدخل المسمى الطبي للحالة">
                    @error('diagnosis') <p class="text-danger mt-1 small">{{ $message }}</p> @enderror
                </div>
            </div>
            <div class="col-md-12">
                <div class="form-group">
                    <label class="form-label">العلامات السريرية البارزة</label>
                    <textarea name="clinical_signs" class="form-control" placeholder="اشرح للطلاب ماذا سيشاهدون عند زيارة الحالة (الأعراض، العلامات الحيوية، إلخ)">{{ old('clinical_signs') }}</textarea>
                </div>
            </div>
            <div class="col-md-12">
                <div class="form-group">
                    <label class="form-label">إرفاق صورة توضيحية (اختياري)</label>
                    <div class="file-upload-wrapper" id="uploadWrapper">
                        <i class="fa-solid fa-cloud-arrow-up upload-icon"></i>
                        <p class="mb-1 fw-bold">اسحب الصورة هنا أو اضغط للاختيار</p>
                        <p class="text-secondary small">JPEG, PNG, JPG (الحد الأقصى 5 ميجابايت)</p>
                        <input type="file" name="attachment" class="file-upload-input" accept="image/*" onchange="previewFile(this)">
                        <div id="filePreview" class="mt-3 d-none">
                            <span class="badge bg-success" id="fileName"></span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="mt-5 pt-4 border-top d-flex gap-3">
            <button type="submit" class="btn-submit">
                <i class="fa-solid fa-bullhorn"></i>
                نشر وإرسال تنبيه للطلاب
            </button>
            <a href="{{ route('doctor.clinical.rare-cases.index') }}" class="btn-cancel">إلغاء</a>
        </div>
    </form>
</div>
@endsection

@push('scripts')
<script>
    function previewFile(input) {
        const wrapper = document.getElementById('uploadWrapper');
        const preview = document.getElementById('filePreview');
        const nameDisplay = document.getElementById('fileName');
        
        if (input.files && input.files[0]) {
            preview.classList.remove('d-none');
            nameDisplay.innerHTML = '<i class="fa-solid fa-paperclip me-1"></i> ' + input.files[0].name;
            wrapper.style.borderColor = 'var(--primary-color)';
            wrapper.style.background = '#f0f4ff';
        }
    }
</script>
@endpush
