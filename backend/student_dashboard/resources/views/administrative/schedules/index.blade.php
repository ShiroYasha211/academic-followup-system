@extends('layouts.administrative')

@section('title', 'جداول المحاضرات')

@section('content')

<style>
    .schedules-hero {
        background: linear-gradient(135deg, #0f172a 0%, #1e1b4b 100%);
        border-radius: 24px;
        padding: 3rem;
        color: white;
        margin-bottom: 2.5rem;
        position: relative;
        overflow: hidden;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
    }

    .schedules-hero::after {
        content: '';
        position: absolute;
        top: -50%;
        left: -10%;
        width: 80%;
        height: 200%;
        background: radial-gradient(circle, rgba(255,255,255,0.05) 0%, transparent 70%);
        transform: rotate(-15deg);
    }

    .hero-stat-grid {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 1.5rem;
        margin-top: 2rem;
    }

    .glass-pill {
        background: rgba(255, 255, 255, 0.1);
        backdrop-filter: blur(10px);
        border: 1px solid rgba(255, 255, 255, 0.2);
        border-radius: 16px;
        padding: 1.25rem;
        text-align: center;
        transition: all 0.3s ease;
    }

    .glass-pill:hover {
        background: rgba(255, 255, 255, 0.15);
        transform: translateY(-5px);
    }

    .table-premium-container {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .day-badge {
        padding: 0.5rem 1rem;
        border-radius: 10px;
        font-weight: 800;
        font-size: 0.85rem;
        background: #f1f5f9;
        color: #475569;
        display: inline-block;
    }

    .time-slot {
        font-family: 'Inter', sans-serif;
        font-weight: 700;
        color: #6366f1;
    }

    .action-btn {
        width: 38px;
        height: 38px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.2s;
        border: none;
        background: #f8fafc;
        color: #64748b;
        text-decoration: none;
    }

    .action-btn:hover {
        transform: translateY(-3px);
    }

    .action-btn.edit:hover { background: #eef2ff; color: #6366f1; }
    .action-btn.delete:hover { background: #fff1f2; color: #e11d48; }
    .action-btn.view:hover { background: #f0fdf4; color: #10b981; }

    .btn-add-new {
        background: #6366f1;
        color: white;
        padding: 0.75rem 1.5rem;
        border-radius: 14px;
        font-weight: 800;
        text-decoration: none;
        display: flex;
        align-items: center;
        gap: 0.75rem;
        transition: all 0.3s;
        box-shadow: 0 10px 15px -3px rgba(99, 102, 241, 0.3);
    }

    .btn-add-new:hover {
        background: #4f46e5;
        transform: translateY(-2px);
        box-shadow: 0 20px 25px -5px rgba(99, 102, 241, 0.4);
        color: white;
    }
</style>

<div class="schedules-hero">
    <div style="display: flex; justify-content: space-between; align-items: flex-start; position: relative; z-index: 2;">
        <div>
            <h1 style="font-size: 2.5rem; font-weight: 900; margin-bottom: 0.5rem;">جداول المحاضرات</h1>
            <p style="font-size: 1.1rem; opacity: 0.8; font-weight: 500;">إدارة الجداول الزمنية الأسبوعية وتوزيع القاعات الدراسية</p>
        </div>
        <a href="{{ route('administrative.schedules.create') }}" class="btn-add-new">
            <i class="fa-solid fa-plus"></i> إضافة موعد جديد
        </a>
    </div>

    <div class="hero-stat-grid">
        <div class="glass-pill">
            <span style="display: block; font-size: 2rem; font-weight: 900;">{{ $schedules->total() }}</span>
            <span style="font-size: 0.85rem; font-weight: 600; opacity: 0.8;">إجمالي الحصص</span>
        </div>
        <div class="glass-pill">
            <span style="display: block; font-size: 2rem; font-weight: 900;">{{ $schedules->unique('hall_name')->count() }}</span>
            <span style="font-size: 0.85rem; font-weight: 600; opacity: 0.8;">قاعة مستخدمة</span>
        </div>
        <div class="glass-pill">
            <span style="display: block; font-size: 2rem; font-weight: 900;">{{ $schedules->unique('subject_id')->count() }}</span>
            <span style="font-size: 0.85rem; font-weight: 600; opacity: 0.8;">مادة أكاديمية</span>
        </div>
        <div class="glass-pill">
            <span style="display: block; font-size: 2rem; font-weight: 900;">+8</span>
            <span style="font-size: 0.85rem; font-weight: 600; opacity: 0.8;">تعديلات اليوم</span>
        </div>
    </div>
</div>

@if($schedules->total() > 0)
<div class="table-premium-container">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0" style="border-collapse: separate; border-spacing: 0;">
            <thead>
                <tr style="background: #f8fafc;">
                    <th style="padding: 1.25rem; border-bottom: 1px solid #e2e8f0; text-align: right; width: 30%;">المادة والدكتور</th>
                    <th style="padding: 1.25rem; border-bottom: 1px solid #e2e8f0; text-align: right;">التخصص والمستوى</th>
                    <th style="padding: 1.25rem; border-bottom: 1px solid #e2e8f0; text-align: center;">اليوم والموعد</th>
                    <th style="padding: 1.25rem; border-bottom: 1px solid #e2e8f0; text-align: center;">القاعة</th>
                    <th style="padding: 1.25rem; border-bottom: 1px solid #e2e8f0; text-align: left; padding-left: 2rem;">الإجراءات</th>
                </tr>
            </thead>
            <tbody>
                @foreach($schedules as $schedule)
                <tr>
                    <td style="padding: 1.5rem;">
                        <div style="display: flex; align-items: center; gap: 1rem;">
                            <div style="width: 48px; height: 48px; border-radius: 12px; background: #eef2ff; color: #6366f1; display: flex; align-items: center; justify-content: center; font-size: 1.25rem;">
                                <i class="fa-solid fa-book-bookmark"></i>
                            </div>
                            <div>
                                <h4 style="font-size: 1rem; font-weight: 800; color: #1e293b; margin: 0;">{{ $schedule->subject->name }}</h4>
                                <span style="font-size: 0.85rem; color: #64748b; font-weight: 600;">{{ $schedule->subject->doctor->name ?? 'دكتور غير محدد' }}</span>
                            </div>
                        </div>
                    </td>
                    <td style="padding: 1.5rem;">
                        <span style="background: #f0fdf4; color: #16a34a; padding: 0.4rem 0.8rem; border-radius: 8px; font-weight: 800; font-size: 0.8rem; display: block; width: fit-content; margin-bottom: 0.25rem;">
                            {{ $schedule->subject->major->name }}
                        </span>
                        <span style="font-size: 0.8rem; color: #94a3b8; font-weight: 700;">{{ $schedule->subject->level->name }}</span>
                    </td>
                    <td style="padding: 1.5rem; text-align: center;">
                        <div class="day-badge mb-2">
                            @php
                                $days = [1 => 'الإثنين', 2 => 'الثلاثاء', 3 => 'الأربعاء', 4 => 'الخميس', 5 => 'الجمعة', 6 => 'السبت', 7 => 'الأحد'];
                            @endphp
                            {{ $days[$schedule->day_of_week] ?? '-' }}
                        </div>
                        <div class="time-slot">
                            {{ \Carbon\Carbon::parse($schedule->start_time)->format('h:i') }} - {{ \Carbon\Carbon::parse($schedule->end_time)->format('h:i A') }}
                        </div>
                    </td>
                    <td style="padding: 1.5rem; text-align: center;">
                        <span style="background: #fffbeb; color: #d97706; padding: 0.5rem 1rem; border-radius: 10px; font-weight: 800; font-size: 0.9rem; border: 1px solid #fde68a;">
                            <i class="fa-solid fa-door-open me-1"></i> {{ $schedule->hall_name }}
                        </span>
                    </td>
                    <td style="padding: 1.5rem; padding-left: 2rem;">
                        <div style="display: flex; gap: 0.75rem; justify-content: flex-end;">
                            <a href="{{ route('administrative.schedules.show', $schedule) }}" class="action-btn view" title="عرض التفاصيل">
                                <i class="fa-solid fa-eye"></i>
                            </a>
                            <a href="{{ route('administrative.schedules.edit', $schedule) }}" class="action-btn edit" title="تعديل">
                                <i class="fa-solid fa-pen"></i>
                            </a>
                            <form action="{{ route('administrative.schedules.destroy', $schedule) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف هذا الموعد؟')" style="margin: 0;">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="action-btn delete" title="حذف">
                                    <i class="fa-solid fa-trash-can"></i>
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>

    @if($schedules->hasPages())
    <div style="padding: 1.5rem; background: #f8fafc; border-top: 1px solid #e2e8f0;">
        {{ $schedules->links() }}
    </div>
    @endif
</div>
@else
<div style="background: white; border-radius: 24px; padding: 5rem; text-align: center; border: 2px dashed #e2e8f0;">
    <div style="width: 100px; height: 100px; background: #f8fafc; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 2rem; font-size: 3rem; color: #cbd5e1;">
        <i class="fa-solid fa-calendar-xmark"></i>
    </div>
    <h2 style="font-weight: 900; color: #1e293b; margin-bottom: 1rem;">لا توجد محاضرات مجدولة</h2>
    <p style="color: #64748b; font-weight: 500; max-width: 400px; margin: 0 auto 2.5rem;">ابدأ بتنظيم الجدول الدراسي الأسبوعي عن طريق إضافة مواعيد المحاضرات الجديدة.</p>
    <a href="{{ route('administrative.schedules.create') }}" class="btn-add-new" style="width: fit-content; margin: 0 auto;">
        <i class="fa-solid fa-plus"></i> إضافة أول موعد
    </a>
</div>
@endif

@endsection
