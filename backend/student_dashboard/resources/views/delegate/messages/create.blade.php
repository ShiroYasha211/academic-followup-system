@extends('layouts.delegate')

@section('title', 'محادثة جديدة')

@section('content')

<style>
    .page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 2rem;
    }

    .page-title {
        font-size: 1.75rem;
        font-weight: 800;
        color: var(--text-primary);
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .back-btn {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        color: var(--text-secondary);
        text-decoration: none;
        font-weight: 600;
        transition: color 0.2s;
    }

    .back-btn:hover {
        color: var(--primary-color);
    }

    .students-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
        gap: 1rem;
    }

    .student-card {
        background: white;
        border-radius: 16px;
        border: 1px solid #e2e8f0;
        padding: 1.25rem;
        display: flex;
        align-items: center;
        gap: 1rem;
        text-decoration: none;
        color: inherit;
        transition: all 0.2s;
    }

    .student-card:hover {
        border-color: var(--primary-color);
        box-shadow: 0 4px 12px -4px rgba(79, 70, 229, 0.2);
        transform: translateY(-2px);
    }

    .student-avatar {
        width: 50px;
        height: 50px;
        border-radius: 12px;
        background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        color: #4f46e5;
        font-size: 1.1rem;
        flex-shrink: 0;
    }

    .student-info h4 {
        font-weight: 700;
        color: var(--text-primary);
        margin: 0 0 0.25rem 0;
    }

    .student-info span {
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    .start-icon {
        margin-right: auto;
        color: var(--primary-color);
        opacity: 0;
        transition: opacity 0.2s;
    }

    .student-card:hover .start-icon {
        opacity: 1;
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
    <a href="{{ route('delegate.messages.index') }}" class="back-btn">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="15 18 9 12 15 6"></polyline>
        </svg>
        العودة للرسائل
    </a>
    <h1 class="page-title">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
            <line x1="12" y1="8" x2="12" y2="12"></line>
            <line x1="10" y1="10" x2="14" y2="10"></line>
        </svg>
        اختر طالب للمحادثة
    </h1>
</div>

@if($students->count() > 0)
<div class="students-grid">
    @foreach($students as $student)
    <form action="{{ route('delegate.messages.store') }}" method="POST" style="display: contents;">
        @csrf
        <input type="hidden" name="student_id" value="{{ $student->id }}">
        <button type="submit" class="student-card" style="cursor: pointer; border: 1px solid #e2e8f0;">
            <div class="student-avatar">{{ mb_substr($student->name, 0, 1) }}</div>
            <div class="student-info">
                <h4>{{ $student->name }}</h4>
                <span>{{ $student->student_number ?? 'طالب' }}</span>
            </div>
            <div class="start-icon">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="22" y1="2" x2="11" y2="13"></line>
                    <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                </svg>
            </div>
        </button>
    </form>
    @endforeach
</div>
@else
<div class="empty-state">
    <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color: #cbd5e1; margin-bottom: 1rem;">
        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
        <circle cx="9" cy="7" r="4"></circle>
        <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
        <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
    </svg>
    <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem;">لا يوجد طلاب</h3>
    <p style="color: var(--text-secondary);">لا يوجد طلاب في شعبتك حالياً.</p>
</div>
@endif

@endsection