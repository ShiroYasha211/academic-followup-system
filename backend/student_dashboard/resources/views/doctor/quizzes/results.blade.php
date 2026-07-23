@extends('layouts.doctor')

@section('title', 'نتائج الكويز')

@section('content')
<style>
    .results-header {
        background: linear-gradient(135deg, #059669 0%, #10b981 100%);
        border-radius: 24px;
        padding: 2.5rem 2rem;
        color: white;
        margin-bottom: 2rem;
        position: relative;
        overflow: hidden;
    }

    .results-header::before {
        content: '';
        position: absolute;
        top: -50%;
        right: -10%;
        width: 300px;
        height: 300px;
        background: rgba(255,255,255,0.08);
        border-radius: 50%;
    }

    .results-header-content {
        position: relative;
        z-index: 1;
    }

    .results-header h1 {
        font-size: 1.8rem;
        font-weight: 800;
        margin-bottom: 0.35rem;
    }

    .results-meta {
        display: flex;
        gap: 0.75rem;
        flex-wrap: wrap;
        margin-top: 1rem;
    }

    .results-meta-pill {
        background: rgba(255,255,255,0.14);
        border: 1px solid rgba(255,255,255,0.2);
        border-radius: 999px;
        padding: 0.45rem 0.9rem;
        font-size: 0.85rem;
        font-weight: 700;
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
    }

    .results-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
    }

    .results-table {
        width: 100%;
        border-collapse: collapse;
    }

    .results-table thead th {
        background: #f8fafc;
        padding: 1rem 1.25rem;
        font-weight: 700;
        font-size: 0.85rem;
        color: #475569;
        text-align: right;
        border-bottom: 2px solid #e2e8f0;
        white-space: nowrap;
    }

    .results-table tbody td {
        padding: 0.85rem 1.25rem;
        font-size: 0.9rem;
        color: #334155;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
    }

    .results-table tbody tr:hover {
        background: #f8fafc;
    }

    .score-cell {
        font-weight: 800;
        font-size: 1rem;
    }

    .score-high { color: #059669; }
    .score-mid { color: #d97706; }
    .score-low { color: #dc2626; }

    .rank-badge {
        width: 30px;
        height: 30px;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 800;
        font-size: 0.8rem;
        color: white;
    }

    .rank-1 { background: linear-gradient(135deg, #f59e0b, #d97706); }
    .rank-2 { background: linear-gradient(135deg, #94a3b8, #64748b); }
    .rank-3 { background: linear-gradient(135deg, #cd7f32, #a0522d); }
    .rank-default { background: #e2e8f0; color: #64748b; }

    .percentage-bar {
        width: 100px;
        height: 8px;
        background: #e2e8f0;
        border-radius: 99px;
        overflow: hidden;
        display: inline-block;
        vertical-align: middle;
        margin-left: 0.5rem;
    }

    .percentage-bar-fill {
        height: 100%;
        border-radius: 99px;
        transition: width 0.3s;
    }

    .btn-action-row {
        display: flex;
        gap: 0.75rem;
        margin-bottom: 2rem;
        flex-wrap: wrap;
    }

    .btn-action {
        padding: 0.7rem 1.25rem;
        border-radius: 12px;
        font-weight: 700;
        font-size: 0.9rem;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        transition: all 0.2s;
        border: none;
    }

    .btn-action-primary {
        background: #059669;
        color: white;
    }

    .btn-action-primary:hover {
        background: #047857;
        color: white;
    }

    .btn-action-secondary {
        background: #f1f5f9;
        color: #475569;
    }

    .btn-action-secondary:hover {
        background: #e2e8f0;
        color: #334155;
    }

    .empty-results {
        text-align: center;
        padding: 4rem 2rem;
    }

    .empty-results i {
        font-size: 3rem;
        color: #cbd5e1;
        margin-bottom: 1rem;
    }
</style>

<div class="results-header">
    <div class="results-header-content">
        <h1><i class="fa-solid fa-chart-bar me-2"></i>نتائج: {{ $quiz->title }}</h1>
        <p style="opacity:0.9; margin-bottom:0;">{{ $quiz->subject->name ?? '-' }} - {{ $attempts->count() }} طالب</p>
        <div class="results-meta">
            <span class="results-meta-pill"><i class="fa-solid fa-layer-group"></i> {{ $quiz->subject->major->name ?? '-' }}</span>
            <span class="results-meta-pill"><i class="fa-solid fa-stairs"></i> {{ $quiz->subject->level->name ?? '-' }}</span>
            <span class="results-meta-pill"><i class="fa-solid fa-eye"></i> {{ $quiz->results_visibility_label }}</span>
        </div>
    </div>
</div>

<div class="btn-action-row">
    <a href="{{ route('doctor.quizzes.results.export', $quiz) }}" class="btn-action btn-action-primary">
        <i class="fa-solid fa-file-excel"></i>
        <span>تصدير Excel</span>
    </a>
    <a href="{{ route('doctor.quizzes.show', $quiz) }}" class="btn-action btn-action-secondary">
        <i class="fa-solid fa-arrow-right"></i>
        <span>رجوع للكويز</span>
    </a>
    <a href="{{ route('doctor.quizzes.index') }}" class="btn-action btn-action-secondary">
        <i class="fa-solid fa-list"></i>
        <span>قائمة الكويزات</span>
    </a>
</div>

<div class="results-card">
    @if($attempts->count() > 0)
        <table class="results-table">
            <thead>
                <tr>
                    <th style="width: 50px;">#</th>
                    <th>الطالب</th>
                    <th>الرقم الجامعي</th>
                    <th>النموذج</th>
                    <th>الدرجة</th>
                    <th>النسبة</th>
                    <th>الصحيح / الخطأ</th>
                    <th>المدة</th>
                    <th>الحالة</th>
                </tr>
            </thead>
            <tbody>
                @foreach($attempts as $i => $attempt)
                    @php
                        $pct = $attempt->percentage;
                        $scoreClass = $pct >= 70 ? 'score-high' : ($pct >= 50 ? 'score-mid' : 'score-low');
                        $barColor = $pct >= 70 ? '#10b981' : ($pct >= 50 ? '#f59e0b' : '#ef4444');
                    @endphp
                    <tr>
                        <td>
                            <div class="rank-badge {{ $i < 3 ? 'rank-' . ($i + 1) : 'rank-default' }}">{{ $i + 1 }}</div>
                        </td>
                        <td style="font-weight: 700;">{{ $attempt->student->name ?? '-' }}</td>
                        <td>{{ $attempt->student->student_number ?? '-' }}</td>
                        <td>
                            <span style="background: #f1f5f9; padding: 0.2rem 0.5rem; border-radius: 6px; font-size: 0.8rem; font-weight: 600;">
                                {{ $attempt->quizModel->name ?? '-' }}
                            </span>
                        </td>
                        <td class="score-cell {{ $scoreClass }}">{{ $attempt->score ?? 0 }} / {{ $attempt->max_score ?? 0 }}</td>
                        <td>
                            <span class="{{ $scoreClass }}" style="font-weight: 700; font-size: 0.85rem;">{{ $pct }}%</span>
                            <div class="percentage-bar">
                                <div class="percentage-bar-fill" style="width: {{ $pct }}%; background: {{ $barColor }};"></div>
                            </div>
                        </td>
                        <td>
                            <span style="color: #059669; font-weight: 700;">{{ $attempt->correct_count }}</span>
                            /
                            <span style="color: #ef4444; font-weight: 700;">{{ $attempt->wrong_count }}</span>
                        </td>
                        <td style="color: #64748b; font-size: 0.85rem;">{{ $attempt->duration ?? '-' }}</td>
                        <td>
                            <span style="padding: 0.2rem 0.6rem; border-radius: 99px; font-size: 0.72rem; font-weight: 700; background: {{ $attempt->status === 'graded' ? '#d1fae5' : '#fef3c7' }}; color: {{ $attempt->status === 'graded' ? '#065f46' : '#92400e' }};">
                                {{ $attempt->status_label }}
                            </span>
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    @else
        <div class="empty-results">
            <i class="fa-solid fa-chart-bar d-block"></i>
            <h3 style="font-weight: 700; color: #475569;">لا توجد محاولات بعد</h3>
            <p class="text-secondary">سيظهر هنا كشف النتائج بعد أن يبدأ الطلاب بحل الكويز.</p>
        </div>
    @endif
</div>
@endsection
