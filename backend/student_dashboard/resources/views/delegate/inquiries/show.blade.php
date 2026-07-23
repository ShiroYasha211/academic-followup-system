@extends('layouts.delegate')

@section('title', 'تفاصيل الاستفسار')

@section('content')
<style>
    .page-shell {
        max-width: 1080px;
    }

    .back-link {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
        color: #64748b;
        font-weight: 800;
        margin-bottom: 1.2rem;
    }

    .back-link:hover { color: #1d4ed8; }

    .hero-card {
        background:
            radial-gradient(circle at top right, rgba(96, 165, 250, 0.22), transparent 28%),
            linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #1d4ed8 100%);
        color: #fff;
        border-radius: 28px;
        padding: 1.75rem 1.85rem;
        margin-bottom: 1.4rem;
        box-shadow: 0 28px 60px -36px rgba(15, 23, 42, 0.6);
    }

    .hero-top {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 1rem;
        flex-wrap: wrap;
    }

    .hero-title {
        font-size: 1.8rem;
        font-weight: 900;
        margin: 0 0 0.5rem;
    }

    .hero-copy {
        margin: 0;
        color: rgba(255,255,255,0.8);
        line-height: 1.8;
        max-width: 760px;
    }

    .status-chip {
        display: inline-flex;
        align-items: center;
        gap: 0.45rem;
        padding: 0.6rem 0.95rem;
        border-radius: 999px;
        background: rgba(255,255,255,0.14);
        backdrop-filter: blur(12px);
        font-weight: 800;
    }

    .grid-layout {
        display: grid;
        grid-template-columns: minmax(0, 1.65fr) 320px;
        gap: 1.25rem;
    }

    .panel {
        background: rgba(255,255,255,0.97);
        border: 1px solid rgba(148,163,184,0.16);
        border-radius: 24px;
        box-shadow: 0 22px 48px -36px rgba(15,23,42,0.45);
        overflow: hidden;
    }

    .panel-body {
        padding: 1.45rem;
    }

    .student-box {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin-bottom: 1.25rem;
    }

    .student-avatar {
        width: 56px;
        height: 56px;
        border-radius: 18px;
        background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
        color: #1d4ed8;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 900;
        font-size: 1.15rem;
    }

    .student-name {
        font-size: 1.05rem;
        font-weight: 900;
        color: #0f172a;
        margin-bottom: 0.2rem;
    }

    .student-submeta {
        color: #64748b;
        font-size: 0.88rem;
    }

    .meta-row {
        display: flex;
        gap: 0.6rem;
        flex-wrap: wrap;
        margin-bottom: 1rem;
    }

    .meta-chip {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        padding: 0.46rem 0.8rem;
        border-radius: 999px;
        background: #f8fafc;
        color: #475569;
        font-size: 0.8rem;
        font-weight: 800;
        border: 1px solid rgba(148,163,184,0.14);
    }

    .section-card {
        background: #f8fafc;
        border: 1px solid rgba(226,232,240,0.92);
        border-radius: 20px;
        padding: 1.2rem;
    }

    .section-label {
        display: flex;
        align-items: center;
        gap: 0.55rem;
        font-size: 0.78rem;
        font-weight: 900;
        color: #64748b;
        margin-bottom: 0.8rem;
    }

    .question-title {
        font-size: 1.18rem;
        font-weight: 900;
        color: #0f172a;
        margin: 0 0 0.7rem;
        line-height: 1.7;
    }

    .question-text,
    .answer-text {
        color: #334155;
        line-height: 1.95;
        white-space: pre-wrap;
        margin: 0;
    }

    .answer-card {
        margin-top: 1rem;
        background: #ecfdf5;
        border: 1px solid rgba(16,185,129,0.16);
    }

    .answer-card .section-label {
        color: #047857;
    }

    .actor-pill {
        display: inline-flex;
        align-items: center;
        gap: 0.45rem;
        margin-top: 0.9rem;
        padding: 0.48rem 0.85rem;
        border-radius: 999px;
        background: rgba(16, 185, 129, 0.12);
        color: #065f46;
        font-size: 0.82rem;
        font-weight: 800;
    }

    .side-panel {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    .action-card,
    .notice-card {
        padding: 1.35rem;
    }

    .card-title {
        font-size: 1rem;
        font-weight: 900;
        color: #0f172a;
        margin-bottom: 0.45rem;
    }

    .card-copy {
        color: #64748b;
        line-height: 1.8;
        font-size: 0.9rem;
        margin-bottom: 1rem;
    }

    .action-stack {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
    }

    .btn-action {
        width: 100%;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        border: none;
        border-radius: 14px;
        padding: 0.92rem 1rem;
        font-weight: 800;
        cursor: pointer;
        transition: all 0.2s ease;
    }

    .btn-forward {
        background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
        color: #fff;
        box-shadow: 0 18px 34px -26px rgba(37,99,235,0.85);
    }

    .btn-close {
        background: #f8fafc;
        color: #475569;
        border: 1px solid rgba(148,163,184,0.16);
    }

    .btn-submit {
        background: linear-gradient(135deg, #059669 0%, #10b981 100%);
        color: #fff;
        box-shadow: 0 18px 34px -26px rgba(5,150,105,0.85);
    }

    .btn-action:hover { transform: translateY(-1px); }

    .reply-form {
        margin-top: 1.2rem;
    }

    .reply-form textarea {
        width: 100%;
        min-height: 170px;
        border-radius: 18px;
        border: 1px solid rgba(148,163,184,0.18);
        background: #f8fafc;
        padding: 1rem 1.05rem;
        font-family: inherit;
        font-size: 0.98rem;
        resize: vertical;
        margin-bottom: 0.9rem;
    }

    .reply-form textarea:focus {
        outline: none;
        background: #fff;
        border-color: #2563eb;
        box-shadow: 0 0 0 3px rgba(37,99,235,0.1);
    }

    .notice-card.locked {
        background: linear-gradient(180deg, #eff6ff, #f8fbff);
        border: 1px solid rgba(59,130,246,0.16);
    }

    .notice-card.closed {
        background: linear-gradient(180deg, #f8fafc, #fff);
    }

    .notice-icon {
        width: 42px;
        height: 42px;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        margin-bottom: 0.85rem;
        background: rgba(37,99,235,0.1);
        color: #1d4ed8;
    }

    @media (max-width: 980px) {
        .grid-layout { grid-template-columns: 1fr; }
    }
</style>

<div class="page-shell">
    <a href="{{ route('delegate.inquiries.index') }}" class="back-link">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="15 18 9 12 15 6"></polyline>
        </svg>
        العودة إلى الاستفسارات
    </a>

    @if(session('success'))
        <div class="alert alert-success mb-4">{{ session('success') }}</div>
    @endif

    <div class="hero-card">
        <div class="hero-top">
            <div>
                <h1 class="hero-title">{{ $inquiry->title }}</h1>
                <p class="hero-copy">
                    راجع السؤال، ثم قرر هل ترد بصفتك المندوب أو تحوّل الاستفسار إلى الدكتور. بعد التحويل يصبح الاستفسار مقفولًا على المندوب ولا يمكنه إضافة رد جديد عليه.
                </p>
            </div>

            <div class="status-chip">{{ $inquiry->status_label }}</div>
        </div>
    </div>

    <div class="grid-layout">
        <div class="panel">
            <div class="panel-body">
                <div class="student-box">
                    <div class="student-avatar">{{ mb_substr($inquiry->student->name ?? '?', 0, 1) }}</div>
                    <div>
                        <div class="student-name">{{ $inquiry->student->name ?? 'غير معروف' }}</div>
                        <div class="student-submeta">{{ $inquiry->student->student_number ?: 'بدون رقم قيد' }}</div>
                    </div>
                </div>

                <div class="meta-row">
                    <span class="meta-chip">{{ $inquiry->subject->name ?? 'مادة غير محددة' }}</span>
                    <span class="meta-chip">أُرسل {{ $inquiry->created_at->diffForHumans() }}</span>
                    @if($inquiry->delegate?->name)
                        <span class="meta-chip">المندوب المسؤول: {{ $inquiry->delegate->name }}</span>
                    @endif
                </div>

                <div class="section-card">
                    <div class="section-label">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <circle cx="12" cy="12" r="10"></circle>
                            <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
                            <line x1="12" y1="17" x2="12.01" y2="17"></line>
                        </svg>
                        سؤال الطالب
                    </div>
                    <h2 class="question-title">{{ $inquiry->title }}</h2>
                    <p class="question-text">{{ $inquiry->question }}</p>
                </div>

                @if($inquiry->answer)
                    <div class="section-card answer-card">
                        <div class="section-label">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="20 6 9 17 4 12"></polyline>
                            </svg>
                            الرد المعتمد
                        </div>
                        <p class="answer-text">{{ $inquiry->answer }}</p>

                        @if($inquiry->answered_by_actor_name)
                            <div class="actor-pill">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                                    <circle cx="12" cy="7" r="4"></circle>
                                </svg>
                                تم الرد بواسطة {{ $inquiry->answered_by_actor_label }}: {{ $inquiry->answered_by_actor_name }}
                            </div>
                        @endif
                    </div>
                @endif

                @if($inquiry->canBeAnsweredByDelegate())
                    <div class="reply-form">
                        <form action="{{ route('delegate.inquiries.answer', $inquiry->id) }}" method="POST">
                            @csrf
                            <textarea name="answer" placeholder="اكتب رد المندوب هنا..." required>{{ old('answer') }}</textarea>
                            @error('answer')
                                <div class="text-danger mb-3">{{ $message }}</div>
                            @enderror
                            <button type="submit" class="btn-action btn-submit">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <line x1="22" y1="2" x2="11" y2="13"></line>
                                    <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                                </svg>
                                إرسال الرد
                            </button>
                        </form>
                    </div>
                @endif
            </div>
        </div>

        <div class="side-panel">
            <div class="panel action-card">
                <div class="card-title">إجراءات المندوب</div>
                <div class="card-copy">
                    اختر الإجراء المناسب حسب حالة الاستفسار. في وضع الانتظار تستطيع الرد أو التحويل، وبعد التحويل يتوقف دور المندوب عند هذه النقطة.
                </div>

                <div class="action-stack">
                    @if($inquiry->canBeAnsweredByDelegate())
                        <form action="{{ route('delegate.inquiries.forward', $inquiry->id) }}" method="POST">
                            @csrf
                            <button type="submit" class="btn-action btn-forward">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <polyline points="15 14 20 9 15 4"></polyline>
                                    <path d="M4 20v-7a4 4 0 0 1 4-4h12"></path>
                                </svg>
                                تحويل إلى الدكتور
                            </button>
                        </form>
                    @endif

                    @if($inquiry->status === 'pending' || ($inquiry->status === 'answered' && (int) $inquiry->answered_by === (int) auth()->id()))
                        <form action="{{ route('delegate.inquiries.close', $inquiry->id) }}" method="POST">
                            @csrf
                            <button type="submit" class="btn-action btn-close">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <line x1="18" y1="6" x2="6" y2="18"></line>
                                    <line x1="6" y1="6" x2="18" y2="18"></line>
                                </svg>
                                إغلاق الاستفسار
                            </button>
                        </form>
                    @endif
                </div>
            </div>

            @if($inquiry->wasForwardedToDoctor())
                <div class="panel notice-card locked">
                    <div class="notice-icon">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <polyline points="15 14 20 9 15 4"></polyline>
                            <path d="M4 20v-7a4 4 0 0 1 4-4h12"></path>
                        </svg>
                    </div>
                    <div class="card-title">تم نقل المسؤولية إلى الدكتور</div>
                    <div class="card-copy" style="margin-bottom:0;">
                        هذا الاستفسار حُوّل بالفعل إلى الدكتور، لذلك لا يمكن للمندوب إرسال رد جديد أو تعديل حالته من هذه الصفحة.
                    </div>
                </div>
            @elseif($inquiry->status === 'closed')
                <div class="panel notice-card closed">
                    <div class="notice-icon" style="background:rgba(100,116,139,0.1); color:#475569;">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <line x1="18" y1="6" x2="6" y2="18"></line>
                            <line x1="6" y1="6" x2="18" y2="18"></line>
                        </svg>
                    </div>
                    <div class="card-title">الاستفسار مغلق</div>
                    <div class="card-copy" style="margin-bottom:0;">
                        لا توجد إجراءات إضافية متاحة لهذا الاستفسار بعد إغلاقه.
                    </div>
                </div>
            @endif
        </div>
    </div>
</div>
@endsection
