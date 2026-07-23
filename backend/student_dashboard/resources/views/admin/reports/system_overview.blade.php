@extends('layouts.admin')

@section('title', 'نظرة عامة على النظام')

@section('content')

<style>
    .page-header {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .page-header-icon {
        width: 56px;
        height: 56px;
        background: linear-gradient(135deg, #06b6d4 0%, #0891b2 100%);
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
    }

    .page-header-text h1 {
        font-size: 1.5rem;
        font-weight: 700;
        margin-bottom: 0.25rem;
    }

    .page-header-text p {
        color: var(--text-secondary);
        font-size: 0.9rem;
    }

    .stats-section {
        margin-bottom: 2rem;
    }

    .stats-section h3 {
        font-size: 1rem;
        font-weight: 700;
        margin-bottom: 1rem;
        color: var(--text-secondary);
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .stats-grid {
        display: grid;
        grid-template-columns: repeat(5, 1fr);
        gap: 1rem;
    }

    .stat-card {
        background: white;
        border-radius: 16px;
        padding: 1.5rem;
        border: 1px solid var(--border-color);
        text-align: center;
        transition: all 0.3s;
    }

    .stat-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 20px -5px rgba(0, 0, 0, 0.1);
    }

    .stat-card .icon {
        width: 48px;
        height: 48px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 0.75rem;
    }

    .stat-card .value {
        font-size: 2rem;
        font-weight: 700;
        margin-bottom: 0.25rem;
    }

    .stat-card .label {
        color: var(--text-secondary);
        font-size: 0.85rem;
    }

    .attendance-section {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1.5rem;
        margin-bottom: 2rem;
    }

    .section-card {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        padding: 1.5rem;
    }

    .section-card h3 {
        font-size: 1.1rem;
        font-weight: 700;
        margin-bottom: 1.25rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .attendance-bars {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    .attendance-bar-item {
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .bar-label {
        width: 80px;
        font-size: 0.9rem;
        font-weight: 600;
    }

    .bar-container {
        flex: 1;
        height: 24px;
        background: #f3f4f6;
        border-radius: 12px;
        overflow: hidden;
        position: relative;
    }

    .bar-fill {
        height: 100%;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: flex-end;
        padding-right: 0.5rem;
        color: white;
        font-size: 0.75rem;
        font-weight: 600;
        min-width: 40px;
        transition: width 0.5s;
    }

    .bar-value {
        width: 60px;
        text-align: left;
        font-size: 0.9rem;
        font-weight: 700;
    }

    .recent-activity {
        max-height: 300px;
        overflow-y: auto;
    }

    .activity-item {
        display: flex;
        align-items: center;
        gap: 1rem;
        padding: 0.75rem 0;
        border-bottom: 1px solid #f1f5f9;
    }

    .activity-icon {
        width: 36px;
        height: 36px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 0.8rem;
        font-weight: 700;
    }

    .activity-info {
        flex: 1;
    }

    .activity-info h4 {
        font-size: 0.9rem;
        font-weight: 600;
        margin-bottom: 0.15rem;
    }

    .activity-info span {
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    .activity-time {
        font-size: 0.75rem;
        color: var(--text-secondary);
    }

    .back-btn {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.75rem 1.25rem;
        background: #f3f4f6;
        border-radius: 10px;
        color: var(--text-primary);
        text-decoration: none;
        font-weight: 600;
        transition: all 0.2s;
    }

    .back-btn:hover {
        background: #e5e7eb;
    }

    .print-btn {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.75rem 1.25rem;
        background: linear-gradient(135deg, #06b6d4, #0891b2);
        border-radius: 10px;
        color: white;
        text-decoration: none;
        font-weight: 600;
        border: none;
        cursor: pointer;
        transition: all 0.2s;
    }

    .print-btn:hover {
        box-shadow: 0 4px 12px -2px rgba(6, 182, 212, 0.4);
    }

    @media print {
        .no-print {
            display: none !important;
        }

        .stat-card,
        .section-card {
            box-shadow: none !important;
            border: 1px solid #ddd !important;
        }
    }
</style>

@php
$totalAttendance = array_sum($attendanceByStatus);
@endphp

<!-- Page Header -->
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
    <div class="page-header" style="margin: 0;">
        <div class="page-header-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="12" y1="8" x2="12" y2="12"></line>
                <line x1="12" y1="16" x2="12.01" y2="16"></line>
            </svg>
        </div>
        <div class="page-header-text">
            <h1>نظرة عامة على النظام</h1>
            <p>ملخص شامل لجميع الإحصائيات الرئيسية</p>
        </div>
    </div>
    <a href="{{ route('admin.reports.index') }}" class="back-btn">
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="19" y1="12" x2="5" y2="12"></line>
            <polyline points="12 19 5 12 12 5"></polyline>
        </svg>
        رجوع للتقارير
    </a>
</div>

<!-- Users Stats -->
<div class="stats-section">
    <h3>
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
            <circle cx="9" cy="7" r="4"></circle>
        </svg>
        إحصائيات المستخدمين
    </h3>
    <div class="stats-grid" style="grid-template-columns: repeat(3, 1fr);">
        <div class="stat-card">
            <div class="icon" style="background: rgba(16, 185, 129, 0.1); color: #10b981;">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                    <circle cx="9" cy="7" r="4"></circle>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                </svg>
            </div>
            <div class="value" style="color: #10b981;">{{ $stats['students'] }}</div>
            <div class="label">الطلاب</div>
        </div>
        <div class="stat-card">
            <div class="icon" style="background: rgba(6, 182, 212, 0.1); color: #06b6d4;">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                    <circle cx="12" cy="7" r="4"></circle>
                </svg>
            </div>
            <div class="value" style="color: #06b6d4;">{{ $stats['doctors'] }}</div>
            <div class="label">أعضاء هيئة التدريس</div>
        </div>
        <div class="stat-card">
            <div class="icon" style="background: rgba(139, 92, 246, 0.1); color: #8b5cf6;">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                    <circle cx="8.5" cy="7" r="4"></circle>
                    <polyline points="17 11 19 13 23 9"></polyline>
                </svg>
            </div>
            <div class="value" style="color: #8b5cf6;">{{ $stats['delegates'] }}</div>
            <div class="label">المندوبين</div>
        </div>
    </div>
</div>

<!-- Academic Stats -->
<div class="stats-section">
    <h3>
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
            <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
        </svg>
        الهيكل الأكاديمي
    </h3>
    <div class="stats-grid">
        <div class="stat-card">
            <div class="value" style="color: #4f46e5;">{{ $stats['universities'] }}</div>
            <div class="label">الجامعات</div>
        </div>
        <div class="stat-card">
            <div class="value" style="color: #3b82f6;">{{ $stats['colleges'] }}</div>
            <div class="label">الكليات</div>
        </div>
        <div class="stat-card">
            <div class="value" style="color: #10b981;">{{ $stats['majors'] }}</div>
            <div class="label">التخصصات</div>
        </div>
        <div class="stat-card">
            <div class="value" style="color: #f59e0b;">{{ $stats['levels'] }}</div>
            <div class="label">المستويات</div>
        </div>
        <div class="stat-card">
            <div class="value" style="color: #ef4444;">{{ $stats['subjects'] }}</div>
            <div class="label">المواد</div>
        </div>
    </div>
</div>

<!-- Attendance Section -->
<div class="attendance-section">
    <div class="section-card">
        <h3>
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                <circle cx="8.5" cy="7" r="4"></circle>
                <polyline points="17 11 19 13 23 9"></polyline>
            </svg>
            توزيع سجلات الحضور
        </h3>
        <div style="text-align: center; margin-bottom: 1.5rem;">
            <div style="font-size: 2.5rem; font-weight: 700; color: #4f46e5;">{{ number_format($stats['attendance_records']) }}</div>
            <div style="color: var(--text-secondary);">إجمالي السجلات</div>
        </div>
        <div class="attendance-bars">
            <div class="attendance-bar-item">
                <span class="bar-label">حاضر</span>
                <div class="bar-container">
                    <div class="bar-fill" style="width: {{ $totalAttendance > 0 ? ($attendanceByStatus['present'] / $totalAttendance) * 100 : 0 }}%; background: #10b981;">
                        {{ $totalAttendance > 0 ? round(($attendanceByStatus['present'] / $totalAttendance) * 100) : 0 }}%
                    </div>
                </div>
                <span class="bar-value" style="color: #10b981;">{{ number_format($attendanceByStatus['present']) }}</span>
            </div>
            <div class="attendance-bar-item">
                <span class="bar-label">غائب</span>
                <div class="bar-container">
                    <div class="bar-fill" style="width: {{ $totalAttendance > 0 ? ($attendanceByStatus['absent'] / $totalAttendance) * 100 : 0 }}%; background: #ef4444;">
                        {{ $totalAttendance > 0 ? round(($attendanceByStatus['absent'] / $totalAttendance) * 100) : 0 }}%
                    </div>
                </div>
                <span class="bar-value" style="color: #ef4444;">{{ number_format($attendanceByStatus['absent']) }}</span>
            </div>
            <div class="attendance-bar-item">
                <span class="bar-label">متأخر</span>
                <div class="bar-container">
                    <div class="bar-fill" style="width: {{ $totalAttendance > 0 ? ($attendanceByStatus['late'] / $totalAttendance) * 100 : 0 }}%; background: #f59e0b;">
                        {{ $totalAttendance > 0 ? round(($attendanceByStatus['late'] / $totalAttendance) * 100) : 0 }}%
                    </div>
                </div>
                <span class="bar-value" style="color: #f59e0b;">{{ number_format($attendanceByStatus['late']) }}</span>
            </div>
            <div class="attendance-bar-item">
                <span class="bar-label">عذر</span>
                <div class="bar-container">
                    <div class="bar-fill" style="width: {{ $totalAttendance > 0 ? ($attendanceByStatus['excused'] / $totalAttendance) * 100 : 0 }}%; background: #3b82f6;">
                        {{ $totalAttendance > 0 ? round(($attendanceByStatus['excused'] / $totalAttendance) * 100) : 0 }}%
                    </div>
                </div>
                <span class="bar-value" style="color: #3b82f6;">{{ number_format($attendanceByStatus['excused']) }}</span>
            </div>
        </div>
    </div>

    <div class="section-card">
        <h3>
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>
            </svg>
            آخر سجلات الحضور
        </h3>
        <div class="recent-activity">
            @forelse($recentAttendance as $record)
            @php
            $statusColors = [
            'present' => ['bg' => '#d1fae5', 'color' => '#059669'],
            'absent' => ['bg' => '#fee2e2', 'color' => '#dc2626'],
            'late' => ['bg' => '#fef3c7', 'color' => '#d97706'],
            'excused' => ['bg' => '#dbeafe', 'color' => '#2563eb'],
            ];
            $statusLabels = [
            'present' => 'حاضر',
            'absent' => 'غائب',
            'late' => 'متأخر',
            'excused' => 'عذر',
            ];
            @endphp
            <div class="activity-item">
                <div class="activity-icon" style="background: {{ $statusColors[$record->status]['bg'] ?? '#f3f4f6' }}; color: {{ $statusColors[$record->status]['color'] ?? '#666' }};">
                    {{ $statusLabels[$record->status] ?? $record->status }}
                </div>
                <div class="activity-info">
                    <h4>{{ $record->student->name ?? 'طالب' }}</h4>
                    <span>{{ $record->subject->name ?? 'مادة' }}</span>
                </div>
                <div class="activity-time">{{ $record->created_at->diffForHumans() }}</div>
            </div>
            @empty
            <div style="text-align: center; padding: 2rem; color: var(--text-secondary);">
                لا توجد سجلات حديثة
            </div>
            @endforelse
        </div>
    </div>
</div>

<!-- Additional Stats -->
<div class="stats-section">
    <h3>
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="18" y1="20" x2="18" y2="10"></line>
            <line x1="12" y1="20" x2="12" y2="4"></line>
            <line x1="6" y1="20" x2="6" y2="14"></line>
        </svg>
        إحصائيات إضافية
    </h3>
    <div class="stats-grid" style="grid-template-columns: repeat(2, 1fr);">
        <div class="stat-card">
            <div class="icon" style="background: rgba(245, 158, 11, 0.1); color: #f59e0b;">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                    <polyline points="14 2 14 8 20 8"></polyline>
                </svg>
            </div>
            <div class="value" style="color: #f59e0b;">{{ $stats['assignments'] }}</div>
            <div class="label">التكاليف والواجبات</div>
        </div>
        <div class="stat-card">
            <div class="icon" style="background: rgba(79, 70, 229, 0.1); color: #4f46e5;">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                    <line x1="16" y1="2" x2="16" y2="6"></line>
                    <line x1="8" y1="2" x2="8" y2="6"></line>
                    <line x1="3" y1="10" x2="21" y2="10"></line>
                </svg>
            </div>
            <div class="value" style="color: #4f46e5;">{{ now()->format('Y/m/d') }}</div>
            <div class="label">تاريخ التقرير</div>
        </div>
    </div>
</div>

@endsection