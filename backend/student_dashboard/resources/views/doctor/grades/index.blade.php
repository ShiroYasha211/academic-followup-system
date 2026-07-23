@extends('layouts.doctor')

@section('title', 'إدارة الدرجات')

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

    .subjects-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
        gap: 1.5rem;
    }

    .subject-card {
        background: white;
        border-radius: 16px;
        border: 1px solid #e2e8f0;
        padding: 1.75rem;
        transition: all 0.2s;
        text-decoration: none;
        color: inherit;
        display: block;
    }

    .subject-card:hover {
        border-color: var(--primary-color);
        box-shadow: 0 8px 20px -8px rgba(79, 70, 229, 0.2);
        transform: translateY(-2px);
    }

    .subject-icon {
        width: 50px;
        height: 50px;
        border-radius: 12px;
        background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        color: #4f46e5;
        margin-bottom: 1.25rem;
    }

    .subject-name {
        font-size: 1.2rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.5rem;
    }

    .subject-meta {
        font-size: 0.85rem;
        color: var(--text-secondary);
        margin-bottom: 1.25rem;
    }

    .subject-stats {
        display: flex;
        gap: 1rem;
        padding-top: 1rem;
        border-top: 1px solid #f1f5f9;
    }

    .stat-item {
        flex: 1;
        text-align: center;
    }

    .stat-value {
        font-size: 1.5rem;
        font-weight: 700;
        color: var(--primary-color);
    }

    .stat-label {
        font-size: 0.75rem;
        color: var(--text-secondary);
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
            <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
            <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
        </svg>
        إدارة الدرجات
    </h1>
    <p style="color: var(--text-secondary);">اختر مقرراً لعرض وتعديل درجات الطلاب</p>
</div>

@if($subjects->count() > 0)
<div class="subjects-grid">
    @foreach($subjects as $subject)
    <a href="{{ route('doctor.grades.show', $subject->id) }}" class="subject-card">
        <div class="subject-icon">
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
            </svg>
        </div>

        <h3 class="subject-name">{{ $subject->name }}</h3>
        <p class="subject-meta">{{ $subject->major->name ?? '' }} • {{ $subject->level->name ?? '' }}</p>

        <div class="subject-stats">
            <div class="stat-item">
                <div class="stat-value">{{ $subject->grades_count ?? 0 }}</div>
                <div class="stat-label">درجات مُدخلة</div>
            </div>
        </div>
    </a>
    @endforeach
</div>
@else
<div class="empty-state">
    <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color: #cbd5e1; margin-bottom: 1rem;">
        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
    </svg>
    <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem;">لا توجد مقررات</h3>
    <p style="color: var(--text-secondary);">لم يتم إسناد أي مقررات دراسية لك بعد</p>
</div>
@endif

@endsection