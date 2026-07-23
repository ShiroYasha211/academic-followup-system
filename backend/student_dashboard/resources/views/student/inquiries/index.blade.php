@extends('layouts.student')

@section('title', 'استفسارات الدكتور')

@section('content')
<style>
    .page-shell {
        display: flex;
        flex-direction: column;
        gap: 1.5rem;
    }

    .page-hero {
        background: linear-gradient(135deg, #0f172a 0%, #1d4ed8 100%);
        border-radius: 24px;
        padding: 2rem;
        color: white;
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 1rem;
        flex-wrap: wrap;
    }

    .page-title {
        font-size: 1.9rem;
        font-weight: 900;
        margin: 0 0 0.5rem;
    }

    .page-subtitle {
        margin: 0;
        color: rgba(255,255,255,.78);
        font-weight: 700;
    }

    .new-inquiry-btn {
        padding: 0.85rem 1.4rem;
        background: white;
        color: #1d4ed8;
        border-radius: 14px;
        font-weight: 800;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        transition: .2s ease;
    }

    .new-inquiry-btn:hover {
        transform: translateY(-1px);
        box-shadow: 0 14px 30px -18px rgba(15,23,42,.45);
        color: #1d4ed8;
    }

    .stats-row,
    .filter-row {
        display: flex;
        gap: 0.75rem;
        flex-wrap: wrap;
    }

    .stat-badge,
    .filter-btn {
        display: inline-flex;
        align-items: center;
        gap: 0.45rem;
        padding: 0.65rem 1rem;
        border-radius: 14px;
        font-weight: 700;
        text-decoration: none;
    }

    .filter-btn {
        color: #475569;
        background: white;
        border: 1px solid #e2e8f0;
    }

    .filter-btn.active {
        background: #1d4ed8;
        border-color: #1d4ed8;
        color: white;
    }

    .inquiry-list {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    .inquiry-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        transition: .2s ease;
        box-shadow: 0 18px 40px -34px rgba(15, 23, 42, 0.28);
        position: relative;
    }

    .inquiry-card:hover {
        transform: translateY(-3px);
        box-shadow: 0 24px 48px -34px rgba(15, 23, 42, 0.38);
        border-color: #cbd5e1;
    }

    .inquiry-topline {
        height: 4px;
        background: linear-gradient(90deg, #1d4ed8 0%, #38bdf8 100%);
    }

    .inquiry-header {
        padding: 1.25rem;
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 1rem;
    }

    .inquiry-subject-wrap {
        display: flex;
        flex-direction: column;
        gap: 0.6rem;
    }

    .inquiry-subject {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.38rem 0.8rem;
        background: #f1f5f9;
        border-radius: 999px;
        font-size: 0.8rem;
        font-weight: 700;
        color: #475569;
        width: fit-content;
    }

    .subject-status {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        width: fit-content;
        padding: 0.28rem 0.7rem;
        border-radius: 999px;
        font-size: 0.75rem;
        font-weight: 800;
    }

    .subject-status.open {
        background: #dcfce7;
        color: #166534;
    }

    .subject-status.closed {
        background: #fee2e2;
        color: #991b1b;
    }

    .closed-note {
        font-size: 0.82rem;
        color: #b45309;
        background: #fff7ed;
        border-right: 3px solid #f59e0b;
        padding: 0.5rem 0.75rem;
        border-radius: 10px;
        line-height: 1.6;
    }

    .inquiry-title {
        font-weight: 800;
        color: #0f172a;
        margin-bottom: 0.35rem;
        font-size: 1.02rem;
    }

    .inquiry-preview {
        color: #64748b;
        font-size: 0.92rem;
        line-height: 1.7;
        max-width: 60ch;
    }

    .inquiry-footer {
        padding: 1rem 1.25rem;
        background: #f8fafc;
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 1rem;
    }

    .inquiry-time {
        font-size: 0.82rem;
        color: #94a3b8;
        font-weight: 700;
    }

    .status-badge {
        padding: 0.38rem 0.8rem;
        border-radius: 999px;
        font-size: 0.8rem;
        font-weight: 800;
        white-space: nowrap;
        box-shadow: inset 0 0 0 1px rgba(255,255,255,0.25);
    }

    .answer-box {
        margin: 0 1.25rem 1.25rem;
        padding: 1rem;
        background: #ecfdf5;
        border-radius: 14px;
        border-right: 4px solid #10b981;
    }

    .answer-label {
        font-size: 0.75rem;
        font-weight: 800;
        color: #059669;
        margin-bottom: 0.35rem;
        text-transform: uppercase;
    }

    .answer-text {
        color: #065f46;
        line-height: 1.7;
    }

    .answer-meta {
        margin-top: 0.65rem;
        font-size: 0.8rem;
        color: #047857;
        font-weight: 700;
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        padding: 0.35rem 0.7rem;
        border-radius: 999px;
        background: rgba(16, 185, 129, 0.12);
    }

    .answer-badges {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 0.75rem;
        flex-wrap: wrap;
        margin-top: 0.75rem;
    }

    .actor-chip {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        padding: 0.34rem 0.68rem;
        border-radius: 999px;
        background: #eef2ff;
        color: #4338ca;
        font-size: 0.76rem;
        font-weight: 800;
    }

    .details-link {
        color: #1d4ed8;
        font-weight: 800;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.3rem;
    }

    .details-link:hover {
        color: #1e40af;
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
        background: #f1f5f9;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 1.5rem;
        color: #94a3b8;
    }
</style>

<div class="page-shell">
    <div class="page-hero">
        <div>
            <h1 class="page-title">استفساراتي للدكتور</h1>
            <p class="page-subtitle">تابع حالة الاستفسار، واعرف هل تم الرد من المندوب أو من الدكتور بشكل واضح.</p>
        </div>

        <a href="{{ route('student.inquiries.create') }}" class="new-inquiry-btn">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            استفسار جديد
        </a>
    </div>

    <div class="stats-row">
        <span class="stat-badge" style="background: #eff6ff; color: #2563eb;">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
            </svg>
            {{ $stats['total'] }} استفسار
        </span>
        <span class="stat-badge" style="background: #fef3c7; color: #d97706;">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
            {{ $stats['pending'] }} قيد الانتظار
        </span>
        <span class="stat-badge" style="background: #dcfce7; color: #16a34a;">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="20 6 9 17 4 12"></polyline>
            </svg>
            {{ $stats['answered'] }} تم الرد
        </span>
    </div>

    <div class="filter-row">
        <a href="{{ route('student.inquiries.index') }}" class="filter-btn {{ !$status ? 'active' : '' }}">الكل</a>
        <a href="{{ route('student.inquiries.index', ['status' => 'pending']) }}" class="filter-btn {{ $status == 'pending' ? 'active' : '' }}">قيد الانتظار</a>
        <a href="{{ route('student.inquiries.index', ['status' => 'forwarded']) }}" class="filter-btn {{ $status == 'forwarded' ? 'active' : '' }}">تم التحويل</a>
        <a href="{{ route('student.inquiries.index', ['status' => 'answered']) }}" class="filter-btn {{ $status == 'answered' ? 'active' : '' }}">تم الرد</a>
    </div>

    @if($inquiries->count() > 0)
        <div class="inquiry-list">
            @foreach($inquiries as $inquiry)
                @php
                    $subject = $inquiry->subject;
                    $canReceive = (bool) ($subject && $subject->doctor_id && $subject->inquiries_enabled);
                @endphp
                <div class="inquiry-card">
                    <div class="inquiry-topline"></div>
                    <div class="inquiry-header">
                        <div>
                            <div class="inquiry-subject-wrap">
                                <div class="inquiry-subject">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                                        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                                    </svg>
                                    {{ $subject->name ?? 'غير محدد' }}
                                </div>
                                <span class="subject-status {{ $canReceive ? 'open' : 'closed' }}">
                                    {{ $canReceive ? 'الاستفسارات مفتوحة' : 'الاستفسارات مغلقة' }}
                                </span>
                                @if(!$canReceive)
                                    <div class="closed-note">
                                        {{ $subject->inquiries_closed_reason ?: 'هذه المادة لا تستقبل استفسارات جديدة حاليًا.' }}
                                    </div>
                                @endif
                            </div>
                            <h3 class="inquiry-title" style="margin-top: 0.6rem;">{{ $inquiry->title }}</h3>
                            <p class="inquiry-preview">{{ Str::limit($inquiry->question, 100) }}</p>
                        </div>
                        <span class="status-badge" style="background: {{ $inquiry->status_color }}20; color: {{ $inquiry->status_color }};">
                            {{ $inquiry->status_label }}
                        </span>
                    </div>

                    @if($inquiry->answer)
                        <div class="answer-box">
                            <div class="answer-label">تم الرد</div>
                            <div class="answer-text">{{ $inquiry->answer }}</div>
                            <div class="answer-badges">
                                @if($inquiry->answered_by_actor_name)
                                    <div class="answer-meta">
                                        <i class="fa-solid fa-user-check"></i>
                                        <span>بواسطة {{ $inquiry->answered_by_actor_label ?? 'المجيب' }}: {{ $inquiry->answered_by_actor_name }}</span>
                                    </div>
                                @endif

                                @if($inquiry->answered_by_actor_label)
                                    <div class="actor-chip">
                                        <i class="fa-solid fa-circle-dot"></i>
                                        <span>{{ $inquiry->answered_by_actor_label }}</span>
                                    </div>
                                @endif
                            </div>
                        </div>
                    @endif

                    <div class="inquiry-footer">
                        <span class="inquiry-time">{{ $inquiry->created_at->diffForHumans() }}</span>
                        <a href="{{ route('student.inquiries.show', $inquiry->id) }}" class="details-link">
                            عرض التفاصيل
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="9 18 15 12 9 6"></polyline>
                            </svg>
                        </a>
                    </div>
                </div>
            @endforeach
        </div>

        @if($inquiries->hasPages())
            <div style="margin-top: 2rem; display: flex; justify-content: center;">
                {{ $inquiries->appends(['status' => $status])->links() }}
            </div>
        @endif
    @else
        <div class="empty-state">
            <div class="empty-icon">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                    <circle cx="12" cy="12" r="10"></circle>
                    <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                </svg>
            </div>
            <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem;">لا توجد استفسارات</h3>
            <p style="color: var(--text-secondary); margin-bottom: 1.5rem;">يمكنك إرسال استفسار جديد للدكتور عبر المادة المتاحة.</p>
            <a href="{{ route('student.inquiries.create') }}" class="new-inquiry-btn" style="display: inline-flex;">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="12" y1="5" x2="12" y2="19"></line>
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
                استفسار جديد
            </a>
        </div>
    @endif
</div>
@endsection
