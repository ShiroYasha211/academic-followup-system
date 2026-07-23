@extends('layouts.delegate')

@section('title', 'الجدول الدراسي')

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
        background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        box-shadow: 0 4px 12px -2px rgba(139, 92, 246, 0.4);
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
        background: #f1f5f9;
        border: 1px solid var(--border-color);
        border-radius: 10px;
        font-weight: 600;
        color: var(--text-primary);
        display: flex;
        align-items: center;
        gap: 0.5rem;
        cursor: pointer;
        transition: all 0.2s;
    }

    .btn-print:hover {
        background: #e2e8f0;
    }

    .btn-add {
        padding: 0.75rem 1.25rem;
        background: linear-gradient(135deg, #8b5cf6, #7c3aed);
        border: none;
        border-radius: 10px;
        font-weight: 600;
        color: white;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
        transition: all 0.2s;
    }

    .btn-add:hover {
        box-shadow: 0 4px 12px -2px rgba(139, 92, 246, 0.4);
    }

    /* Weekly Calendar View */
    .calendar-wrapper {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        overflow: hidden;
    }

    .calendar-header {
        display: grid;
        grid-template-columns: repeat(7, 1fr);
        background: linear-gradient(135deg, #8b5cf6, #7c3aed);
        color: white;
    }

    .calendar-day-header {
        padding: 1rem;
        text-align: center;
        font-weight: 700;
        font-size: 0.95rem;
        border-left: 1px solid rgba(255, 255, 255, 0.1);
    }

    .calendar-day-header:last-child {
        border-left: none;
    }

    .calendar-body {
        display: grid;
        grid-template-columns: repeat(7, 1fr);
        min-height: 400px;
    }

    .calendar-day {
        border-left: 1px solid var(--border-color);
        border-bottom: 1px solid var(--border-color);
        padding: 0.75rem;
        min-height: 150px;
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }

    .calendar-day:last-child {
        border-left: none;
    }

    .schedule-item {
        background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
        border: 1px solid #bae6fd;
        border-radius: 10px;
        padding: 0.75rem;
        position: relative;
        transition: all 0.2s;
    }

    .schedule-item:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 8px -2px rgba(0, 0, 0, 0.1);
    }

    .schedule-item.alternate {
        background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
        border-color: #fcd34d;
    }

    .schedule-item.third {
        background: linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%);
        border-color: #6ee7b7;
    }

    .schedule-item.official {
        border: 2px solid #10b981;
        background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%);
    }

    .official-badge {
        position: absolute;
        top: 0.5rem;
        right: 0.5rem;
        background: #10b981;
        color: white;
        padding: 0.1rem 0.4rem;
        border-radius: 4px;
        font-size: 0.6rem;
        font-weight: 800;
        display: flex;
        align-items: center;
        gap: 2px;
        box-shadow: 0 2px 4px rgba(16, 185, 129, 0.2);
    }

    .schedule-subject {
        font-weight: 700;
        font-size: 0.9rem;
        color: var(--text-primary);
        margin-bottom: 0.35rem;
    }

    .schedule-doctor {
        font-size: 0.8rem;
        color: var(--text-secondary);
        margin-bottom: 0.5rem;
    }

    .schedule-time {
        font-size: 0.75rem;
        font-weight: 600;
        color: #0369a1;
        display: flex;
        align-items: center;
        gap: 0.25rem;
    }

    .schedule-hall {
        position: absolute;
        top: 0.5rem;
        left: 0.5rem;
        background: rgba(0, 0, 0, 0.6);
        color: white;
        padding: 0.15rem 0.4rem;
        border-radius: 4px;
        font-size: 0.65rem;
        font-weight: 600;
    }

    .schedule-actions {
        display: flex;
        gap: 0.25rem;
        margin-top: 0.5rem;
        padding-top: 0.5rem;
        border-top: 1px solid rgba(0, 0, 0, 0.05);
    }

    .schedule-actions a,
    .schedule-actions button {
        width: 24px;
        height: 24px;
        border-radius: 6px;
        display: flex;
        align-items: center;
        justify-content: center;
        border: none;
        cursor: pointer;
        transition: all 0.2s;
    }

    .schedule-actions .edit {
        background: #e0f2fe;
        color: #0284c7;
    }

    .schedule-actions .delete {
        background: #fee2e2;
        color: #dc2626;
    }

    .empty-day {
        display: flex;
        align-items: center;
        justify-content: center;
        height: 100%;
        color: var(--text-light);
        font-size: 0.85rem;
    }

    /* Stats Row */
    .stats-row {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .stat-mini {
        background: white;
        border-radius: 16px;
        padding: 1rem;
        border: 1px solid var(--border-color);
        display: flex;
        align-items: center;
        gap: 0.875rem;
    }

    .stat-mini .icon {
        width: 44px;
        height: 44px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .stat-mini .value {
        font-size: 1.5rem;
        font-weight: 700;
    }

    .stat-mini .label {
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    .empty-state {
        text-align: center;
        padding: 4rem 2rem;
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
    }

    .empty-state svg {
        margin-bottom: 1rem;
        opacity: 0.4;
    }

    .empty-state h3 {
        font-size: 1.15rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.5rem;
    }

    .empty-state p {
        color: var(--text-secondary);
        margin-bottom: 1.5rem;
    }
</style>

@php
$days = [
6 => 'السبت',
7 => 'الأحد',
1 => 'الإثنين',
2 => 'الثلاثاء',
3 => 'الأربعاء',
4 => 'الخميس',
5 => 'الجمعة'
];
$totalLectures = $schedules->count();
$totalHours = $schedules->sum(function($s) {
$start = \Carbon\Carbon::parse($s->start_time);
$end = \Carbon\Carbon::parse($s->end_time);
return abs($end->diffInMinutes($start)) / 60;
});
$totalHours = round($totalHours, 1);
$daysWithLectures = $schedules->pluck('day_of_week')->unique()->count();
@endphp

<!-- Page Header -->
<div class="page-header">
    <div class="header-info">
        <div class="header-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                <line x1="16" y1="2" x2="16" y2="6"></line>
                <line x1="8" y1="2" x2="8" y2="6"></line>
                <line x1="3" y1="10" x2="21" y2="10"></line>
            </svg>
        </div>
        <div class="header-text">
            <h1>الجدول الدراسي</h1>
            <p>جدول المحاضرات الأسبوعي للدفعة</p>
        </div>
    </div>
    <div class="header-actions">
        <button onclick="printSchedule()" class="btn-print">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="6 9 6 2 18 2 18 9"></polyline>
                <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path>
                <rect x="6" y="14" width="12" height="8"></rect>
            </svg>
            طباعة الجدول
        </button>
        @php $canCreate = Auth::user()->hasDelegatePermission('schedules', 'create'); @endphp
        <a 
            @if($canCreate) href="{{ route('delegate.schedules.create') }}" @endif
            class="btn-add {{ !$canCreate ? 'btn-locked' : '' }}"
            @if(!$canCreate) title="ليس لديك صلاحية إضافة مواعد" @endif
        >
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            إضافة موعد
        </a>
    </div>
</div>

@if(session('success'))
<div class="alert alert-success" style="margin-bottom: 1.5rem;">
    {{ session('success') }}
</div>
@endif

<!-- Stats Row -->
<div class="stats-row">
    <div class="stat-mini">
        <div class="icon" style="background: rgba(139, 92, 246, 0.1); color: #8b5cf6;">
            <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                <line x1="16" y1="2" x2="16" y2="6"></line>
                <line x1="8" y1="2" x2="8" y2="6"></line>
                <line x1="3" y1="10" x2="21" y2="10"></line>
            </svg>
        </div>
        <div>
            <div class="value" style="color: #8b5cf6;">{{ $totalLectures }}</div>
            <div class="label">محاضرة أسبوعياً</div>
        </div>
    </div>

    <div class="stat-mini">
        <div class="icon" style="background: rgba(59, 130, 246, 0.1); color: #3b82f6;">
            <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
        </div>
        <div>
            <div class="value" style="color: #3b82f6;">{{ $totalHours }}</div>
            <div class="label">ساعة دراسية</div>
        </div>
    </div>

    <div class="stat-mini">
        <div class="icon" style="background: rgba(16, 185, 129, 0.1); color: #10b981;">
            <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
            </svg>
        </div>
        <div>
            <div class="value" style="color: #10b981;">{{ $schedules->pluck('subject_id')->unique()->count() }}</div>
            <div class="label">مادة مجدولة</div>
        </div>
    </div>

    <div class="stat-mini">
        <div class="icon" style="background: rgba(245, 158, 11, 0.1); color: #f59e0b;">
            <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                <circle cx="12" cy="10" r="3"></circle>
            </svg>
        </div>
        <div>
            <div class="value" style="color: #f59e0b;">{{ $daysWithLectures }}</div>
            <div class="label">يوم دراسي</div>
        </div>
    </div>
</div>

@if($schedules->isEmpty())
<div class="empty-state">
    <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1">
        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
        <line x1="16" y1="2" x2="16" y2="6"></line>
        <line x1="8" y1="2" x2="8" y2="6"></line>
        <line x1="3" y1="10" x2="21" y2="10"></line>
    </svg>
    <h3>لا يوجد جدول دراسي</h3>
    <p>ابدأ بإضافة مواعيد المحاضرات لتنظيم جدول الدفعة</p>
    <a href="{{ route('delegate.schedules.create') }}" class="btn-add" style="display: inline-flex;">
        إضافة أول موعد
    </a>
</div>
@else
<!-- Weekly Calendar -->
<div class="calendar-wrapper">
    <div class="calendar-header">
        @foreach($days as $dayId => $dayName)
        <div class="calendar-day-header">{{ $dayName }}</div>
        @endforeach
    </div>
    <div class="calendar-body">
        @php $colorIndex = 0; @endphp
        @foreach($days as $dayId => $dayName)
        @php
        $daySchedules = $schedules->where('day_of_week', $dayId)->sortBy('start_time');
        @endphp
        <div class="calendar-day">
            @forelse($daySchedules as $schedule)
            @php
            $isOfficial = $schedule->creator && in_array($schedule->creator->role->value, ['admin', 'administrative']);
            $colorClass = $isOfficial ? 'official' : (['', 'alternate', 'third'][$colorIndex % 3]);
            if(!$isOfficial) $colorIndex++;
            @endphp
            <div class="schedule-item {{ $colorClass }}">
                @if($isOfficial)
                <div class="official-badge">
                    <i class="fa-solid fa-check-double"></i> رسمـي
                </div>
                @endif
                @if($schedule->hall_name)
                <span class="schedule-hall" style="{{ $isOfficial ? 'top: 2rem;' : '' }}">{{ $schedule->hall_name }}</span>
                @endif
                <div class="schedule-subject">{{ $schedule->subject->name }}</div>
                <div class="schedule-doctor">{{ $schedule->subject->doctor->name ?? 'غير محدد' }}</div>
                <div class="schedule-time">
                    <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="10"></circle>
                        <polyline points="12 6 12 12 16 14"></polyline>
                    </svg>
                    {{ \Carbon\Carbon::parse($schedule->start_time)->format('h:i') }} - {{ \Carbon\Carbon::parse($schedule->end_time)->format('h:i A') }}
                </div>
                @if(!$isOfficial)
                <div class="schedule-actions">
                    @php $canUpdate = Auth::user()->hasDelegatePermission('schedules', 'update'); @endphp
                    <a 
                        @if($canUpdate) href="{{ route('delegate.schedules.edit', $schedule->id) }}" @endif
                        class="edit {{ !$canUpdate ? 'btn-locked' : '' }}" 
                        title="{{ $canUpdate ? 'تعديل' : 'ليس لديك صلاحية التعديل' }}"
                    >
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                        </svg>
                    </a>
                    @php $canDelete = Auth::user()->hasDelegatePermission('schedules', 'delete'); @endphp
                    <form action="{{ route('delegate.schedules.destroy', $schedule->id) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف هذا الموعد؟')" style="display: inline;">
                        @csrf
                        @method('DELETE')
                        <button type="{{ $canDelete ? 'submit' : 'button' }}" class="delete {{ !$canDelete ? 'btn-locked' : '' }}" title="{{ $canDelete ? 'حذف' : 'ليس لديك صلاحية الحذف' }}">
                            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="3 6 5 6 21 6"></polyline>
                                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                            </svg>
                        </button>
                    </form>
                </div>
                @endif
            </div>
            @empty
            <div class="empty-day">لا توجد محاضرات</div>
            @endforelse
        </div>
        @endforeach
    </div>
</div>
@endif

@php
$groupedSchedules = $schedules->groupBy('day_of_week');
@endphp
<script>
    function printSchedule() {
        const printWindow = window.open('', '_blank');
        const scheduleData = @json($groupedSchedules);
        const daysMap = {
            6: 'السبت',
            7: 'الأحد',
            1: 'الإثنين',
            2: 'الثلاثاء',
            3: 'الأربعاء',
            4: 'الخميس',
            5: 'الجمعة'
        };
        const daysOrder = [6, 7, 1, 2, 3, 4, 5];

        let tableRows = '';
        for (const day of daysOrder) {
            const daySchedules = scheduleData[day] || [];
            if (daySchedules.length > 0) {
                daySchedules.forEach((schedule, index) => {
                    tableRows += `
                    <tr>
                        ${index === 0 ? `<td rowspan="${daySchedules.length}" class="day-cell">${daysMap[day]}</td>` : ''}
                        <td>${schedule.subject?.name || '-'}</td>
                        <td>${schedule.subject?.doctor?.name || 'غير محدد'}</td>
                        <td class="time-cell">${formatTime(schedule.start_time)} - ${formatTime(schedule.end_time)}</td>
                        <td>${schedule.hall_name || '-'}</td>
                    </tr>
                `;
                });
            }
        }

        if (!tableRows) {
            tableRows = '<tr><td colspan="5" style="text-align: center; padding: 2rem;">لا يوجد جدول دراسي</td></tr>';
        }

        const printContent = `
        <!DOCTYPE html>
        <html dir="rtl" lang="ar">
        <head>
            <meta charset="UTF-8">
            <title>الجدول الدراسي</title>
            <style>
                @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&display=swap');
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { font-family: 'Cairo', sans-serif; padding: 20px; background: white; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
                .header { text-align: center; border-bottom: 3px solid #8b5cf6; padding-bottom: 20px; margin-bottom: 30px; }
                .university-name { font-size: 24px; font-weight: 700; color: #1e3a5f; margin-bottom: 5px; }
                .college-info { font-size: 16px; color: #4b5563; margin-bottom: 10px; }
                .schedule-title { font-size: 20px; font-weight: 700; color: #8b5cf6; margin-top: 10px; }
                table { width: 100%; border-collapse: collapse; margin-top: 20px; }
                th { background: #8b5cf6; color: white; padding: 12px 8px; font-weight: 600; font-size: 14px; text-align: center; }
                td { padding: 10px 8px; border: 1px solid #e5e7eb; text-align: center; font-size: 13px; }
                .day-cell { background: #f5f3ff; font-weight: 700; color: #7c3aed; vertical-align: middle; }
                .time-cell { font-family: monospace; font-size: 12px; white-space: nowrap; }
                tr:nth-child(even) td:not(.day-cell) { background: #f9fafb; }
                .footer { margin-top: 30px; text-align: center; font-size: 12px; color: #6b7280; border-top: 1px solid #e5e7eb; padding-top: 15px; }
            </style>
        </head>
        <body>
            <div class="header">
                <div class="university-name">{{ Auth::user()->university->name ?? 'الجامعة' }}</div>
                <div class="college-info">{{ Auth::user()->college->name ?? 'الكلية' }} - {{ Auth::user()->major->name ?? 'التخصص' }}</div>
                <div class="college-info">المستوى: {{ Auth::user()->level->name ?? '-' }}</div>
                <div class="schedule-title">📅 الجدول الدراسي الأسبوعي</div>
            </div>
            <div class="table-responsive">
<table>
                <thead><tr><th>اليوم</th><th>المادة</th><th>الدكتور</th><th>الوقت</th><th>القاعة</th></tr></thead>
                <tbody>${tableRows}</tbody>
            </table>
</div>
            <div class="footer">تم الطباعة بتاريخ: ${new Date().toLocaleDateString('ar-SA')} | نظام إدارة الحضور الجامعي</div>
            <script>window.onload = function() { window.print(); }<\/script>
        </body>
        </html>
    `;

        printWindow.document.write(printContent);
        printWindow.document.close();
    }

    function formatTime(timeStr) {
        if (!timeStr) return '-';
        const [hours, minutes] = timeStr.split(':');
        const h = parseInt(hours);
        const ampm = h >= 12 ? 'م' : 'ص';
        const h12 = h % 12 || 12;
        return `${h12}:${minutes} ${ampm}`;
    }
</script>

@endsection