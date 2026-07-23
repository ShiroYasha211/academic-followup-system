@extends('layouts.doctor')

@section('title', 'تقرير الحضور')

@section('content')
<div class="container py-4">
    <div class="card border-0 shadow-sm">
        <div class="card-body text-center py-5">
            <h1 class="h4 mb-3">تقرير الحضور</h1>
            <p class="text-muted mb-4">تم نقل عرض التقرير إلى النسخة المحدثة من صفحة التقرير.</p>
            <a href="{{ route('doctor.attendance.index') }}" class="btn btn-primary">العودة إلى الحضور</a>
        </div>
    </div>
</div>
@endsection
