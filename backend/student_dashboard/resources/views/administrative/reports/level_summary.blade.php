@extends('layouts.administrative')

@section('title', 'ملخص الدفعة: ' . $level->name)

@section('content')

<style>
    .level-hero {
        background: linear-gradient(135deg, #1e1b4b 0%, #312e81 100%);
        border-radius: 24px;
        padding: 2.5rem;
        color: white;
        margin-bottom: 2.5rem;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
    }

    .level-stat-card {
        background: white;
        border-radius: 20px;
        padding: 1.5rem;
        border: 1px solid #e2e8f0;
        display: flex;
        align-items: center;
        gap: 1.25rem;
        transition: transform 0.3s ease;
    }

    .level-stat-card:hover {
        transform: translateY(-5px);
    }

    .subject-card {
        background: white;
        border-radius: 24px;
        padding: 1.5rem;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
        border: 1px solid #f1f5f9;
    }
</style>

<div class="level-hero">
    <div style="display: flex; justify-content: space-between; align-items: flex-start;">
        <div>
            <span style="background: rgba(255,255,255,0.1); padding: 0.4rem 1rem; border-radius: 100px; font-size: 0.8rem; font-weight: 800; margin-bottom: 1rem; display: inline-block;">تفاصيل الدفعة الدراسية</span>
            <h1 style="font-size: 2.25rem; font-weight: 900; margin-bottom: 0.5rem;">{{ $level->name }}</h1>
            <p style="opacity: 0.8; font-weight: 600;">{{ $level->major->name }} | {{ $level->major->college->name }}</p>
        </div>
        <a href="{{ route('administrative.reports.index') }}" style="background: rgba(255,255,255,0.15); color: white; padding: 0.75rem 1.5rem; border-radius: 14px; text-decoration: none; font-weight: 800; backdrop-filter: blur(10px);">
            <i class="fa-solid fa-arrow-right"></i> العودة للمركز
        </a>
    </div>
</div>

<div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 1.5rem; margin-bottom: 3rem;">
    <div class="level-stat-card">
        <div style="width: 48px; height: 48px; border-radius: 14px; background: #eef2ff; color: #4338ca; display: flex; align-items: center; justify-content: center; font-size: 1.25rem;">
            <i class="fa-solid fa-graduation-cap"></i>
        </div>
        <div>
            <span style="display: block; font-size: 0.8rem; font-weight: 700; color: #64748b;">إجمالي الطلاب</span>
            <span style="font-size: 1.5rem; font-weight: 900; color: #1e293b;">{{ $students->count() }}</span>
        </div>
    </div>
    <div class="level-stat-card">
        <div style="width: 48px; height: 48px; border-radius: 14px; background: #f0fdf4; color: #16a34a; display: flex; align-items: center; justify-content: center; font-size: 1.25rem;">
            <i class="fa-solid fa-book"></i>
        </div>
        <div>
            <span style="display: block; font-size: 0.8rem; font-weight: 700; color: #64748b;">المواد المفعلة</span>
            <span style="font-size: 1.5rem; font-weight: 900; color: #1e293b;">{{ $subjectStats->count() }}</span>
        </div>
    </div>
    <div class="level-stat-card">
        <div style="width: 48px; height: 48px; border-radius: 14px; background: #faf5ff; color: #9333ea; display: flex; align-items: center; justify-content: center; font-size: 1.25rem;">
            <i class="fa-solid fa-user-shield"></i>
        </div>
        <div>
            <span style="display: block; font-size: 0.8rem; font-weight: 700; color: #64748b;">مندوب الدفعة</span>
            <span style="font-size: 1rem; font-weight: 900; color: #1e293b;">{{ $delegate->name ?? 'لم يتم التعيين' }}</span>
        </div>
    </div>
</div>

<div class="subject-card">
    <h3 style="font-size: 1.25rem; font-weight: 900; color: #1e293b; margin-bottom: 2rem; display: flex; align-items: center; gap: 0.75rem;">
        <i class="fa-solid fa-chart-simple" style="color: #4338ca;"></i> مصفوفة أداء المواد
    </h3>
    <div class="table-responsive">
        <table class="table-premium" style="width: 100%;">
            <thead>
                <tr>
                    <th style="text-align: right;">المادة</th>
                    <th style="text-align: right;">أستاذ المقرر</th>
                    <th style="text-align: center;">سجلات الرصد</th>
                    <th style="text-align: center;">نسبة الحضور</th>
                    <th style="width: 250px;">التوزيع البصري</th>
                </tr>
            </thead>
            <tbody>
                @foreach($subjectStats as $stat)
                <tr>
                    <td style="font-weight: 800;">{{ $stat['subject']->name }}</td>
                    <td style="color: #64748b; font-weight: 600;">{{ $stat['subject']->doctor->name ?? '-' }}</td>
                    <td style="text-align: center; font-weight: 800;">{{ $stat['total_records'] }}</td>
                    <td style="text-align: center;">
                        <span style="padding: 0.4rem 0.8rem; border-radius: 8px; font-weight: 900; background: {{ $stat['attendance_rate'] > 70 ? '#f0fdf4' : '#fffbeb' }}; color: {{ $stat['attendance_rate'] > 70 ? '#16a34a' : '#d97706' }};">
                            {{ $stat['attendance_rate'] }}%
                        </span>
                    </td>
                    <td>
                        <div style="width: 100%; height: 8px; background: #f1f5f9; border-radius: 10px; overflow: hidden;">
                            <div style="width: {{ $stat['attendance_rate'] }}%; height: 100%; background: {{ $stat['attendance_rate'] > 70 ? '#16a34a' : '#f59e0b' }}; border-radius: 10px;"></div>
                        </div>
                    </td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</div>

@endsection
