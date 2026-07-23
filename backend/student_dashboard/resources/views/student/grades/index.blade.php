@extends('layouts.student')

@section('title', 'النتائج الدراسية')

@section('content')

<style>
    .page-header {
        margin-bottom: 2rem;
    }

    .page-title {
        font-size: 1.75rem;
        font-weight: 800;
        color: var(--text-primary);
        margin-bottom: 0.5rem;
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .page-subtitle {
        color: var(--text-secondary);
    }

    /* Summary Card */
    .summary-card {
        background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
        border-radius: 24px;
        padding: 2rem;
        color: white;
        margin-bottom: 2rem;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 2rem;
        position: relative;
        overflow: hidden;
    }

    .summary-card::before {
        content: '';
        position: absolute;
        top: -50%;
        right: -10%;
        width: 300px;
        height: 300px;
        background: rgba(255, 255, 255, 0.1);
        border-radius: 50%;
    }

    .summary-content {
        position: relative;
        z-index: 1;
    }

    .summary-label {
        font-size: 0.9rem;
        opacity: 0.9;
        margin-bottom: 0.5rem;
    }

    .summary-value {
        font-size: 3rem;
        font-weight: 800;
        line-height: 1;
    }

    .summary-desc {
        font-size: 0.9rem;
        opacity: 0.8;
        margin-top: 0.5rem;
    }

    .grade-badge {
        background: rgba(255, 255, 255, 0.2);
        padding: 0.75rem 1.5rem;
        border-radius: 12px;
        font-weight: 700;
        font-size: 1.1rem;
    }

    /* Grades Grid */
    .grades-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
        gap: 1.5rem;
    }

    .grade-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        transition: all 0.3s ease;
    }

    .grade-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 16px 32px -8px rgba(0, 0, 0, 0.1);
    }

    .grade-header {
        padding: 1.25rem 1.5rem;
        background: #f8fafc;
        border-bottom: 1px solid #f1f5f9;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .subject-name {
        font-weight: 700;
        font-size: 1.1rem;
        color: var(--text-primary);
    }

    .subject-code {
        background: #e0e7ff;
        color: #4f46e5;
        padding: 0.25rem 0.6rem;
        border-radius: 6px;
        font-family: monospace;
        font-size: 0.8rem;
        font-weight: 600;
    }

    .grade-body {
        padding: 1.5rem;
    }

    .grade-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0.75rem 0;
        border-bottom: 1px dashed #f1f5f9;
    }

    .grade-row:last-child {
        border-bottom: none;
        padding-bottom: 0;
    }

    .grade-type {
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .type-icon {
        width: 36px;
        height: 36px;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .type-label {
        font-weight: 600;
        color: var(--text-primary);
    }

    .type-weight {
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    .grade-score {
        text-align: left;
    }

    .score-value {
        font-size: 1.25rem;
        font-weight: 700;
    }

    .score-max {
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    /* Total Row */
    .total-row {
        margin-top: 1rem;
        padding-top: 1rem;
        border-top: 2px solid #e2e8f0;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .total-label {
        font-weight: 700;
        font-size: 1rem;
        color: var(--text-primary);
    }

    .total-badge {
        padding: 0.5rem 1rem;
        border-radius: 10px;
        font-weight: 800;
        font-size: 1.1rem;
    }

    .total-badge.excellent {
        background: linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%);
        color: #16a34a;
    }

    .total-badge.good {
        background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
        color: #2563eb;
    }

    .total-badge.average {
        background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
        color: #d97706;
    }

    .total-badge.fail {
        background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%);
        color: #dc2626;
    }

    /* No Grades State */
    .no-grades {
        text-align: center;
        padding: 1.5rem;
        color: var(--text-secondary);
        font-style: italic;
    }

    /* Empty State */
    .empty-state {
        grid-column: 1 / -1;
        text-align: center;
        padding: 4rem 2rem;
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
    }

    .empty-icon {
        width: 80px;
        height: 80px;
        background: #f1f5f9;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 1.5rem;
        color: var(--text-secondary);
    }
</style>

<div class="page-header">
    <h1 class="page-title">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
            <line x1="18" y1="20" x2="18" y2="10"></line>
            <line x1="12" y1="20" x2="12" y2="4"></line>
            <line x1="6" y1="20" x2="6" y2="14"></line>
        </svg>
        النتائج الدراسية
    </h1>
    <p class="page-subtitle">عرض درجاتك في جميع المقررات الدراسية</p>
</div>

@if($totalGrades > 0)
<!-- Summary Card -->
<div class="summary-card">
    <div class="summary-content">
        <div class="summary-label">المعدل العام</div>
        <div class="summary-value">{{ $overallAverage }}%</div>
        <div class="summary-desc">بناءً على {{ $totalGrades }} مقرر</div>
    </div>
    <div class="grade-badge">
        @if($overallAverage >= 85)
        ممتاز 🌟
        @elseif($overallAverage >= 70)
        جيد جداً 👍
        @elseif($overallAverage >= 50)
        مقبول 📝
        @else
        يحتاج تحسين 📚
        @endif
    </div>
</div>
@endif

<!-- Grades Grid -->
<div class="grades-grid">
    @forelse($subjects as $subject)
    @php
    $subjectGrades = $grades->get($subject->id, collect());
    $continuousSum = $subjectGrades->where('type', 'continuous')->where('status', 'approved')->sum('score');
    $final = $subjectGrades->where('type', 'final')->first();

    $total = null;
    if ($continuousSum > 0 || $final) {
        $fScore = $final ? $final->score : 0;
        $total = round($continuousSum + $fScore, 1);
    }

    $gradeClass = 'fail';
    if ($total !== null) {
    if ($total >= 85) $gradeClass = 'excellent';
    elseif ($total >= 70) $gradeClass = 'good';
    elseif ($total >= 50) $gradeClass = 'average';
    }
    @endphp
    <div class="grade-card">
        <div class="grade-header">
            <span class="subject-name">{{ $subject->name }}</span>
            <span class="subject-code">{{ $subject->code }}</span>
        </div>
        <div class="grade-body">
            @if($continuous || $final)
            <!-- Continuous Grade -->
            <div class="grade-row">
                <div class="grade-type">
                    <div class="type-icon" style="background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%); color: #d97706;">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                            <polyline points="14 2 14 8 20 8"></polyline>
                        </svg>
                    </div>
                    <div>
                        <div class="type-label">المحصلة</div>
                        <div class="type-weight">40%</div>
                    </div>
                </div>
                <div class="grade-score">
                    @if($continuousSum > 0)
                    <span class="score-value">{{ number_format($continuousSum, 1) }}</span>
                    <span class="score-max">/ 40</span>
                    @else
                    <span style="color: var(--text-secondary);">لم تُدخل</span>
                    @endif
                </div>
            </div>

            <!-- Final Grade -->
            <div class="grade-row">
                <div class="grade-type">
                    <div class="type-icon" style="background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%); color: #2563eb;">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                            <polyline points="22 4 12 14.01 9 11.01"></polyline>
                        </svg>
                    </div>
                    <div>
                        <div class="type-label">النهائي</div>
                        <div class="type-weight">60%</div>
                    </div>
                </div>
                <div class="grade-score">
                    @if($final)
                    <span class="score-value">{{ number_format($final->score, 1) }}</span>
                    <span class="score-max">/ {{ $final->max_score }}</span>
                    @else
                    <span style="color: var(--text-secondary);">لم تُدخل</span>
                    @endif
                </div>
            </div>

            <!-- Total -->
            @if($total !== null)
            <div class="total-row">
                <span class="total-label">المجموع الكلي</span>
                <span class="total-badge {{ $gradeClass }}">{{ $total }}%</span>
            </div>
            @endif
            @else
            <div class="no-grades">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom: 0.5rem;">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="12" y1="8" x2="12" y2="12"></line>
                    <line x1="12" y1="16" x2="12.01" y2="16"></line>
                </svg>
                <p style="margin: 0;">لم يتم إدخال درجات بعد</p>
            </div>
            @endif
        </div>
    </div>
    @empty
    <div class="empty-state">
        <div class="empty-icon">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                <line x1="18" y1="20" x2="18" y2="10"></line>
                <line x1="12" y1="20" x2="12" y2="4"></line>
                <line x1="6" y1="20" x2="6" y2="14"></line>
            </svg>
        </div>
        <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem;">لا توجد مقررات</h3>
        <p style="color: var(--text-secondary);">لم يتم تسجيل أي مواد دراسية لك في هذا الفصل.</p>
    </div>
    @endforelse
</div>

@endsection