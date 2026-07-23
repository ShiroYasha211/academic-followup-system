@extends('layouts.doctor')

@section('title', isset($volunteer) ? 'تعديل بيانات المتطوع' : 'إضافة متطوع جديد')

@section('content')
<style>
    .premium-form-card {
        max-width: 850px;
        margin: 2rem auto;
        background: white;
        border-radius: 30px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05);
    }

    .form-header-banner {
        background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
        padding: 3rem 2.5rem;
        color: white;
        text-align: right;
        position: relative;
    }

    .form-header-banner i {
        position: absolute;
        left: 30px;
        top: 50%;
        transform: translateY(-50%);
        font-size: 5rem;
        opacity: 0.15;
    }

    .form-body-content {
        padding: 3rem 3.5rem;
    }

    .input-wrapper {
        margin-bottom: 2rem;
    }

    .premium-label {
        display: block;
        font-weight: 800;
        color: #1e293b;
        margin-bottom: 0.75rem;
        font-size: 0.95rem;
        letter-spacing: -0.2px;
    }

    .premium-input {
        width: 100%;
        padding: 1rem 1.25rem;
        background: #f8fafc;
        border: 2px solid #f1f5f9;
        border-radius: 16px;
        font-weight: 700;
        font-size: 1rem;
        color: #1e293b;
        transition: all 0.3s;
    }

    .premium-input:focus {
        background: white;
        border-color: #4f46e5;
        box-shadow: 0 0 0 5px rgba(79, 70, 229, 0.1);
        outline: none;
    }

    .premium-textarea {
        min-height: 140px;
        resize: vertical;
    }

    .submit-btn-premium {
        background: #4f46e5;
        color: white;
        padding: 1.1rem 3rem;
        border-radius: 18px;
        font-weight: 900;
        font-size: 1.1rem;
        border: none;
        width: 100%;
        transition: all 0.3s;
        box-shadow: 0 4px 6px -1px rgba(79, 70, 229, 0.2);
        margin-top: 1rem;
    }

    .submit-btn-premium:hover {
        background: #4338ca;
        transform: translateY(-3px);
        box-shadow: 0 20px 25px -5px rgba(79, 70, 229, 0.25);
    }

    .cancel-link-premium {
        display: block;
        text-align: center;
        margin-top: 2rem;
        color: #64748b;
        font-weight: 800;
        font-size: 0.95rem;
        text-decoration: none;
        transition: color 0.2s;
    }

    .cancel-link-premium:hover {
        color: #1e293b;
    }

    /* Selection Indicator for radio/checkbox if needed */
    .field-hint {
        font-size: 0.8rem;
        color: #94a3b8;
        font-weight: 600;
        margin-top: 0.5rem;
        display: block;
    }

    @media (max-width: 768px) {
        .form-body-content {
            padding: 2rem 1.5rem;
        }
    }
</style>

<div class="premium-form-card">
    <div class="form-header-banner">
        <i class="fa-solid fa-address-book"></i>
        <h2 class="fw-900 mb-2">{{ isset($volunteer) ? 'تعديل بيانات المتطوع' : 'إضافة متطوع جديد' }}</h2>
        <p class="opacity-75 fw-600 mb-0">بيانات هذا السجل مشفرة وخاصة بك فقء لا تظهر للطلاب أو الإدارة.</p>
    </div>

    <div class="form-body-content">
        <form action="{{ isset($volunteer) ? route('doctor.clinical.volunteers.update', $volunteer->id) : route('doctor.clinical.volunteers.store') }}" method="POST">
            @csrf
            @if(isset($volunteer)) @method('PUT') @endif

            <!-- Name Field -->
            <div class="input-wrapper">
                <label class="premium-label">إسم المتطوع / المريض</label>
                <input type="text" name="name" class="premium-input @error('name') is-invalid @enderror" value="{{ old('name', $volunteer->name ?? '') }}" placeholder="أدخل الاسم الثلاثي بالكامل" required>
                @error('name') <div class="invalid-feedback fw-bold mt-2">{{ $message }}</div> @enderror
            </div>

            <div class="row">
                <div class="col-md-7">
                    <div class="input-wrapper" x-data="{ showSecond: {{ old('phone_secondary', $volunteer->phone_secondary ?? '') ? 'true' : 'false' }} }">
                        <label class="premium-label d-flex justify-content-between align-items-center">
                            <span>بيانات الاتصال (الهاتف)</span>
                            <button type="button" @click="showSecond = !showSecond" class="btn btn-sm p-0 text-primary fw-bold" style="font-size: 0.8rem;">
                                <i class="fa-solid" :class="showSecond ? 'fa-minus-circle' : 'fa-plus-circle'"></i>
                                <span x-text="showSecond ? ' إزالة الرقم الإضافي' : ' إضافة رقم آخر'"></span>
                            </button>
                        </label>
                        <input type="text" name="contact_info" class="premium-input @error('contact_info') is-invalid @enderror" value="{{ old('contact_info', $volunteer->contact_info ?? '') }}" placeholder="رقم الهاتف الأساسي" required>
                        @error('contact_info') <div class="invalid-feedback fw-bold mt-2">{{ $message }}</div> @enderror
                        
                        <div x-show="showSecond" x-transition class="mt-3">
                            <input type="text" name="phone_secondary" class="premium-input @error('phone_secondary') is-invalid @enderror" value="{{ old('phone_secondary', $volunteer->phone_secondary ?? '') }}" placeholder="رقم هاتف إضافي (اختياري)">
                            @error('phone_secondary') <div class="invalid-feedback fw-bold mt-2">{{ $message }}</div> @enderror
                        </div>
                    </div>
                </div>
                <div class="col-md-5">
                    <div class="input-wrapper">
                        <label class="premium-label">البريد الإلكتروني (اختياري)</label>
                        <input type="email" name="email" class="premium-input @error('email') is-invalid @enderror" value="{{ old('email', $volunteer->email ?? '') }}" placeholder="example@mail.com">
                        @error('email') <div class="invalid-feedback fw-bold mt-2">{{ $message }}</div> @enderror
                    </div>
                </div>
            </div>

            <div class="input-wrapper">
                <label class="premium-label">التشخيص الطبي (Primary Diagnosis)</label>
                <input type="text" name="diagnosis" class="premium-input @error('diagnosis') is-invalid @enderror" value="{{ old('diagnosis', $volunteer->diagnosis ?? '') }}" placeholder="مثال: Chronic Heart Failure / ضيق في الصمام الميترالي" required>
                @error('diagnosis') <div class="invalid-feedback fw-bold mt-2">{{ $message }}</div> @enderror
            </div>

            <div class="input-wrapper">
                <label class="premium-label">العلامات والنتائج السريرية (Clinical Signs & Findings)</label>
                <textarea name="clinical_signs" class="premium-input premium-textarea @error('clinical_signs') is-invalid @enderror" placeholder="وصف مفصل للعلامات التي يمكن للطلاب التدريب عليها (مثال: Murmur grade 3/6, Hepatomegaly...)">{{ old('clinical_signs', $volunteer->clinical_signs ?? '') }}</textarea>
                <span class="field-hint">هذا الوصف سيظهر لك في البطاقة لمساعدتك في تذكر ميزات الحالة.</span>
                @error('clinical_signs') <div class="invalid-feedback fw-bold mt-2">{{ $message }}</div> @enderror
            </div>

            <button type="submit" class="submit-btn-premium">
                <i class="fa-solid fa-save me-2"></i>
                {{ isset($volunteer) ? 'تحديث بيانات المتطوع' : 'حفظ في السجل السري' }}
            </button>

            <a href="{{ route('doctor.clinical.volunteers.index') }}" class="cancel-link-premium">
                <i class="fa-solid fa-arrow-right me-1"></i>
                إلغاء والعودة للقائمة
            </a>
        </form>
    </div>
</div>
@endsection
