@extends('layouts.student')

@section('title', 'عرض الاستفسار')

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

    .back-btn {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        color: white;
        text-decoration: none;
        font-weight: 800;
        padding: 0.8rem 1.1rem;
        border-radius: 14px;
        background: rgba(255,255,255,0.12);
    }

    .back-btn:hover {
        color: white;
        background: rgba(255,255,255,0.18);
    }

    .hero-title {
        font-size: 1.8rem;
        font-weight: 900;
        margin: 0 0 0.5rem;
    }

    .hero-meta {
        display: flex;
        gap: 0.6rem;
        flex-wrap: wrap;
    }

    .hero-chip {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        padding: 0.4rem 0.8rem;
        border-radius: 999px;
        background: rgba(255,255,255,0.12);
        color: rgba(255,255,255,0.92);
        font-size: 0.82rem;
        font-weight: 800;
    }

    .content-card {
        background: white;
        border-radius: 22px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        box-shadow: 0 18px 40px -34px rgba(15, 23, 42, 0.28);
    }

    .content-header {
        padding: 1.5rem;
        border-bottom: 1px solid #f1f5f9;
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 1rem;
    }

    .subject-badge {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.38rem 0.8rem;
        background: #f1f5f9;
        border-radius: 999px;
        font-size: 0.85rem;
        font-weight: 700;
        color: #475569;
        margin-bottom: 0.6rem;
    }

    .inquiry-title {
        font-size: 1.3rem;
        font-weight: 900;
        color: #0f172a;
        margin: 0 0 0.25rem;
    }

    .inquiry-time {
        font-size: 0.82rem;
        color: #94a3b8;
        font-weight: 700;
    }

    .status-badge {
        padding: 0.45rem 0.9rem;
        border-radius: 999px;
        font-size: 0.82rem;
        font-weight: 800;
        white-space: nowrap;
    }

    .section {
        padding: 1.5rem;
    }

    .section-label {
        font-size: 0.75rem;
        font-weight: 800;
        color: #64748b;
        text-transform: uppercase;
        margin-bottom: 0.75rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .question-box {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 16px;
        padding: 1rem 1.1rem;
        color: #0f172a;
        line-height: 1.8;
        white-space: pre-wrap;
    }

    .answer-section {
        padding: 1.5rem;
        background: #ecfdf5;
        border-top: 1px solid #d1fae5;
    }

    .answer-section .section-label {
        color: #059669;
    }

    .answer-box {
        color: #065f46;
        line-height: 1.8;
        white-space: pre-wrap;
    }

    .responder-meta {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        margin-top: 0.9rem;
        padding: 0.45rem 0.8rem;
        border-radius: 999px;
        background: rgba(16, 185, 129, 0.12);
        color: #065f46;
        font-size: 0.82rem;
        font-weight: 800;
    }

    .waiting-section {
        padding: 2rem;
        text-align: center;
        background: #f8fafc;
        border-top: 1px solid #f1f5f9;
    }

    .waiting-icon {
        width: 60px;
        height: 60px;
        background: #fef3c7;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 1rem;
        color: #d97706;
    }
</style>

<div class="page-shell">
    <div class="page-hero">
        <div>
            <h1 class="hero-title">تفاصيل الاستفسار</h1>
            <div class="hero-meta">
                <span class="hero-chip">{{ $inquiry->subject->name ?? 'غير محدد' }}</span>
                <span class="hero-chip">{{ $inquiry->status_label }}</span>
                <span class="hero-chip">تم الإرسال {{ $inquiry->created_at->diffForHumans() }}</span>
            </div>
        </div>

        <a href="{{ route('student.inquiries.index') }}" class="back-btn">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg>
            العودة للاستفسارات
        </a>
    </div>

    <div class="content-card">
        <div class="content-header">
            <div>
                <div class="subject-badge">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                    </svg>
                    {{ $inquiry->subject->name ?? 'غير محدد' }}
                </div>
                <h2 class="inquiry-title">{{ $inquiry->title }}</h2>
                <div class="inquiry-time">أرسلت هذا الاستفسار {{ $inquiry->created_at->diffForHumans() }}</div>
            </div>
            <span class="status-badge" style="background: {{ $inquiry->status_color }}20; color: {{ $inquiry->status_color }};">
                {{ $inquiry->status_label }}
            </span>
        </div>

        <div class="section">
            <div class="section-label">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                </svg>
                السؤال
            </div>
            <div class="question-box">{{ $inquiry->question }}</div>
        </div>

        @if($inquiry->answer)
            <div class="answer-section">
                <div class="section-label">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                    الرد
                    @if($inquiry->answered_at)
                        <span style="font-weight: 400; font-size: 0.7rem;">({{ $inquiry->answered_at->diffForHumans() }})</span>
                    @endif
                </div>

                <div class="answer-box">{{ $inquiry->answer }}</div>

                @if($inquiry->answered_by_actor_name)
                    <div class="responder-meta">
                        <i class="fa-solid fa-user-check"></i>
                        <span>تم الرد بواسطة {{ $inquiry->answered_by_actor_label ?? 'المجيب' }}: {{ $inquiry->answered_by_actor_name }}</span>
                    </div>
                @endif
            </div>
        @elseif($inquiry->status !== 'closed')
            <div class="waiting-section">
                <div class="waiting-icon">
                    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="10"></circle>
                        <polyline points="12 6 12 12 16 14"></polyline>
                    </svg>
                </div>
                <div style="font-weight: 800; color: #0f172a; margin-bottom: 0.25rem;">في انتظار الرد</div>
                <div style="color: #64748b; font-size: 0.95rem;">سيتم إشعارك عند وصول رد من المندوب أو الدكتور.</div>
            </div>
        @endif
    </div>
</div>
@endsection
