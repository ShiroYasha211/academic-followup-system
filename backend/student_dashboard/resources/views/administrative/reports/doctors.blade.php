@extends('layouts.administrative')

@section('title', 'أداء الكادر التعليمي')

@section('content')

<style>
    .page-header-premium {
        background: linear-gradient(135deg, #1e1b4b 0%, #312e81 100%);
        border-radius: 20px;
        padding: 2rem 2.5rem;
        color: white;
        margin-bottom: 2.5rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
        box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
    }

    .doctor-card-premium {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        padding: 2rem;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        height: 100%;
        display: flex;
        flex-direction: column;
        gap: 1.5rem;
    }

    .doctor-card-premium:hover {
        transform: translateY(-8px);
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.05);
        border-color: #6366f1;
    }

    .avatar-placeholder {
        width: 64px;
        height: 64px;
        background: #f1f5f9;
        color: #6366f1;
        border-radius: 18px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.75rem;
        font-weight: 800;
    }

    .metric-box {
        background: #f8fafc;
        border-radius: 16px;
        padding: 1rem;
        text-align: center;
        flex: 1;
    }

    .metric-value {
        display: block;
        font-size: 1.25rem;
        font-weight: 900;
        color: #1e293b;
    }

    .metric-label {
        font-size: 0.75rem;
        font-weight: 700;
        color: #64748b;
        text-transform: uppercase;
    }

    .attendance-bar-container {
        height: 10px;
        background: #f1f5f9;
        border-radius: 10px;
        overflow: hidden;
        margin: 0.5rem 0;
    }

    .attendance-bar-fill {
        height: 100%;
        border-radius: 10px;
        transition: width 1s ease;
    }
</style>

<div class="page-header-premium">
    <div>
        <nav style="margin-bottom: 0.75rem;">
            <a href="{{ route('administrative.reports.index') }}" style="color: rgba(255,255,255,0.7); text-decoration: none; font-size: 0.9rem; font-weight: 600; display: flex; align-items: center; gap: 0.5rem;">
                <i class="fa-solid fa-arrow-right"></i> العودة لمركز التقارير
            </a>
        </nav>
        <h1 style="font-size: 2rem; font-weight: 900; margin: 0;">أداء الكادر التعليمي</h1>
        <p style="margin: 0.5rem 0 0 0; opacity: 0.8; font-weight: 500;">متابعة دقيقة لنشاط الجلسات وتفاعل الطلاب مع كل دكتور</p>
    </div>
    <div style="background: rgba(255,255,255,0.1); padding: 1rem 1.5rem; border-radius: 16px; border: 1px solid rgba(255,255,255,0.15);">
        <div style="font-size: 0.85rem; font-weight: 700; opacity: 0.7;">إجمالي الدكاترة</div>
        <div style="font-size: 1.75rem; font-weight: 900;">{{ $doctors->count() }}</div>
    </div>
</div>

<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 2rem;">
    @foreach($doctors as $doctor)
    <div class="doctor-card-premium">
        <div style="display: flex; align-items: center; gap: 1.25rem;">
            <div class="avatar-placeholder">
                {{ mb_substr($doctor->name, 0, 1) }}
            </div>
            <div>
                <h3 style="font-size: 1.2rem; font-weight: 800; color: #1e293b; margin: 0;">{{ $doctor->name }}</h3>
                <span style="font-size: 0.85rem; color: #64748b; font-weight: 600;">{{ $doctor->college->name ?? 'عضو هيئة تدريس' }}</span>
            </div>
        </div>

        <div style="display: flex; gap: 1rem;">
            <div class="metric-box">
                <span class="metric-value">{{ $doctor->qr_sessions_count }}</span>
                <span class="metric-label">جلسات مكتملة</span>
            </div>
            <div class="metric-box">
                <span class="metric-value" style="color: #6366f1;">{{ $doctor->subjects_count ?? $doctor->subjects->count() }}</span>
                <span class="metric-label">مواد يدرسها</span>
            </div>
        </div>

        <div>
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem;">
                <span style="font-weight: 800; font-size: 0.9rem; color: #1e293b;">متوسط حضور الطلاب</span>
                <span style="font-weight: 900; color: #10b981; font-size: 1.1rem;">{{ $doctor->attendance_rate }}%</span>
            </div>
            <div class="attendance-bar-container">
                @php
                    $color = $doctor->attendance_rate >= 75 ? '#10b981' : ($doctor->attendance_rate >= 50 ? '#f59e0b' : '#e11d48');
                @endphp
                <div class="attendance-bar-fill" style="width: {{ $doctor->attendance_rate }}%; background: {{ $color }};"></div>
            </div>
            <p style="margin-top: 0.5rem; font-size: 0.75rem; color: #94a3b8; font-weight: 600;">يتم احتساب النسبة بناءً على إجمالي الطلاب المسجلين في مواد الدكتور.</p>
        </div>
    </div>
    @endforeach
</div>

@endsection
