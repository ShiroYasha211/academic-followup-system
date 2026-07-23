@extends('layouts.student')

@section('title', 'التنبيهات والإنذارات')

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

    /* Stats Summary */
    .stats-summary {
        display: flex;
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .summary-badge {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.6rem 1.25rem;
        background: white;
        border-radius: 12px;
        border: 1px solid #e2e8f0;
        font-weight: 600;
        font-size: 0.9rem;
    }

    .summary-badge .count {
        background: #f1f5f9;
        padding: 0.2rem 0.6rem;
        border-radius: 6px;
        font-weight: 700;
    }

    .summary-badge.unread .count {
        background: #fee2e2;
        color: #dc2626;
    }

    /* Alert Card */
    .alert-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        margin-bottom: 1rem;
        transition: all 0.3s ease;
    }

    .alert-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 20px -6px rgba(0, 0, 0, 0.08);
    }

    .alert-card.unread {
        border-color: #fca5a5;
        background: linear-gradient(135deg, #fef2f2 0%, #fff 100%);
    }

    .alert-card.unread .card-stripe {
        background: linear-gradient(180deg, #dc2626 0%, #ef4444 100%);
    }

    .card-stripe {
        width: 4px;
        position: absolute;
        top: 0;
        right: 0;
        bottom: 0;
        background: #e2e8f0;
    }

    .alert-content {
        padding: 1.5rem;
        padding-right: 1.75rem;
        position: relative;
    }

    .alert-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 0.75rem;
    }

    .alert-icon {
        width: 48px;
        height: 48px;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        margin-left: 1rem;
    }

    .alert-card.unread .alert-icon {
        background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%);
        color: #dc2626;
    }

    .alert-card:not(.unread) .alert-icon {
        background: #f1f5f9;
        color: var(--text-secondary);
    }

    .alert-title {
        font-size: 1.1rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.25rem;
    }

    .alert-time {
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    .alert-message {
        color: var(--text-secondary);
        line-height: 1.7;
        margin-right: 4rem;
    }

    .mark-read-btn {
        padding: 0.5rem 1rem;
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        color: white;
        border: none;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.85rem;
        cursor: pointer;
        transition: all 0.2s;
    }

    .mark-read-btn:hover {
        transform: scale(1.02);
        box-shadow: 0 4px 12px -2px rgba(79, 70, 229, 0.4);
    }

    /* Empty State */
    .empty-state {
        text-align: center;
        padding: 4rem 2rem;
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
    }

    .empty-icon {
        width: 80px;
        height: 80px;
        background: linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%);
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 1.5rem;
        color: #16a34a;
    }
</style>

<div class="page-header">
    <h1 class="page-title">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: #dc2626;">
            <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
            <line x1="12" y1="9" x2="12" y2="13"></line>
            <line x1="12" y1="17" x2="12.01" y2="17"></line>
        </svg>
        التنبيهات والإنذارات
    </h1>
    <p class="page-subtitle">سجل التنبيهات والإنذارات المرسلة من القسم الأكاديمي</p>
</div>

@php
$unreadCount = $alerts->whereNull('read_at')->count();
$readCount = $alerts->whereNotNull('read_at')->count();
@endphp

<div class="stats-summary">
    <div class="summary-badge unread">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="12" y1="8" x2="12" y2="12"></line>
            <line x1="12" y1="16" x2="12.01" y2="16"></line>
        </svg>
        غير مقروء
        <span class="count">{{ $unreadCount }}</span>
    </div>
    <div class="summary-badge">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
        مقروء
        <span class="count">{{ $readCount }}</span>
    </div>
</div>

@if($alerts->count() > 0)
<div>
    @foreach($alerts as $alert)
    <div class="alert-card {{ $alert->read_at ? '' : 'unread' }}">
        <div class="card-stripe"></div>
        <div class="alert-content">
            <div class="alert-header">
                <div style="display: flex; align-items: flex-start;">
                    <div class="alert-icon">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                            <line x1="12" y1="9" x2="12" y2="13"></line>
                            <line x1="12" y1="17" x2="12.01" y2="17"></line>
                        </svg>
                    </div>
                    <div>
                        <div class="alert-title">{{ $alert->data['title'] ?? 'تنبيه جديد' }}</div>
                        <div class="alert-time">{{ $alert->created_at->diffForHumans() }}</div>
                    </div>
                </div>
                @if(!$alert->read_at)
                <form action="{{ route('student.alerts.read', $alert->id) }}" method="POST">
                    @csrf
                    <button type="submit" class="mark-read-btn">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display: inline; vertical-align: middle; margin-left: 0.25rem;">
                            <polyline points="20 6 9 17 4 12"></polyline>
                        </svg>
                        تحديد كمقروء
                    </button>
                </form>
                @endif
            </div>
            <p class="alert-message">{{ $alert->data['message'] ?? 'لا توجد تفاصيل.' }}</p>
        </div>
    </div>
    @endforeach

    <div style="margin-top: 2rem;">
        {{ $alerts->links() }}
    </div>
</div>
@else
<div class="empty-state">
    <div class="empty-icon">
        <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
    </div>
    <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem;">سجلك نظيف!</h3>
    <p style="color: var(--text-secondary);">لا توجد إنذارات أو تنبيهات حالياً</p>
</div>
@endif

@endsection