@extends('layouts.doctor')

@section('title', 'تفاصيل الاستفسار')

@section('content')
<style>
    .page-shell {
        max-width: 1100px;
        margin: 0 auto;
    }

    .back-link {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
        color: #64748b;
        font-weight: 800;
        margin-bottom: 1.5rem;
        transition: all 0.2s ease;
        padding: 0.5rem 0.8rem;
        border-radius: 10px;
        background: #f1f5f9;
        font-size: 0.88rem;
    }

    .back-link:hover {
        color: #0f766e;
        background: #e2e8f0;
    }

    .hero-card {
        background:
            radial-gradient(circle at top right, rgba(20, 184, 166, 0.15), transparent 35%),
            linear-gradient(135deg, #0f172a 0%, #1e293b 45%, #0f766e 100%);
        color: #ffffff;
        border-radius: 24px;
        padding: 1.8rem 2rem;
        margin-bottom: 1.5rem;
        box-shadow: 0 20px 40px -15px rgba(15, 23, 42, 0.5);
    }

    .hero-top {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 1.5rem;
        flex-wrap: wrap;
    }

    .hero-title {
        font-size: 1.8rem;
        font-weight: 900;
        margin: 0 0 0.5rem;
        color: #f8fafc;
        line-height: 1.5;
    }

    .hero-copy {
        margin: 0;
        color: #cbd5e1;
        line-height: 1.7;
        max-width: 760px;
        font-size: 0.95rem;
    }

    .status-chip {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.55rem 1.1rem;
        border-radius: 999px;
        background: rgba(255, 255, 255, 0.1);
        backdrop-filter: blur(10px);
        font-weight: 800;
        border: 1px solid rgba(255, 255, 255, 0.15);
        color: #ccfbf1;
        font-size: 0.88rem;
    }

    .layout-grid {
        display: grid;
        grid-template-columns: minmax(0, 1.7fr) 340px;
        gap: 1.5rem;
    }

    .panel {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 24px;
        box-shadow: 0 10px 30px -10px rgba(0, 0, 0, 0.04);
        overflow: hidden;
    }

    .panel-body {
        padding: 1.8rem;
    }

    /* Student info sidebar card */
    .student-card-web {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 20px;
        padding: 1.4rem;
        margin-bottom: 1.5rem;
        text-align: center;
    }

    .student-avatar {
        width: 64px;
        height: 64px;
        border-radius: 18px;
        background: linear-gradient(135deg, #0f766e 0%, #14b8a6 100%);
        color: #ffffff;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 900;
        font-size: 1.4rem;
        margin: 0 auto 1rem;
        box-shadow: 0 6px 15px -4px rgba(15, 118, 110, 0.4);
    }

    .student-name {
        font-size: 1.15rem;
        font-weight: 900;
        color: #0f172a;
        margin-bottom: 0.3rem;
    }

    .student-submeta {
        color: #64748b;
        font-size: 0.88rem;
        font-weight: 700;
    }

    .meta-row {
        display: flex;
        gap: 0.5rem;
        flex-wrap: wrap;
        margin-bottom: 1.5rem;
        justify-content: center;
    }

    .meta-chip {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        padding: 0.45rem 0.85rem;
        border-radius: 999px;
        background: #ffffff;
        color: #475569;
        font-size: 0.82rem;
        font-weight: 800;
        border: 1px solid #e2e8f0;
    }

    /* Conversation timeline styles */
    .bubble-container {
        display: flex;
        flex-direction: column;
        gap: 1.5rem;
    }

    .chat-bubble {
        position: relative;
        border-radius: 20px;
        padding: 1.4rem;
        max-width: 90%;
        box-shadow: 0 4px 15px -5px rgba(0,0,0,0.03);
    }

    .chat-bubble.student-question {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        align-self: flex-start;
        border-top-right-radius: 4px;
    }

    .chat-bubble.doctor-reply {
        background: #f0fdf4;
        border: 1px solid #dcfce7;
        align-self: flex-end;
        border-top-left-radius: 4px;
    }

    .bubble-header {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.82rem;
        font-weight: 900;
        margin-bottom: 0.8rem;
    }

    .student-question .bubble-header { color: #0284c7; }
    .doctor-reply .bubble-header { color: #166534; }

    .question-title {
        font-size: 1.25rem;
        font-weight: 900;
        color: #0f172a;
        margin: 0 0 0.8rem;
        line-height: 1.5;
    }

    .question-text,
    .answer-text {
        color: #334155;
        line-height: 1.85;
        white-space: pre-wrap;
        margin: 0;
        font-size: 1rem;
    }

    .actor-pill {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        margin-top: 1rem;
        padding: 0.4rem 0.8rem;
        border-radius: 999px;
        background: rgba(16, 185, 129, 0.1);
        color: #14532d;
        font-size: 0.8rem;
        font-weight: 800;
    }

    /* Reply side panel */
    .side-panel {
        display: flex;
        flex-direction: column;
        gap: 1.25rem;
    }

    .reply-card {
        padding: 1.5rem;
    }

    .card-title {
        font-size: 1.15rem;
        font-weight: 900;
        color: #0f172a;
        margin-bottom: 0.5rem;
    }

    .card-copy {
        color: #64748b;
        line-height: 1.7;
        font-size: 0.88rem;
        margin-bottom: 1.2rem;
    }

    .reply-card textarea {
        width: 100%;
        min-height: 160px;
        border-radius: 14px;
        border: 1px solid #cbd5e1;
        background: #f8fafc;
        padding: 0.9rem 1rem;
        font-family: inherit;
        font-size: 0.95rem;
        resize: vertical;
        margin-bottom: 1rem;
        transition: all 0.2s ease;
    }

    .reply-card textarea:focus {
        outline: none;
        background: #ffffff;
        border-color: #0f766e;
        box-shadow: 0 0 0 3px rgba(15, 118, 110, 0.1);
    }

    /* Canned Templates Styling */
    .canned-tag {
        display: inline-flex;
        padding: 0.35rem 0.7rem;
        border-radius: 8px;
        background: #f1f5f9;
        border: 1px solid #e2e8f0;
        color: #475569;
        font-size: 0.78rem;
        font-weight: 800;
        cursor: pointer;
        transition: all 0.2s ease;
    }

    .canned-tag:hover {
        background: #ccfbf1;
        color: #0f766e;
        border-color: #99f6e4;
    }

    .btn-submit {
        width: 100%;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        border: none;
        border-radius: 12px;
        padding: 0.85rem 1rem;
        font-weight: 800;
        cursor: pointer;
        color: #ffffff;
        background: linear-gradient(135deg, #0f766e 0%, #14b8a6 100%);
        box-shadow: 0 8px 16px -6px rgba(15, 118, 110, 0.4);
        transition: all 0.2s ease;
        font-size: 0.95rem;
    }

    .btn-submit:hover {
        transform: translateY(-1px);
        box-shadow: 0 10px 20px -5px rgba(15, 118, 110, 0.5);
    }

    .notice-card {
        padding: 1.5rem;
        background: linear-gradient(180deg, #f0f9ff, #f8fafc);
        border: 1px solid #bae6fd;
    }

    .notice-icon {
        width: 40px;
        height: 40px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        margin-bottom: 0.85rem;
        background: #e0f2fe;
        color: #0284c7;
    }

    @media (max-width: 980px) {
        .layout-grid {
            grid-template-columns: 1fr;
        }
    }
</style>

<div class="page-shell">
    <a href="{{ route('doctor.inquiries.index') }}" class="back-link">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <polyline points="15 18 9 12 15 6"></polyline>
        </svg>
        العودة إلى قائمة الاستفسارات
    </a>

    @if(session('success'))
        <div class="alert alert-success mb-4" style="border-radius: 16px; font-weight: bold; padding: 1rem 1.25rem;">
            {{ session('success') }}
        </div>
    @endif

    <div class="hero-card">
        <div class="hero-top">
            <div>
                <h1 class="hero-title">{{ $inquiry->title }}</h1>
                <p class="hero-copy">
                    مراجعة تفاصيل سؤال الطالب والإجابة عليه مباشرة من أستاذ المادة.
                </p>
            </div>

            <div class="status-chip">{{ $inquiry->status_label }}</div>
        </div>
    </div>

    <div class="layout-grid">
        <!-- المحادثة وتفاصيل السؤال -->
        <div class="panel">
            <div class="panel-body">
                <!-- بطاقة الطالب المدمجة -->
                <div class="student-card-web">
                    <div class="student-avatar">{{ mb_substr($inquiry->student->name ?? '?', 0, 1) }}</div>
                    <div class="student-name">{{ $inquiry->student->name ?? 'طالب' }}</div>
                    <div class="student-submeta">رقم القيد الأكاديمي: {{ $inquiry->student->student_number ?: 'بدون رقم قيد' }}</div>
                    
                    <div class="meta-row mt-3">
                        <span class="meta-chip">{{ $inquiry->subject->name ?? 'مادة غير محددة' }}</span>
                        <span class="meta-chip">أُرسل: {{ $inquiry->created_at->format('Y-m-d H:i') }}</span>
                        @if($inquiry->answered_at)
                            <span class="meta-chip">تم الرد: {{ $inquiry->answered_at->format('Y-m-d H:i') }}</span>
                        @endif
                    </div>
                </div>

                <!-- جدول المحادثة -->
                <div class="bubble-container">
                    <!-- سؤال الطالب -->
                    <div class="chat-bubble student-question">
                        <div class="bubble-header">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                <circle cx="12" cy="12" r="10"></circle>
                                <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
                                <line x1="12" y1="17" x2="12.01" y2="17"></line>
                            </svg>
                            سؤال الطالب للمادة
                        </div>
                        <h3 class="question-title">{{ $inquiry->title }}</h3>
                        <p class="question-text">{{ $inquiry->question }}</p>
                    </div>

                    <!-- رد الدكتور (إن وجد) -->
                    @if($inquiry->answer)
                        <div class="chat-bubble doctor-reply">
                            <div class="bubble-header">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                    <polyline points="20 6 9 17 4 12"></polyline>
                                </svg>
                                الرد المعتمد والنهائي
                            </div>
                            <p class="answer-text">{{ $inquiry->answer }}</p>

                            @if($inquiry->answered_by_actor_name)
                                <div class="actor-pill">
                                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                                        <circle cx="12" cy="7" r="4"></circle>
                                    </svg>
                                    أجاب عليه {{ $inquiry->answered_by_actor_label }}: {{ $inquiry->answered_by_actor_name }}
                                </div>
                            @endif
                        </div>
                    @endif
                </div>
            </div>
        </div>

        <!-- الجانب التفاعلي والرد -->
        <div class="side-panel">
            @if($inquiry->status === 'forwarded')
                <div class="panel reply-card">
                    <div class="card-title">كتابة رد الدكتور</div>
                    <div class="card-copy">
                        سيتم إرسال هذا الرد مباشرة لحساب الطالب وتحديث حالة السؤال إلى "تمت الإجابة".
                    </div>

                    <!-- ميزة الردود الجاهزة السريعة -->
                    <div class="canned-responses mb-3">
                        <label style="font-size:0.8rem; color:#64748b; font-weight:bold; display:block; margin-bottom:0.6rem;">الردود الجاهزة السريعة:</label>
                        <div style="display:flex; gap:0.4rem; flex-wrap:wrap;">
                            <span class="canned-tag" onclick="insertCanned('يرجى مراجعة المندوب لمتابعة الطلب.')">مراجعة المندوب</span>
                            <span class="canned-tag" onclick="insertCanned('سأقوم بشرح هذا الموضوع بالتفصيل في المحاضرة القادمة.')">شرح بالمحاضرة</span>
                            <span class="canned-tag" onclick="insertCanned('تمت المراجعة وتعديل بياناتك بنجاح.')">تم التعديل</span>
                            <span class="canned-tag" onclick="insertCanned('يرجى الحضور لمكتب أستاذ المادة في الكلية للمناقشة.')">حضور للمكتب</span>
                        </div>
                    </div>

                    <form action="{{ route('doctor.inquiries.answer', $inquiry->id) }}" method="POST">
                        @csrf
                        <textarea name="answer" id="answerTextarea" placeholder="اكتب رد الدكتور الواضح والمباشر هنا..." required>{{ old('answer') }}</textarea>
                        @error('answer')
                            <div class="text-danger mb-3" style="font-weight: bold; font-size: 0.85rem;">{{ $message }}</div>
                        @enderror
                        
                        <button type="submit" class="btn-submit">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                <line x1="22" y1="2" x2="11" y2="13"></line>
                                <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                            </svg>
                            إرسال الإجابة للطالب
                        </button>
                    </form>
                </div>
            @else
                <div class="panel notice-card">
                    <div class="notice-icon">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                            <polyline points="20 6 9 17 4 12"></polyline>
                        </svg>
                    </div>
                    <div class="card-title">مستند أرشيفي مغلق</div>
                    <div class="card-copy" style="margin-bottom:0;">
                        تم الرد على هذا الاستفسار وإغلاقه بشكل نهائي. السجل الآن محفوظ ومتاح للقراءة والمطابقة في أي وقت.
                    </div>
                </div>
            @endif
        </div>
    </div>
</div>

<script>
    // إدخال الرد السريع في حقل النص
    function insertCanned(text) {
        const textarea = document.getElementById('answerTextarea');
        if (textarea) {
            textarea.value = text;
            textarea.focus();
        }
    }
</script>
@endsection
