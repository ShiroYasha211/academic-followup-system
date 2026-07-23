@extends('layouts.admin')

@section('title', 'ملخص الدفعة: ' . $level->name)

@section('content')

<style>
    .page-header {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .page-header-icon {
        width: 56px;
        height: 56px;
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
    }

    .page-header-text h1 {
        font-size: 1.5rem;
        font-weight: 700;
        margin-bottom: 0.25rem;
    }

    .page-header-text p {
        color: var(--text-secondary);
        font-size: 0.9rem;
    }

    .stats-grid {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: white;
        border-radius: 16px;
        padding: 1.25rem;
        border: 1px solid var(--border-color);
        text-align: center;
    }

    .stat-card .value {
        font-size: 2rem;
        font-weight: 700;
        margin-bottom: 0.25rem;
    }

    .stat-card .label {
        color: var(--text-secondary);
        font-size: 0.85rem;
    }

    .main-grid {
        display: grid;
        grid-template-columns: 2fr 1fr;
        gap: 1.5rem;
    }

    .section-card {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        padding: 1.5rem;
        margin-bottom: 1.5rem;
    }

    .section-card h3 {
        font-size: 1.1rem;
        font-weight: 700;
        margin-bottom: 1rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .subject-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 1rem;
        border: 1px solid var(--border-color);
        border-radius: 12px;
        margin-bottom: 0.75rem;
    }

    .subject-info h4 {
        font-size: 0.95rem;
        font-weight: 600;
        margin-bottom: 0.25rem;
    }

    .subject-info span {
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    .attendance-bar {
        width: 120px;
        height: 8px;
        background: #e5e7eb;
        border-radius: 4px;
        overflow: hidden;
    }

    .attendance-bar-fill {
        height: 100%;
        border-radius: 4px;
    }

    .delegate-card {
        background: linear-gradient(135deg, #8b5cf6, #7c3aed);
        color: white;
        padding: 1.5rem;
        border-radius: 16px;
        text-align: center;
    }

    .delegate-avatar {
        width: 60px;
        height: 60px;
        background: rgba(255, 255, 255, 0.2);
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 1rem;
        font-size: 1.5rem;
        font-weight: 700;
    }

    .back-btn {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.75rem 1.25rem;
        background: #f3f4f6;
        border-radius: 10px;
        color: var(--text-primary);
        text-decoration: none;
        font-weight: 600;
        transition: all 0.2s;
    }

    .back-btn:hover {
        background: #e5e7eb;
    }
</style>

<!-- Page Header -->
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
    <div class="page-header" style="margin: 0;">
        <div class="page-header-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="3" width="7" height="7"></rect>
                <rect x="14" y="3" width="7" height="7"></rect>
                <rect x="14" y="14" width="7" height="7"></rect>
                <rect x="3" y="14" width="7" height="7"></rect>
            </svg>
        </div>
        <div class="page-header-text">
            <h1>ملخص الدفعة: {{ $level->name }}</h1>
            <p>{{ $level->major->name ?? '-' }} - {{ $level->major->college->name ?? '-' }}</p>
        </div>
    </div>
    <a href="{{ route('admin.reports.index') }}" class="back-btn">
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="19" y1="12" x2="5" y2="12"></line>
            <polyline points="12 19 5 12 12 5"></polyline>
        </svg>
        رجوع للتقارير
    </a>
</div>

<!-- Stats Grid -->
<div class="stats-grid">
    <div class="stat-card">
        <div class="value" style="color: #10b981;">{{ $students->count() }}</div>
        <div class="label">إجمالي الطلاب</div>
    </div>
    <div class="stat-card">
        <div class="value" style="color: #3b82f6;">{{ $subjectStats->count() }}</div>
        <div class="label">المواد الدراسية</div>
    </div>
    <div class="stat-card">
        <div class="value" style="color: #8b5cf6;">{{ $level->terms->count() }}</div>
        <div class="label">الفصول الدراسية</div>
    </div>
    <div class="stat-card">
        <div class="value" style="color: #f59e0b;">{{ $subjectStats->sum('total_records') }}</div>
        <div class="label">سجلات الحضور</div>
    </div>
</div>

<!-- Main Grid -->
<div class="main-grid">
    <!-- Subjects List -->
    <div>
        <div class="section-card">
            <h3>
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                </svg>
                المواد الدراسية ونسب الحضور
            </h3>

            @forelse($subjectStats as $stat)
            <div class="subject-item">
                <div class="subject-info">
                    <h4>{{ $stat['subject']->name }}</h4>
                    <span>{{ $stat['subject']->doctor->name ?? 'غير محدد' }} - {{ $stat['subject']->term->name ?? '-' }}</span>
                </div>
                <div style="text-align: left;">
                    <div style="font-weight: 700; font-size: 1.1rem; color: {{ $stat['attendance_rate'] >= 70 ? '#10b981' : ($stat['attendance_rate'] >= 50 ? '#f59e0b' : '#ef4444') }};">
                        {{ $stat['attendance_rate'] }}%
                    </div>
                    <div class="attendance-bar">
                        <div class="attendance-bar-fill" style="width: {{ $stat['attendance_rate'] }}%; background: {{ $stat['attendance_rate'] >= 70 ? '#10b981' : ($stat['attendance_rate'] >= 50 ? '#f59e0b' : '#ef4444') }};"></div>
                    </div>
                </div>
            </div>
            @empty
            <div style="text-align: center; padding: 2rem; color: var(--text-secondary);">
                لا توجد مواد مسجلة لهذه الدفعة
            </div>
            @endforelse
        </div>
    </div>

    <!-- Side Info -->
    <div>
        @if($delegate)
        <div class="delegate-card">
            <div class="delegate-avatar">{{ mb_substr($delegate->name, 0, 1) }}</div>
            <h4>{{ $delegate->name }}</h4>
            <div style="opacity: 0.9; font-size: 0.85rem;">مندوب الدفعة</div>
            <div style="opacity: 0.8; font-size: 0.8rem; margin-top: 0.5rem;">{{ $delegate->email }}</div>
        </div>
        @else
        <div class="section-card" style="text-align: center; padding: 2rem;">
            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#d1d5db" stroke-width="1.5" style="margin-bottom: 1rem;">
                <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                <circle cx="8.5" cy="7" r="4"></circle>
            </svg>
            <div style="color: var(--text-secondary);">لم يتم تعيين مندوب لهذه الدفعة</div>
        </div>
        @endif

        <div class="section-card" style="margin-top: 1.5rem;">
            <h3>
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                    <circle cx="9" cy="7" r="4"></circle>
                </svg>
                الطلاب المسجلين
            </h3>
            <div style="max-height: 300px; overflow-y: auto;">
                @forelse($students->take(10) as $student)
                <div style="display: flex; align-items: center; gap: 0.75rem; padding: 0.5rem 0; border-bottom: 1px solid #f1f5f9;">
                    <div style="width: 32px; height: 32px; background: #d1fae5; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 0.8rem; font-weight: 600; color: #059669;">
                        {{ mb_substr($student->name, 0, 1) }}
                    </div>
                    <div>
                        <div style="font-weight: 600; font-size: 0.9rem;">{{ $student->name }}</div>
                        <div style="font-size: 0.75rem; color: var(--text-secondary);">{{ $student->student_number }}</div>
                    </div>
                </div>
                @empty
                <div style="text-align: center; color: var(--text-secondary);">لا يوجد طلاب</div>
                @endforelse
                @if($students->count() > 10)
                <div style="text-align: center; padding: 0.5rem; color: var(--text-secondary); font-size: 0.85rem;">
                    و {{ $students->count() - 10 }} طالب آخر...
                </div>
                @endif
            </div>
        </div>
    </div>
</div>

@endsection