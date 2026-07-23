@extends('layouts.student')

@section('title', 'الرئيسية')

@section('content')

<style>
    /* Welcome Banner */
    .welcome-banner {
        background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
        border-radius: 24px;
        padding: 2rem;
        color: white;
        margin-bottom: 2rem;
        position: relative;
        overflow: hidden;
    }

    .welcome-banner::before {
        content: '';
        position: absolute;
        top: -50%;
        right: -20%;
        width: 400px;
        height: 400px;
        background: rgba(255, 255, 255, 0.1);
        border-radius: 50%;
    }

    .welcome-banner::after {
        content: '';
        position: absolute;
        bottom: -30%;
        left: 10%;
        width: 200px;
        height: 200px;
        background: rgba(255, 255, 255, 0.05);
        border-radius: 50%;
    }

    /* Stats Cards */
    .stats-grid {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 1.5rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: white;
        border-radius: 20px;
        padding: 1.5rem;
        display: flex;
        align-items: center;
        gap: 1.25rem;
        border: 1px solid #e2e8f0;
        transition: all 0.3s ease;
    }

    .stat-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 12px 24px -8px rgba(0, 0, 0, 0.1);
    }

    .stat-icon {
        width: 56px;
        height: 56px;
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .stat-value {
        font-size: 1.75rem;
        font-weight: 800;
        line-height: 1;
        margin-bottom: 0.25rem;
    }

    .stat-label {
        color: var(--text-secondary);
        font-size: 0.9rem;
    }

    /* Content Grid */
    .content-grid {
        display: grid;
        grid-template-columns: 1.5fr 1fr;
        gap: 1.5rem;
        align-items: start;
    }

    /* Alert Box */
    .alert-box {
        background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%);
        border: 2px solid #fecaca;
        border-radius: 20px;
        padding: 1.5rem;
        display: flex;
        align-items: center;
        gap: 1.25rem;
        margin-bottom: 1.25rem;
        box-shadow: 0 4px 6px -1px rgba(220, 38, 38, 0.1);
        transition: transform 0.2s;
    }

    .alert-box:hover {
        transform: scale(1.01);
    }

    .alert-box.warning {
        background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%);
        border-color: #fde68a;
        box-shadow: 0 4px 6px -1px rgba(217, 119, 6, 0.1);
    }

    .alert-icon {
        width: 50px;
        height: 50px;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .alert-content {
        flex: 1;
    }

    .alert-title {
        font-weight: 800;
        font-size: 1.1rem;
        margin-bottom: 0.35rem;
    }

    .alert-desc {
        margin: 0;
        font-size: 0.95rem;
        opacity: 0.9;
    }

    /* Section Card */
    .section-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.02);
    }

    .section-header {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid #f1f5f9;
        display: flex;
        align-items: center;
        gap: 0.75rem;
        font-weight: 800;
        font-size: 1.1rem;
        color: var(--text-primary);
    }

    .section-body {
        padding: 1.5rem;
    }

    /* Announcement Item */
    .announcement-item {
        padding: 1.25rem;
        border-radius: 16px;
        background: #f8fafc;
        margin-bottom: 1rem;
        border-right: 4px solid #6366f1;
        transition: all 0.2s;
    }

    .announcement-item:hover {
        background: #f1f5f9;
    }

    .announcement-item.urgent {
        border-right-color: #ef4444;
        background: #fef2f2;
    }

    .announcement-item.academic {
        border-right-color: #3b82f6;
    }

    /* Reminder Item */
    .reminder-item {
        display: flex;
        gap: 1rem;
        padding: 1rem 0;
        border-bottom: 1px solid #f1f5f9;
    }

    .reminder-item:last-child {
        border-bottom: none;
        padding-bottom: 0;
    }

    .date-box {
        width: 52px;
        height: 52px;
        background: linear-gradient(135deg, #f1f5f9 0%, #e2e8f0 100%);
        border-radius: 12px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .date-day {
        font-size: 1.25rem;
        font-weight: 800;
        color: var(--text-primary);
        line-height: 1;
    }

    .date-month {
        font-size: 0.7rem;
        color: var(--primary-color);
        font-weight: 700;
        text-transform: uppercase;
    }

    /* Quick Links */
    .quick-link {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.75rem;
        padding: 1.25rem;
        background: #f8fafc;
        border-radius: 16px;
        text-decoration: none;
        transition: all 0.2s;
    }

    .quick-link:hover {
        background: #f1f5f9;
        transform: translateY(-2px);
    }

    .quick-link-icon {
        width: 48px;
        height: 48px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .quick-link-text {
        font-weight: 600;
        color: var(--text-primary);
        font-size: 0.9rem;
    }

    @media (max-width: 1200px) {
        .stats-grid {
            grid-template-columns: repeat(2, 1fr);
        }
    }

    @media (max-width: 900px) {
        .content-grid {
            grid-template-columns: 1fr;
        }
    }
</style>

<!-- Welcome Banner -->
<div class="welcome-banner">
    <div style="position: relative; z-index: 1;">
        <h1 style="font-size: 1.5rem; font-weight: 700; margin-bottom: 0.5rem;">
            مرحباً، {{ $student->name }} 👋
        </h1>
        <p style="opacity: 0.9; margin-bottom: 1rem;">
            {{ $student->university->name ?? 'النظام الأكاديمي' }} | {{ $student->major->name ?? 'التخصص' }} - {{ $student->level->name ?? 'المستوى' }}
        </p>
        <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
            <span style="background: rgba(255,255,255,0.2); padding: 0.4rem 0.75rem; border-radius: 8px; font-size: 0.85rem;">
                📅 {{ now()->format('l, d M Y') }}
            </span>
        </div>
    </div>
</div>

<!-- Alerts Section -->
@if((isset($warnings) && count($warnings) > 0) || (isset($excuseWarnings) && $excuseWarnings->count() > 0))
<div style="margin-bottom: 2rem;">
    @if(isset($warnings) && count($warnings) > 0)
    @foreach($warnings as $warn)
    <div class="alert-box">
        <div class="alert-icon" style="background: rgba(220, 38, 38, 0.15); color: #dc2626;">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                <line x1="12" y1="9" x2="12" y2="13"></line>
                <line x1="12" y1="17" x2="12.01" y2="17"></line>
            </svg>
        </div>
        <div class="alert-content">
            @if($warn['status'] == 'banned')
            <div class="alert-title" style="color: #b91c1c;">قرار حرمان مؤكد 🚫</div>
            <p class="alert-desc" style="color: #7f1d1d;">لقد تجاوزت الحد الأقصى المسموح للغياب في مقرر <strong>{{ $warn['subject'] }}</strong> (الغيابات: {{ $warn['absences'] }}/{{ $warn['max'] }}). يرجى مراجعة شؤون الطلاب.</p>
            @else
            <div class="alert-title" style="color: #b91c1c;">الإنذار الأخير قبل الحرمان ⚠️</div>
            <p class="alert-desc" style="color: #7f1d1d;">انتبه! تبقى لك غياب واحد فقط في مقرر <strong>{{ $warn['subject'] }}</strong> (الغيابات: {{ $warn['absences'] }}/{{ $warn['max'] }}).</p>
            @endif
        </div>
    </div>
    @endforeach
    @endif

    @if(isset($excuseWarnings) && $excuseWarnings->count() > 0)
    @foreach($excuseWarnings as $warning)
    <div class="alert-box warning">
        <div class="alert-icon" style="background: rgba(245, 158, 11, 0.15); color: #d97706;">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
        </div>
        <div class="alert-content">
            <div class="alert-title" style="color: #a16207;">تذكير بمهلة تقديم عذر غياب ⏰</div>
            <p class="alert-desc" style="color: #78350f;">اقتربت نهاية مهلة التبرير لغيابك في مادة <strong>{{ $warning->subject->name }}</strong> بتاريخ {{ $warning->date->format('Y-m-d') }}.</p>
        </div>
        <a href="{{ route('student.subjects.show', $warning->subject_id) }}" style="background: #f59e0b; color: white; padding: 0.5rem 1rem; border-radius: 10px; text-decoration: none; font-weight: 600; font-size: 0.85rem; white-space: nowrap;">تقديم عذر</a>
    </div>
    @endforeach
    @endif
</div>
@endif

<!-- Stats Grid -->
<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-icon" style="background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%); color: #4f46e5;">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
            </svg>
        </div>
        <div>
            <div class="stat-value">{{ $subjects->count() }}</div>
            <div class="stat-label">مقرر دراسي</div>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-icon" style="background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%); color: #2563eb;">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
                <line x1="16" y1="13" x2="8" y2="13"></line>
                <line x1="16" y1="17" x2="8" y2="17"></line>
            </svg>
        </div>
        <div>
            <div class="stat-value">{{ $assignmentsCount }}</div>
            <div class="stat-label">تكليف نشط</div>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-icon" style="background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%); color: #dc2626;">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="15" y1="9" x2="9" y2="15"></line>
                <line x1="9" y1="9" x2="15" y2="15"></line>
            </svg>
        </div>
        <div>
            <div class="stat-value" style="color: #dc2626;">{{ $totalAbsences }}</div>
            <div class="stat-label">إجمالي أيام الغياب</div>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-icon" style="background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%); color: #d97706;">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
        </div>
        <div>
            <div class="stat-value">{{ $reminders->count() }}</div>
            <div class="stat-label">تذكير قادم</div>
        </div>
    </div>
</div>

<!-- Exam Countdown Card -->
@if(isset($nextExam) && $nextExam)
<div style="background: linear-gradient(135deg, #dc2626 0%, #ef4444 100%); border-radius: 20px; padding: 1.5rem; margin-bottom: 2rem; color: white; display: flex; justify-content: space-between; align-items: center; position: relative; overflow: hidden;">
    <div style="position: absolute; top: -20px; left: -20px; width: 100px; height: 100px; background: rgba(255,255,255,0.1); border-radius: 50%;"></div>
    <div style="position: absolute; bottom: -30px; right: 10%; width: 80px; height: 80px; background: rgba(255,255,255,0.05); border-radius: 50%;"></div>
    <div style="position: relative; z-index: 1;">
        <div style="display: flex; align-items: center; gap: 0.75rem; margin-bottom: 0.5rem;">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
            </svg>
            <span style="font-weight: 600; font-size: 0.9rem; opacity: 0.9;">الاختبار القادم</span>
        </div>
        <div style="font-size: 1.2rem; font-weight: 700; margin-bottom: 0.25rem;">{{ $nextExam['subject'] }}</div>
        <div style="font-size: 0.85rem; opacity: 0.9;">
            📅 {{ \Carbon\Carbon::parse($nextExam['date'])->format('Y-m-d') }}
            @if($nextExam['start_time'])
            • ⏰ {{ \Carbon\Carbon::parse($nextExam['start_time'])->format('h:i A') }}
            @endif
            @if($nextExam['location'])
            • 📍 {{ $nextExam['location'] }}
            @endif
        </div>
    </div>
    <div style="text-align: center; position: relative; z-index: 1;">
        <div style="font-size: 3rem; font-weight: 900; line-height: 1;">{{ $nextExam['days_remaining'] }}</div>
        <div style="font-size: 0.85rem; opacity: 0.9;">{{ $nextExam['days_remaining'] == 1 ? 'يوم واحد' : 'يوم متبقي' }}</div>
    </div>
    <a href="{{ route('student.exams.index') }}" style="position: relative; z-index: 1; background: rgba(255,255,255,0.2); padding: 0.6rem 1rem; border-radius: 10px; text-decoration: none; color: white; font-weight: 600; font-size: 0.85rem;">
        عرض الجدول
    </a>
</div>
@endif

    <!-- Right Column: Announcements -->
    <div style="display: flex; flex-direction: column; gap: 1.5rem;">
        <!-- Administrative Announcements -->
        @if(isset($adminAnnouncements) && $adminAnnouncements->count() > 0)
        <div class="section-card" style="border-top: 4px solid var(--primary-color);">
            <div class="section-header">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M22 17H2a3 3 0 0 0 3-3V9a7 7 0 0 1 14 0v5a3 3 0 0 0 3 3zm-8.27 4a2 2 0 0 1-3.46 0"></path>
                </svg>
                إعلانات الإدارة
                <span style="background: var(--primary-color); color: white; padding: 2px 8px; border-radius: 6px; font-size: 0.75rem; margin-right: auto;">تنبيهات رسمية</span>
            </div>
            <div class="section-body">
                @foreach($adminAnnouncements as $notif)
                <div class="announcement-item" style="border-right-color: {{ $notif->color ?? '#6366f1' }}; background: {{ ($notif->color ?? '#6366f1') . '08' }};">
                    <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 0.5rem;">
                        <span style="font-size: 0.8rem; padding: 0.25rem 0.5rem; border-radius: 6px; font-weight: 600; background: {{ ($notif->color ?? '#6366f1') . '15' }}; color: {{ $notif->color ?? '#6366f1' }};">
                            @php
                                $typeLabels = [
                                    'exam' => 'اخبار الاختبارات',
                                    'assignment' => 'تكليف دراسي',
                                    'resource' => 'مصدر تعليمي',
                                    'announcement' => 'إعلان إداري',
                                    'attendance' => 'تنبيه حضور',
                                    'poll' => 'استطلاع رأي'
                                ];
                            @endphp
                            {{ $typeLabels[$notif->type] ?? 'تنبيه' }}
                        </span>
                        <span style="font-size: 0.8rem; color: var(--text-secondary);">{{ $notif->created_at->diffForHumans() }}</span>
                    </div>
                    <h4 style="font-weight: 700; margin-bottom: 0.5rem; font-size: 1.05rem; color: var(--text-primary);">{{ $notif->title }}</h4>
                    <p style="color: var(--text-secondary); font-size: 0.9rem; margin: 0; line-height: 1.6;">{{ Str::limit($notif->message, 150) }}</p>
                    
                    <div style="margin-top: 1rem; display: flex; gap: 0.75rem;">
                        <a href="{{ route('student.notifications.index') }}" style="font-size: 0.85rem; font-weight: 700; color: var(--primary-color); text-decoration: none; display: flex; align-items: center; gap: 0.25rem;">
                            عرض التفاصيل
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                <path d="M15 18l-6-6 6-6"></path>
                            </svg>
                        </a>
                        @if($notif->attachment_path)
                        <a href="{{ $notif->attachment_url }}" target="_blank" style="font-size: 0.85rem; font-weight: 700; color: #64748b; text-decoration: none; display: flex; align-items: center; gap: 0.25rem;">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                <path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"></path>
                            </svg>
                            المرفق
                        </a>
                        @endif
                    </div>
                </div>
                @endforeach
            </div>
        </div>
        @endif

        <!-- Latest Announcements -->
        <div class="section-card">
        <div class="section-header">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
            </svg>
            آخر الإعلانات
            <a href="{{ route('student.news.index') }}" style="margin-right: auto; font-size: 0.85rem; color: var(--primary-color); text-decoration: none;">عرض الكل</a>
        </div>
        <div class="section-body">
            @forelse($announcements as $post)
            <div class="announcement-item {{ $post->category }}">
                <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 0.5rem;">
                    <span style="font-size: 0.8rem; padding: 0.25rem 0.5rem; border-radius: 6px; font-weight: 600; {{ $post->category == 'urgent' ? 'background: #fee2e2; color: #dc2626;' : ($post->category == 'academic' ? 'background: #dbeafe; color: #2563eb;' : 'background: #f1f5f9; color: #64748b;') }}">
                        {{ $post->category == 'urgent' ? 'عاجل' : ($post->category == 'academic' ? 'أكاديمي' : 'عام') }}
                    </span>
                    <span style="font-size: 0.8rem; color: var(--text-secondary);">{{ $post->created_at->diffForHumans() }}</span>
                </div>
                <h4 style="font-weight: 700; margin-bottom: 0.5rem; font-size: 1rem;">{{ $post->title }}</h4>
                <p style="color: var(--text-secondary); font-size: 0.9rem; margin: 0; line-height: 1.6;">{{ Str::limit($post->content, 120) }}</p>
            </div>
            @empty
            <div style="text-align: center; padding: 2rem; color: var(--text-secondary);">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin: 0 auto 1rem;">
                    <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
                </svg>
                <p>لا توجد إعلانات حالياً</p>
            </div>
            @endforelse
        </div>
    </div>

    <!-- Left Column -->
    <div style="display: flex; flex-direction: column; gap: 1.5rem;">
        <!-- Reminders -->
        <div class="section-card">
            <div class="section-header">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <polyline points="12 6 12 12 16 14"></polyline>
                </svg>
                تذكيرات قادمة
            </div>
            <div class="section-body" style="padding-top: 1rem;">
                @forelse($reminders as $reminder)
                <div class="reminder-item">
                    <div class="date-box">
                        <span class="date-day">{{ $reminder->event_date->format('d') }}</span>
                        <span class="date-month">{{ $reminder->event_date->format('M') }}</span>
                    </div>
                    <div style="flex: 1; min-width: 0;">
                        <div style="font-weight: 700; font-size: 0.95rem; margin-bottom: 0.25rem;">{{ $reminder->title }}</div>
                        <div style="font-size: 0.85rem; color: var(--text-secondary); margin-bottom: 0.25rem;">{{ Str::limit($reminder->description, 60) }}</div>
                        <div style="font-size: 0.8rem; color: var(--primary-color); font-weight: 600;">{{ $reminder->event_date->format('h:i A') }}</div>
                    </div>
                </div>
                @empty
                <div style="text-align: center; padding: 1.5rem; color: var(--text-secondary);">
                    لا توجد تذكيرات قادمة
                </div>
                @endforelse
            </div>
        </div>

        <!-- Quick Links -->
        <div class="section-card">
            <div class="section-header">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon>
                </svg>
                وصول سريع
            </div>
            <div class="section-body">
                <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem;">
                    <a href="{{ route('student.attendance.scan') }}" class="quick-link">
                        <div class="quick-link-icon" style="background: linear-gradient(135deg, #fde68a 0%, #f59e0b 100%); color: #78350f;">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M3 7V5a2 2 0 0 1 2-2h2"></path>
                                <path d="M17 3h2a2 2 0 0 1 2 2v2"></path>
                                <path d="M21 17v2a2 2 0 0 1-2 2h-2"></path>
                                <path d="M7 21H5a2 2 0 0 1-2-2v-2"></path>
                                <path d="M7 12h10"></path>
                                <path d="M7 16h6"></path>
                                <path d="M7 8h8"></path>
                            </svg>
                        </div>
                        <span class="quick-link-text">مسح QR</span>
                    </a>

                    <a href="{{ route('student.subjects.index') }}" class="quick-link">
                        <div class="quick-link-icon" style="background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%); color: #4f46e5;">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                                <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                            </svg>
                        </div>
                        <span class="quick-link-text">المقررات</span>
                    </a>
                    <a href="{{ route('student.schedule.index') }}" class="quick-link">
                        <div class="quick-link-icon" style="background: linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%); color: #16a34a;">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                                <line x1="16" y1="2" x2="16" y2="6"></line>
                                <line x1="8" y1="2" x2="8" y2="6"></line>
                                <line x1="3" y1="10" x2="21" y2="10"></line>
                            </svg>
                        </div>
                        <span class="quick-link-text">الجدول</span>
                    </a>
                    <a href="{{ route('student.exams.index') }}" class="quick-link">
                        <div class="quick-link-icon" style="background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%); color: #dc2626;">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                                <polyline points="14 2 14 8 20 8"></polyline>
                                <line x1="16" y1="13" x2="8" y2="13"></line>
                                <line x1="16" y1="17" x2="8" y2="17"></line>
                            </svg>
                        </div>
                        <span class="quick-link-text">الاختبارات</span>
                    </a>

                    <a href="{{ route('student.subjects.index') }}" class="quick-link">
                        <div class="quick-link-icon" style="background: linear-gradient(135deg, #f3e8ff 0%, #d8b4fe 100%); color: #7c3aed;">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"></path>
                                <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"></path>
                            </svg>
                        </div>
                        <span class="quick-link-text">المحاضرات</span>
                    </a>

                    @if(Auth::user()->isClinicalDelegate() || Auth::user()->isClinicalSubDelegate())
                    <a href="{{ route('student.clinical.cases.index') }}" class="quick-link">
                        <div class="quick-link-icon" style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white;">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M22 12h-4l-3 9L9 3l-3 9H2"></path>
                            </svg>
                        </div>
                        <span class="quick-link-text">الحالات السريرية</span>
                    </a>
                    @endif
                </div>
            </div>
        </div>
    </div>
</div>

@endsection
