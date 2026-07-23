@extends('layouts.administrative')

@section('title', 'إعدادات الكلية')

@section('content')
<div class="container-fluid py-4">
    <div class="card shadow-sm border-0">
        <div class="card-body p-4">
            <div class="mb-4">
                <h1 class="h4 mb-1">إعدادات الكلية</h1>
                <p class="text-muted mb-0">ضبط مسار الأعذار ومهلة تقديمها وزمن تدوير QR.</p>
            </div>

            <form action="{{ route('administrative.settings.update') }}" method="POST" class="row g-4">
                @csrf
                @method('PUT')

                <div class="col-md-6">
                    <label class="form-label">نسبة الحرمان (%)</label>
                    <input type="number" name="absence_deprivation_percentage" class="form-control" min="1" max="100"
                        value="{{ old('absence_deprivation_percentage', $college->absence_deprivation_percentage) }}" required>
                    @error('absence_deprivation_percentage')
                        <div class="text-danger small mt-1">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-md-6">
                    <label class="form-label">مهلة تقديم العذر بالأيام</label>
                    <input type="number" name="excuses_deadline_days" class="form-control" min="1" max="30"
                        value="{{ old('excuses_deadline_days', $college->excuses_deadline_days) }}" required>
                    @error('excuses_deadline_days')
                        <div class="text-danger small mt-1">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-md-6">
                    <label class="form-label">مستقبل الأعذار الجديدة</label>
                    <select name="excuse_receiver" class="form-select" required>
                        <option value="administrative" @selected(old('excuse_receiver', $college->excuse_receiver) === 'administrative')>المسؤول الإداري</option>
                        <option value="doctor" @selected(old('excuse_receiver', $college->excuse_receiver) === 'doctor')>دكتور المادة</option>
                    </select>
                    <div class="form-text">إذا اخترت الدكتور فسيتم توجيه الأعذار الجديدة إليه لاتخاذ القرار النهائي.</div>
                    @error('excuse_receiver')
                        <div class="text-danger small mt-1">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-md-6">
                    <label class="form-label">زمن تدوير QR بالثواني</label>
                    <input type="number" name="qr_rotation_seconds" class="form-control" min="5" max="300"
                        value="{{ old('qr_rotation_seconds', $college->qr_rotation_seconds ?? 30) }}" required>
                    @error('qr_rotation_seconds')
                        <div class="text-danger small mt-1">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-md-6">
                    <label class="form-label">الرصيد الابتدائي لمنح النجوم للدكتور</label>
                    <input type="number" name="doctor_initial_star_balance" class="form-control" min="0" max="1000000"
                        value="{{ old('doctor_initial_star_balance', $college->doctor_initial_star_balance ?? 50) }}" required>
                    <div class="form-text">يطبق على محافظ الدكاترة الجدد. يمكن إضافة رصيد منفصل لأي دكتور من صفحة إدارة الدكاترة.</div>
                    @error('doctor_initial_star_balance')
                        <div class="text-danger small mt-1">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-12">
                    <div class="alert alert-info mb-0">
                        عند قبول العذر سيتم اختيار إحدى النتائج التالية: مستأذن، إعفاء، أو إبقاء الطالب غائبًا.
                    </div>
                </div>

                <div class="col-12 d-flex justify-content-end">
                    <button type="submit" class="btn btn-primary px-4">حفظ الإعدادات</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
