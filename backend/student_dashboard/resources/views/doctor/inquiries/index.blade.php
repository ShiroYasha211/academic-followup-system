@extends('layouts.doctor')

@section('title', 'استفسارات الطلاب')

@section('content')
<style>
    /* Premium Styling and Animations */
    .hero-shell {
        background:
            radial-gradient(circle at top right, rgba(20, 184, 166, 0.15), transparent 35%),
            linear-gradient(135deg, #0f172a 0%, #1e293b 45%, #0f766e 100%);
        border-radius: 24px;
        padding: 2.2rem;
        color: #fff;
        margin-bottom: 2rem;
        box-shadow: 0 20px 40px -15px rgba(15, 23, 42, 0.5);
        position: relative;
        overflow: hidden;
    }

    .hero-top {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 1.5rem;
        flex-wrap: wrap;
        position: relative;
        z-index: 2;
    }

    .hero-title {
        font-size: 2.2rem;
        font-weight: 900;
        margin: 0 0 0.8rem;
        display: flex;
        align-items: center;
        gap: 1rem;
        color: #f8fafc;
    }

    .hero-copy {
        color: #cbd5e1;
        line-height: 1.8;
        margin: 0;
        max-width: 820px;
        font-size: 1rem;
    }

    .hero-chip {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.65rem 1.2rem;
        border-radius: 999px;
        background: rgba(255, 255, 255, 0.1);
        font-weight: 800;
        border: 1px solid rgba(255, 255, 255, 0.15);
        backdrop-filter: blur(10px);
        color: #ccfbf1;
        font-size: 0.9rem;
    }

    .section-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 24px;
        padding: 1.8rem;
        margin-bottom: 2rem;
        box-shadow: 0 10px 30px -10px rgba(0, 0, 0, 0.04);
    }

    .section-head {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 1.5rem;
        margin-bottom: 1.5rem;
        flex-wrap: wrap;
    }

    .section-title {
        font-size: 1.35rem;
        font-weight: 900;
        color: #0f172a;
        margin-bottom: 0.4rem;
    }

    .section-copy {
        color: #64748b;
        line-height: 1.8;
        margin: 0;
        font-size: 0.95rem;
    }

    .subject-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
        gap: 1.25rem;
    }

    .subject-card {
        border-radius: 20px;
        padding: 1.4rem;
        border: 1px solid #e2e8f0;
        background: #f8fafc;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        position: relative;
        display: flex;
        flex-direction: column;
        justify-content: space-between;
    }

    .subject-card:hover {
        border-color: #0f766e;
        background: #ffffff;
        box-shadow: 0 12px 24px -10px rgba(15, 118, 110, 0.08);
        transform: translateY(-2px);
    }

    .subject-top {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 0.8rem;
        margin-bottom: 1rem;
    }

    .subject-name {
        font-size: 1.1rem;
        font-weight: 900;
        color: #0f172a;
        margin-bottom: 0.3rem;
    }

    .subject-meta {
        font-size: 0.85rem;
        color: #64748b;
        line-height: 1.6;
    }

    .subject-pill {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        padding: 0.45rem 0.9rem;
        border-radius: 999px;
        font-size: 0.8rem;
        font-weight: 800;
    }

    .subject-pill.open {
        background: #e6f4ea;
        color: #137333;
    }

    .subject-pill.closed {
        background: #fce8e6;
        color: #c5221f;
    }

    .reason-box {
        background: #fff7ed;
        color: #c2410c;
        border: 1px solid rgba(251, 146, 60, 0.2);
        border-radius: 12px;
        padding: 0.85rem 1rem;
        line-height: 1.7;
        font-size: 0.88rem;
        margin-bottom: 1rem;
        font-weight: 700;
    }

    .settings-form textarea {
        width: 100%;
        min-height: 80px;
        resize: vertical;
        border-radius: 14px;
        border: 1px solid #cbd5e1;
        background: #ffffff;
        padding: 0.85rem 1rem;
        font-family: inherit;
        font-size: 0.9rem;
        margin-bottom: 0.8rem;
        transition: all 0.2s ease;
    }

    .settings-form textarea:focus {
        outline: none;
        border-color: #0f766e;
        box-shadow: 0 0 0 3px rgba(15, 118, 110, 0.12);
    }

    .settings-foot {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 0.75rem;
        flex-wrap: wrap;
    }

    .btn-toggle {
        border: none;
        border-radius: 12px;
        padding: 0.75rem 1.2rem;
        font-weight: 800;
        color: #ffffff;
        cursor: pointer;
        background: linear-gradient(135deg, #0f766e 0%, #14b8a6 100%);
        transition: all 0.2s ease;
        font-size: 0.88rem;
        box-shadow: 0 8px 16px -6px rgba(15, 118, 110, 0.4);
    }

    .btn-toggle:hover {
        opacity: 0.95;
        transform: translateY(-1px);
        box-shadow: 0 10px 20px -5px rgba(15, 118, 110, 0.5);
    }

    .btn-toggle.to-close {
        background: linear-gradient(135deg, #b91c1c 0%, #ef4444 100%);
        box-shadow: 0 8px 16px -6px rgba(185, 28, 28, 0.4);
    }

    .btn-toggle.to-close:hover {
        box-shadow: 0 10px 20px -5px rgba(185, 28, 28, 0.5);
    }

    /* Bento stats layout */
    .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
        gap: 1.25rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 20px;
        padding: 1.4rem 1.6rem;
        box-shadow: 0 10px 25px -12px rgba(0, 0, 0, 0.03);
        display: flex;
        align-items: center;
        justify-content: space-between;
        position: relative;
        overflow: hidden;
    }

    .stat-info {
        position: relative;
        z-index: 2;
    }

    .stat-label {
        font-size: 0.88rem;
        color: #64748b;
        font-weight: 800;
        margin-bottom: 0.6rem;
    }

    .stat-value {
        font-size: 2.2rem;
        font-weight: 900;
        color: #0f172a;
        line-height: 1;
    }

    .stat-icon-wrapper {
        width: 48px;
        height: 48px;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: #f1f5f9;
        color: #64748b;
    }

    .stat-card.stat-pending .stat-icon-wrapper { background: #fee2e2; color: #ef4444; }
    .stat-card.stat-answered .stat-icon-wrapper { background: #dcfce7; color: #10b981; }
    .stat-card.stat-total .stat-icon-wrapper { background: #e0f2fe; color: #0284c7; }

    /* Local Search & Advanced Filter Section */
    .search-filter-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 20px;
        padding: 1.2rem;
        margin-bottom: 1.5rem;
        display: flex;
        gap: 1rem;
        align-items: center;
        flex-wrap: wrap;
    }

    .search-input-web {
        flex: 1;
        min-width: 280px;
        border-radius: 12px;
        border: 1px solid #cbd5e1;
        padding: 0.8rem 1.2rem;
        font-size: 0.95rem;
        transition: all 0.2s ease;
        background: #f8fafc;
    }

    .search-input-web:focus {
        outline: none;
        border-color: #0f766e;
        background: #ffffff;
        box-shadow: 0 0 0 3px rgba(15, 118, 110, 0.1);
    }

    .filter-select-web {
        min-width: 200px;
        border-radius: 12px;
        border: 1px solid #cbd5e1;
        padding: 0.8rem 1rem;
        font-size: 0.95rem;
        background-color: #ffffff;
        cursor: pointer;
    }

    .filter-select-web:focus {
        outline: none;
        border-color: #0f766e;
    }

    /* Filters tabs row */
    .filters-bar {
        display: flex;
        gap: 0.6rem;
        flex-wrap: wrap;
        margin-bottom: 1.5rem;
    }

    .filter-pill {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.65rem 1.2rem;
        border-radius: 999px;
        text-decoration: none;
        font-weight: 800;
        color: #475569;
        background: #ffffff;
        border: 1px solid #e2e8f0;
        transition: all 0.2s ease;
        font-size: 0.88rem;
    }

    .filter-pill:hover {
        background: #f8fafc;
        border-color: #cbd5e1;
    }

    .filter-pill.active {
        color: #ffffff;
        background: linear-gradient(135deg, #0f766e 0%, #14b8a6 100%);
        border-color: transparent;
        box-shadow: 0 8px 16px -6px rgba(15, 118, 110, 0.4);
    }

    .inquiries-stack {
        display: flex;
        flex-direction: column;
        gap: 1.2rem;
    }

    .inquiry-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 20px;
        overflow: hidden;
        box-shadow: 0 8px 24px -12px rgba(0, 0, 0, 0.05);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .inquiry-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 20px 35px -15px rgba(15, 23, 42, 0.08);
        border-color: #cbd5e1;
    }

    .inquiry-topline {
        height: 6px;
    }

    .status-forwarded { border-right: 5px solid #f59e0b; }
    .status-answered { border-right: 5px solid #10b981; }
    .status-closed { border-right: 5px solid #6b7280; }

    .status-forwarded .inquiry-topline { background: linear-gradient(90deg, #f59e0b, #fef08a); }
    .status-answered .inquiry-topline { background: linear-gradient(90deg, #10b981, #a7f3d0); }
    .status-closed .inquiry-topline { background: linear-gradient(90deg, #6b7280, #cbd5e1); }

    .inquiry-body {
        padding: 1.5rem;
    }

    .inquiry-meta {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 1.5rem;
        margin-bottom: 1.2rem;
        flex-wrap: wrap;
    }

    .student-box {
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .student-avatar {
        width: 48px;
        height: 48px;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 900;
        color: #ffffff;
        background: linear-gradient(135deg, #0f766e 0%, #14b8a6 100%);
        font-size: 1.1rem;
        box-shadow: 0 4px 10px -4px rgba(15, 118, 110, 0.4);
    }

    .student-name {
        font-weight: 900;
        color: #0f172a;
        font-size: 1.05rem;
        margin-bottom: 0.2rem;
    }

    .student-submeta {
        color: #64748b;
        font-size: 0.85rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        flex-wrap: wrap;
    }

    .chip-row {
        display: flex;
        gap: 0.5rem;
        flex-wrap: wrap;
    }

    .chip {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        padding: 0.45rem 0.9rem;
        border-radius: 999px;
        font-size: 0.8rem;
        font-weight: 800;
        border: 1px solid transparent;
    }

    .chip.subject {
        background: #ecfeff;
        color: #0f766e;
        border-color: #cffafe;
    }

    .chip.status {
        background: #f8fafc;
        color: #475569;
        border-color: #e2e8f0;
    }

    .chip.actor {
        background: #f0fdf4;
        color: #166534;
        border-color: #dcfce7;
    }

    .inquiry-title {
        font-size: 1.2rem;
        font-weight: 900;
        color: #0f172a;
        margin: 0 0 0.6rem;
        line-height: 1.6;
    }

    .inquiry-question {
        color: #475569;
        line-height: 1.8;
        margin: 0 0 1.2rem;
        font-size: 0.95rem;
    }

    .info-band {
        display: flex;
        align-items: center;
        gap: 0.6rem;
        padding: 0.9rem 1.1rem;
        border-radius: 14px;
        background: #fffbeb;
        color: #b45309;
        font-size: 0.9rem;
        font-weight: 700;
        margin-bottom: 1.2rem;
        border: 1px solid #fef3c7;
    }

    .info-band.answered {
        background: #f0fdf4;
        color: #15803d;
        border: 1px solid #dcfce7;
    }

    .inquiry-footer {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 1.5rem;
        flex-wrap: wrap;
        padding-top: 1.2rem;
        border-top: 1px solid #f1f5f9;
    }

    .time-meta {
        color: #94a3b8;
        font-size: 0.85rem;
        font-weight: 700;
    }

    .view-btn {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
        color: #ffffff;
        font-weight: 800;
        border-radius: 12px;
        padding: 0.75rem 1.25rem;
        background: linear-gradient(135deg, #0f766e 0%, #14b8a6 100%);
        box-shadow: 0 8px 16px -6px rgba(15, 118, 110, 0.4);
        transition: all 0.2s ease;
        font-size: 0.88rem;
    }

    .view-btn:hover {
        transform: translateY(-1px);
        box-shadow: 0 10px 20px -5px rgba(15, 118, 110, 0.5);
    }

    .empty-state {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 24px;
        padding: 4rem 2rem;
        text-align: center;
        box-shadow: 0 8px 24px -12px rgba(0, 0, 0, 0.05);
    }

    .empty-state h3 {
        margin: 1.2rem 0 0.6rem;
        font-size: 1.4rem;
        font-weight: 900;
        color: #0f172a;
    }

    .empty-state p {
        margin: 0;
        color: #64748b;
        line-height: 1.8;
    }
</style>

<div class="hero-shell">
    <div class="hero-top">
        <div>
            <h1 class="hero-title">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <circle cx="12" cy="12" r="10"></circle>
                    <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                </svg>
                استفسارات الطلاب
            </h1>
            <p class="hero-copy">
                هذه الصفحة تعرض فقط الاستفسارات التي وصلت إليك بعد تحويلها من المندوب أو الاستفسارات التي أجبت عليها سابقًا.
            </p>
        </div>

        <div class="hero-chip">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <path d="M12 8v4l3 3"></path>
                <circle cx="12" cy="12" r="10"></circle>
            </svg>
            {{ $stats['forwarded'] }} بانتظار رد الدكتور
        </div>
    </div>
</div>

@if(session('success'))
    <div class="alert alert-success mb-4" style="border-radius: 16px; font-weight: bold; padding: 1rem 1.25rem;">
        {{ session('success') }}
    </div>
@endif

<!-- إعدادات استقبال الاستفسارات للمواد -->
<div class="section-card">
    <div class="section-head">
        <div>
            <div class="section-title">إدارة فتح وإغلاق الاستفسارات</div>
            <p class="section-copy">
                إغلاق الاستفسارات يمنع الطلاب من إرسال أسئلة جديدة مع الحفاظ على الأرشيف.
            </p>
        </div>
    </div>

    @if($subjects->count())
        <div class="subject-grid">
            @foreach($subjects as $subject)
                @php
                    $enabled = (bool) $subject->inquiries_enabled;
                    $reason = $subject->inquiries_closed_reason;
                @endphp
                <div class="subject-card">
                    <div>
                        <div class="subject-top">
                            <div>
                                <div class="subject-name">{{ $subject->name }}</div>
                                <div class="subject-meta">
                                    {{ $subject->code ?: 'لا يوجد رمز مقرر' }}
                                    @if($subject->level?->name)
                                        • {{ $subject->level->name }}
                                    @endif
                                </div>
                            </div>

                            <span class="subject-pill {{ $enabled ? 'open' : 'closed' }}">
                                {{ $enabled ? 'مفتوحة' : 'مغلقة' }}
                            </span>
                        </div>

                        @if(!$enabled)
                            <div class="reason-box">
                                {{ $reason ?: 'الاستفسارات مغلقة حالياً لهذه المادة.' }}
                            </div>
                        @endif
                    </div>

                    <form class="settings-form mt-3" method="POST" action="{{ route('doctor.inquiries.settings.update', $subject->id) }}">
                        @csrf
                        @method('PATCH')
                        <input type="hidden" name="inquiries_enabled" value="{{ $enabled ? 0 : 1 }}">

                        <textarea
                            name="inquiries_closed_reason"
                            placeholder="اكتب سبب إغلاق الاستفسارات ليظهر للطالب (اختياري)...">{{ old('inquiries_closed_reason', $reason) }}</textarea>

                        <div class="settings-foot">
                            <button type="submit" class="btn-toggle {{ $enabled ? 'to-close' : '' }}">
                                {{ $enabled ? 'إغلاق الاستفسارات' : 'فتح الاستفسارات' }}
                            </button>

                            <div style="font-size:0.8rem; color:#64748b; font-weight: bold;">
                                {{ $enabled ? 'إغلاق الاستقبال الفوري' : 'السماح باستقبال الأسئلة' }}
                            </div>
                        </div>
                    </form>
                </div>
            @endforeach
        </div>
    @else
        <div class="empty-state" style="padding:2rem;">
            <h3>لا توجد مواد مرتبطة بالدكتور</h3>
            <p>يرجى مراجعة إدارة شؤون الطلاب لربط المقررات الدراسية بحسابك.</p>
        </div>
    @endif
</div>

<!-- Bento Stats Cards -->
<div class="stats-grid">
    <div class="stat-card stat-total">
        <div class="stat-info">
            <div class="stat-label">الإجمالي المعروض</div>
            <div class="stat-value">{{ $stats['total'] }}</div>
        </div>
        <div class="stat-icon-wrapper">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
            </svg>
        </div>
    </div>
    <div class="stat-card stat-pending">
        <div class="stat-info">
            <div class="stat-label">بانتظار ردك</div>
            <div class="stat-value">{{ $stats['forwarded'] }}</div>
        </div>
        <div class="stat-icon-wrapper">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="12" y1="8" x2="12" y2="12"></line>
                <line x1="12" y1="16" x2="12.01" y2="16"></line>
            </svg>
        </div>
    </div>
    <div class="stat-card stat-answered">
        <div class="stat-info">
            <div class="stat-label">تمت الإجابة عليها</div>
            <div class="stat-value">{{ $stats['answered'] }}</div>
        </div>
        <div class="stat-icon-wrapper">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
        </div>
    </div>
</div>

<!-- شريط البحث الفوري والتصفية بالويب -->
<div class="search-filter-card">
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2.5" class="ms-1">
        <circle cx="11" cy="11" r="8"></circle>
        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
    </svg>
    <input type="text" id="localSearchInput" placeholder="البحث بالاسم، القيد، عنوان السؤال أو السؤال نفسه لحظياً..." class="search-input-web">
    
    <select id="localSubjectFilter" class="filter-select-web">
        <option value="">كل المواد الدراسية</option>
        @foreach($subjects as $subj)
            <option value="{{ $subj->name }}">{{ $subj->name }}</option>
        @endforeach
    </select>
</div>

<!-- التبويبات الفئوية -->
<div class="filters-bar">
    <a href="{{ route('doctor.inquiries.index') }}" class="filter-pill {{ $status === '' ? 'active' : '' }}">الكل</a>
    <a href="{{ route('doctor.inquiries.index', ['status' => 'forwarded']) }}" class="filter-pill {{ $status === 'forwarded' ? 'active' : '' }}">بانتظار الرد</a>
    <a href="{{ route('doctor.inquiries.index', ['status' => 'answered']) }}" class="filter-pill {{ $status === 'answered' ? 'active' : '' }}">تم الرد</a>
    <a href="{{ route('doctor.inquiries.index', ['status' => 'closed']) }}" class="filter-pill {{ $status === 'closed' ? 'active' : '' }}">مغلق</a>
</div>

<!-- قائمة الاستفسارات المصفاة -->
@if($inquiries->count())
    <div class="inquiries-stack" id="inquiriesStack">
        @foreach($inquiries as $inquiry)
            <article class="inquiry-card status-{{ $inquiry->status }}">
                <div class="inquiry-topline"></div>
                <div class="inquiry-body">
                    <div class="inquiry-meta">
                        <div class="student-box">
                            <div class="student-avatar">{{ mb_substr($inquiry->student->name ?? '?', 0, 1) }}</div>
                            <div>
                                <div class="student-name">{{ $inquiry->student->name ?? 'طالب' }}</div>
                                <div class="student-submeta">
                                    <span>رقم القيد: {{ $inquiry->student->student_number ?: 'بدون رقم قيد' }}</span>
                                    <span>•</span>
                                    <span>أرسل: {{ $inquiry->created_at->diffForHumans() }}</span>
                                </div>
                            </div>
                        </div>

                        <div class="chip-row">
                            <span class="chip subject">{{ $inquiry->subject->name ?? 'مادة غير محددة' }}</span>
                            <span class="chip status">{{ $inquiry->status_label }}</span>
                            @if($inquiry->answered_by_actor_label)
                                <span class="chip actor">بواسطة {{ $inquiry->answered_by_actor_label }}</span>
                            @endif
                        </div>
                    </div>

                    <h3 class="inquiry-title">{{ $inquiry->title }}</h3>
                    <p class="inquiry-question">{{ Str::limit($inquiry->question, 200) }}</p>

                    @if($inquiry->status === 'forwarded')
                        <div class="info-band">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                <circle cx="12" cy="12" r="10"></circle>
                                <line x1="12" y1="8" x2="12" y2="12"></line>
                                <line x1="12" y1="16" x2="12.01" y2="16"></line>
                            </svg>
                            هذا الاستفسار بانتظار إجابة الدكتور.
                        </div>
                    @elseif($inquiry->answer)
                        <div class="info-band answered">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
                            </svg>
                            <strong>الرد المعتمد:</strong> {{ Str::limit($inquiry->answer, 180) }}
                        </div>
                    @endif

                    <div class="inquiry-footer">
                        <div class="time-meta">
                            آخر تحديث: {{ $inquiry->updated_at->diffForHumans() }}
                        </div>

                        <a href="{{ route('doctor.inquiries.show', $inquiry->id) }}" class="view-btn">
                            عرض وتفصيل الاستفسار
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                <line x1="19" y1="12" x2="5" y2="12"></line>
                                <polyline points="12 19 5 12 12 5"></polyline>
                            </svg>
                        </a>
                    </div>
                </div>
            </article>
        @endforeach
    </div>

    @if($inquiries->hasPages())
        <div class="mt-4">
            {{ $inquiries->appends(request()->query())->links() }}
        </div>
    @endif
@else
    <div class="empty-state">
        <svg width="70" height="70" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5">
            <circle cx="12" cy="12" r="10"></circle>
            <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
            <line x1="12" y1="17" x2="12.01" y2="17"></line>
        </svg>
        <h3>لا توجد استفسارات متوفرة</h3>
        <p>لم يتم تحويل استفسارات إليك من المندوب في هذا التبويب حالياً.</p>
    </div>
@endif

<script>
    // JS Local Search & Subject Filter
    document.addEventListener('DOMContentLoaded', function() {
        const searchInput = document.getElementById('localSearchInput');
        const subjectFilter = document.getElementById('localSubjectFilter');
        const cards = document.querySelectorAll('.inquiry-card');

        function filterInquiries() {
            const query = searchInput.value.toLowerCase().trim();
            const filterSubject = subjectFilter.value;

            cards.forEach(card => {
                const studentName = card.querySelector('.student-name').textContent.toLowerCase();
                const studentMeta = card.querySelector('.student-submeta').textContent.toLowerCase();
                const title = card.querySelector('.inquiry-title').textContent.toLowerCase();
                const question = card.querySelector('.inquiry-question').textContent.toLowerCase();
                const cardSubject = card.querySelector('.chip.subject').textContent.trim();

                const matchesQuery = studentName.includes(query) || 
                                     studentMeta.includes(query) || 
                                     title.includes(query) || 
                                     question.includes(query);
                                     
                const matchesSubject = !filterSubject || cardSubject === filterSubject;

                if (matchesQuery && matchesSubject) {
                    card.style.display = '';
                } else {
                    card.style.display = 'none';
                }
            });
        }

        if (searchInput) searchInput.addEventListener('input', filterInquiries);
        if (subjectFilter) subjectFilter.addEventListener('change', filterInquiries);
    });
</script>
@endsection
