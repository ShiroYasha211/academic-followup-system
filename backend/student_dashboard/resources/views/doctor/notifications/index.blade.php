@extends('layouts.doctor')

@section('title', 'الإشعارات')

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

    .mark-all-btn {
        padding: 0.75rem 1.5rem;
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        color: white;
        border: none;
        border-radius: 12px;
        font-weight: 700;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        transition: all 0.2s;
    }

    .mark-all-btn:hover {
        box-shadow: 0 4px 12px -2px rgba(79, 70, 229, 0.4);
        transform: translateY(-1px);
    }

    .stats-row {
        display: flex;
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .stat-badge {
        padding: 0.5rem 1rem;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.9rem;
    }

    .notification-list {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    .notification-card {
        background: white;
        border-radius: 16px;
        border: 1px solid #e2e8f0;
        padding: 1.25rem;
        display: flex;
        gap: 1rem;
        transition: all 0.2s;
    }

    .notification-card:hover {
        box-shadow: 0 4px 12px -4px rgba(0, 0, 0, 0.1);
    }

    .notification-card.unread {
        border-right: 4px solid var(--primary-color);
        background: linear-gradient(135deg, #fafbff 0%, #f8fafc 100%);
    }

    .notification-icon {
        width: 48px;
        height: 48px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .notification-content {
        flex: 1;
    }

    .notification-title {
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.25rem;
    }

    .notification-message {
        color: var(--text-secondary);
        font-size: 0.9rem;
        line-height: 1.6;
        margin-bottom: 0.5rem;
        white-space: pre-line;
    }

    .notification-time {
        font-size: 0.8rem;
        color: #94a3b8;
    }

    .notification-actions {
        display: flex;
        align-items: center;
    }

    .mark-read-btn {
        padding: 0.5rem;
        background: #f1f5f9;
        border: none;
        border-radius: 8px;
        cursor: pointer;
        color: #64748b;
        transition: all 0.2s;
    }

    .mark-read-btn:hover {
        background: #e2e8f0;
        color: var(--primary-color);
    }

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
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
            <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
        </svg>
        الإشعارات
    </h1>
    @if($unreadCount > 0)
    <form action="{{ route('doctor.notifications.markAllRead') }}" method="POST">
        @csrf
        <button type="submit" class="mark-all-btn">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="9 11 12 14 22 4"></polyline>
                <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path>
            </svg>
            تعليم الكل كمقروء
        </button>
    </form>
    @endif
</div>

<div class="stats-row">
    <span class="stat-badge" style="background: #eff6ff; color: #2563eb;">
        {{ $notifications->total() }} إشعار
    </span>
    @if($unreadCount > 0)
    <span class="stat-badge" style="background: #fef2f2; color: #dc2626;">
        {{ $unreadCount }} غير مقروء
    </span>
    @endif
</div>

@if($notifications->count() > 0)
<div class="notification-list">
    @foreach($notifications as $notification)
    <div class="notification-card {{ is_null($notification->read_at) ? 'unread' : '' }}">
        <div class="notification-icon" style="background: {{ $notification->color ?? '#4f46e5' }}20; color: {{ $notification->color ?? '#4f46e5' }};">
            @switch($notification->type)
            @case('lecture_report')
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
                <line x1="16" y1="13" x2="8" y2="13"></line>
                <line x1="16" y1="17" x2="8" y2="17"></line>
            </svg>
            @break
            @case('excuse')
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
                <line x1="16" y1="13" x2="8" y2="13"></line>
            </svg>
            @break
            @case('attendance')
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                <circle cx="8.5" cy="7" r="4"></circle>
                <polyline points="17 11 19 13 23 9"></polyline>
            </svg>
            @break
            @default
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
                <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
            </svg>
            @endswitch
        </div>
        <div class="notification-content">
            <div class="notification-title">{{ $notification->title }}</div>
            <div class="notification-message">{{ $notification->message }}</div>
            <div class="notification-time">{{ $notification->created_at->diffForHumans() }}</div>
        </div>
        @if(is_null($notification->read_at))
        <div class="notification-actions">
            <form action="{{ route('doctor.notifications.markAsRead', $notification->id) }}" method="POST">
                @csrf
                <button type="submit" class="mark-read-btn" title="تعليم كمقروء">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                </button>
            </form>
        </div>
        @endif
    </div>
    @endforeach
</div>

@if($notifications->hasPages())
<div style="margin-top: 2rem; display: flex; justify-content: center;">
    {{ $notifications->links() }}
</div>
@endif

@else
<div class="empty-state">
    <div class="empty-icon">
        <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
            <polyline points="22 4 12 14.01 9 11.01"></polyline>
        </svg>
    </div>
    <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem;">🎉 لا توجد إشعارات</h3>
    <p style="color: var(--text-secondary);">ستظهر هنا الإشعارات الجديدة مثل تقارير المحاضرات وطلبات الأعذار.</p>
</div>
@endif

@endsection