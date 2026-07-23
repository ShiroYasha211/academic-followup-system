@extends('layouts.delegate')

@section('title', 'إضافة طالب جديد')

@section('content')
<div class="container fade-in" style="max-width: 800px; padding: 1rem;">

    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="font-weight-bold mb-2">تسجيل طالب جديد</h2>
            <p class="text-muted">إضافة طالب جديد إلى الدفعة الحالية ({{ Auth::user()->level->name ?? '-' }})</p>
        </div>
        <a href="{{ route('delegate.students.index') }}" class="btn btn-outline-secondary btn-sm px-3">
            عودة للقائمة
        </a>
    </div>

    <div class="card border-0 shadow-sm">
        <div class="card-body p-4">

            @if ($errors->any())
            <div class="alert alert-danger mb-4">
                <ul class="mb-0 small">
                    @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
            @endif

            <form action="{{ route('delegate.students.store') }}" method="POST">
                @csrf

                <div class="row g-3 mb-3">
                    <div class="col-md-6">
                        <label class="form-label font-weight-bold small text-uppercase">الرقم الجامعي <span class="text-danger">*</span></label>
                        <input type="text" name="student_number" class="form-control" required value="{{ old('student_number') }}" placeholder="Ex: 20231010">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label font-weight-bold small text-uppercase">الاسم الكامل <span class="text-danger">*</span></label>
                        <input type="text" name="name" class="form-control" required value="{{ old('name') }}" placeholder="الاسم الرباعي">
                    </div>
                </div>

                <div class="mb-3">
                    <label class="form-label font-weight-bold small text-uppercase">البريد الإلكتروني <span class="text-danger">*</span></label>
                    <input type="email" name="email" class="form-control" value="{{ old('email') }}" placeholder="student@university.edu.ye">
                </div>

                <div class="mb-3">
                    <label class="form-label font-weight-bold small text-uppercase">الجنس <span class="text-danger">*</span></label>
                    <select name="gender" class="form-control" required>
                        <option value="">اختر الجنس</option>
                        <option value="male" {{ old('gender') === 'male' ? 'selected' : '' }}>ذكر</option>
                        <option value="female" {{ old('gender') === 'female' ? 'selected' : '' }}>أنثى</option>
                    </select>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-md-6">
                        <label class="form-label font-weight-bold small text-uppercase">كلمة المرور <span class="text-danger">*</span></label>
                        <input type="password" name="password" class="form-control">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label font-weight-bold small text-uppercase">تأكيد كلمة المرور</label>
                        <input type="password" name="password_confirmation" class="form-control">
                    </div>
                </div>

                <div class="alert alert-light border small text-muted mb-4">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-2 text-primary">
                        <circle cx="12" cy="12" r="10"></circle>
                        <line x1="12" y1="16" x2="12" y2="12"></line>
                        <line x1="12" y1="8" x2="12.01" y2="8"></line>
                    </svg>
                    سيتم تسجيل الطالب تلقائياً في <strong>{{ Auth::user()->major->name ?? '' }} - {{ Auth::user()->level->name ?? '' }}</strong>.
                </div>

                <div class="d-grid gap-2">
                    <button type="submit" class="btn btn-primary py-2 font-weight-bold">حفظ بيانات الطالب</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
