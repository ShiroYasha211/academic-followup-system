@extends('layouts.delegate')

@section('title', 'إدارة النتائج')

@section('content')

<style>
    /* Stats Banner */
    .stats-banner {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: white;
        border-radius: 16px;
        padding: 1.25rem;
        text-align: center;
        border: 1px solid #e2e8f0;
        transition: all 0.3s;
    }

    .stat-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 20px rgba(0, 0, 0, 0.05);
    }

    .stat-card .stat-icon {
        margin-bottom: 0.5rem;
    }

    .stat-card .stat-value {
        font-size: 1.75rem;
        font-weight: 800;
        color: var(--text-primary);
    }

    .stat-card .stat-label {
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    /* Subject Cards Grid */
    .subjects-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
        gap: 1.5rem;
    }

    .subject-card {
        background: white;
        border-radius: 20px;
        padding: 1.5rem;
        border: 1px solid #e2e8f0;
        transition: all 0.3s;
        position: relative;
        overflow: hidden;
    }

    .subject-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 12px 24px rgba(0, 0, 0, 0.06);
    }

    .subject-card::before {
        content: '';
        position: absolute;
        top: 0;
        right: 0;
        bottom: 0;
        width: 5px;
        background: var(--primary-color);
    }

    .subject-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 1rem;
    }

    .subject-name {
        font-size: 1.1rem;
        font-weight: 800;
        color: var(--text-primary);
        margin-bottom: 0.25rem;
    }

    .subject-code {
        font-size: 0.85rem;
        color: var(--text-secondary);
        font-family: monospace;
    }

    .grade-count {
        background: #eff6ff;
        color: var(--primary-color);
        padding: 0.5rem 1rem;
        border-radius: 12px;
        font-weight: 800;
        font-size: 0.9rem;
    }

    .subject-actions {
        display: flex;
        gap: 0.75rem;
        margin-top: 1.5rem;
        padding-top: 1rem;
        border-top: 1px dashed #e2e8f0;
    }

    .action-link {
        flex: 1;
        padding: 0.6rem;
        border-radius: 10px;
        text-align: center;
        text-decoration: none;
        font-weight: 700;
        font-size: 0.85rem;
        transition: all 0.2s;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.4rem;
    }

    .action-link.primary {
        background: var(--primary-color);
        color: white;
    }

    .action-link.primary:hover {
        background: #4338ca;
    }

    .action-link.secondary {
        background: #f1f5f9;
        color: var(--text-secondary);
    }

    .action-link.secondary:hover {
        background: #e2e8f0;
        color: var(--text-primary);
    }

    @media (max-width: 768px) {
        .stats-banner {
            grid-template-columns: repeat(2, 1fr);
        }
    }
</style>

<div class="container">

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
        <div>
            <h1 style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary);">إدارة النتائج</h1>
            <p style="color: var(--text-secondary);">إدخال وإدارة درجات الطلاب للمواد الدراسية.</p>
        </div>
        <a href="{{ route('delegate.grades.create') }}" class="btn btn-primary" style="padding: 0.8rem 1.5rem; border-radius: 12px; display: flex; align-items: center; gap: 0.5rem; font-weight: 700; box-shadow: 0 4px 12px rgba(67, 56, 202, 0.2);">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            إضافة درجات
        </a>
    </div>

    <!-- Stats Banner -->
    <div class="stats-banner">
        <div class="stat-card">
            <div class="stat-icon">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                </svg>
            </div>
            <div class="stat-value">{{ $stats['subjects'] }}</div>
            <div class="stat-label">المواد</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#4f46e5" stroke-width="2">
                    <line x1="18" y1="20" x2="18" y2="10"></line>
                    <line x1="12" y1="20" x2="12" y2="4"></line>
                    <line x1="6" y1="20" x2="6" y2="14"></line>
                </svg>
            </div>
            <div class="stat-value" style="color: #4f46e5;">{{ $stats['total'] }}</div>
            <div class="stat-label">إجمالي الدرجات</div>
        </div>
        <div class="stat-card" style="border-color: #fde68a;">
            <div class="stat-icon">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                    <polyline points="14 2 14 8 20 8"></polyline>
                    <line x1="16" y1="13" x2="8" y2="13"></line>
                    <line x1="16" y1="17" x2="8" y2="17"></line>
                </svg>
            </div>
            <div class="stat-value" style="color: #f59e0b;">{{ $stats['continuous'] }}</div>
            <div class="stat-label">محصلة</div>
        </div>
        <div class="stat-card" style="border-color: #bbf7d0;">
            <div class="stat-icon">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2">
                    <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
                    <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
                </svg>
            </div>
            <div class="stat-value" style="color: #10b981;">{{ $stats['final'] }}</div>
            <div class="stat-label">نهائي</div>
        </div>
    </div>

    @if(session('success'))
    <div class="alert alert-success d-flex align-items-center gap-2 mb-4" style="border-radius: 12px;">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
        {{ session('success') }}
    </div>
    @endif

    <!-- Subjects Grid -->
    <div class="subjects-grid">
        @forelse($subjects as $subject)
        <div class="subject-card">
            <div class="subject-header">
                <div>
                    <h3 class="subject-name">{{ $subject->name }}</h3>
                    <span class="subject-code">{{ $subject->code }}</span>
                </div>
                <span class="grade-count">{{ $subject->grades_count }} درجة</span>
            </div>

            <div class="subject-actions">
                <a href="{{ route('delegate.grades.create', ['subject_id' => $subject->id]) }}" class="action-link primary">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="12" y1="5" x2="12" y2="19"></line>
                        <line x1="5" y1="12" x2="19" y2="12"></line>
                    </svg>
                    إضافة
                </a>
                <a href="{{ route('delegate.grades.show', $subject->id) }}" class="action-link secondary">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                        <circle cx="12" cy="12" r="3"></circle>
                    </svg>
                    عرض
                </a>
            </div>
        </div>
        @empty
        <div style="grid-column: 1 / -1; text-align: center; padding: 4rem; background: white; border-radius: 20px; border: 2px dashed #e2e8f0;">
            <div style="width: 80px; height: 80px; background: #f8fafc; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.5rem; color: #94a3b8;">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                </svg>
            </div>
            <h3 style="font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">لا توجد مواد</h3>
            <p style="color: var(--text-secondary);">لم يتم إضافة مواد دراسية بعد.</p>
        </div>
        @endforelse
    </div>

</div>

@endsection