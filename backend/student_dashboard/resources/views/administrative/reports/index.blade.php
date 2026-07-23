@extends('layouts.administrative')

@section('title', 'مركز تقارير القسم')

@section('content')

<style>
    .reports-hero {
        background: linear-gradient(135deg, #1e1b4b 0%, #312e81 100%);
        border-radius: 24px;
        padding: 3rem;
        color: white;
        margin-bottom: 2.5rem;
        position: relative;
        overflow: hidden;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
    }

    .reports-hero::after {
        content: '';
        position: absolute;
        top: -50%;
        left: -10%;
        width: 80%;
        height: 200%;
        background: radial-gradient(circle, rgba(255,255,255,0.05) 0%, transparent 70%);
        transform: rotate(-15deg);
    }

    .hero-icon {
        position: absolute;
        left: 5%;
        top: 50%;
        transform: translateY(-50%);
        font-size: 8rem;
        opacity: 0.1;
        pointer-events: none;
    }

    .glass-stat-card {
        background: rgba(255, 255, 255, 0.1);
        backdrop-filter: blur(10px);
        border: 1px solid rgba(255, 255, 255, 0.2);
        border-radius: 20px;
        padding: 1.5rem;
        text-align: center;
        transition: all 0.3s ease;
    }

    .glass-stat-card:hover {
        background: rgba(255, 255, 255, 0.15);
        transform: translateY(-5px);
    }

    .glass-stat-card .value {
        font-size: 1.75rem;
        font-weight: 900;
        margin-bottom: 0.25rem;
        display: block;
    }

    .glass-stat-card .label {
        font-size: 0.85rem;
        font-weight: 600;
        opacity: 0.8;
    }

    .report-category-title {
        font-size: 1.25rem;
        font-weight: 800;
        color: #1e293b;
        margin-bottom: 1.5rem;
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .report-card-premium {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        padding: 2rem;
        height: 100%;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        display: flex;
        flex-direction: column;
    }

    .report-card-premium:hover {
        border-color: #6366f1;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.05);
        transform: translateY(-8px);
    }

    .report-card-icon {
        width: 56px;
        height: 56px;
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.5rem;
        margin-bottom: 1.5rem;
    }

    .btn-premium-action {
        margin-top: auto;
        width: 100%;
        height: 48px;
        border-radius: 14px;
        font-weight: 800;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        text-decoration: none;
        transition: all 0.2s;
        border: none;
    }

    .input-premium {
        width: 100%;
        height: 44px;
        padding: 0 1rem;
        background: #f8fafc;
        border: 1.5px solid #edf2f7;
        border-radius: 12px;
        font-size: 0.9rem;
        font-weight: 700;
        color: #1e293b;
        outline: none;
        transition: all 0.2s;
    }

    .input-premium:focus {
        border-color: #6366f1;
        background: white;
        box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.1);
    }
</style>

<div class="reports-hero">
    <div class="hero-icon"><i class="fa-solid fa-chart-mixed"></i></div>
    <div style="position: relative; z-index: 2;">
        <h1 style="font-size: 2.5rem; font-weight: 900; margin-bottom: 0.75rem;">مركز التقارير التحليلي</h1>
        <p style="font-size: 1.1rem; opacity: 0.9; margin-bottom: 2.5rem; font-weight: 500;">
            نظرة شاملة ودقيقة على أداء الكادر التعليمي، مستويات الحضور، والإنذارات الأكاديمية لـ <strong>{{ auth()->user()->college->name }}</strong>
        </p>

        <div style="display: grid; grid-template-columns: repeat(5, 1fr); gap: 1.5rem;">
            <div class="glass-stat-card">
                <span class="value">{{ $totalStudents }}</span>
                <span class="label">إجمالي الطلاب</span>
            </div>
            <div class="glass-stat-card">
                <span class="value">{{ $totalDoctors }}</span>
                <span class="label">هيئة التدريس</span>
            </div>
            <div class="glass-stat-card">
                <span class="value">{{ $totalSubjects }}</span>
                <span class="label">المواد الدراسية</span>
            </div>
            <div class="glass-stat-card">
                <span class="value">{{ number_format($totalAttendance) }}</span>
                <span class="label">سجلات الحضور</span>
            </div>
            <div class="glass-stat-card" style="background: rgba(239, 68, 68, 0.2); border-color: rgba(239, 68, 68, 0.3);">
                <span class="value" style="color: #fecdd3;">{{ $deprivedCount }}</span>
                <span class="label" style="color: #fecdd3;">حالات حرمان</span>
            </div>
        </div>
    </div>
</div>

<div style="margin-bottom: 3rem;">
    <h2 class="report-category-title">
        <div style="width: 8px; height: 24px; background: #6366f1; border-radius: 4px;"></div>
        تقارير الحضور والغياب المتقدمة
    </h2>

    <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 2rem;">
        <!-- Subject Report -->
        <div class="report-card-premium">
            <div class="report-card-icon" style="background: #eef2ff; color: #6366f1;">
                <i class="fa-solid fa-file-invoice"></i>
            </div>
            <h3 style="font-size: 1.2rem; font-weight: 800; color: #1e293b; margin-bottom: 0.75rem;">إحصائيات المادة</h3>
            <p style="color: #64748b; font-size: 0.9rem; line-height: 1.6; margin-bottom: 1.5rem;">تحليل كامل لحضور الطلاب في مادة محددة، مع حساب نسب الغياب لكل طالب.</p>
            
            <form action="{{ route('administrative.reports.subject') }}" method="GET">
                <div style="margin-bottom: 1rem;">
                    <select name="subject_id" class="input-premium" required>
                        <option value="">-- اختر المادة الدراسية --</option>
                        @foreach($subjects as $subject)
                        <option value="{{ $subject->id }}">{{ $subject->name }} ({{ $subject->level->name ?? '-' }})</option>
                        @endforeach
                    </select>
                </div>
                <button type="submit" class="btn-premium-action" style="background: #1e1b4b; color: white;">
                    <i class="fa-solid fa-magnifying-glass"></i> استخراج التقرير
                </button>
            </form>
        </div>

        <!-- Threshold Report -->
        <div class="report-card-premium">
            <div class="report-card-icon" style="background: #fff1f2; color: #e11d48;">
                <i class="fa-solid fa-triangle-exclamation"></i>
            </div>
            <h3 style="font-size: 1.2rem; font-weight: 800; color: #1e293b; margin-bottom: 0.75rem;">نظام الإنذارات</h3>
            <p style="color: #64748b; font-size: 0.9rem; line-height: 1.6; margin-bottom: 1.5rem;">رصد تلقائي للطلاب المتجاوزين لنسبة الغياب المسموح بها في أي مستوى.</p>
            
            <form action="{{ route('administrative.reports.threshold') }}" method="GET">
                <div style="display: grid; grid-template-columns: 1fr 80px; gap: 0.75rem; margin-bottom: 1rem;">
                    <select name="level_id" class="input-premium" required>
                        <option value="">-- المحتوى --</option>
                        @foreach($majors as $major)
                        <optgroup label="{{ $major->name }}">
                            @foreach($major->levels as $level)
                            <option value="{{ $level->id }}">{{ $level->name }}</option>
                            @endforeach
                        </optgroup>
                        @endforeach
                    </select>
                    <div style="position: relative;">
                        <input type="number" name="threshold" class="input-premium" value="25" min="1" max="100">
                        <span style="position: absolute; left: 10px; top: 50%; transform: translateY(-50%); font-size: 0.75rem; font-weight: 800; color: #94a3b8;">%</span>
                    </div>
                </div>
                <button type="submit" class="btn-premium-action" style="background: #e11d48; color: white;">
                    <i class="fa-solid fa-bolt"></i> فحص التجاوزات
                </button>
            </form>
        </div>

        <!-- Level Summary -->
        <div class="report-card-premium">
            <div class="report-card-icon" style="background: #f0fdf4; color: #10b981;">
                <i class="fa-solid fa-layer-group"></i>
            </div>
            <h3 style="font-size: 1.2rem; font-weight: 800; color: #1e293b; margin-bottom: 0.75rem;">ملخص الدفعات</h3>
            <p style="color: #64748b; font-size: 0.9rem; line-height: 1.6; margin-bottom: 1.5rem;">عرض إحصائيات مجمعة لمستوى دراسي كامل، تشمل حضور كافة المواد.</p>
            
            <form action="{{ route('administrative.reports.level-summary') }}" method="GET">
                <div style="margin-bottom: 1rem;">
                    <select name="level_id" class="input-premium" required>
                        <option value="">-- اختر الدفعة المستهدفة --</option>
                        @foreach($majors as $major)
                        <optgroup label="{{ $major->name }}">
                            @foreach($major->levels as $level)
                            <option value="{{ $level->id }}">{{ $level->name }}</option>
                            @endforeach
                        </optgroup>
                        @endforeach
                    </select>
                </div>
                <button type="submit" class="btn-premium-action" style="background: #10b981; color: white;">
                    <i class="fa-solid fa-eye"></i> عرض الملخص
                </button>
            </form>
        </div>
    </div>
</div>

<div>
    <h2 class="report-category-title">
        <div style="width: 8px; height: 24px; background: #8b5cf6; border-radius: 4px;"></div>
        تقارير الأداء والمتابعة
    </h2>
    
    <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 2rem;">
        <!-- Doctor Performance -->
        <div class="report-card-premium">
            <div class="report-card-icon" style="background: #f5f3ff; color: #8b5cf6;">
                <i class="fa-solid fa-user-tie"></i>
            </div>
            <h3 style="font-size: 1.2rem; font-weight: 800; color: #1e293b; margin-bottom: 0.75rem;">أداء الكادر التعليمي</h3>
            <p style="color: #64748b; font-size: 0.9rem; line-height: 1.6; margin-bottom: 1.5rem;">متابعة مدى التزام الدكاترة بتفعيل جلسات التحضير ونسب حضور طلابهم.</p>
            <a href="{{ route('administrative.reports.doctor-performance') }}" class="btn-premium-action" style="background: #8b5cf6; color: white;">
                <i class="fa-solid fa-chart-user"></i> معاينة الأداء
            </a>
        </div>

    </div>
</div>

@endsection
