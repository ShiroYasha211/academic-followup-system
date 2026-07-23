@extends('layouts.administrative')

@section('title', 'عرض الجدول الدراسي')

@section('content')

<style>
    .page-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 1rem;
        margin-bottom: 2rem;
        flex-wrap: wrap;
    }

    .header-info {
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .header-icon {
        width: 56px;
        height: 56px;
        background: linear-gradient(135deg, #6366f1 0%, #4338ca 100%);
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        box-shadow: 0 4px 12px -2px rgba(99, 102, 241, 0.4);
    }

    .header-text h1 {
        font-size: 1.5rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.25rem;
    }

    .header-text p {
        color: var(--text-secondary);
        font-size: 0.9rem;
    }

    .header-actions {
        display: flex;
        gap: 0.75rem;
    }

    .btn-print {
        padding: 0.75rem 1.25rem;
        background: white;
        border: 1px solid var(--border-color);
        border-radius: 10px;
        font-weight: 600;
        color: var(--text-primary);
        display: flex;
        align-items: center;
        gap: 0.5rem;
        cursor: pointer;
        transition: all 0.2s;
        box-shadow: 0 1px 2px rgba(0,0,0,0.05);
    }

    .btn-print:hover {
        background: #f8fafc;
    }

    .btn-back {
        padding: 0.75rem 1.25rem;
        background: #f1f5f9;
        border: 1px solid var(--border-color);
        border-radius: 10px;
        font-weight: 600;
        color: var(--text-primary);
        text-decoration: none;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    /* Weekly Calendar View */
    .calendar-wrapper {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        overflow: hidden;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    }

    .calendar-header {
        display: grid;
        grid-template-columns: repeat(7, 1fr);
        background: #f8fafc;
        border-bottom: 1px solid var(--border-color);
    }

    .calendar-day-header {
        padding: 1.25rem 1rem;
        text-align: center;
        font-weight: 800;
        font-size: 0.9rem;
        color: #64748b;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        border-left: 1px solid var(--border-color);
    }

    .calendar-day-header:last-child {
        border-left: none;
    }

    .calendar-body {
        display: grid;
        grid-template-columns: repeat(7, 1fr);
        min-height: 500px;
    }

    .calendar-day {
        border-left: 1px solid var(--border-color);
        border-bottom: 1px solid var(--border-color);
        padding: 0.75rem;
        min-height: 150px;
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        background: #fafafa;
    }

    .calendar-day:nth-child(even) {
        background: white;
    }

    .calendar-day:last-child {
        border-left: none;
    }

    .schedule-item {
        background: white;
        border-radius: 12px;
        padding: 0.85rem;
        position: relative;
        transition: all 0.2s;
        border: 1px solid #e2e8f0;
        box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    }

    .schedule-item:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 12px -2px rgba(0, 0, 0, 0.1);
        border-color: #cbd5e1;
    }

    .schedule-item.official {
        background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%);
        border: 1px solid #bdf2d5;
    }

    .schedule-item.delegate {
        background: linear-gradient(135deg, #fefce8 0%, #fef9c3 100%);
        border: 1px solid #fef08a;
    }

    .official-badge {
        position: absolute;
        top: 0.5rem;
        left: 0.5rem;
        background: #10b981;
        color: white;
        padding: 0.15rem 0.4rem;
        border-radius: 4px;
        font-size: 0.55rem;
        font-weight: 800;
        display: flex;
        align-items: center;
        gap: 2px;
    }

    .delegate-badge {
        position: absolute;
        top: 0.5rem;
        left: 0.5rem;
        background: #f59e0b;
        color: white;
        padding: 0.15rem 0.4rem;
        border-radius: 4px;
        font-size: 0.55rem;
        font-weight: 800;
        display: flex;
        align-items: center;
        gap: 2px;
    }

    .schedule-subject {
        font-weight: 800;
        font-size: 0.85rem;
        color: #1e293b;
        margin-bottom: 0.25rem;
        line-height: 1.2;
    }

    .schedule-doctor {
        font-size: 0.75rem;
        color: #64748b;
        margin-bottom: 0.5rem;
        display: flex;
        align-items: center;
        gap: 4px;
    }

    .schedule-time {
        font-size: 0.7rem;
        font-weight: 700;
        color: #475569;
        display: flex;
        align-items: center;
        gap: 0.25rem;
        background: rgba(0,0,0,0.03);
        padding: 0.25rem 0.5rem;
        border-radius: 6px;
        width: fit-content;
    }

    .schedule-hall {
        position: absolute;
        bottom: 0.75rem;
        left: 0.75rem;
        font-size: 0.65rem;
        font-weight: 800;
        color: #64748b;
    }

    .schedule-actions {
        display: flex;
        gap: 0.25rem;
        margin-top: 0.75rem;
        padding-top: 0.5rem;
        border-top: 1px solid rgba(0,0,0,0.05);
    }

    .schedule-actions a {
        width: 28px;
        height: 28px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        text-decoration: none;
        font-size: 0.75rem;
        transition: all 0.2s;
    }

    .schedule-actions .edit {
        background: #f1f5f9;
        color: #475569;
    }

    .schedule-actions .edit:hover {
        background: #6366f1;
        color: white;
    }

    .empty-day {
        display: flex;
        align-items: center;
        justify-content: center;
        height: 100%;
        color: #cbd5e1;
        font-size: 0.8rem;
        font-weight: 600;
    }

    .info-bar {
        background: #eef2ff;
        border-radius: 12px;
        padding: 1rem 1.5rem;
        display: flex;
        align-items: center;
        gap: 2rem;
        margin-bottom: 1.5rem;
        border: 1px solid #e0e7ff;
    }

    .info-item {
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .info-label {
        color: #6366f1;
        font-weight: 700;
        font-size: 0.85rem;
    }

    .info-value {
        color: #1e293b;
        font-weight: 800;
        font-size: 0.95rem;
    }

    @media print {
        .page-header, .btn-back, .info-bar, .schedule-actions { display: none !important; }
        .main-content { margin: 0 !important; padding: 0 !important; }
        .calendar-wrapper { border: none; box-shadow: none; }
        .calendar-day { background: white !important; }
    }
</style>

<div class="page-header">
    <div class="header-info">
        <div class="header-icon">
            <i class="fa-solid fa-calendar-week fa-xl"></i>
        </div>
        <div class="header-text">
            <h1>الجدول الدراسي الأسبوعي</h1>
            <p>معاينة الجدول الدراسي للتخصص والمستوى المحدد</p>
        </div>
    </div>
    <div class="header-actions">
        <a href="{{ route('administrative.schedules.index') }}" class="btn-back">
            <i class="fa-solid fa-arrow-left"></i>
            العودة للقائمة
        </a>
    </div>
</div>

<div class="info-bar">
    <div class="info-item">
        <span class="info-label">التخصص:</span>
        <span class="info-value">{{ $major->name }}</span>
    </div>
    <div class="info-item">
        <span class="info-label">المستوى:</span>
        <span class="info-value">{{ $level->name }}</span>
    </div>
    <div class="info-item">
        <span class="info-label">إجمالي المحاضرات:</span>
        <span class="info-value text-primary">{{ $schedules->count() }}</span>
    </div>
</div>

<div class="calendar-wrapper">
    <div class="calendar-header">
        @php
            $days = [6 => 'السبت', 7 => 'الأحد', 1 => 'الإثنين', 2 => 'الثلاثاء', 3 => 'الأربعاء', 4 => 'الخميس', 5 => 'الجمعة'];
        @endphp
        @foreach($days as $dayId => $dayName)
        <div class="calendar-day-header">{{ $dayName }}</div>
        @endforeach
    </div>
    <div class="calendar-body">
        @foreach($days as $dayId => $dayName)
        @php
        $daySchedules = $schedules->where('day_of_week', $dayId)->sortBy('start_time');
        @endphp
        <div class="calendar-day">
            @forelse($daySchedules as $schedule)
            @php
                $isOfficial = $schedule->creator && in_array($schedule->creator->role->value, ['admin', 'administrative']);
            @endphp
            <div class="schedule-item {{ $isOfficial ? 'official' : 'delegate' }}">
                @if($isOfficial)
                <div class="official-badge" title="رسمي من الإدارة">
                    <i class="fa-solid fa-check-double"></i> رسمـي
                </div>
                @else
                <div class="delegate-badge" title="مقترح من المندوب">
                    <i class="fa-solid fa-user-pen"></i> مندوب
                </div>
                @endif

                <div class="schedule-subject">{{ $schedule->subject->name }}</div>
                <div class="schedule-doctor">
                    <i class="fa-solid fa-user-tie"></i>
                    {{ $schedule->subject->doctor->name ?? 'غير محدد' }}
                </div>
                
                <div class="schedule-time">
                    <i class="fa-regular fa-clock"></i>
                    {{ \Carbon\Carbon::parse($schedule->start_time)->format('h:i') }} - {{ \Carbon\Carbon::parse($schedule->end_time)->format('h:i A') }}
                </div>

                <div class="schedule-hall">
                    <i class="fa-solid fa-location-dot"></i>
                    {{ $schedule->hall_name }}
                </div>

                <div class="schedule-actions">
                    <a href="{{ route('administrative.schedules.edit', $schedule->id) }}" class="edit" title="تعديل الموعد">
                        <i class="fa-solid fa-gear"></i>
                    </a>
                </div>
            </div>
            @empty
            <div class="empty-day">لا توجد محاضرات</div>
            @endforelse
        </div>
        @endforeach
    </div>
</div>

@endsection
