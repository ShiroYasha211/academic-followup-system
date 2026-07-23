@extends('layouts.administrative')

@section('title', 'لوحة التحكم الإدارية')

@section('content')

<style>
    .welcome-hero {
        background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
        border-radius: 24px;
        padding: 2.5rem;
        color: white;
        margin-bottom: 2.5rem;
        position: relative;
        overflow: hidden;
        box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1);
    }
    
    .welcome-hero::after {
        content: '';
        position: absolute;
        top: -50%;
        left: -20%;
        width: 100%;
        height: 200%;
        background: radial-gradient(circle, rgba(255,255,255,0.05) 0%, transparent 70%);
        transform: rotate(-15deg);
    }

    .stat-card {
        background: white;
        border-radius: 20px;
        padding: 1.5rem;
        display: flex;
        align-items: center;
        gap: 1.25rem;
        border: 1px solid rgba(226, 232, 240, 0.8);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        text-decoration: none;
    }

    .stat-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.05), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
        border-color: var(--primary-color);
    }

    .stat-icon {
        width: 60px;
        height: 60px;
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.5rem;
    }

    .action-tile {
        background: white;
        border-radius: 18px;
        padding: 1.5rem;
        text-align: center;
        border: 1px solid var(--border-color);
        transition: all 0.2s;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 1rem;
        color: var(--text-primary);
        font-weight: 600;
    }

    .action-tile:hover {
        background: #f8fafc;
        border-color: var(--primary-color);
        transform: scale(1.02);
    }

    .action-icon {
        width: 48px;
        height: 48px;
        border-radius: 12px;
        background: #f1f5f9;
        color: var(--primary-color);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.25rem;
    }

    .settings-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 1rem;
        background: #f8fafc;
        border-radius: 12px;
        margin-bottom: 0.75rem;
        border: 1px solid transparent;
        transition: all 0.2s;
    }
    
    .settings-item:hover {
        border-color: #cbd5e1;
        background: white;
    }

    .action-tile.locked {
        opacity: 0.6;
        filter: grayscale(1);
        cursor: not-allowed;
        background: #f1f5f9;
        border-color: #e2e8f0;
        position: relative;
    }

    .action-tile.locked::after {
        content: '🔒';
        position: absolute;
        top: 0.5rem;
        left: 0.5rem;
        font-size: 0.8rem;
    }
</style>

<!-- Welcome Hero -->
<div class="welcome-hero">
    <div style="position: relative; z-index: 1;">
        <h1 style="font-size: 2rem; font-weight: 800; margin-bottom: 0.5rem;">بوابة {{ $college->name }}</h1>
        <p style="opacity: 0.8; font-size: 1.1rem; font-weight: 500;">أهلاً بك مجدداً، تدير الآن العمليات الإدارية والأكاديمية للكلية بكل سهولة.</p>
    </div>
</div>

<!-- Stats Grid -->
<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; margin-bottom: 2.5rem;">
    <div class="stat-card">
        <div class="stat-icon" style="background: #eef2ff; color: #4338ca;">
            <i class="fa-solid fa-user-doctor"></i>
        </div>
        <div>
            <div style="font-size: 0.85rem; color: var(--text-secondary); font-weight: 600; margin-bottom: 0.25rem;">عدد الكادر التعليمي</div>
            <div style="font-size: 1.75rem; font-weight: 800; color: #1e293b;">{{ number_format($stats['doctors_count']) }}</div>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-icon" style="background: #fff7ed; color: #ea580c;">
            <i class="fa-solid fa-users-gear"></i>
        </div>
        <div>
            <div style="font-size: 0.85rem; color: var(--text-secondary); font-weight: 600; margin-bottom: 0.25rem;">مناديب الدفعات</div>
            <div style="font-size: 1.75rem; font-weight: 800; color: #1e293b;">{{ number_format($stats['delegates_count']) }}</div>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-icon" style="background: #f0fdf4; color: #16a34a;">
            <i class="fa-solid fa-graduation-cap"></i>
        </div>
        <div>
            <div style="font-size: 0.85rem; color: var(--text-secondary); font-weight: 600; margin-bottom: 0.25rem;">إجمالي الطلاب</div>
            <div style="font-size: 1.75rem; font-weight: 800; color: #1e293b;">{{ number_format($stats['students_count']) }}</div>
        </div>
    </div>
</div>

<div style="display: grid; grid-template-columns: 1.5fr 1fr; gap: 2rem;">
    <!-- Main Content Area -->
    <div>
        <div class="card" style="margin-bottom: 2rem;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
                <h3 style="font-size: 1.25rem; font-weight: 700; color: var(--text-primary);">إجراءات سريعة</h3>
                <span style="font-size: 0.85rem; color: var(--text-secondary);">اختصارات المهام المتكررة</span>
            </div>
            
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 1rem;">
                <a href="{{ route('administrative.notifications.create') }}" class="action-tile {{ !auth()->user()->isSubscribed() ? 'locked' : '' }}">
                    <div class="action-icon">
                        <i class="fa-solid fa-bullhorn"></i>
                    </div>
                    إعلان جديد
                </a>
                <a href="{{ route('administrative.delegates.index') }}" class="action-tile {{ !auth()->user()->isSubscribed() ? 'locked' : '' }}">
                    <div class="action-icon">
                        <i class="fa-solid fa-users-viewfinder"></i>
                    </div>
                    إدارة المناديب
                </a>
                <a href="{{ route('administrative.reports.index') }}" class="action-tile {{ !auth()->user()->isSubscribed() ? 'locked' : '' }}">
                    <div class="action-icon">
                        <i class="fa-solid fa-chart-pie"></i>
                    </div>
                    تقارير القسم
                </a>
                <a href="{{ route('administrative.profile.password') }}" class="action-tile">
                    <div class="action-icon">
                        <i class="fa-solid fa-key"></i>
                    </div>
                    تغيير الكلمة
                </a>
            </div>
        </div>

    </div>

    <!-- Sidebar Content Area -->
    <div>
        <div class="card">
            <h3 style="font-size: 1.25rem; font-weight: 700; color: var(--text-primary); margin-bottom: 1.5rem; padding-bottom: 1rem; border-bottom: 2px solid #f1f5f9;">إعدادات الكلية الحالية</h3>
            
            <div class="settings-item">
                <span style="color: var(--text-secondary); font-size: 0.9rem;">نسبة الحرمان</span>
                <span style="font-weight: 700; color: var(--danger-color); background: #fef2f2; padding: 0.25rem 0.75rem; border-radius: 8px;">{{ $college->absence_deprivation_percentage }}%</span>
            </div>
            
            <div class="settings-item">
                <span style="color: var(--text-secondary); font-size: 0.9rem;">مهلة تقديم الأعذار</span>
                <span style="font-weight: 700; color: var(--text-primary); background: #f1f5f9; padding: 0.25rem 0.75rem; border-radius: 8px;">{{ $college->excuses_deadline_days }} أيام</span>
            </div>
            

            <div style="margin-top: 2rem;">
                <a href="{{ route('administrative.settings') }}" class="btn btn-primary" style="width: 100%; padding: 1rem; border-radius: 14px; background: linear-gradient(135deg, var(--primary-color) 0%, #4f46e5 100%);">
                    <i class="fa-solid fa-pen-to-square" style="margin-left: 0.5rem;"></i>
                    تحديث الإعدادات
                </a>
            </div>
        </div>

    </div>
</div>

@endsection
