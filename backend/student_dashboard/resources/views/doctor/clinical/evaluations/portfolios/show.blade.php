@extends('layouts.doctor')

@section('title', 'كشف التقييم السريري للطالب')

@section('content')
@php
    $student = $portfolio['student'];
    $summary = $portfolio['summary'];
@endphp

<style>
    .report-hero {
        background: linear-gradient(135deg, #102a43 0%, #2563a8 58%, #0f766e 100%);
        border-radius: 24px;
        padding: 1.75rem;
        color: #fff;
        box-shadow: 0 20px 48px rgba(15, 42, 67, .16);
    }
    .report-panel, .report-metric {
        background: #fff;
        border: 1px solid #e2e8f0;
        border-radius: 18px;
        box-shadow: 0 10px 28px rgba(15, 23, 42, .05);
    }
    .report-panel { padding: 1.1rem; }
    .report-metric { padding: 1rem; height: 100%; }
    .report-table { width: 100%; min-width: 820px; border-collapse: separate; border-spacing: 0; }
    .report-table th {
        background: #f1f5f9;
        color: #334155;
        font-size: .8rem;
        padding: .8rem;
        border-bottom: 1px solid #dbe4ee;
        white-space: nowrap;
    }
    .report-table td {
        padding: .8rem;
        border-bottom: 1px solid #edf2f7;
        color: #334155;
        font-size: .86rem;
        vertical-align: middle;
    }
    .report-table tr:last-child td { border-bottom: 0; }
    .grade-pill {
        display: inline-block;
        padding: .25rem .55rem;
        border-radius: 8px;
        background: #e8f1fb;
        color: #1d4f91;
        font-weight: 800;
        font-size: .76rem;
    }
</style>

<div class="report-hero mb-4">
    <div class="d-flex justify-content-between align-items-start gap-3 flex-wrap">
        <div>
            <div class="small fw-bold opacity-75 mb-2">Cumulative OSCE report</div>
            <h1 class="h3 fw-bold mb-2">{{ $student['name'] }}</h1>
            <p class="mb-0 opacity-75">
                {{ $student['student_number'] ?: '-' }} ·
                {{ data_get($student, 'major.name', '-') }} ·
                {{ data_get($student, 'level.name', '-') }}
            </p>
        </div>
        <div class="d-flex gap-2 flex-wrap">
            <a href="{{ route('doctor.clinical.evaluations.portfolios.excel', array_merge(['student' => $student['id']], request()->only(['date_from', 'date_to', 'checklist_id', 'doctor_id']))) }}" class="btn btn-light rounded-3 fw-bold">تصدير Excel</a>
            <a href="{{ route('doctor.clinical.evaluations.portfolios.index') }}" class="btn btn-outline-light rounded-3 fw-bold">رجوع</a>
        </div>
    </div>
</div>

<form method="GET" class="report-panel mb-4">
    <div class="row g-3 align-items-end">
        <div class="col-lg-3 col-md-6">
            <label class="form-label fw-bold">من تاريخ</label>
            <input type="date" name="date_from" value="{{ request('date_from') }}" class="form-control rounded-3">
        </div>
        <div class="col-lg-3 col-md-6">
            <label class="form-label fw-bold">إلى تاريخ</label>
            <input type="date" name="date_to" value="{{ request('date_to') }}" class="form-control rounded-3">
        </div>
        <div class="col-lg-3 col-md-6">
            <label class="form-label fw-bold">قائمة التقييم</label>
            <select name="checklist_id" class="form-select rounded-3">
                <option value="">كل القوائم</option>
                @foreach($filters['checklists'] as $checklist)
                    <option value="{{ $checklist['id'] }}" @selected((string) request('checklist_id') === (string) $checklist['id'])>{{ $checklist['title'] }}</option>
                @endforeach
            </select>
        </div>
        <div class="col-lg-3 col-md-6">
            <label class="form-label fw-bold">الدكتور</label>
            <select name="doctor_id" class="form-select rounded-3">
                <option value="">كل الدكاترة</option>
                @foreach($filters['doctors'] as $doctor)
                    <option value="{{ $doctor['id'] }}" @selected((string) request('doctor_id') === (string) $doctor['id'])>{{ $doctor['name'] }}</option>
                @endforeach
            </select>
        </div>
        <div class="col-12 d-flex gap-2">
            <button class="btn btn-primary rounded-3 fw-bold px-4">تطبيق الفلاتر</button>
            <a href="{{ route('doctor.clinical.evaluations.portfolios.show', $student['id']) }}" class="btn btn-outline-secondary rounded-3 px-4">مسح</a>
        </div>
    </div>
</form>

<div class="row g-3 mb-4">
    @foreach([
        ['المحاولات', $summary['attempts_count']],
        ['القوائم المختلفة', $summary['checklists_count']],
        ['الدكاترة', $summary['doctors_count']],
        ['المتوسط', number_format($summary['average_percentage'], 1) . '%'],
        ['أعلى نتيجة', number_format($summary['highest_percentage'], 1) . '%'],
        ['نسبة النجاح', number_format($summary['pass_rate'], 1) . '%'],
    ] as [$label, $value])
        <div class="col-xl-2 col-md-4 col-6">
            <div class="report-metric">
                <div class="small text-muted fw-bold mb-2">{{ $label }}</div>
                <div class="h4 fw-bold mb-0 text-dark">{{ $value }}</div>
            </div>
        </div>
    @endforeach
</div>

<section class="report-panel mb-4">
    <div class="d-flex justify-content-between align-items-center gap-2 flex-wrap mb-3">
        <div>
            <h2 class="h5 fw-bold mb-1">ملخص القوائم</h2>
            <div class="small text-muted">عدد مرات اختبار كل قائمة والدكاترة والنتائج التراكمية.</div>
        </div>
        <span class="grade-pill">إجمالي الوقت {{ $summary['formatted_total_time'] }}</span>
    </div>
    <div class="table-responsive">
        <table class="report-table">
            <thead>
                <tr>
                    <th>قائمة التقييم</th>
                    <th>نوع المهارة</th>
                    <th>المحاولات</th>
                    <th>الدكاترة</th>
                    <th>المتوسط</th>
                    <th>الأعلى</th>
                    <th>آخر تقييم</th>
                </tr>
            </thead>
            <tbody>
                @foreach($portfolio['checklists'] as $checklist)
                    <tr>
                        <td class="fw-bold">{{ $checklist['title'] }}</td>
                        <td>{{ $checklist['skill_label'] }}</td>
                        <td>{{ $checklist['attempts_count'] }}</td>
                        <td>{{ collect($checklist['doctors'])->pluck('name')->implode('، ') ?: '-' }}</td>
                        <td>{{ number_format($checklist['average_percentage'], 1) }}%</td>
                        <td>{{ number_format($checklist['highest_percentage'], 1) }}%</td>
                        <td>{{ $checklist['last_evaluation_at'] ? \Carbon\Carbon::parse($checklist['last_evaluation_at'])->format('Y-m-d') : '-' }}</td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</section>

<section class="report-panel">
    <div class="mb-3">
        <h2 class="h5 fw-bold mb-1">سجل المحاولات</h2>
        <div class="small text-muted">التفاصيل الزمنية والدرجات لكل تقييم أجراه الطالب.</div>
    </div>
    <div class="table-responsive">
        <table class="report-table">
            <thead>
                <tr>
                    <th>التاريخ</th>
                    <th>القائمة</th>
                    <th>الدكتور</th>
                    <th>نظام الجسم / الحالة</th>
                    <th>الدرجة</th>
                    <th>النسبة</th>
                    <th>التقدير</th>
                    <th>الوقت</th>
                </tr>
            </thead>
            <tbody>
                @foreach($portfolio['attempts'] as $attempt)
                    <tr>
                        <td>{{ $attempt['display_date'] }}</td>
                        <td class="fw-bold">{{ data_get($attempt, 'checklist.title', '-') }}</td>
                        <td>{{ data_get($attempt, 'doctor.name', '-') }}</td>
                        <td>
                            {{ data_get($attempt, 'body_system.name', '-') }}
                            @if(data_get($attempt, 'clinical_case.name'))
                                <div class="small text-muted mt-1">{{ data_get($attempt, 'clinical_case.name') }}</div>
                            @endif
                        </td>
                        <td>{{ $attempt['total_score'] }} / {{ $attempt['max_score'] }}</td>
                        <td>{{ number_format($attempt['percentage'], 1) }}%</td>
                        <td><span class="grade-pill">{{ $attempt['grade_label'] }}</span></td>
                        <td>{{ $attempt['formatted_time'] }}</td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</section>
@endsection
