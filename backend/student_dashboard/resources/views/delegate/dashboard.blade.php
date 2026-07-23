@extends('layouts.delegate')

@section('title', 'لوحة القيادة')

@section('content')

<style>
    .dashboard-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 2rem;
        gap: 1rem;
        flex-wrap: wrap;
    }

    .welcome-section {
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .welcome-icon {
        width: 60px;
        height: 60px;
        background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        box-shadow: 0 4px 12px -2px rgba(99, 102, 241, 0.4);
    }

    .welcome-text h1 {
        font-size: 1.5rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.25rem;
    }

    .welcome-text p {
        color: var(--text-secondary);
        font-size: 0.9rem;
    }

    .quick-action-btn {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.875rem 1.5rem;
        background: linear-gradient(135deg, #10b981, #059669);
        color: white;
        border: none;
        border-radius: 12px;
        font-weight: 600;
        font-size: 0.95rem;
        cursor: pointer;
        transition: all 0.2s;
        box-shadow: 0 4px 12px -2px rgba(16, 185, 129, 0.3);
    }

    .quick-action-btn:hover {
        transform: translateY(-2px);
        box-shadow: 0 6px 16px -2px rgba(16, 185, 129, 0.4);
    }

    /* Stats Grid */
    .stats-grid {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 1.25rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: white;
        border-radius: 16px;
        padding: 1.25rem;
        border: 1px solid var(--border-color);
        display: flex;
        align-items: center;
        gap: 1rem;
        transition: all 0.2s;
    }

    .stat-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.08);
    }

    .stat-icon {
        width: 52px;
        height: 52px;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .stat-content .value {
        font-size: 1.75rem;
        font-weight: 700;
        line-height: 1;
    }

    .stat-content .label {
        font-size: 0.85rem;
        color: var(--text-secondary);
        margin-top: 0.25rem;
    }

    /* Info Cards Row */
    .info-row {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1.5rem;
        margin-bottom: 2rem;
    }

    .info-card {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        padding: 1.5rem;
    }

    .info-card-header {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        margin-bottom: 1.25rem;
        padding-bottom: 1rem;
        border-bottom: 1px solid var(--border-color);
    }

    .info-card-header .icon {
        width: 40px;
        height: 40px;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .info-card-header h3 {
        font-size: 1rem;
        font-weight: 700;
    }

    /* Progress Bar */
    .progress-section {
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .progress-bar-wrapper {
        flex: 1;
    }

    .progress-bar {
        height: 12px;
        background: #e5e7eb;
        border-radius: 6px;
        overflow: hidden;
    }

    .progress-fill {
        height: 100%;
        border-radius: 6px;
        transition: width 0.5s;
    }

    .progress-meta {
        display: flex;
        justify-content: space-between;
        margin-top: 0.5rem;
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    .progress-circle {
        width: 64px;
        height: 64px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.1rem;
        font-weight: 700;
        flex-shrink: 0;
    }

    /* Top Absent List */
    .absent-list {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
    }

    .absent-item {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        padding: 0.75rem;
        background: #fef2f2;
        border-radius: 10px;
        border: 1px solid #fecaca;
    }

    .absent-rank {
        width: 28px;
        height: 28px;
        background: #ef4444;
        color: white;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 0.8rem;
        font-weight: 700;
    }

    .absent-info {
        flex: 1;
    }

    .absent-info .name {
        font-weight: 600;
        font-size: 0.9rem;
    }

    .absent-badge {
        background: #fee2e2;
        color: #dc2626;
        padding: 0.25rem 0.5rem;
        border-radius: 6px;
        font-size: 0.75rem;
        font-weight: 600;
    }

    /* Alert Card */
    .alert-card {
        background: linear-gradient(135deg, #fef2f2 0%, #fff 100%);
        border: 1px solid #fecaca;
        border-radius: 16px;
        padding: 1.25rem;
        margin-bottom: 2rem;
    }

    .alert-header {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        margin-bottom: 1rem;
    }

    .alert-icon {
        width: 44px;
        height: 44px;
        background: #ef4444;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
    }

    .alert-title {
        font-size: 1.1rem;
        font-weight: 700;
        color: #991b1b;
    }

    .alert-subtitle {
        font-size: 0.8rem;
        color: #dc2626;
    }

    .risk-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
        gap: 0.75rem;
    }

    .risk-item {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        padding: 0.75rem;
        background: white;
        border-radius: 10px;
        border: 1px solid #fecaca;
    }

    .risk-percent {
        width: 40px;
        height: 40px;
        background: #fef2f2;
        color: #ef4444;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 0.85rem;
        font-weight: 700;
    }

    .risk-info {
        flex: 1;
    }

    .risk-info .name {
        font-weight: 600;
        font-size: 0.9rem;
    }

    .risk-info .detail {
        font-size: 0.75rem;
        color: var(--text-secondary);
    }

    /* Content Grid */
    .content-grid {
        display: grid;
        grid-template-columns: 2fr 1fr;
        gap: 1.5rem;
    }

    /* Subjects Table */
    .subjects-card {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        overflow: hidden;
    }

    .card-header {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid var(--border-color);
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .card-header h3 {
        font-size: 1.05rem;
        font-weight: 700;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .subjects-table {
        width: 100%;
        border-collapse: collapse;
    }

    .subjects-table th {
        padding: 0.875rem 1.5rem;
        text-align: right;
        font-weight: 600;
        color: var(--text-secondary);
        font-size: 0.8rem;
        background: #f8fafc;
    }

    .subjects-table td {
        padding: 1rem 1.5rem;
        border-bottom: 1px solid #f1f5f9;
    }

    .subject-cell {
        display: flex;
        flex-direction: column;
    }

    .subject-cell .name {
        font-weight: 600;
        color: var(--text-primary);
    }

    .subject-cell .code {
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    .doctor-cell {
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .doctor-avatar {
        width: 28px;
        height: 28px;
        border-radius: 50%;
        background: linear-gradient(135deg, #6366f1, #4f46e5);
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 0.7rem;
        font-weight: 700;
    }

    /* Sidebar Cards */
    .sidebar-card {
        background: white;
        border-radius: 16px;
        border: 1px solid var(--border-color);
        padding: 1.25rem;
        margin-bottom: 1rem;
    }

    .sidebar-card h4 {
        font-size: 0.95rem;
        font-weight: 700;
        margin-bottom: 1rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .attendance-list {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
    }

    .attendance-item {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        padding-bottom: 0.75rem;
        border-bottom: 1px solid #f1f5f9;
    }

    .attendance-avatar {
        width: 36px;
        height: 36px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        font-size: 0.8rem;
    }

    .attendance-info {
        flex: 1;
        min-width: 0;
    }

    .attendance-info .name {
        font-weight: 600;
        font-size: 0.9rem;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .attendance-info .subject {
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    .attendance-time {
        font-size: 0.75rem;
        color: var(--text-light);
    }

    .empty-message {
        text-align: center;
        padding: 1.5rem;
        color: var(--text-secondary);
    }

    .view-all-link {
        display: block;
        text-align: center;
        margin-top: 1rem;
        color: var(--primary-color);
        font-weight: 600;
        font-size: 0.9rem;
        text-decoration: none;
    }

    /* Modal */
    [x-cloak] {
        display: none !important;
    }
</style>

<div x-data="{ showQuickAttendance: false }">

    <!-- Dashboard Header -->
    <div class="dashboard-header">
        <div class="welcome-section">
            <div class="welcome-icon">
                <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
                    <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
                </svg>
            </div>
            <div class="welcome-text">
                <h1>{{ $delegate->university->name ?? 'الجامعة' }}</h1>
                <p>{{ $delegate->college->name ?? 'الكلية' }} - {{ $delegate->major->name ?? 'التخصص' }} (المستوى {{ $delegate->level->name ?? '-' }})</p>
            </div>
        </div>

        <button @click="showQuickAttendance = true" class="quick-action-btn">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="9 11 12 14 22 4"></polyline>
                <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path>
            </svg>
            رصد حضور سريع
        </button>
    </div>

    <!-- Stats Grid -->
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon" style="background: rgba(99, 102, 241, 0.1); color: #6366f1;">
                <svg xmlns="http://www.w3.org/2000/svg" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                    <circle cx="9" cy="7" r="4"></circle>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                </svg>
            </div>
            <div class="stat-content">
                <div class="value" style="color: #6366f1;">{{ $studentsCount ?? 0 }}</div>
                <div class="label">طالب في الدفعة</div>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-icon" style="background: rgba(59, 130, 246, 0.1); color: #3b82f6;">
                <svg xmlns="http://www.w3.org/2000/svg" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                </svg>
            </div>
            <div class="stat-content">
                <div class="value" style="color: #3b82f6;">{{ count($subjects) }}</div>
                <div class="label">مادة دراسية</div>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-icon" style="background: rgba(16, 185, 129, 0.1); color: #10b981;">
                <svg xmlns="http://www.w3.org/2000/svg" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                    <line x1="16" y1="2" x2="16" y2="6"></line>
                    <line x1="8" y1="2" x2="8" y2="6"></line>
                    <line x1="3" y1="10" x2="21" y2="10"></line>
                </svg>
            </div>
            <div class="stat-content">
                <div class="value" style="color: #10b981;">{{ $todayLecturesCount ?? 0 }}</div>
                <div class="label">محاضرات اليوم</div>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-icon" style="background: rgba(245, 158, 11, 0.1); color: #f59e0b;">
                <svg xmlns="http://www.w3.org/2000/svg" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                    <line x1="12" y1="9" x2="12" y2="13"></line>
                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                </svg>
            </div>
            <div class="stat-content">
                <div class="value" style="color: #f59e0b;">{{ $alertsCount ?? 0 }}</div>
                <div class="label">تنبيه غياب</div>
            </div>
        </div>
    </div>

    <!-- Info Row: Attendance Rate + Top Absent -->
    <div class="info-row">
        <div class="info-card">
            <div class="info-card-header">
                <div class="icon" style="background: rgba(16, 185, 129, 0.1); color: #10b981;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="18" y1="20" x2="18" y2="10"></line>
                        <line x1="12" y1="20" x2="12" y2="4"></line>
                        <line x1="6" y1="20" x2="6" y2="14"></line>
                    </svg>
                </div>
                <h3>نسبة الحضور الأسبوعي</h3>
            </div>
            <div class="progress-section">
                <div class="progress-bar-wrapper">
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: {{ $weeklyAttendanceRate ?? 0 }}%; background: {{ ($weeklyAttendanceRate ?? 0) >= 75 ? '#10b981' : (($weeklyAttendanceRate ?? 0) >= 50 ? '#f59e0b' : '#ef4444') }};"></div>
                    </div>
                    <div class="progress-meta">
                        <span>آخر 7 أيام</span>
                        <span>{{ $weeklyAttendanceRate ?? 0 }}%</span>
                    </div>
                </div>
                <div class="progress-circle" style="background: {{ ($weeklyAttendanceRate ?? 0) >= 75 ? 'rgba(16, 185, 129, 0.1)' : (($weeklyAttendanceRate ?? 0) >= 50 ? 'rgba(245, 158, 11, 0.1)' : 'rgba(239, 68, 68, 0.1)') }}; color: {{ ($weeklyAttendanceRate ?? 0) >= 75 ? '#10b981' : (($weeklyAttendanceRate ?? 0) >= 50 ? '#f59e0b' : '#ef4444') }};">
                    {{ $weeklyAttendanceRate ?? 0 }}%
                </div>
            </div>
        </div>

        <div class="info-card">
            <div class="info-card-header">
                <div class="icon" style="background: rgba(239, 68, 68, 0.1); color: #ef4444;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                        <line x1="12" y1="9" x2="12" y2="13"></line>
                        <line x1="12" y1="17" x2="12.01" y2="17"></line>
                    </svg>
                </div>
                <h3>أكثر الطلاب غياباً</h3>
            </div>
            @if(isset($topAbsentStudents) && $topAbsentStudents->count() > 0)
            <div class="absent-list">
                @foreach($topAbsentStudents as $student)
                <div class="absent-item">
                    <div class="absent-rank">{{ $loop->iteration }}</div>
                    <div class="absent-info">
                        <div class="name">{{ $student->name }}</div>
                    </div>
                    <span class="absent-badge">{{ $student->absence_count }} غياب</span>
                </div>
                @endforeach
            </div>
            @else
            <div class="empty-message">
                <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="opacity: 0.5; margin-bottom: 0.5rem;">
                    <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
                <div>لا يوجد غياب مسجل 🎉</div>
            </div>
            @endif
        </div>
    </div>

    <!-- At-Risk Students Alert -->
    @if(isset($atRiskStudents) && $atRiskStudents->count() > 0)
    <div class="alert-card">
        <div class="alert-header">
            <div class="alert-icon">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                    <line x1="12" y1="9" x2="12" y2="13"></line>
                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                </svg>
            </div>
            <div>
                <div class="alert-title">⚠️ طلاب معرضون للحرمان</div>
                <div class="alert-subtitle">تجاوزوا نسبة 20% من الغياب</div>
            </div>
        </div>
        <div class="risk-grid">
            @foreach($atRiskStudents as $risk)
            <div class="risk-item">
                <div class="risk-percent">{{ round($risk['absence_rate']) }}%</div>
                <div class="risk-info">
                    <div class="name">{{ $risk['student']->name }}</div>
                    <div class="detail">{{ $risk['subject']->name }} ({{ $risk['absences'] }}/{{ $risk['total'] }})</div>
                </div>
            </div>
            @endforeach
        </div>
    </div>
    @endif

    <!-- Content Grid -->
    <div class="content-grid">
        <!-- Subjects Table -->
        <div class="subjects-card">
            <div class="card-header">
                <h3>
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                    </svg>
                    المواد المسجلة
                </h3>
                <a href="{{ route('delegate.subjects.index') }}" class="btn btn-sm btn-secondary" style="font-size: 0.8rem;">عرض الكل</a>
            </div>
            <div class="table-responsive">
                <table class="subjects-table">
                    <thead>
                        <tr>
                            <th>المادة</th>
                            <th>الدكتور</th>
                            <th>الطلاب</th>
                        </tr>
                    </thead>
                <tbody>
                    @forelse($subjects as $subject)
                    <tr>
                        <td>
                            <div class="subject-cell">
                                <span class="name">{{ $subject->name }}</span>
                                <span class="code">{{ $subject->code }}</span>
                            </div>
                        </td>
                        <td>
                            @if($subject->doctor)
                            <div class="doctor-cell">
                                <div class="doctor-avatar">{{ mb_substr($subject->doctor->name, 0, 1) }}</div>
                                <span>{{ $subject->doctor->name }}</span>
                            </div>
                            @else
                            <span style="color: var(--text-light);">غير محدد</span>
                            @endif
                        </td>
                        <td>
                            <span class="badge badge-info">{{ $studentsCount }} طالب</span>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="3" class="empty-message">لا توجد مواد مسجلة</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
</div>
        </div>

        <!-- Sidebar -->
        <div>
            <!-- Latest Attendance -->
            <div class="sidebar-card">
                <h4>
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="10"></circle>
                        <polyline points="12 6 12 12 16 14"></polyline>
                    </svg>
                    آخر الحضور
                </h4>
                <div class="attendance-list">
                    @forelse($latestAttendance as $attendance)
                    <div class="attendance-item">
                        <div class="attendance-avatar" style="background: {{ $attendance->status == 'present' ? '#d1fae5' : ($attendance->status == 'absent' ? '#fee2e2' : '#fef3c7') }}; color: {{ $attendance->status == 'present' ? '#065f46' : ($attendance->status == 'absent' ? '#9f1239' : '#92400e') }};">
                            {{ mb_substr($attendance->student?->name ?? '-', 0, 1) }}
                        </div>
                        <div class="attendance-info">
                            <div class="name">{{ $attendance->student?->name ?? 'طالب غير محدد' }}</div>
                            <div class="subject">{{ $attendance->subject?->name ?? 'محاضرة غير رسمية' }}</div>
                        </div>
                        <span class="attendance-time">{{ $attendance->created_at->format('H:i') }}</span>
                    </div>
                    @empty
                    <div class="empty-message">لا يوجد سجلات حديثة</div>
                    @endforelse
                </div>
                <a href="{{ route('delegate.attendance.index') }}" class="view-all-link">عرض سجل الحضور ←</a>
            </div>

            <!-- Latest Students -->
            <div class="sidebar-card">
                <h4>
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                        <circle cx="8.5" cy="7" r="4"></circle>
                        <line x1="20" y1="8" x2="20" y2="14"></line>
                        <line x1="23" y1="11" x2="17" y2="11"></line>
                    </svg>
                    آخر المنضمين
                </h4>
                @forelse($latestStudents as $student)
                <div style="display: flex; align-items: center; gap: 0.5rem; padding: 0.5rem 0; border-bottom: 1px solid #f1f5f9;">
                    <div style="width: 8px; height: 8px; background: #10b981; border-radius: 50%;"></div>
                    <span style="flex: 1; font-size: 0.9rem; font-weight: 500;">{{ $student->name }}</span>
                    <span style="font-size: 0.75rem; color: var(--text-light);">{{ $student->created_at->diffForHumans(null, true, true) }}</span>
                </div>
                @empty
                <div class="empty-message">لا يوجد طلاب جدد</div>
                @endforelse
            </div>
        </div>
    </div>

    <!-- Quick Attendance Modal -->
    <div x-show="showQuickAttendance" x-cloak
        style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; z-index: 9999; display: flex; align-items: center; justify-content: center;"
        @keydown.escape.window="showQuickAttendance = false">

        <div @click="showQuickAttendance = false"
            style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.6);"
            x-transition:enter="transition ease-out duration-200"
            x-transition:enter-start="opacity-0"
            x-transition:enter-end="opacity-100"></div>

        <div x-transition:enter="transition ease-out duration-200"
            x-transition:enter-start="opacity-0 transform scale-95"
            x-transition:enter-end="opacity-100 transform scale-100"
            style="position: relative; z-index: 10000; background: white; border-radius: 20px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); width: 90%; max-width: 500px; padding: 1.5rem; max-height: 80vh; overflow-y: auto;">

            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; padding-bottom: 1rem; border-bottom: 1px solid #e5e7eb;">
                <h2 style="font-size: 1.25rem; font-weight: 700; display: flex; align-items: center; gap: 0.5rem;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2">
                        <polyline points="9 11 12 14 22 4"></polyline>
                        <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path>
                    </svg>
                    رصد حضور سريع
                </h2>
                <button @click="showQuickAttendance = false" style="background: none; border: none; cursor: pointer; color: var(--text-secondary); padding: 0.25rem;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </button>
            </div>

            <p style="color: var(--text-secondary); margin-bottom: 1rem; font-size: 0.9rem;">
                📅 محاضرات اليوم - اختر مادة لبدء رصد الحضور:
            </p>

            @if(isset($todaySubjects) && $todaySubjects->count() > 0)
            <div style="display: flex; flex-direction: column; gap: 0.75rem;">
                @foreach($todaySubjects as $schedule)
                <a href="{{ route('delegate.attendance.create', $schedule->subject->id) }}"
                    style="display: flex; align-items: center; gap: 1rem; padding: 1rem; background: #f8fafc; border: 2px solid #e5e7eb; border-radius: 12px; text-decoration: none; transition: all 0.2s;"
                    onmouseover="this.style.borderColor='#10b981'; this.style.background='rgba(16,185,129,0.05)';"
                    onmouseout="this.style.borderColor='#e5e7eb'; this.style.background='#f8fafc';">

                    <div style="background: #10b981; color: white; padding: 0.5rem 0.75rem; border-radius: 8px; text-align: center; min-width: 70px;">
                        <div style="font-size: 0.9rem; font-weight: 700;">{{ \Carbon\Carbon::parse($schedule->start_time)->format('H:i') }}</div>
                        <div style="font-size: 0.65rem; opacity: 0.8;">{{ \Carbon\Carbon::parse($schedule->end_time)->format('H:i') }}</div>
                    </div>

                    <div style="flex: 1;">
                        <div style="font-weight: 600; color: var(--text-primary); margin-bottom: 0.25rem;">{{ $schedule->subject->name }}</div>
                        <div style="font-size: 0.8rem; color: var(--text-secondary);">{{ $schedule->subject->code }} • {{ $schedule->hall_name ?? 'قاعة غير محددة' }}</div>
                    </div>

                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2">
                        <polyline points="15 18 9 12 15 6"></polyline>
                    </svg>
                </a>
                @endforeach
            </div>
            @else
            <div style="text-align: center; padding: 2.5rem; color: var(--text-secondary);">
                <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom: 1rem; opacity: 0.5;">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                    <line x1="16" y1="2" x2="16" y2="6"></line>
                    <line x1="8" y1="2" x2="8" y2="6"></line>
                    <line x1="3" y1="10" x2="21" y2="10"></line>
                </svg>
                <div style="font-weight: 600; color: var(--text-primary); margin-bottom: 0.5rem;">لا توجد محاضرات اليوم 🎉</div>
                <div style="font-size: 0.85rem;">يوم إجازة!</div>
            </div>
            @endif
        </div>
    </div>

</div>

@endsection
