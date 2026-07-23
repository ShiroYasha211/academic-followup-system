@extends('layouts.administrative')

@section('title', 'بوابة ذكاء الحضور والغياب')

@section('content')

<style>
    .attendance-hero {
        background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
        border-radius: 24px;
        padding: 2.5rem;
        color: white;
        margin-bottom: 2.5rem;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
    }

    .filter-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 1.25rem;
        background: rgba(255, 255, 255, 0.05);
        backdrop-filter: blur(10px);
        padding: 1.5rem;
        border-radius: 20px;
        border: 1px solid rgba(255, 255, 255, 0.1);
    }

    .stat-premium-card {
        background: white;
        border-radius: 20px;
        padding: 1.5rem;
        border: 1px solid #e2e8f0;
        display: flex;
        align-items: center;
        gap: 1.25rem;
        transition: all 0.3s ease;
    }

    .stat-premium-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05);
    }

    .nav-tabs-premium {
        display: flex;
        gap: 1rem;
        background: #f1f5f9;
        padding: 0.5rem;
        border-radius: 16px;
        margin-bottom: 2rem;
        width: fit-content;
    }

    .nav-link-premium {
        padding: 0.75rem 1.5rem;
        border-radius: 12px;
        font-weight: 700;
        color: #64748b;
        text-decoration: none;
        transition: all 0.2s;
        border: none;
        background: transparent;
        cursor: pointer;
    }

    .nav-link-premium.active {
        background: white;
        color: #6366f1;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .input-dark {
        background: rgba(255, 255, 255, 0.1);
        border: 1px solid rgba(255, 255, 255, 0.2);
        color: white;
        border-radius: 10px;
        padding: 0.5rem 1rem;
        width: 100%;
        outline: none;
    }

    .input-dark:focus {
        border-color: #6366f1;
        background: rgba(255, 255, 255, 0.15);
    }
</style>

<div x-data="{ activeTab: 'overview' }">
    <!-- Hero & Filter Section -->
    <div class="attendance-hero">
        <div style="margin-bottom: 2rem;">
            <h1 style="font-size: 2rem; font-weight: 900; margin-bottom: 0.5rem;">بوابة ذكاء الحضور</h1>
            <p style="opacity: 0.8; font-weight: 500;">تحليل مباشر لسلوك الحضور وأداء الكادر التعليمي في الكلية</p>
        </div>

        <form action="{{ route('administrative.reports.attendance') }}" method="GET" class="filter-grid">
            <div>
                <label style="display: block; font-size: 0.75rem; font-weight: 800; color: #94a3b8; margin-bottom: 0.5rem;">التخصص</label>
                <select name="major_id" class="input-dark">
                    <option value="">كل التخصصات</option>
                    @foreach($majors as $major)
                    <option value="{{ $major->id }}" {{ request('major_id') == $major->id ? 'selected' : '' }}>{{ $major->name }}</option>
                    @endforeach
                </select>
            </div>
            <div>
                <label style="display: block; font-size: 0.75rem; font-weight: 800; color: #94a3b8; margin-bottom: 0.5rem;">البحث</label>
                <input type="text" name="search" value="{{ request('search') }}" class="input-dark" placeholder="اسم الطالب، المادة...">
            </div>
            <div style="display: flex; align-items: flex-end;">
                <button type="submit" style="width: 100%; height: 42px; background: #6366f1; border: none; border-radius: 10px; color: white; font-weight: 800; cursor: pointer;">
                    <i class="fa-solid fa-filter"></i> تطبيق الفلترة
                </button>
            </div>
        </form>
    </div>

    <!-- Stats Grid -->
    <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 1.5rem; margin-bottom: 3rem;">
        <div class="stat-premium-card">
            <div style="width: 48px; height: 48px; border-radius: 14px; background: #f0fdf4; color: #10b981; display: flex; align-items: center; justify-content: center; font-size: 1.25rem;">
                <i class="fa-solid fa-user-check"></i>
            </div>
            <div>
                <span style="display: block; font-size: 0.8rem; font-weight: 700; color: #64748b;">حاضر اليوم</span>
                <span style="font-size: 1.5rem; font-weight: 900; color: #1e293b;">{{ $stats['present'] }}</span>
            </div>
        </div>
        <div class="stat-premium-card">
            <div style="width: 48px; height: 48px; border-radius: 14px; background: #fff1f2; color: #e11d48; display: flex; align-items: center; justify-content: center; font-size: 1.25rem;">
                <i class="fa-solid fa-user-xmark"></i>
            </div>
            <div>
                <span style="display: block; font-size: 0.8rem; font-weight: 700; color: #64748b;">غائب اليوم</span>
                <span style="font-size: 1.5rem; font-weight: 900; color: #1e293b;">{{ $stats['absent'] }}</span>
            </div>
        </div>
        <div class="stat-premium-card">
            <div style="width: 48px; height: 48px; border-radius: 14px; background: #eff6ff; color: #2563eb; display: flex; align-items: center; justify-content: center; font-size: 1.25rem;">
                <i class="fa-solid fa-file-medical"></i>
            </div>
            <div>
                <span style="display: block; font-size: 0.8rem; font-weight: 700; color: #64748b;">أعذار مقبولة</span>
                <span style="font-size: 1.5rem; font-weight: 900; color: #1e293b;">{{ $stats['excused'] }}</span>
            </div>
        </div>
        <div class="stat-premium-card">
            <div style="width: 48px; height: 48px; border-radius: 14px; background: #fefce8; color: #ca8a04; display: flex; align-items: center; justify-content: center; font-size: 1.25rem;">
                <i class="fa-solid fa-qrcode"></i>
            </div>
            <div>
                <span style="display: block; font-size: 0.8rem; font-weight: 700; color: #64748b;">جلسات نشطة</span>
                <span style="font-size: 1.5rem; font-weight: 900; color: #1e293b;">{{ $stats['active_sessions'] }}</span>
            </div>
        </div>
    </div>

    <!-- Content Tabs -->
    <div class="nav-tabs-premium no-print">
        <button @click="activeTab = 'overview'" :class="{ 'active': activeTab === 'overview' }" class="nav-link-premium">نظرة عامة</button>
        <button @click="activeTab = 'sessions'" :class="{ 'active': activeTab === 'sessions' }" class="nav-link-premium">الجلسات اليومية</button>
        <button @click="activeTab = 'danger'" :class="{ 'active': activeTab === 'danger' }" class="nav-link-premium">منطقة الخطر</button>
        <button @click="activeTab = 'logs'" :class="{ 'active': activeTab === 'logs' }" class="nav-link-premium">سجل الأرشفة</button>
    </div>

    <!-- Tab Contents -->
    <div class="card-premium p-0 overflow-hidden">
        <!-- Overview Tab -->
        <div x-show="activeTab === 'overview'" style="padding: 2rem;">
            <h3 style="font-size: 1.1rem; font-weight: 800; margin-bottom: 2rem;">تطور الحضور خلال السبعة أيام الماضية</h3>
            <div style="height: 400px;">
                <canvas id="trendsChart"></canvas>
            </div>
        </div>

        <!-- Sessions Tab -->
        <div x-show="activeTab === 'sessions'" class="table-responsive">
            <table class="table-premium">
                <thead>
                    <tr>
                        <th>المادة</th>
                        <th>الدكتور</th>
                        <th>الإحصائيات</th>
                        <th>نسبة الحضور</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($dailySessions as $session)
                    <tr>
                        <td>
                            <span style="display: block; font-weight: 800;">{{ $session->subject->name }}</span>
                            <span style="font-size: 0.75rem; color: #64748b;">{{ $session->date->format('Y-m-d') }}</span>
                        </td>
                        <td>{{ $session->subject->doctor->name }}</td>
                        <td>
                            <span style="color: #10b981; font-weight: 800;">{{ $session->present_count }} حاضر</span> / 
                            <span style="color: #ef4444; font-weight: 800;">{{ $session->absent_count }} غائب</span>
                        </td>
                        <td>
                            @php $perc = $session->total_students > 0 ? round(($session->present_count / $session->total_students) * 100) : 0; @endphp
                            <div style="display: flex; align-items: center; gap: 0.75rem;">
                                <div style="flex: 1; height: 6px; background: #f1f5f9; border-radius: 10px; overflow: hidden;">
                                    <div style="width: {{ $perc }}%; height: 100%; background: {{ $perc > 70 ? '#10b981' : '#f59e0b' }};"></div>
                                </div>
                                <span style="font-weight: 900; font-size: 0.85rem;">{{ $perc }}%</span>
                            </div>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>

        <!-- Danger Zone Tab -->
        <div x-show="activeTab === 'danger'" class="table-responsive">
            <table class="table-premium">
                <thead>
                    <tr>
                        <th>الطالب</th>
                        <th>المادة</th>
                        <th>عدد الغيابات</th>
                        <th>النسبة من الحرمان</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($dangerStudents as $row)
                    <tr>
                        <td>
                            <span style="display: block; font-weight: 800;">{{ $row->student->name }}</span>
                            <span style="font-size: 0.75rem; color: #64748b;">{{ $row->student->student_number }}</span>
                        </td>
                        <td>{{ $row->subject->name }}</td>
                        <td style="font-weight: 800; color: #e11d48;">{{ $row->absence_count }}</td>
                        <td>
                            @php 
                                $limit = $row->subject->max_absences ?? 5;
                                $perc = round(($row->absence_count / $limit) * 100);
                            @endphp
                            <span class="badge" style="background: {{ $perc >= 90 ? '#fff1f2' : '#fffbeb' }}; color: {{ $perc >= 90 ? '#e11d48' : '#d97706' }}; font-weight: 800;">
                                {{ $perc }}% من الحد الأقصى
                            </span>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>

        <!-- Logs Tab -->
        <div x-show="activeTab === 'logs'" class="table-responsive">
            <table class="table-premium">
                <thead>
                    <tr>
                        <th>الطالب</th>
                        <th>المادة</th>
                        <th>الحالة</th>
                        <th>الوقت</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($auditLogs as $log)
                    <tr>
                        <td>{{ $log->student->name }}</td>
                        <td>{{ $log->subject->name }}</td>
                        <td>
                            @php
                                $colors = ['present' => '#10b981', 'absent' => '#ef4444', 'excused' => '#3b82f6'];
                                $labels = ['present' => 'حاضر', 'absent' => 'غائب', 'excused' => 'بعذر'];
                            @endphp
                            <span style="padding: 0.25rem 0.75rem; border-radius: 6px; font-size: 0.75rem; font-weight: 800; background: {{ $colors[$log->status] ?? '#f1f5f9' }}15; color: {{ $colors[$log->status] ?? '#64748b' }};">
                                {{ $labels[$log->status] ?? $log->status }}
                            </span>
                        </td>
                        <td style="font-size: 0.8rem; color: #64748b;">{{ $log->created_at->format('Y-m-d H:i') }}</td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
            <div style="padding: 1.5rem;">
                {{ $auditLogs->links() }}
            </div>
        </div>
    </div>
</div>

@endsection

@push('scripts')
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        const ctx = document.getElementById('trendsChart').getContext('2d');
        const labels = {!! json_encode($trends->map(fn($t) => $t->date->format('M d'))) !!};
        const presentData = {!! json_encode($trends->pluck('present')) !!};
        const absentData = {!! json_encode($trends->pluck('absent')) !!};

        new Chart(ctx, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [
                    {
                        label: 'حاضر',
                        data: presentData,
                        borderColor: '#10b981',
                        backgroundColor: 'rgba(16, 185, 129, 0.1)',
                        fill: true,
                        tension: 0.4
                    },
                    {
                        label: 'غائب',
                        data: absentData,
                        borderColor: '#ef4444',
                        backgroundColor: 'rgba(239, 68, 68, 0.05)',
                        fill: true,
                        tension: 0.4
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'top', rtl: true }
                },
                scales: {
                    x: { grid: { display: false } },
                    y: { beginAtZero: true }
                }
            }
        });
    });
</script>
@endpush
