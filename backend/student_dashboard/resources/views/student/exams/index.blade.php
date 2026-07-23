@extends('layouts.student')

@section('title', 'جداول الاختبارات')

@push('styles')
<style>
    .page-header {
        margin-bottom: 2.5rem;
    }

    .page-title {
        font-size: 2rem;
        font-weight: 800;
        color: var(--text-primary);
        margin-bottom: 0.5rem;
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .page-subtitle {
        color: var(--text-secondary);
        font-size: 1.1rem;
    }

    /* Exam Schedule Container */
    .exam-schedule {
        background: white;
        border-radius: 28px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        margin-bottom: 3rem;
        transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .exam-schedule:hover {
        transform: translateY(-5px);
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
    }

    /* Official Schedule Styling */
    .exam-schedule.is-official {
        border: 2px solid #4f46e5;
        position: relative;
    }

    .schedule-header {
        background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
        color: white;
        padding: 2rem;
        position: relative;
        overflow: hidden;
    }

    .schedule-header.is-official {
        background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
    }

    .schedule-header::before {
        content: '';
        position: absolute;
        top: -50px;
        left: -50px;
        width: 150px;
        height: 150px;
        background: rgba(255, 255, 255, 0.05);
        border-radius: 50%;
    }

    .schedule-header.is-official::before {
        background: rgba(255, 255, 255, 0.15);
    }

    .schedule-title {
        font-size: 1.6rem;
        font-weight: 800;
        margin-bottom: 0.75rem;
        position: relative;
        z-index: 1;
        letter-spacing: -0.02em;
    }

    .schedule-meta {
        display: flex;
        flex-wrap: wrap;
        gap: 1.5rem;
        font-size: 0.95rem;
        opacity: 0.9;
        position: relative;
        z-index: 1;
    }

    .schedule-meta span {
        display: flex;
        align-items: center;
        gap: 0.6rem;
    }

    /* Official Badge */
    .official-tag {
        background: rgba(255, 255, 255, 0.15);
        backdrop-filter: blur(8px);
        padding: 0.5rem 1rem;
        border-radius: 99px;
        font-size: 0.8rem;
        font-weight: 700;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        border: 1px solid rgba(255, 255, 255, 0.2);
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }

    .official-tag i {
        color: #fbbf24;
        font-size: 1rem;
    }

    .official-tag.is-official {
        background: #fbbf24;
        color: #78350f;
        border: none;
    }

    .official-tag.is-official i {
        color: #78350f;
    }

    /* Layout */
    .schedule-content {
        display: grid;
        grid-template-columns: 1fr 300px;
        min-height: 400px;
    }

    /* Info Sidebar */
    .info-sidebar {
        background: #f8fafc;
        border-right: 1px solid #e2e8f0;
        padding: 2rem;
    }

    .info-title {
        font-weight: 800;
        color: #475569;
        font-size: 0.9rem;
        margin-bottom: 1.25rem;
        display: flex;
        align-items: center;
        gap: 0.6rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .stats-card-group {
        display: flex;
        flex-direction: column;
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .stat-mini-card {
        background: white;
        border-radius: 16px;
        padding: 1.25rem;
        display: flex;
        align-items: center;
        gap: 1rem;
        border: 1px solid #e2e8f0;
        transition: all 0.2s;
    }

    .stat-mini-card:hover {
        border-color: #4f46e5;
        background: #fefeff;
    }

    .mini-icon {
        width: 40px;
        height: 40px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.2rem;
    }

    .stat-info {
        display: flex;
        flex-direction: column;
    }

    .stat-val {
        font-size: 1.5rem;
        font-weight: 800;
        color: #1e293b;
        line-height: 1;
    }

    .stat-lbl {
        font-size: 0.8rem;
        color: #64748b;
        margin-top: 0.25rem;
    }

    .notes-display {
        background: #f1f5f9;
        border-radius: 16px;
        padding: 1.25rem;
        font-size: 0.95rem;
        line-height: 1.8;
        color: #334155;
        border: 1px solid #e2e8f0;
    }

    /* Exam Table Enhancement */
    .exam-table-wrapper {
        padding: 2rem;
    }

    .premium-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0 0.75rem;
    }

    .premium-table thead th {
        padding: 1rem 1.5rem;
        text-align: right;
        font-weight: 700;
        color: #64748b;
        font-size: 0.85rem;
        border: none;
        text-transform: uppercase;
    }

    .premium-table tbody tr {
        background: white;
        transition: transform 0.2s;
    }

    .premium-table tbody tr td {
        padding: 1.5rem;
        border-top: 1px solid #f1f5f9;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
    }

    .premium-table tbody tr td:first-child {
        border-right: 1px solid #f1f5f9;
        border-radius: 0 16px 16px 0;
    }

    .premium-table tbody tr td:last-child {
        border-left: 1px solid #f1f5f9;
        border-radius: 16px 0 0 16px;
    }

    .premium-table tbody tr:hover {
        background: #f8fafc;
        transform: scale(1.005);
    }

    .subj-name {
        font-weight: 800;
        color: #1e293b;
        font-size: 1.1rem;
        margin-bottom: 0.2rem;
    }

    .subj-meta {
        font-size: 0.85rem;
        color: #64748b;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .date-pill {
        display: inline-flex;
        align-items: center;
        gap: 0.75rem;
        background: #f1f5f9;
        padding: 0.6rem 1rem;
        border-radius: 12px;
    }

    .day-txt {
        color: #4f46e5;
        font-weight: 800;
        font-size: 0.9rem;
    }

    .date-num {
        color: #64748b;
        font-weight: 600;
        font-family: 'Inter', system-ui, sans-serif;
    }

    .time-luxury-badge {
        display: inline-flex;
        align-items: center;
        gap: 0.85rem;
        padding: 0.75rem 1.25rem;
        background: white;
        border: 2px solid #f1f5f9;
        border-radius: 16px;
        font-size: 0.95rem;
    }

    .t-icon { color: #f59e0b; }
    .t-val { font-weight: 800; color: #1e293b; }
    .t-sep { color: #cbd5e1; }

    .loc-info {
        display: flex;
        align-items: center;
        gap: 0.6rem;
        color: #475569;
        font-weight: 600;
    }

    .loc-info i {
        color: #ef4444;
    }

    /* Empty State */
    .premium-empty {
        text-align: center;
        padding: 6rem 3rem;
        background: white;
        border-radius: 32px;
        border: 1px solid #e2e8f0;
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
    }

    .empty-sphere {
        width: 100px;
        height: 100px;
        background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 2rem;
        color: #cbd5e1;
        font-size: 3rem;
        border: 1px solid #e2e8f0;
    }

    @media (max-width: 1024px) {
        .schedule-content {
            grid-template-columns: 1fr;
        }
        .info-sidebar {
            border-right: none;
            border-top: 1px solid #e2e8f0;
        }
    }

    @media print {
        .sidebar, .top-header, .btn-group, .btn { display: none !important; }
        .main-content { margin: 0 !important; width: 100% !important; }
        .exam-schedule { box-shadow: none !important; border: 1px solid #000 !important; }
    }
</style>
@endpush

@section('content')

<div class="page-header animate__animated animate__fadeIn">
    <h1 class="page-title">
        <i class="fa-solid fa-calendar-check" style="color: #4f46e5;"></i>
        جداول الاختبارات
    </h1>
    <p class="page-subtitle">قائمة جداول الاختبارات المعتمدة والمقترحة للفصل الدراسي الحالي</p>
</div>

@forelse($schedules as $exam)
<div class="exam-schedule animate__animated animate__fadeInUp {{ $exam->creator && in_array($exam->creator->role->value, ['admin', 'administrative']) ? 'is-official' : '' }}">
    <!-- Header -->
    <div class="schedule-header {{ $exam->creator && in_array($exam->creator->role->value, ['admin', 'administrative']) ? 'is-official' : '' }}">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <div class="schedule-title">{{ $exam->title }}</div>
            
            @if($exam->creator && in_array($exam->creator->role->value, ['admin', 'administrative']))
                <div class="official-tag is-official">
                    <i class="fa-solid fa-shield-check"></i>
                    <span>جدول رسمي معتمد</span>
                </div>
            @else
                <div class="official-tag">
                    <i class="fa-solid fa-file-signature"></i>
                    <span>جدول مقترح من المندوب</span>
                </div>
            @endif
        </div>
        
        <div class="schedule-meta">
            <span>
                <i class="fa-solid fa-graduation-cap"></i>
                {{ $term->name ?? $exam->term->name ?? '-' }}
            </span>
            <span>
                <i class="fa-solid fa-calendar-day"></i>
                تاريخ النشر: {{ $exam->created_at->translatedFormat('d F Y') }}
            </span>
            <span>
                <i class="fa-solid fa-book-bookmark"></i>
                {{ $exam->items->count() }} مواد دراسية
            </span>
        </div>
    </div>

    <!-- Content Area -->
    <div class="schedule-content">
        <!-- Main Table Section -->
        <div class="exam-table-wrapper">
            <div class="table-responsive">
                <table class="premium-table">
                    <thead>
                        <tr>
                            <th width="35%">المادة الدراسية</th>
                            <th width="25%">اليوم والتاريخ</th>
                            <th width="25%">الفترة الزمنية</th>
                            <th width="15%">المقر</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($exam->items->sortBy('exam_date') as $item)
                        <tr>
                            <td>
                                <div class="subj-name">{{ $item->subject->name }}</div>
                                @if($item->subject->code)
                                <div class="subj-meta">
                                    <span class="badge bg-light text-dark border">{{ $item->subject->code }}</span>
                                </div>
                                @endif
                            </td>
                            <td>
                                <div class="date-pill text-nowrap">
                                    <span class="day-txt">{{ $item->exam_date->locale('ar')->translatedFormat('l') }}</span>
                                    <span class="date-num">{{ $item->exam_date->format('Y/m/d') }}</span>
                                </div>
                            </td>
                            <td>
                                <div class="time-luxury-badge text-nowrap">
                                    <i class="fa-solid fa-clock t-icon"></i>
                                    <span class="t-val">{{ \Carbon\Carbon::parse($item->start_time)->format('h:i A') }}</span>
                                    <span class="t-sep ml-1 mr-1">-</span>
                                    <span class="t-val">{{ \Carbon\Carbon::parse($item->end_time)->format('h:i A') }}</span>
                                </div>
                            </td>
                            <td>
                                @if($item->location)
                                <div class="loc-info">
                                    <i class="fa-solid fa-location-dot"></i>
                                    <span>{{ $item->location }}</span>
                                </div>
                                @else
                                <span class="text-muted small italic">قيد التحديد</span>
                                @endif
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="4" class="text-center py-5">لا توجد مواد مضافة لهذا الجدول</td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Sidebar Section -->
        <div class="info-sidebar">
            <div class="info-title">
                <i class="fa-solid fa-circle-info"></i>
                ملخص الجدول
            </div>

            <div class="stats-card-group">
                <div class="stat-mini-card">
                    <div class="mini-icon" style="background: #eff6ff; color: #3b82f6;">
                        <i class="fa-solid fa-book"></i>
                    </div>
                    <div class="stat-info">
                        <span class="stat-val">{{ $exam->items->count() }}</span>
                        <span class="stat-lbl">إجمالي المواد</span>
                    </div>
                </div>
                
                <div class="stat-mini-card">
                    <div class="mini-icon" style="background: #fff7ed; color: #f59e0b;">
                        <i class="fa-solid fa-hourglass-half"></i>
                    </div>
                    <div class="stat-info">
                        <span class="stat-val text-nowrap" style="font-size: 1.1rem;">
                            @php
                                $firstExam = $exam->items->sortBy('exam_date')->first();
                                $lastExam = $exam->items->sortByDesc('exam_date')->first();
                            @endphp
                            {{ $firstExam ? $firstExam->exam_date->diffInDays($lastExam->exam_date) + 1 : 0 }} يوم
                        </span>
                        <span class="stat-lbl">فترة الاختبارات</span>
                    </div>
                </div>
            </div>

            @if($exam->description)
            <div class="info-title">
                <i class="fa-solid fa-note-sticky"></i>
                تعليمات وملاحظات
            </div>
            <div class="notes-display animate__animated animate__fadeIn">
                {{ $exam->description }}
            </div>
            @endif

        </div>
    </div>
</div>
@empty
<div class="premium-empty animate__animated animate__zoomIn">
    <div class="empty-sphere">
        <i class="fa-solid fa-calendar-xmark text-muted"></i>
    </div>
    <h3 class="fw-bold text-dark mb-2">لا توجد جداول اختبارات</h3>
    <p class="text-muted mx-auto" style="max-width: 400px;">لم يتم نشر أي جداول اختبارات لتخصصك في الوقت الحالي. سيتم تنبيهك فور نشر الجداول الرسمية.</p>
</div>
@endforelse

@endsection