@extends('layouts.doctor')

@section('title', 'التقارير')

@section('content')

<style>
    .page-header {
        margin-bottom: 2rem;
    }

    .page-title {
        font-size: 1.75rem;
        font-weight: 800;
        color: var(--text-primary);
        display: flex;
        align-items: center;
        gap: 0.75rem;
        margin-bottom: 0.5rem;
    }

    .page-subtitle {
        color: var(--text-secondary);
    }

    .subjects-grid {
        display: flex;
        flex-direction: column;
        gap: 1.25rem;
    }

    .subject-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        padding: 1.75rem;
        transition: all 0.2s;
    }

    .subject-card:hover {
        border-color: var(--primary-color);
        box-shadow: 0 8px 20px -8px rgba(79, 70, 229, 0.2);
    }

    .subject-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 1.5rem;
    }

    .subject-info {
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .subject-icon {
        width: 56px;
        height: 56px;
        border-radius: 14px;
        background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        color: #4f46e5;
    }

    .subject-name {
        font-size: 1.25rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.25rem;
    }

    .subject-meta {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    .subject-badge {
        padding: 0.35rem 0.75rem;
        background: #f1f5f9;
        border-radius: 8px;
        font-size: 0.8rem;
        font-weight: 600;
    }

    .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
        gap: 1rem;
        margin-bottom: 1.5rem;
    }

    .stat-box {
        background: #f8fafc;
        border-radius: 12px;
        padding: 1rem;
        text-align: center;
    }

    .stat-box-value {
        font-size: 1.5rem;
        font-weight: 700;
        margin-bottom: 0.25rem;
    }

    .stat-box-value.success {
        color: #10b981;
    }

    .stat-box-value.danger {
        color: #ef4444;
    }

    .stat-box-value.warning {
        color: #f59e0b;
    }

    .stat-box-value.info {
        color: #3b82f6;
    }

    .stat-box-label {
        font-size: 0.75rem;
        color: var(--text-secondary);
    }

    .progress-section {
        margin-bottom: 1.25rem;
    }

    .progress-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 0.5rem;
    }

    .progress-label {
        font-weight: 600;
        font-size: 0.9rem;
        color: var(--text-primary);
    }

    .progress-value {
        font-weight: 700;
        font-size: 1.25rem;
    }

    .progress-bar {
        height: 10px;
        background: #e2e8f0;
        border-radius: 5px;
        overflow: hidden;
    }

    .progress-fill {
        height: 100%;
        border-radius: 5px;
        transition: width 0.5s ease;
    }

    .progress-fill.success {
        background: linear-gradient(90deg, #10b981, #059669);
    }

    .progress-fill.warning {
        background: linear-gradient(90deg, #f59e0b, #d97706);
    }

    .progress-fill.danger {
        background: linear-gradient(90deg, #ef4444, #dc2626);
    }

    .subject-actions {
        display: flex;
        gap: 0.75rem;
    }

    .btn-report {
        padding: 0.75rem 1.5rem;
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        color: white;
        border: none;
        border-radius: 12px;
        font-weight: 600;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        transition: all 0.2s;
    }

    .btn-report:hover {
        box-shadow: 0 4px 12px -2px rgba(79, 70, 229, 0.4);
        color: white;
    }

    .empty-state {
        text-align: center;
        padding: 4rem 2rem;
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
    }
</style>

<div class="page-header">
    <h1 class="page-title">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
            <line x1="18" y1="20" x2="18" y2="10"></line>
            <line x1="12" y1="20" x2="12" y2="4"></line>
            <line x1="6" y1="20" x2="6" y2="14"></line>
        </svg>
        التقارير الدراسية
    </h1>
    <p class="page-subtitle">عرض إحصائيات وتقارير الحضور لكل مقرر</p>
</div>

<div class="subjects-grid">
    @forelse($subjects as $subject)
    @php
    $progressClass = $subject->attendance_rate >= 70 ? 'success' : ($subject->attendance_rate >= 50 ? 'warning' : 'danger');
    @endphp
    <div class="subject-card">
        <div class="subject-header">
            <div class="subject-info">
                <div class="subject-icon">
                    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                    </svg>
                </div>
                <div>
                    <div class="subject-name">{{ $subject->name }}</div>
                    <div class="subject-meta">
                        <span class="subject-badge">{{ $subject->major->name ?? '-' }}</span>
                        <span class="subject-badge">{{ $subject->level->name ?? '-' }}</span>
                        @if($subject->term)
                        <span class="subject-badge">{{ $subject->term->name }}</span>
                        @endif
                    </div>
                </div>
            </div>
        </div>

        <div class="stats-grid">
            <div class="stat-box">
                <div class="stat-box-value info">{{ $subject->students_count }}</div>
                <div class="stat-box-label">طالب</div>
            </div>
            <div class="stat-box">
                <div class="stat-box-value" style="color: var(--text-primary);">{{ $subject->lectures_count }}</div>
                <div class="stat-box-label">محاضرة</div>
            </div>
            <div class="stat-box">
                <div class="stat-box-value success">{{ $subject->present_count }}</div>
                <div class="stat-box-label">حضور</div>
            </div>
            <div class="stat-box">
                <div class="stat-box-value danger">{{ $subject->absent_count }}</div>
                <div class="stat-box-label">غياب</div>
            </div>
            <div class="stat-box">
                <div class="stat-box-value warning">{{ $subject->excused_count }}</div>
                <div class="stat-box-label">بعذر</div>
            </div>
        </div>

        <div class="progress-section">
            <div class="progress-header">
                <span class="progress-label">نسبة الحضور الإجمالية</span>
                <span class="progress-value" style="color: {{ $subject->attendance_rate >= 70 ? '#10b981' : ($subject->attendance_rate >= 50 ? '#f59e0b' : '#ef4444') }};">{{ $subject->attendance_rate }}%</span>
            </div>
            <div class="progress-bar">
                <div class="progress-fill {{ $progressClass }}" style="width: {{ $subject->attendance_rate }}%;"></div>
            </div>
        </div>

        <div class="subject-actions">
            <a href="{{ route('doctor.reports.show', $subject->id) }}" class="btn-report">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                    <circle cx="12" cy="12" r="3"></circle>
                </svg>
                عرض التقرير المفصل
            </a>
        </div>
    </div>
    @empty
    <div class="empty-state">
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color: #cbd5e1; margin-bottom: 1rem;">
            <line x1="18" y1="20" x2="18" y2="10"></line>
            <line x1="12" y1="20" x2="12" y2="4"></line>
            <line x1="6" y1="20" x2="6" y2="14"></line>
        </svg>
        <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem;">لا توجد مقررات</h3>
        <p style="color: var(--text-secondary);">لم يتم إسناد أي مقررات دراسية لك بعد</p>
    </div>
    @endforelse
</div>

@endsection