@extends('layouts.delegate')

@section('title', 'استفسارات الطلاب')

@section('content')
<style>
    .hero-shell {
        background:
            radial-gradient(circle at top right, rgba(59, 130, 246, 0.18), transparent 32%),
            linear-gradient(135deg, #0f172a 0%, #1e293b 52%, #1d4ed8 100%);
        border-radius: 28px;
        padding: 2rem;
        color: #fff;
        margin-bottom: 1.5rem;
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
        font-size: 2rem;
        font-weight: 900;
        margin: 0 0 0.6rem;
        display: flex;
        align-items: center;
        gap: 0.85rem;
    }

    .hero-copy {
        color: rgba(255, 255, 255, 0.8);
        max-width: 760px;
        line-height: 1.8;
        margin: 0;
    }

    .hero-chip {
        display: inline-flex;
        align-items: center;
        gap: 0.45rem;
        padding: 0.55rem 0.9rem;
        border-radius: 999px;
        background: rgba(255, 255, 255, 0.12);
        color: #fff;
        font-weight: 700;
        font-size: 0.9rem;
        backdrop-filter: blur(10px);
    }

    .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
        gap: 1rem;
        margin-bottom: 1.5rem;
    }

    .stat-card {
        background: linear-gradient(180deg, rgba(255, 255, 255, 0.98), rgba(248, 250, 252, 0.96));
        border: 1px solid rgba(148, 163, 184, 0.18);
        border-radius: 22px;
        padding: 1.25rem 1.35rem;
        box-shadow: 0 20px 45px -32px rgba(15, 23, 42, 0.4);
    }

    .stat-label {
        font-size: 0.84rem;
        color: #64748b;
        font-weight: 700;
        margin-bottom: 0.6rem;
    }

    .stat-value {
        font-size: 1.8rem;
        font-weight: 900;
        color: #0f172a;
    }

    .stat-tone-pending .stat-value { color: #d97706; }
    .stat-tone-forwarded .stat-value { color: #2563eb; }
    .stat-tone-answered .stat-value { color: #059669; }

    .filters-bar {
        display: flex;
        gap: 0.75rem;
        flex-wrap: wrap;
        margin-bottom: 1.5rem;
    }

    .filter-pill {
        display: inline-flex;
        align-items: center;
        gap: 0.45rem;
        padding: 0.75rem 1rem;
        border-radius: 999px;
        text-decoration: none;
        font-weight: 800;
        color: #475569;
        background: rgba(255, 255, 255, 0.88);
        border: 1px solid rgba(148, 163, 184, 0.2);
        transition: all 0.2s ease;
        box-shadow: 0 10px 25px -22px rgba(15, 23, 42, 0.4);
    }

    .filter-pill:hover {
        color: #1d4ed8;
        border-color: rgba(59, 130, 246, 0.25);
        transform: translateY(-1px);
    }

    .filter-pill.active {
        color: #fff;
        background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
        border-color: transparent;
    }

    .inquiries-stack {
        display: flex;
        flex-direction: column;
        gap: 1.1rem;
    }

    .inquiry-card {
        background: rgba(255, 255, 255, 0.97);
        border: 1px solid rgba(148, 163, 184, 0.16);
        border-radius: 24px;
        overflow: hidden;
        box-shadow: 0 22px 48px -36px rgba(15, 23, 42, 0.45);
        transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
    }

    .inquiry-card:hover {
        transform: translateY(-2px);
        border-color: rgba(59, 130, 246, 0.18);
        box-shadow: 0 26px 54px -34px rgba(37, 99, 235, 0.22);
    }

    .inquiry-topline {
        height: 5px;
    }

    .status-pending { background: linear-gradient(90deg, #f59e0b, #fbbf24); }
    .status-forwarded { background: linear-gradient(90deg, #2563eb, #60a5fa); }
    .status-answered { background: linear-gradient(90deg, #059669, #34d399); }
    .status-closed { background: linear-gradient(90deg, #64748b, #94a3b8); }

    .inquiry-body {
        padding: 1.35rem 1.45rem 1.1rem;
    }

    .inquiry-meta {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 1rem;
        margin-bottom: 1rem;
        flex-wrap: wrap;
    }

    .student-box {
        display: flex;
        align-items: center;
        gap: 0.9rem;
    }

    .student-avatar {
        width: 48px;
        height: 48px;
        border-radius: 15px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 900;
        font-size: 1rem;
        color: #1d4ed8;
        background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
        box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.65);
    }

    .student-name {
        font-weight: 900;
        color: #0f172a;
        margin-bottom: 0.2rem;
    }

    .student-submeta {
        color: #64748b;
        font-size: 0.88rem;
        display: flex;
        align-items: center;
        gap: 0.45rem;
        flex-wrap: wrap;
    }

    .subject-chip,
    .status-chip,
    .actor-chip {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        border-radius: 999px;
        padding: 0.42rem 0.78rem;
        font-size: 0.78rem;
        font-weight: 800;
    }

    .subject-chip {
        background: #eef2ff;
        color: #4338ca;
    }

    .status-chip {
        background: #f8fafc;
        color: #334155;
        border: 1px solid rgba(148, 163, 184, 0.14);
    }

    .actor-chip {
        background: #ecfdf5;
        color: #047857;
    }

    .inquiry-title {
        font-size: 1.1rem;
        font-weight: 900;
        color: #0f172a;
        margin: 0 0 0.55rem;
        line-height: 1.7;
    }

    .inquiry-question {
        color: #475569;
        line-height: 1.9;
        margin: 0 0 1rem;
    }

    .info-band {
        display: flex;
        align-items: center;
        gap: 0.6rem;
        padding: 0.85rem 1rem;
        border-radius: 16px;
        font-size: 0.9rem;
        font-weight: 700;
        margin-bottom: 1rem;
    }

    .info-band.forwarded {
        background: #eff6ff;
        color: #1d4ed8;
    }

    .info-band.answered {
        background: #ecfdf5;
        color: #047857;
    }

    .inquiry-footer {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 1rem;
        flex-wrap: wrap;
        padding-top: 1rem;
        border-top: 1px solid rgba(226, 232, 240, 0.85);
    }

    .time-meta {
        color: #94a3b8;
        font-size: 0.84rem;
        font-weight: 700;
    }

    .view-btn {
        display: inline-flex;
        align-items: center;
        gap: 0.45rem;
        text-decoration: none;
        color: #fff;
        font-weight: 800;
        border-radius: 14px;
        padding: 0.8rem 1.1rem;
        background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
        box-shadow: 0 18px 34px -26px rgba(37, 99, 235, 0.85);
    }

    .empty-state {
        background: rgba(255, 255, 255, 0.97);
        border: 1px solid rgba(148, 163, 184, 0.16);
        border-radius: 28px;
        padding: 3.5rem 2rem;
        text-align: center;
        box-shadow: 0 22px 48px -36px rgba(15, 23, 42, 0.45);
    }

    .empty-state h3 {
        margin: 1rem 0 0.5rem;
        font-size: 1.35rem;
        font-weight: 900;
        color: #0f172a;
    }

    .empty-state p {
        margin: 0;
        color: #64748b;
        line-height: 1.9;
    }
</style>

<div class="hero-shell">
    <div class="hero-top">
        <div>
            <h1 class="hero-title">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                </svg>
                استفسارات الطلاب
            </h1>
            <p class="hero-copy">
                راجع استفسارات الدفعة، ثم قرر هل ترد مباشرة بصفتك المندوب أو تحوّل الاستفسار إلى الدكتور. بعد التحويل تنتهي مهمة المندوب ويصبح الاستفسار في عهدة الدكتور فقط.
            </p>
        </div>

        <div class="hero-chip">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M12 8v4l3 3"></path>
                <circle cx="12" cy="12" r="10"></circle>
            </svg>
            {{ $stats['pending'] }} بانتظار المعالجة
        </div>
    </div>
</div>

@if(session('success'))
    <div class="alert alert-success mb-4">{{ session('success') }}</div>
@endif

<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-label">إجمالي الاستفسارات</div>
        <div class="stat-value">{{ $stats['total'] }}</div>
    </div>
    <div class="stat-card stat-tone-pending">
        <div class="stat-label">قيد الانتظار</div>
        <div class="stat-value">{{ $stats['pending'] }}</div>
    </div>
    <div class="stat-card stat-tone-forwarded">
        <div class="stat-label">تم تحويلها للدكتور</div>
        <div class="stat-value">{{ $stats['forwarded'] }}</div>
    </div>
    <div class="stat-card stat-tone-answered">
        <div class="stat-label">تم الرد عليها</div>
        <div class="stat-value">{{ $stats['answered'] }}</div>
    </div>
</div>

<div class="filters-bar">
    <a href="{{ route('delegate.inquiries.index') }}" class="filter-pill {{ $status === '' ? 'active' : '' }}">الكل</a>
    <a href="{{ route('delegate.inquiries.index', ['status' => 'pending']) }}" class="filter-pill {{ $status === 'pending' ? 'active' : '' }}">قيد الانتظار</a>
    <a href="{{ route('delegate.inquiries.index', ['status' => 'forwarded']) }}" class="filter-pill {{ $status === 'forwarded' ? 'active' : '' }}">تم التحويل</a>
    <a href="{{ route('delegate.inquiries.index', ['status' => 'answered']) }}" class="filter-pill {{ $status === 'answered' ? 'active' : '' }}">تم الرد</a>
</div>

@if($inquiries->count())
    <div class="inquiries-stack">
        @foreach($inquiries as $inquiry)
            <article class="inquiry-card">
                <div class="inquiry-topline status-{{ $inquiry->status }}"></div>
                <div class="inquiry-body">
                    <div class="inquiry-meta">
                        <div class="student-box">
                            <div class="student-avatar">{{ mb_substr($inquiry->student->name ?? '?', 0, 1) }}</div>
                            <div>
                                <div class="student-name">{{ $inquiry->student->name ?? 'غير معروف' }}</div>
                                <div class="student-submeta">
                                    <span>{{ $inquiry->student->student_number ?: 'بدون رقم قيد' }}</span>
                                    <span>•</span>
                                    <span>{{ $inquiry->created_at->diffForHumans() }}</span>
                                </div>
                            </div>
                        </div>

                        <div style="display:flex; gap:0.5rem; flex-wrap:wrap;">
                            <span class="subject-chip">{{ $inquiry->subject->name ?? 'مادة غير محددة' }}</span>
                            <span class="status-chip">{{ $inquiry->status_label }}</span>
                            @if($inquiry->answered_by_actor_label)
                                <span class="actor-chip">الرد بواسطة {{ $inquiry->answered_by_actor_label }}</span>
                            @endif
                        </div>
                    </div>

                    <h3 class="inquiry-title">{{ $inquiry->title }}</h3>
                    <p class="inquiry-question">{{ Str::limit($inquiry->question, 180) }}</p>

                    @if($inquiry->wasForwardedToDoctor())
                        <div class="info-band forwarded">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="15 14 20 9 15 4"></polyline>
                                <path d="M4 20v-7a4 4 0 0 1 4-4h12"></path>
                            </svg>
                            تم تحويل هذا الاستفسار إلى الدكتور، ولم يعد قابلًا للرد أو التعديل من صفحة المندوب.
                        </div>
                    @elseif($inquiry->answer)
                        <div class="info-band answered">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="20 6 9 17 4 12"></polyline>
                            </svg>
                            {{ Str::limit($inquiry->answer, 140) }}
                        </div>
                    @endif

                    <div class="inquiry-footer">
                        <div class="time-meta">
                            آخر تحديث: {{ $inquiry->updated_at->diffForHumans() }}
                        </div>

                        <a href="{{ route('delegate.inquiries.show', $inquiry->id) }}" class="view-btn">
                            عرض التفاصيل
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="9 18 15 12 9 6"></polyline>
                            </svg>
                        </a>
                    </div>
                </div>
            </article>
        @endforeach
    </div>

    @if($inquiries->hasPages())
        <div style="margin-top: 1.75rem;">
            {{ $inquiries->appends(['status' => $status])->links() }}
        </div>
    @endif
@else
    <div class="empty-state">
        <svg width="70" height="70" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5">
            <circle cx="12" cy="12" r="10"></circle>
            <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
            <line x1="12" y1="17" x2="12.01" y2="17"></line>
        </svg>
        <h3>لا توجد استفسارات حالية</h3>
        <p>ستظهر هنا استفسارات طلاب الدفعة مع حالة كل استفسار، سواء كان بانتظار رد المندوب أو تم تحويله للدكتور أو أُجيب عليه.</p>
    </div>
@endif
@endsection
