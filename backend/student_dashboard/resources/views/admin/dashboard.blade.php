@extends('layouts.admin')

@section('title', 'لوحة القيادة')

@section('content')

<style>
    /* Premium Dashboard Styles */
    :root {
        --glass-bg: rgba(255, 255, 255, 0.7);
        --glass-border: rgba(255, 255, 255, 0.4);
        --card-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.07);
    }

    .dashboard-container {
        animation: fadeIn 0.8s ease-out;
    }

    @keyframes fadeIn {
        from { opacity: 0; transform: translateY(10px); }
        to { opacity: 1; transform: translateY(0); }
    }

    .page-header {
        margin-bottom: 2.5rem;
        display: flex;
        align-items: center;
        gap: 1.25rem;
    }

    .header-icon-box {
        width: 60px;
        height: 60px;
        background: linear-gradient(135deg, var(--primary-color) 0%, #6366f1 100%);
        border-radius: 18px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        box-shadow: 0 10px 20px -5px rgba(67, 56, 186, 0.3);
    }

    .stat-card {
        background: var(--glass-bg);
        backdrop-filter: blur(12px);
        -webkit-backdrop-filter: blur(12px);
        border: 1px solid var(--glass-border);
        border-radius: 20px;
        padding: 1.5rem;
        box-shadow: var(--card-shadow);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        height: 100%;
        display: flex;
        flex-direction: column;
        justify-content: space-between;
    }

    .stat-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 15px 45px 0 rgba(31, 38, 135, 0.12);
        border-color: var(--primary-color);
    }

    .stat-icon {
        width: 48px;
        height: 48px;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        margin-bottom: 1rem;
    }

    .stat-value {
        font-size: 1.85rem;
        font-weight: 800;
        color: var(--text-primary);
        line-height: 1.2;
    }

    .stat-label {
        font-size: 0.9rem;
        color: var(--text-secondary);
        font-weight: 600;
    }

    .trend-bar-container {
        height: 180px;
        display: flex;
        align-items: flex-end;
        gap: 12px;
        padding: 1rem 0;
    }

    .trend-column {
        flex: 1;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 8px;
        height: 100%;
        justify-content: flex-end;
    }

    .trend-bar-group {
        width: 100%;
        max-width: 32px;
        border-radius: 8px;
        overflow: hidden;
        display: flex;
        flex-direction: column;
        gap: 2px;
        transition: all 0.3s ease;
    }

    .trend-bar-present {
        background: linear-gradient(180deg, #34d399 0%, #10b981 100%);
    }

    .trend-bar-absent {
        background: linear-gradient(180deg, #f87171 0%, #ef4444 100%);
    }

    .table-premium {
        background: white;
        border-radius: 16px;
        overflow: hidden;
        border: 1px solid var(--border-color);
    }

    .badge-premium {
        padding: 0.4rem 0.8rem;
        border-radius: 8px;
        font-size: 0.75rem;
        font-weight: 700;
    }

    .quick-action-card {
        background: linear-gradient(135deg, var(--primary-color) 0%, #312e81 100%);
        color: white;
        border-radius: 20px;
        padding: 2rem;
        position: relative;
        overflow: hidden;
    }

    .quick-action-card::after {
        content: '';
        position: absolute;
        top: -20%;
        right: -10%;
        width: 150px;
        height: 150px;
        background: rgba(255, 255, 255, 0.1);
        border-radius: 50%;
    }
</style>

<div class="dashboard-container">
    <!-- Page Header -->
    <div class="page-header">
        <div class="header-icon-box">
            <i class="fa-solid fa-shapes fa-xl"></i>
        </div>
        <div>
            <h1 class="h3 font-weight-bold mb-1">لوحة الإدارة العامة</h1>
            <p class="text-muted mb-0">مرحباً {{ $user->name }}، إليك ملخص أداء النظام لليوم</p>
        </div>
    </div>

    <!-- Main Stats Row -->
    <div class="row g-4 mb-5">
        <div class="col-md-3">
            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(67, 56, 202, 0.1); color: var(--primary-color);">
                    <i class="fa-solid fa-user-graduate fa-lg"></i>
                </div>
                <div>
                    <div class="stat-value">{{ number_format($userStats['students_count']) }}</div>
                    <div class="stat-label">إجمالي الطلاب</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(59, 130, 246, 0.1); color: var(--info-color);">
                    <i class="fa-solid fa-chalkboard-user fa-lg"></i>
                </div>
                <div>
                    <div class="stat-value">{{ number_format($userStats['doctors_count']) }}</div>
                    <div class="stat-label">هيئة التدريس</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(16, 185, 129, 0.1); color: var(--success-color);">
                    <i class="fa-solid fa-book-open fa-lg"></i>
                </div>
                <div>
                    <div class="stat-value">{{ number_format($academicStats['subjects_count']) }}</div>
                    <div class="stat-label">مادة دراسية</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="stat-card">
                <div class="stat-icon" style="background: rgba(245, 158, 11, 0.1); color: var(--warning-color);">
                    <i class="fa-solid fa-id-badge fa-lg"></i>
                </div>
                <div>
                    <div class="stat-value">{{ number_format($userStats['delegates_count']) }}</div>
                    <div class="stat-label">مناديب الدفعات</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Secondary Insights Row -->
    <div class="row g-4 mb-5">
        <div class="col-md-3">
            <div class="stat-card text-center py-4">
                <div class="stat-value mb-2" style="color: var(--success-color);">{{ $attendanceStats['attendance_rate'] }}%</div>
                <div class="stat-label">نسبة الحضور العامة</div>
                <div class="progress mt-3" style="height: 8px; border-radius: 4px; background: #eaeef4;">
                    <div class="progress-bar" style="width: {{ $attendanceStats['attendance_rate'] }}%; background: var(--success-color); border-radius: 4px;"></div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="stat-card text-center py-4">
                <div class="stat-value mb-2" style="color: {{ $atRiskStudents > 0 ? '#ef4444' : 'var(--text-primary)' }};">{{ $atRiskStudents }}</div>
                <div class="stat-label">طلاب معرضون للحرمان</div>
                @if($atRiskStudents > 0)
                    <a href="{{ route('admin.reports.index') }}" class="btn btn-link btn-sm text-danger mt-1 p-0">عرض القائمة <i class="fa-solid fa-chevron-left ms-1" style="font-size: 0.7rem;"></i></a>
                @endif
            </div>
        </div>
        <div class="col-md-3">
            <div class="stat-card text-center py-4">
                <div class="stat-value mb-2" style="color: var(--info-color);">{{ $todayAttendance }}</div>
                <div class="stat-label">سجلات حضور اليوم</div>
                <div class="text-danger font-weight-bold mt-2" style="font-size: 0.8rem;">
                    <i class="fa-solid fa-circle-exclamation me-1"></i> {{ $todayAbsent }} غياب
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="stat-card text-center py-4">
                <div class="stat-value mb-2" style="color: {{ $userStats['pending_users'] > 0 ? 'var(--warning-color)' : 'var(--text-primary)' }};">{{ $userStats['pending_users'] }}</div>
                <div class="stat-label">طلبات بانتظار التفعيل</div>
                @if($userStats['pending_users'] > 0)
                    <a href="{{ route('admin.registration_requests.index') }}" class="btn btn-link btn-sm text-warning mt-1 p-0">مراجعة الآن <i class="fa-solid fa-chevron-left ms-1" style="font-size: 0.7rem;"></i></a>
                @endif
            </div>
        </div>
    </div>

    <!-- Charts & Tables Row -->
    <div class="row g-4 mb-5">
        <div class="col-md-8">
            <div class="stat-card">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h5 class="font-weight-bold mb-0"><i class="fa-solid fa-chart-pie me-2 text-primary"></i> توزيع سجلات الحضور</h5>
                    <span class="badge bg-light text-dark">{{ $attendanceStats['total'] }} سجل إجمالي</span>
                </div>
                
                <div class="row text-center mb-4">
                    <div class="col-3">
                        <div class="p-3 rounded-4" style="background: rgba(16, 185, 129, 0.08);">
                            <div class="h4 font-weight-bold mb-1 text-success">{{ $attendanceStats['present'] }}</div>
                            <small class="text-muted font-weight-bold">حاضر</small>
                        </div>
                    </div>
                    <div class="col-3">
                        <div class="p-3 rounded-4" style="background: rgba(239, 68, 68, 0.08);">
                            <div class="h4 font-weight-bold mb-1 text-danger">{{ $attendanceStats['absent'] }}</div>
                            <small class="text-muted font-weight-bold">غائب</small>
                        </div>
                    </div>
                    <div class="col-3">
                        <div class="p-3 rounded-4" style="background: rgba(245, 158, 11, 0.08);">
                            <div class="h4 font-weight-bold mb-1 text-warning">{{ $attendanceStats['late'] }}</div>
                            <small class="text-muted font-weight-bold">متأخر</small>
                        </div>
                    </div>
                    <div class="col-3">
                        <div class="p-3 rounded-4" style="background: rgba(59, 130, 246, 0.08);">
                            <div class="h4 font-weight-bold mb-1 text-info">{{ $attendanceStats['excused'] }}</div>
                            <small class="text-muted font-weight-bold">معذور</small>
                        </div>
                    </div>
                </div>

                @if($attendanceStats['total'] > 0)
                <div class="progress mb-2" style="height: 14px; border-radius: 7px; overflow: hidden; background: #f1f5f9;">
                    <div class="progress-bar bg-success" style="width: {{ ($attendanceStats['present'] / $attendanceStats['total']) * 100 }}%" title="حاضر"></div>
                    <div class="progress-bar bg-warning" style="width: {{ ($attendanceStats['late'] / $attendanceStats['total']) * 100 }}%" title="متأخر"></div>
                    <div class="progress-bar bg-info" style="width: {{ ($attendanceStats['excused'] / $attendanceStats['total']) * 100 }}%" title="معذور"></div>
                    <div class="progress-bar bg-danger" style="width: {{ ($attendanceStats['absent'] / $attendanceStats['total']) * 100 }}%" title="غائب"></div>
                </div>
                @endif
            </div>
        </div>

        <div class="col-md-4">
            <div class="stat-card">
                <h5 class="font-weight-bold mb-4"><i class="fa-solid fa-building-columns me-2 text-primary"></i> الطلاب حسب التخصص</h5>
                <div class="list-group list-group-flush">
                    @forelse($studentsPerMajor as $major)
                    <div class="list-group-item d-flex justify-content-between align-items-center px-0 bg-transparent border-light">
                        <span class="font-weight-bold text-dark">{{ $major->name }}</span>
                        <span class="badge bg-primary rounded-pill">{{ $major->students_count }}</span>
                    </div>
                    @empty
                    <div class="text-center py-4 text-muted">لا توجد تخصصات مسجلة</div>
                    @endforelse
                </div>
            </div>
        </div>
    </div>

    <!-- Recent Activity & Quick Actions -->
    <div class="row g-4 mb-5">
        <div class="col-md-8">
            <div class="stat-card">
                <h5 class="font-weight-bold mb-4"><i class="fa-solid fa-clock-rotate-left me-2 text-primary"></i> آخر سجلات الحضور</h5>
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="bg-light">
                            <tr>
                                <th class="border-0 rounded-start text-right">المادة</th>
                                <th class="border-0 text-right">الطالب</th>
                                <th class="border-0 text-center">الحالة</th>
                                <th class="border-0 rounded-end text-right">التاريخ</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($latestAttendance as $attendance)
                            <tr>
                                <td class="font-weight-bold">{{ $attendance->subject->name ?? '-' }}</td>
                                <td>{{ $attendance->student->name ?? '-' }}</td>
                                <td class="text-center">
                                    <span class="badge badge-premium {{ $attendance->status == 'present' ? 'bg-success' : ($attendance->status == 'absent' ? 'bg-danger' : 'bg-warning') }}">
                                        {{ $attendance->status == 'present' ? 'حاضر' : ($attendance->status == 'absent' ? 'غائب' : 'أخرى') }}
                                    </span>
                                </td>
                                <td class="text-muted small">{{ $attendance->date->format('Y-m-d') }}</td>
                            </tr>
                            @empty
                            <tr><td colspan="4" class="text-center py-5 text-muted">لا توجد سجلات حديثة</td></tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <div class="col-md-4">
            <div class="quick-action-card">
                <h4 class="font-weight-bold mb-3 text-white">مركز التقارير 📊</h4>
                <p class="small text-white-50">اطلع على تقارير الغياب والحضور التفصيلية لكل مادة وقسم.</p>
                <a href="{{ route('admin.reports.index') }}" class="btn btn-light btn-block font-weight-bold text-primary py-2 rounded-3 mt-3 shadow-sm">
                    فتح التقارير
                </a>
            </div>
        </div>
    </div>
</div>

@endsection