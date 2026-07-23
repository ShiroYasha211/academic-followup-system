@extends('layouts.student')

@section('title', 'التذكيرات والمواعيد')

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

    /* Stats Grid */
    .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 1.25rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: white;
        border-radius: 16px;
        padding: 1.25rem;
        border: 1px solid #e2e8f0;
        display: flex;
        align-items: center;
        gap: 1rem;
        transition: all 0.2s;
    }

    .stat-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.06);
    }

    .stat-icon {
        width: 52px;
        height: 52px;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .stat-value {
        font-size: 1.5rem;
        font-weight: 800;
        color: var(--text-primary);
    }

    .stat-label {
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    /* Reminders Grid */
    .reminders-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
        gap: 1.5rem;
    }

    .reminder-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        transition: all 0.3s ease;
    }

    .reminder-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 16px 32px -8px rgba(0, 0, 0, 0.1);
    }

    .card-stripe {
        height: 5px;
    }

    .card-stripe.urgent {
        background: linear-gradient(90deg, #dc2626 0%, #ef4444 100%);
    }

    .card-stripe.soon {
        background: linear-gradient(90deg, #f59e0b 0%, #fbbf24 100%);
    }

    .card-stripe.normal {
        background: linear-gradient(90deg, #4f46e5 0%, #6366f1 100%);
    }

    .card-stripe.passed {
        background: linear-gradient(90deg, #6b7280 0%, #9ca3af 100%);
    }

    .card-body {
        padding: 1.5rem;
    }

    .card-header-row {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 1rem;
        gap: 1rem;
    }

    .reminder-title {
        font-size: 1.1rem;
        font-weight: 700;
        color: var(--text-primary);
        margin: 0;
        line-height: 1.4;
    }

    .time-badge {
        display: flex;
        align-items: center;
        gap: 0.35rem;
        font-size: 0.8rem;
        font-weight: 700;
        padding: 0.4rem 0.75rem;
        border-radius: 10px;
        white-space: nowrap;
    }

    .time-badge.urgent {
        background: #fef2f2;
        color: #dc2626;
    }

    .time-badge.soon {
        background: #fffbeb;
        color: #d97706;
    }

    .time-badge.normal {
        background: #eff6ff;
        color: #2563eb;
    }

    .time-badge.passed {
        background: #f3f4f6;
        color: #6b7280;
    }

    .reminder-desc {
        color: var(--text-secondary);
        line-height: 1.6;
        margin-bottom: 1.25rem;
        font-size: 0.95rem;
    }

    .card-footer {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding-top: 1rem;
        border-top: 1px solid #f1f5f9;
    }

    .date-info {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    .date-info .icon {
        width: 32px;
        height: 32px;
        background: #f8fafc;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: #64748b;
    }

    .countdown-box {
        text-align: center;
        background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
        padding: 0.75rem 1.25rem;
        border-radius: 12px;
    }

    .countdown-box.urgent {
        background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%);
    }

    .countdown-number {
        font-size: 1.25rem;
        font-weight: 800;
        color: var(--text-primary);
    }

    .countdown-label {
        font-size: 0.7rem;
        color: var(--text-secondary);
        text-transform: uppercase;
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
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
            <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
        </svg>
        التذكيرات والمواعيد
    </h1>
    <p class="page-subtitle">استعراض المواعيد الهامة والتنبيهات المجدولة</p>
</div>

<!-- Stats Grid -->
@php
$now = \Carbon\Carbon::now();
$upcomingCount = $reminders->filter(fn($r) => $r->event_date > $now)->count();
$todayCount = $reminders->filter(fn($r) => $r->event_date->isToday())->count();
$urgentCount = $reminders->filter(fn($r) => $r->event_date > $now && $now->diffInDays($r->event_date, false) <= 2)->count();
@endphp

<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-icon" style="background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%); color: #2563eb;">
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
                <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
            </svg>
        </div>
        <div>
            <div class="stat-value">{{ $reminders->count() }}</div>
            <div class="stat-label">إجمالي التذكيرات</div>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-icon" style="background: linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%); color: #16a34a;">
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
        </div>
        <div>
            <div class="stat-value">{{ $upcomingCount }}</div>
            <div class="stat-label">قادمة</div>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-icon" style="background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%); color: #dc2626;">
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                <line x1="12" y1="9" x2="12" y2="13"></line>
                <line x1="12" y1="17" x2="12.01" y2="17"></line>
            </svg>
        </div>
        <div>
            <div class="stat-value">{{ $urgentCount }}</div>
            <div class="stat-label">عاجلة (خلال يومين)</div>
        </div>
    </div>
</div>

<!-- Reminders List -->
@if($reminders->count() > 0)
<div class="reminders-grid">
    @foreach($reminders as $reminder)
    @php
    $eventDate = $reminder->event_date->copy();
    $isPassed = $eventDate < $now;
        $daysLeft=(int) floor($now->copy()->startOfDay()->diffInDays($eventDate->copy()->startOfDay(), false));

        if ($isPassed) {
        $stripeClass = 'passed';
        $badgeClass = 'passed';
        $badgeText = 'انتهى';
        } elseif ($daysLeft <= 1) {
            $stripeClass='urgent' ;
            $badgeClass='urgent' ;
            $badgeText=$daysLeft==0 ? 'اليوم!' : 'غداً' ;
            } elseif ($daysLeft <=3) {
            $stripeClass='soon' ;
            $badgeClass='soon' ;
            $badgeText=$daysLeft . ' أيام' ;
            } else {
            $stripeClass='normal' ;
            $badgeClass='normal' ;
            $badgeText=$daysLeft . ' يوم' ;
            }
            @endphp
            <div class="reminder-card">
            <div class="card-stripe {{ $stripeClass }}"></div>
            <div class="card-body">
                <div class="card-header-row">
                    <h3 class="reminder-title">{{ $reminder->title }}</h3>
                    <span class="time-badge {{ $badgeClass }}">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <circle cx="12" cy="12" r="10"></circle>
                            <polyline points="12 6 12 12 16 14"></polyline>
                        </svg>
                        {{ $badgeText }}
                    </span>
                </div>

                @if($reminder->description)
                <p class="reminder-desc">{{ $reminder->description }}</p>
                @endif

                <div class="card-footer">
                    <div class="date-info">
                        <div class="icon">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                                <line x1="16" y1="2" x2="16" y2="6"></line>
                                <line x1="8" y1="2" x2="8" y2="6"></line>
                                <line x1="3" y1="10" x2="21" y2="10"></line>
                            </svg>
                        </div>
                        <div>
                            <div style="font-weight: 600; color: var(--text-primary);">{{ $eventDate->format('Y/m/d') }}</div>
                            <div style="font-size: 0.75rem;">{{ $eventDate->format('h:i A') }}</div>
                        </div>
                    </div>

                    @if(!$isPassed)
                    <div class="countdown-box {{ $daysLeft <= 1 ? 'urgent' : '' }}">
                        <div class="countdown-number">{{ max(0, $daysLeft) }}</div>
                        <div class="countdown-label">يوم متبقي</div>
                    </div>
                    @else
                    <div class="countdown-box" style="background: #f3f4f6;">
                        <div class="countdown-number" style="color: #9ca3af;">✓</div>
                        <div class="countdown-label">منتهي</div>
                    </div>
                    @endif
                </div>
            </div>
</div>
@endforeach
</div>
@else
<div class="empty-state">
    <div class="empty-icon">
        <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
            <polyline points="22 4 12 14.01 9 11.01"></polyline>
        </svg>
    </div>
    <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem;">🎉 لا توجد تذكيرات</h3>
    <p style="color: var(--text-secondary);">لا توجد أي تذكيرات أو مواعيد هامة حالياً.</p>
</div>
@endif

@endsection
