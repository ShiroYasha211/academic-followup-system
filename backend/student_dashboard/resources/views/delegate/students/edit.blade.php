@extends('layouts.delegate')

@section('title', 'تعديل بيانات الطالب')

@section('content')
<div class="container fade-in" style="max-width: 800px; padding: 1rem;">

    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="font-weight-bold mb-2">تعديل بيانات الطالب</h2>
            <p class="text-muted">تحديث بيانات الطالب: {{ $student->name }}</p>
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

            <form action="{{ route('delegate.students.update', $student->id) }}" method="POST">
                @csrf
                @method('PUT')

                <div class="row g-3 mb-3">
                    <div class="col-md-6">
                        <label class="form-label font-weight-bold small text-uppercase">الرقم الجامعي <span class="text-danger">*</span></label>
                        <input type="text" name="student_number" class="form-control" required value="{{ old('student_number', $student->student_number) }}">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label font-weight-bold small text-uppercase">الاسم الكامل <span class="text-danger">*</span></label>
                        <input type="text" name="name" class="form-control" required value="{{ old('name', $student->name) }}">
                    </div>
                </div>

                <div class="mb-3">
                    <label class="form-label font-weight-bold small text-uppercase">البريد الإلكتروني <span class="text-danger">*</span></label>
                    <input type="email" name="email" class="form-control" value="{{ old('email', $student->email) }}">
                </div>

                <div class="mb-3">
                    <label class="form-label font-weight-bold small text-uppercase">الجنس <span class="text-danger">*</span></label>
                    <select name="gender" class="form-control" required>
                        <option value="">اختر الجنس</option>
                        <option value="male" {{ old('gender', $student->gender) === 'male' ? 'selected' : '' }}>ذكر</option>
                        <option value="female" {{ old('gender', $student->gender) === 'female' ? 'selected' : '' }}>أنثى</option>
                    </select>
                </div>

                <div class="alert alert-light border small text-muted mb-4 d-flex align-items-center">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-2">
                        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                        <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                    </svg>
                    اترك حقول كلمة المرور فارغة إذا كنت لا تريد تغييرها.
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-md-6">
                        <label class="form-label font-weight-bold small text-uppercase">كلمة المرور الجديدة</label>
                        <input type="password" name="password" class="form-control">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label font-weight-bold small text-uppercase">تأكيد كلمة المرور</label>
                        <input type="password" name="password_confirmation" class="form-control">
                    </div>
                </div>

                <div class="d-grid gap-2">
                    <button type="submit" class="btn btn-primary py-2 font-weight-bold">حفظ التغييرات</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
