@extends('layouts.admin')

@section('title', 'أداء أعضاء هيئة التدريس')

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
        background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
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

    .doctor-cards {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
        gap: 1.5rem;
    }

    .doctor-card {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        overflow: hidden;
        transition: all 0.3s;
    }

    .doctor-card:hover {
        box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
        transform: translateY(-2px);
    }

    .doctor-header {
        background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
        color: white;
        padding: 1.5rem;
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .doctor-avatar {
        width: 50px;
        height: 50px;
        background: rgba(255, 255, 255, 0.2);
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.25rem;
        font-weight: 700;
    }

    .doctor-info h4 {
        font-size: 1.1rem;
        font-weight: 700;
        margin-bottom: 0.25rem;
    }

    .doctor-info span {
        opacity: 0.9;
        font-size: 0.85rem;
    }

    .doctor-stats {
        padding: 1.5rem;
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 1rem;
    }

    .stat-item {
        text-align: center;
    }

    .stat-item .value {
        font-size: 1.5rem;
        font-weight: 700;
        margin-bottom: 0.25rem;
    }

    .stat-item .label {
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    .performance-bar {
        margin: 0 1.5rem 1.5rem;
        padding: 1rem;
        background: #f8fafc;
        border-radius: 12px;
    }

    .performance-bar-header {
        display: flex;
        justify-content: space-between;
        margin-bottom: 0.5rem;
    }

    .performance-bar-header span {
        font-size: 0.85rem;
        font-weight: 600;
    }

    .bar-container {
        height: 10px;
        background: #e5e7eb;
        border-radius: 5px;
        overflow: hidden;
    }

    .bar-fill {
        height: 100%;
        border-radius: 5px;
        transition: width 0.5s;
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

    .empty-state {
        text-align: center;
        padding: 4rem;
        color: var(--text-secondary);
    }

    .empty-state svg {
        margin-bottom: 1rem;
    }
</style>

<!-- Page Header -->
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
    <div class="page-header" style="margin: 0;">
        <div class="page-header-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                <circle cx="12" cy="7" r="4"></circle>
            </svg>
        </div>
        <div class="page-header-text">
            <h1>أداء أعضاء هيئة التدريس</h1>
            <p>إحصائيات المحاضرات ونسب الحضور لكل عضو</p>
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

<!-- Doctor Cards -->
<div class="doctor-cards">
    @forelse($performanceData as $data)
    @php
    $doctor = $data['doctor'];
    $rate = $data['attendance_rate'];
    $rateColor = $rate >= 70 ? '#10b981' : ($rate >= 50 ? '#f59e0b' : '#ef4444');
    @endphp
    <div class="doctor-card">
        <div class="doctor-header">
            <div class="doctor-avatar">{{ mb_substr($doctor->name, 0, 1) }}</div>
            <div class="doctor-info">
                <h4>{{ $doctor->name }}</h4>
                <span>{{ $doctor->email }}</span>
            </div>
        </div>

        <div class="doctor-stats">
            <div class="stat-item">
                <div class="value" style="color: #3b82f6;">{{ $data['subjects_count'] }}</div>
                <div class="label">المواد</div>
            </div>
            <div class="stat-item">
                <div class="value" style="color: #8b5cf6;">{{ $data['total_sessions'] }}</div>
                <div class="label">المحاضرات</div>
            </div>
            <div class="stat-item">
                <div class="value" style="color: {{ $rateColor }};">{{ $rate }}%</div>
                <div class="label">نسبة الحضور</div>
            </div>
        </div>

        <div class="performance-bar">
            <div class="performance-bar-header">
                <span>معدل حضور الطلاب</span>
                <span style="color: {{ $rateColor }};">{{ $rate }}%</span>
            </div>
            <div class="bar-container">
                <div class="bar-fill" style="width: {{ $rate }}%; background: {{ $rateColor }};"></div>
            </div>
        </div>
    </div>
    @empty
    <div class="empty-state" style="grid-column: 1 / -1;">
        <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="#d1d5db" stroke-width="1.5">
            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
            <circle cx="12" cy="7" r="4"></circle>
        </svg>
        <h3>لا يوجد أعضاء هيئة تدريس</h3>
        <p>لم يتم العثور على أي بيانات أداء</p>
    </div>
    @endforelse
</div>

@endsection