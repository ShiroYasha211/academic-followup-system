@extends('layouts.admin')

@section('title', 'نتائج الكويز الإداري')

@section('content')
<style>
    .results-header {
        background: linear-gradient(135deg, #0f766e 0%, #14b8a6 100%);
        border-radius: 24px;
        padding: 2.25rem 2rem;
        color: white;
        margin-bottom: 1.5rem;
        position: relative;
        overflow: hidden;
    }

    .results-header::before {
        content: '';
        position: absolute;
        top: -60px;
        left: -60px;
        width: 220px;
        height: 220px;
        background: rgba(255,255,255,0.1);
        border-radius: 50%;
    }

    .results-header-content {
        position: relative;
        z-index: 1;
    }

    .results-header h2 {
        font-size: 1.55rem;
        font-weight: 800;
        margin-bottom: 0.35rem;
    }

    .results-meta {
        display: flex;
        gap: 0.65rem;
        flex-wrap: wrap;
        margin-top: 1rem;
    }

    .results-meta-pill {
        background: rgba(255,255,255,0.14);
        border: 1px solid rgba(255,255,255,0.22);
        border-radius: 999px;
        padding: 0.45rem 0.9rem;
        font-size: 0.85rem;
        font-weight: 700;
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
    }

    .btn-action-row {
        display: flex;
        gap: 0.75rem;
        flex-wrap: wrap;
        align-items: center;
        margin-bottom: 1.5rem;
    }

    .btn-action {
        padding: 0.7rem 1.1rem;
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
        background: #0f766e;
        color: white;
    }

    .btn-action-primary:hover {
        background: #115e59;
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

    .visibility-form {
        display: inline-flex;
        gap: 0.5rem;
        align-items: center;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        padding: 0.45rem;
    }

    .visibility-form select {
        min-width: 180px;
        border: 0;
        background: transparent;
        font-size: 0.85rem;
        font-weight: 700;
        color: #334155;
        box-shadow: none;
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
        padding: 1rem 1.1rem;
        font-weight: 800;
        font-size: 0.82rem;
        color: #475569;
        text-align: right;
        border-bottom: 2px solid #e2e8f0;
        white-space: nowrap;
    }

    .results-table tbody td {
        padding: 0.85rem 1.1rem;
        font-size: 0.9rem;
        color: #334155;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
        white-space: nowrap;
    }

    .results-table tbody tr:hover {
        background: #f8fafc;
    }

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

    .score-cell {
        font-weight: 800;
        font-size: 1rem;
    }

    .score-high { color: #059669; }
    .score-mid { color: #d97706; }
    .score-low { color: #dc2626; }

    .percentage-bar {
        width: 90px;
        height: 8px;
        background: #e2e8f0;
        border-radius: 99px;
        overflow: hidden;
        display: inline-block;
        vertical-align: middle;
        margin-right: 0.5rem;
    }

    .percentage-bar-fill {
        height: 100%;
        border-radius: 99px;
    }

    .student-cell {
        min-width: 190px;
        white-space: normal !important;
    }

    .student-name {
        font-weight: 800;
        color: #0f172a;
    }

    .student-sub {
        color: #64748b;
        font-size: 0.76rem;
        margin-top: 0.15rem;
    }

    .status-pill {
        padding: 0.25rem 0.7rem;
        border-radius: 999px;
        font-size: 0.75rem;
        font-weight: 800;
        display: inline-flex;
    }

    .status-graded {
        background: #d1fae5;
        color: #065f46;
    }

    .status-pending {
        background: #fef3c7;
        color: #92400e;
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
        <h2><i class="fa-solid fa-chart-bar me-2"></i>نتائج: {{ $quiz->title }}</h2>
        <div style="opacity: 0.92;">{{ $quiz->subject->name ?? 'كويز إداري عام' }} - {{ $attempts->count() }} محاولة</div>
        <div class="results-meta">
            <span class="results-meta-pill"><i class="fa-solid fa-eye"></i> {{ $quiz->results_visibility_label }}</span>
            <span class="results-meta-pill"><i class="fa-solid fa-users"></i> {{ $quiz->targets->count() }} فئة مستهدفة</span>
            <span class="results-meta-pill"><i class="fa-solid fa-layer-group"></i> {{ $quiz->models->count() }} نموذج</span>
        </div>
    </div>
</div>

<div class="btn-action-row">
    <a href="{{ route('admin.quizzes.results.export', $quiz) }}" class="btn-action btn-action-primary">
        <i class="fa-solid fa-file-excel"></i>
        <span>تصدير Excel</span>
    </a>

    <form action="{{ route('admin.quizzes.share-results', $quiz) }}" method="POST" class="visibility-form">
        @csrf
        <select name="visibility" class="form-select form-select-sm" aria-label="إعداد ظهور النتائج">
            <option value="hidden" {{ $quiz->results_visibility === 'hidden' ? 'selected' : '' }}>مخفية</option>
            <option value="individual" {{ $quiz->results_visibility === 'individual' ? 'selected' : '' }}>فردية للطالب</option>
            <option value="public" {{ $quiz->results_visibility === 'public' ? 'selected' : '' }}>عامة للجميع</option>
        </select>
        <button type="submit" class="btn btn-sm btn-outline-primary" style="border-radius: 10px; font-weight: 800;">
            <i class="fa-solid fa-floppy-disk"></i>
            حفظ
        </button>
    </form>

    <a href="{{ route('admin.quizzes.show', $quiz) }}" class="btn-action btn-action-secondary">
        <i class="fa-solid fa-arrow-right"></i>
        <span>رجوع للكويز</span>
    </a>

    <a href="{{ route('admin.quizzes.index') }}" class="btn-action btn-action-secondary">
        <i class="fa-solid fa-list"></i>
        <span>قائمة الكويزات</span>
    </a>
</div>

<div class="results-card">
    @if($attempts->count() > 0)
        <div class="table-responsive">
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
                        <th>تاريخ التسليم</th>
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
                            <td class="student-cell">
                                <div class="student-name">{{ $attempt->student?->name ?? '-' }}</div>
                                <div class="student-sub">
                                    {{ $attempt->student?->major?->name ?? '-' }} / {{ $attempt->student?->level?->name ?? '-' }}
                                </div>
                            </td>
                            <td>{{ $attempt->student?->student_number ?? '-' }}</td>
                            <td>
                                <span class="badge bg-light text-dark fw-bold">{{ $attempt->quizModel?->name ?? '-' }}</span>
                            </td>
                            <td class="score-cell {{ $scoreClass }}">{{ $attempt->score ?? 0 }} / {{ $attempt->max_score ?? 0 }}</td>
                            <td>
                                <span class="{{ $scoreClass }}" style="font-weight: 800; font-size: 0.85rem;">{{ $pct }}%</span>
                                <div class="percentage-bar">
                                    <div class="percentage-bar-fill" style="width: {{ $pct }}%; background: {{ $barColor }};"></div>
                                </div>
                            </td>
                            <td>
                                <span style="color: #059669; font-weight: 800;">{{ $attempt->correct_count }}</span>
                                /
                                <span style="color: #ef4444; font-weight: 800;">{{ $attempt->wrong_count }}</span>
                            </td>
                            <td>{{ $attempt->duration !== null ? $attempt->duration . ' دقيقة' : '-' }}</td>
                            <td>{{ $attempt->submitted_at?->format('Y-m-d h:i A') ?? '-' }}</td>
                            <td>
                                <span class="status-pill {{ $attempt->status === 'graded' ? 'status-graded' : 'status-pending' }}">
                                    {{ $attempt->status_label }}
                                </span>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    @else
        <div class="empty-results">
            <i class="fa-solid fa-chart-bar d-block"></i>
            <h4 class="fw-bold text-secondary">لا توجد محاولات بعد</h4>
            <p class="text-muted mb-0">ستظهر هنا نتائج الطلاب بعد بدء حل الكويز وتسليمه.</p>
        </div>
    @endif
</div>
@endsection
