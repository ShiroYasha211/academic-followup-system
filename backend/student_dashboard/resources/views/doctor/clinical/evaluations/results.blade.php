@extends('layouts.doctor')
@section('title', 'نتائج التقييمات')
@section('content')
<style>
    .clinical-page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.75rem;
        flex-wrap: wrap;
        gap: 1rem;
    }

    .clinical-page-header .right-side h1 {
        font-size: 1.6rem;
        font-weight: 800;
        color: var(--text-primary);
        margin: 0 0 0.15rem 0;
    }

    .clinical-page-header .right-side p {
        color: var(--text-secondary);
        font-size: 0.9rem;
        margin: 0;
    }

    .clinical-page-header .left-side {
        display: flex;
        gap: 0.75rem;
        align-items: center;
    }

    .btn-back {
        background: white;
        color: var(--text-secondary);
        border: 1.5px solid #e2e8f0;
        padding: 0.55rem 1.1rem;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.88rem;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
        transition: all 0.2s;
    }

    .btn-back:hover {
        border-color: #cbd5e1;
        background: #f8fafc;
        color: var(--text-primary);
        text-decoration: none;
    }

    .card-section {
        background: white;
        border-radius: 18px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
    }

    .filter-bar {
        background: linear-gradient(135deg, #f8fafc, #f1f5f9);
        padding: 1rem 1.25rem;
        border-radius: 14px;
        border: 1px solid #e2e8f0;
        margin-bottom: 1.5rem;
        display: flex;
        gap: 0.85rem;
        align-items: center;
        flex-wrap: wrap;
    }

    .filter-bar select {
        padding: 0.55rem;
        font-size: 0.88rem;
        border: 1.5px solid #e2e8f0;
        border-radius: 9px;
        background: white;
        font-family: inherit;
    }

    .btn-filter {
        background: var(--primary-color);
        color: white;
        border: none;
        padding: 0.55rem 1.25rem;
        border-radius: 9px;
        font-weight: 600;
        font-size: 0.85rem;
        cursor: pointer;
    }

    .table-modern {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
    }

    .table-modern th {
        background: #f8fafc;
        font-weight: 600;
        color: var(--text-secondary);
        padding: 0.85rem 1rem;
        text-align: right;
        font-size: 0.82rem;
        border-bottom: 2px solid #e2e8f0;
    }

    .table-modern td {
        padding: 0.85rem 1rem;
        vertical-align: middle;
        border-bottom: 1px solid #f1f5f9;
        font-size: 0.9rem;
    }

    .table-modern tr:hover td {
        background: #fafbfe;
    }

    .grade-badge {
        padding: 0.25rem 0.6rem;
        border-radius: 6px;
        font-size: 0.78rem;
        font-weight: 700;
        color: white;
    }

    .pct-bar {
        height: 6px;
        border-radius: 3px;
        background: #e2e8f0;
        overflow: hidden;
        margin-top: 0.25rem;
    }

    .pct-bar .fill {
        height: 100%;
        border-radius: 3px;
        transition: width 0.3s;
    }

    .alert-banner {
        padding: 0.85rem 1.25rem;
        border-radius: 12px;
        margin-bottom: 1.5rem;
        font-weight: 600;
        font-size: 0.9rem;
    }

    .alert-banner.success {
        background: #d1fae5;
        color: #065f46;
        border: 1px solid #6ee7b7;
    }
</style>

<div class="clinical-page-header">
    <div class="right-side">
        <h1>نتائج التقييمات 📊</h1>
        <p>جميع التقييمات السريرية التي أجريتها</p>
    </div>
    <div class="left-side">
        <a href="{{ route('doctor.clinical.evaluations.portfolios.index') }}" class="btn-back" style="border-color:#99f6e4;color:#0f766e;">كشوف الطلاب</a>
        <a href="{{ route('doctor.clinical.evaluations.start') }}" class="btn-back" style="border-color:#c7d2fe;color:var(--primary-color);">🎯 تقييم جديد</a>
        <a href="{{ route('doctor.clinical.evaluations.checklists') }}" class="btn-back"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg> القوائم</a>
    </div>
</div>

@if(session('success'))<div class="alert-banner success">✅ {{ session('success') }}</div>@endif

<form action="{{ route('doctor.clinical.evaluations.results') }}" method="GET" class="filter-bar">
    <select name="student_id" class="select2">
        <option value="">كل الطلاب</option>
        @foreach($students as $s)<option value="{{ $s->id }}" {{ request('student_id') == $s->id ? 'selected' : '' }}>{{ $s->name }}</option>@endforeach
    </select>
    <button type="submit" class="btn-filter">تصفية</button>
    @if(request('student_id'))<a href="{{ route('doctor.clinical.evaluations.results') }}" style="font-size:0.82rem;color:#64748b;text-decoration:none;">إلغاء</a>@endif
</form>

<div class="card-section">
    <div style="overflow-x:auto;">
        <div class="table-responsive">
<table class="table-modern">
            <thead>
                <tr>
                    <th>#</th>
                    <th>الطالب</th>
                    <th>القائمة</th>
                    <th>النتيجة</th>
                    <th>التقدير</th>
                    <th>الوقت</th>
                    <th>التاريخ</th>
                    <th>تفاصيل</th>
                </tr>
            </thead>
            <tbody>
                @forelse($evaluations as $ev)
                <tr>
                    <td>{{ $loop->iteration }}</td>
                    <td style="font-weight:700;color:var(--primary-color);">{{ $ev->student->name ?? '-' }}</td>
                    <td style="font-size:0.82rem;">{{ $ev->checklist->title ?? '-' }}</td>
                    <td>
                        <span style="font-weight:700;">{{ $ev->total_score }}/{{ $ev->max_score }}</span>
                        <div class="pct-bar">
                            <div class="fill" style="width:{{ $ev->percentage }}%;background:{{ $ev->grade_color }};"></div>
                        </div>
                    </td>
                    <td><span class="grade-badge" style="background:{{ $ev->grade_color }};">{{ $ev->grade_label }}</span></td>
                    <td style="font-size:0.82rem;color:var(--text-secondary);">{{ $ev->formatted_time }}</td>
                    <td style="font-size:0.82rem;color:var(--text-secondary);">{{ $ev->created_at->format('Y-m-d') }}</td>
                    <td><a href="{{ route('doctor.clinical.evaluations.results.show', $ev->id) }}" style="color:var(--primary-color);font-weight:600;font-size:0.82rem;text-decoration:none;">عرض ←</a></td>
                </tr>
                @empty
                <tr>
                    <td colspan="8" style="text-align:center;color:var(--text-secondary);padding:3rem;">لا توجد تقييمات بعد.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
</div>
    </div>
    @if($evaluations->hasPages())<div style="margin-top:1.5rem;">{{ $evaluations->links() }}</div>@endif
</div>
@endsection

@push('scripts')
<link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet" />
<script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>
<script>
    $(document).ready(function() {
        $('.select2').select2({
            dir: "rtl",
            width: 'resolve'
        });
    });
</script>
@endpush
