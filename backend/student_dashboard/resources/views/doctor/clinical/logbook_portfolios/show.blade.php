@extends('layouts.doctor')

@section('title', 'تفاصيل إنجازات الطالب العملية')

@section('content')
@php
    $student = $portfolio['student'];
    $summary = $portfolio['summary'];
@endphp

<style>
    .portfolio-header {
        background: linear-gradient(135deg, #0f172a 0%, #1d4ed8 58%, #0f766e 100%);
        border-radius: 28px;
        padding: 2rem;
        color: #fff;
        box-shadow: 0 24px 60px rgba(15, 23, 42, 0.18);
        margin-bottom: 1.5rem;
    }
    .soft-card {
        background: #fff;
        border: 1px solid #e2e8f0;
        border-radius: 22px;
        padding: 1rem;
        box-shadow: 0 12px 32px rgba(15, 23, 42, 0.05);
    }
    .portfolio-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
        overflow: hidden;
        border-radius: 18px;
        border: 1px solid #e2e8f0;
    }
    .portfolio-table th {
        background: #f8fafc;
        color: #0f172a;
        font-weight: 900;
        padding: .85rem;
        border-bottom: 1px solid #e2e8f0;
    }
    .portfolio-table td {
        padding: .85rem;
        border-bottom: 1px solid #edf2f7;
        color: #334155;
        font-weight: 700;
    }
    .portfolio-table tr:last-child td { border-bottom: 0; }
    .count-cell {
        font-variant-numeric: tabular-nums;
        text-align: center;
    }
</style>

<div class="portfolio-header">
    <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
        <div>
            <div class="fw-bold small opacity-75 mb-2">Student clinical portfolio</div>
            <h1 class="fw-black mb-2" style="font-weight: 900;">{{ $student['name'] }}</h1>
            <p class="mb-0 opacity-75">
                {{ $student['student_number'] ?: '-' }} | {{ data_get($student, 'major.name', '-') }} | {{ data_get($student, 'level.name', '-') }}
            </p>
        </div>
        <div class="d-flex gap-2 flex-wrap">
            <a href="{{ route('doctor.clinical.logbook-portfolios.pdf', array_merge(['student' => $student['id']], request()->only(['from', 'to']))) }}" class="btn btn-light rounded-4 fw-bold px-4">PDF</a>
            <a href="{{ route('doctor.clinical.logbook-portfolios.csv', array_merge(['student' => $student['id']], request()->only(['from', 'to']))) }}" class="btn btn-outline-light rounded-4 fw-bold px-4">Excel</a>
            <a href="{{ route('doctor.clinical.logbook-portfolios.index', request()->only(['from', 'to'])) }}" class="btn btn-outline-light rounded-4 fw-bold px-4">رجوع</a>
        </div>
    </div>
</div>

<div class="row g-3 mb-4">
    <div class="col-md-3"><div class="soft-card"><div class="text-muted small fw-bold">إجمالي الأنشطة</div><div class="h3 fw-bold mb-0">{{ $summary['approved_activities'] }}</div></div></div>
    <div class="col-md-3"><div class="soft-card"><div class="text-muted small fw-bold">قصص مرضية</div><div class="h3 fw-bold mb-0">{{ $summary['history_taking'] }}</div></div></div>
    <div class="col-md-3"><div class="soft-card"><div class="text-muted small fw-bold">فحوصات سريرية</div><div class="h3 fw-bold mb-0">{{ $summary['clinical_examination'] }}</div></div></div>
    <div class="col-md-3"><div class="soft-card"><div class="text-muted small fw-bold">مرور</div><div class="h3 fw-bold mb-0">{{ $summary['round'] }}</div></div></div>
</div>

<div class="soft-card mb-4">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
        <h2 class="h5 fw-bold mb-0">جدول الإنجاز التراكمي</h2>
        <span class="text-muted small">يعتمد فقط على الأنشطة المعتمدة</span>
    </div>
    <div class="table-responsive">
        <table class="portfolio-table">
            <thead>
                <tr>
                    <th>نظام الجسم / المهارة</th>
                    <th class="text-center">قصص مرضية</th>
                    <th class="text-center">فحوصات سريرية</th>
                    <th class="text-center">مرور</th>
                    <th class="text-center">الإجمالي</th>
                </tr>
            </thead>
            <tbody>
                @foreach($portfolio['matrix'] as $row)
                    <tr>
                        <td>{{ $row['body_system'] }}</td>
                        <td class="count-cell">{{ $row['history_taking'] }}</td>
                        <td class="count-cell">{{ $row['clinical_examination'] }}</td>
                        <td class="count-cell">{{ $row['round'] }}</td>
                        <td class="count-cell fw-black">{{ $row['total'] }}</td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</div>

<div class="soft-card">
    <h2 class="h5 fw-bold mb-3">تفاصيل الجلسات المعتمدة</h2>
    <div class="table-responsive">
        <table class="portfolio-table">
            <thead>
                <tr>
                    <th>التاريخ</th>
                    <th>المركز</th>
                    <th>القسم</th>
                    <th>النشاط</th>
                    <th>النظام/الحالة</th>
                    <th>الدكتور</th>
                </tr>
            </thead>
            <tbody>
                @foreach($portfolio['logs'] as $log)
                    @foreach($log['activities'] as $activity)
                        <tr>
                            <td>{{ $log['date'] }}</td>
                            <td>{{ $log['training_center'] ?: '-' }}</td>
                            <td>{{ $log['department'] ?: '-' }}</td>
                            <td>{{ $activity['type_label'] }}</td>
                            <td>{{ $activity['body_system'] }}</td>
                            <td>{{ $log['doctor'] ?: '-' }}</td>
                        </tr>
                    @endforeach
                @endforeach
            </tbody>
        </table>
    </div>
</div>
@endsection
