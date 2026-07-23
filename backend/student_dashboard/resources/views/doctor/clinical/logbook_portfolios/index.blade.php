@extends('layouts.doctor')

@section('title', 'تقارير إنجازات الطلاب العملية')

@section('content')
<style>
    .portfolio-hero {
        background: linear-gradient(135deg, #0f172a 0%, #1d4ed8 55%, #0f766e 100%);
        border-radius: 28px;
        padding: 2rem;
        color: #fff;
        box-shadow: 0 24px 60px rgba(15, 23, 42, 0.18);
        margin-bottom: 1.5rem;
    }
    .portfolio-card {
        background: #fff;
        border: 1px solid #e2e8f0;
        border-radius: 22px;
        padding: 1.15rem;
        box-shadow: 0 14px 34px rgba(15, 23, 42, 0.06);
        transition: transform .18s ease, box-shadow .18s ease;
        height: 100%;
    }
    .portfolio-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 18px 42px rgba(15, 23, 42, 0.09);
    }
    .metric-pill {
        display: inline-flex;
        align-items: center;
        gap: .35rem;
        padding: .35rem .65rem;
        border-radius: 999px;
        background: #f8fafc;
        color: #334155;
        font-size: .78rem;
        font-weight: 800;
        border: 1px solid #e2e8f0;
    }
    .filter-panel {
        background: #fff;
        border: 1px solid #e2e8f0;
        border-radius: 22px;
        padding: 1rem;
        box-shadow: 0 10px 28px rgba(15, 23, 42, 0.04);
    }
</style>

<div class="portfolio-hero">
    <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
        <div>
            <div class="fw-bold small opacity-75 mb-2">Clinical logbook portfolio</div>
            <h1 class="fw-black mb-2" style="font-weight: 900;">تقارير إنجازات الطلاب العملية</h1>
            <p class="mb-0 opacity-75">استعرض إنجاز كل طالب بشكل تراكمي حسب نظام الجسم ونوع النشاط، مع إمكانية تصدير تقرير مفصل.</p>
        </div>
        <a href="{{ route('doctor.clinical.logbook-records') }}" class="btn btn-light fw-bold rounded-4 px-4">السجلات اليومية</a>
    </div>
</div>

<form class="filter-panel mb-4" method="GET">
    <div class="row g-3 align-items-end">
        <div class="col-lg-4">
            <label class="form-label fw-bold">بحث</label>
            <input type="search" name="search" value="{{ request('search') }}" class="form-control rounded-4" placeholder="اسم الطالب أو رقم القيد أو البريد">
        </div>
        <div class="col-lg-2 col-md-6">
            <label class="form-label fw-bold">التخصص</label>
            <select name="major_id" class="form-select rounded-4">
                <option value="">الكل</option>
                @foreach($filters['majors'] as $major)
                    <option value="{{ $major['id'] }}" @selected((string) request('major_id') === (string) $major['id'])>{{ $major['name'] }}</option>
                @endforeach
            </select>
        </div>
        <div class="col-lg-2 col-md-6">
            <label class="form-label fw-bold">المستوى</label>
            <select name="level_id" class="form-select rounded-4">
                <option value="">الكل</option>
                @foreach($filters['levels'] as $level)
                    <option value="{{ $level['id'] }}" @selected((string) request('level_id') === (string) $level['id'])>{{ $level['name'] }}</option>
                @endforeach
            </select>
        </div>
        <div class="col-lg-2 col-md-6">
            <label class="form-label fw-bold">من تاريخ</label>
            <input type="date" name="from" value="{{ request('from') }}" class="form-control rounded-4">
        </div>
        <div class="col-lg-2 col-md-6">
            <label class="form-label fw-bold">إلى تاريخ</label>
            <input type="date" name="to" value="{{ request('to') }}" class="form-control rounded-4">
        </div>
        <div class="col-12 d-flex gap-2">
            <button type="submit" class="btn btn-primary rounded-4 px-4 fw-bold">تطبيق الفلاتر</button>
            <a href="{{ route('doctor.clinical.logbook-portfolios.index') }}" class="btn btn-outline-secondary rounded-4 px-4 fw-bold">مسح</a>
        </div>
    </div>
</form>

<div class="row g-3">
    @forelse($students as $student)
        @php($summary = $student['summary'])
        <div class="col-xl-4 col-md-6">
            <a href="{{ route('doctor.clinical.logbook-portfolios.show', array_merge(['student' => $student['id']], request()->only(['from', 'to']))) }}" class="text-decoration-none">
                <div class="portfolio-card">
                    <div class="d-flex justify-content-between gap-3 mb-3">
                        <div>
                            <h2 class="h5 fw-bold text-dark mb-1">{{ $student['name'] }}</h2>
                            <div class="text-muted small">{{ $student['student_number'] ?: '-' }}</div>
                        </div>
                        <div class="rounded-4 bg-primary-subtle text-primary fw-bold d-flex align-items-center justify-content-center" style="width: 46px; height: 46px;">
                            {{ mb_substr($student['name'], 0, 1) }}
                        </div>
                    </div>
                    <div class="text-muted small mb-3">
                        {{ data_get($student, 'major.name', '-') }} | {{ data_get($student, 'level.name', '-') }}
                    </div>
                    <div class="d-flex flex-wrap gap-2">
                        <span class="metric-pill">الأنشطة: {{ $summary['approved_activities'] }}</span>
                        <span class="metric-pill">قصص: {{ $summary['history_taking'] }}</span>
                        <span class="metric-pill">فحوصات: {{ $summary['clinical_examination'] }}</span>
                        <span class="metric-pill">مرور: {{ $summary['round'] }}</span>
                    </div>
                </div>
            </a>
        </div>
    @empty
        <div class="col-12">
            <div class="portfolio-card text-center py-5 text-muted">لا توجد إنجازات عملية معتمدة مطابقة للفلاتر الحالية.</div>
        </div>
    @endforelse
</div>

@if($students->hasPages())
    <div class="mt-4">{{ $students->links() }}</div>
@endif
@endsection
