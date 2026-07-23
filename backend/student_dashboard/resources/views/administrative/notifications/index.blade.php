@extends('layouts.administrative')

@section('title', 'مركز الإعلانات')

@section('content')

<style>
    .welcome-hero {
        background: linear-gradient(135deg, #1e1b4b 0%, #312e81 100%);
        border-radius: 24px;
        padding: 2.5rem;
        color: white;
        margin-bottom: 2.5rem;
        position: relative;
        overflow: hidden;
        box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
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
        padding: 1.25rem;
        display: flex;
        align-items: center;
        gap: 1rem;
        border: 1px solid rgba(226, 232, 240, 0.8);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        position: relative;
        overflow: hidden;
    }

    .stat-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.05);
    }

    .stat-icon {
        width: 48px;
        height: 48px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.25rem;
    }

    .filter-card {
        background: white;
        border-radius: 24px;
        padding: 2rem;
        margin-bottom: 2.5rem;
        border: 1px solid #e2e8f0;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .input-premium {
        width: 100%;
        height: 48px;
        padding: 0 1rem;
        border: 1.5px solid #edf2f7;
        border-radius: 14px;
        background: #f8fafc;
        font-weight: 600;
        outline: none;
        transition: all 0.2s;
    }

    .input-premium:focus {
        border-color: var(--primary-color);
        background-color: white;
        box-shadow: 0 0 0 4px rgba(67, 56, 202, 0.1);
    }

    .table-container {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .reach-progress {
        width: 100%;
        height: 8px;
        background: #f1f5f9;
        border-radius: 10px;
        overflow: hidden;
        margin-top: 0.5rem;
    }

    .reach-bar {
        height: 100%;
        background: linear-gradient(90deg, #6366f1, #818cf8);
        border-radius: 10px;
        transition: width 1s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .type-badge {
        padding: 0.4rem 0.75rem;
        border-radius: 10px;
        font-size: 0.75rem;
        font-weight: 800;
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
    }
</style>

<!-- Welcome Hero -->
<div class="welcome-hero">
    <div style="position: relative; z-index: 1; display: flex; justify-content: space-between; align-items: center;">
        <div>
            <h1 style="font-size: 2.25rem; font-weight: 800; margin-bottom: 0.5rem; letter-spacing: -0.02em;">مركز الإعلانات الذكي</h1>
            <p style="opacity: 0.85; font-size: 1.1rem; font-weight: 500;">تواصل مباشر، إحصائيات دقيقة، وتحكم كامل في محتوى كليتك</p>
        </div>
        <a href="{{ route('administrative.notifications.create') }}" 
           style="background: white; color: #1e1b4b; display: flex; align-items: center; gap: 0.75rem; padding: 1rem 2rem; border-radius: 16px; font-weight: 800; text-decoration: none; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1); transition: all 0.3s ease;">
            <i class="fa-solid fa-plus-circle"></i>
            إرسال إعلان جديد
        </a>
    </div>
</div>

<!-- Stats Bar -->
<div style="display: grid; grid-template-columns: repeat(5, 1fr); gap: 1.25rem; margin-bottom: 2.5rem;">
    @php
        $types = [
            'announcement' => ['label' => 'عامة', 'color' => '#6366f1', 'icon' => 'bullhorn'],
            'exam' => ['label' => 'اختبارات', 'color' => '#ef4444', 'icon' => 'file-lines'],
            'assignment' => ['label' => 'تكاليف', 'color' => '#f59e0b', 'icon' => 'clipboard-list'],
            'attendance' => ['label' => 'حضور', 'color' => '#10b981', 'icon' => 'user-check'],
            'poll' => ['label' => 'استفتاءات', 'color' => '#8b5cf6', 'icon' => 'chart-bar'],
        ];
    @endphp
    @foreach($types as $typeKey => $typeData)
        <div class="stat-card">
            <div class="stat-icon" style="background: {{ $typeData['color'] }}15; color: {{ $typeData['color'] }};">
                <i class="fa-solid fa-{{ $typeData['icon'] }}"></i>
            </div>
            <div>
                <div style="font-size: 0.75rem; color: #64748b; font-weight: 700;">{{ $typeData['label'] }}</div>
                <div style="font-size: 1.25rem; font-weight: 800; color: #1e293b;">{{ $broadcasts->where('type', $typeKey)->count() }}</div>
            </div>
        </div>
    @endforeach
</div>

<!-- Advanced Filter Center -->
<div class="filter-card">
    <form action="{{ route('administrative.notifications.index') }}" method="GET">
        <div style="display: grid; grid-template-columns: 1fr 1.5fr 1.5fr auto; gap: 1.5rem; align-items: flex-end;">
            <!-- Type Filter -->
            <div>
                <label style="display: block; margin-bottom: 0.75rem; font-size: 0.9rem; font-weight: 800; color: #1e293b;">نوع الإعلان</label>
                <select name="type" class="input-premium" onchange="this.form.submit()" style="appearance: none; background-image: url('data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' fill=\'none\' viewBox=\'0 0 24 24\' stroke=\'%234a5568\' stroke-width=\'2\'%3E%3Cpath stroke-linecap=\'round\' stroke-linejoin=\'round\' d=\'M19 9l-7 7-7-7\'%3E%3C/path%3E%3C/svg%3E'); background-repeat: no-repeat; background-position: left 1rem center; background-size: 1.25rem;">
                    <option value="">جميع الأنواع</option>
                    @foreach($types as $key => $data)
                        <option value="{{ $key }}" {{ request('type') == $key ? 'selected' : '' }}>{{ $data['label'] }}</option>
                    @endforeach
                </select>
            </div>

            <!-- Date From -->
            <div>
                <label style="display: block; margin-bottom: 0.75rem; font-size: 0.9rem; font-weight: 800; color: #1e293b;">من تاريخ</label>
                <input type="date" name="from_date" value="{{ request('from_date') }}" class="input-premium">
            </div>

            <!-- Date To -->
            <div>
                <label style="display: block; margin-bottom: 0.75rem; font-size: 0.9rem; font-weight: 800; color: #1e293b;">إلى تاريخ</label>
                <input type="date" name="to_date" value="{{ request('to_date') }}" class="input-premium">
            </div>

            <!-- Actions -->
            <div style="display: flex; gap: 0.75rem;">
                <button type="submit" style="height: 48px; padding: 0 1.75rem; background: #1e1b4b; color: white; border: none; border-radius: 14px; font-weight: 700; cursor: pointer; transition: all 0.2s;">
                    <i class="fa-solid fa-magnifying-glass" style="margin-left: 0.5rem;"></i> بحث
                </button>
                @if(request()->hasAny(['type', 'from_date', 'to_date']))
                    <a href="{{ route('administrative.notifications.index') }}" style="height: 48px; width: 48px; background: #fff1f2; color: #e11d48; border-radius: 14px; display: flex; align-items: center; justify-content: center; text-decoration: none; border: 1px solid #fecdd3;">
                        <i class="fa-solid fa-xmark"></i>
                    </a>
                @endif
            </div>
        </div>
    </form>
</div>

<!-- Notifications Table -->
<div class="table-container">
    <div class="table-responsive">
        <table style="width: 100%; border-collapse: collapse;">
            <thead>
                <tr style="background: #f8fafc; border-bottom: 2px solid #f1f5f9;">
                    <th style="padding: 1.25rem 2rem; text-align: right; font-weight: 800; font-size: 0.85rem; color: #64748b;">موضوع الإعلان</th>
                    <th style="padding: 1.25rem 1.5rem; text-align: right; font-weight: 800; font-size: 0.85rem; color: #64748b;">النوع</th>
                    <th style="padding: 1.25rem 1.5rem; text-align: right; font-weight: 800; font-size: 0.85rem; color: #64748b;">تفاعل الوصول</th>
                    <th style="padding: 1.25rem 1.5rem; text-align: right; font-weight: 800; font-size: 0.85rem; color: #64748b;">وقت الإرسال</th>
                    <th style="padding: 1.25rem 2rem; text-align: center; font-weight: 800; font-size: 0.85rem; color: #64748b;">التحليلات</th>
                </tr>
            </thead>
            <tbody>
                @forelse($broadcasts as $broadcast)
                    <tr style="border-bottom: 1px solid #f1f5f9; transition: background 0.2s;" onmouseover="this.style.background='#fcfdfe'" onmouseout="this.style.background='white'">
                        <td style="padding: 1.25rem 2rem;">
                            <div style="display: flex; align-items: center; gap: 1rem;">
                                <div style="width: 44px; height: 44px; border-radius: 12px; background: #f1f5f9; color: #1e1b4b; display: flex; align-items: center; justify-content: center; font-size: 1.1rem; border: 1px solid #e2e8f0;">
                                    <i class="fa-solid fa-{{ $types[$broadcast->type]['icon'] ?? 'bell' }}"></i>
                                </div>
                                <div style="font-weight: 700; color: #1e293b; font-size: 0.95rem; max-width: 350px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                                    {{ $broadcast->title }}
                                </div>
                            </div>
                        </td>
                        <td style="padding: 1.25rem 1.5rem;">
                            @php $color = $types[$broadcast->type]['color'] ?? '#64748b'; @endphp
                            <span class="type-badge" style="background: {{ $color }}10; color: {{ $color }}; border: 1px solid {{ $color }}20;">
                                <i class="fa-solid fa-circle" style="font-size: 0.4rem;"></i>
                                {{ $types[$broadcast->type]['label'] ?? 'غير معروف' }}
                            </span>
                        </td>
                        <td style="padding: 1.25rem 1.5rem;">
                            @php $percentage = $broadcast->total_count > 0 ? round(($broadcast->read_count / $broadcast->total_count) * 100) : 0; @endphp
                            <div style="width: 140px;">
                                <div style="display: flex; justify-content: space-between; font-size: 0.75rem; font-weight: 800; color: #1e293b; margin-bottom: 0.2rem;">
                                    <span>{{ $broadcast->read_count }}/{{ $broadcast->total_count }}</span>
                                    <span>{{ $percentage }}%</span>
                                </div>
                                <div class="reach-progress">
                                    <div class="reach-bar" style="width: {{ $percentage }}%; background: linear-gradient(90deg, {{ $color }}, {{ $color }}dd);"></div>
                                </div>
                            </div>
                        </td>
                        <td style="padding: 1.25rem 1.5rem;">
                            <div style="font-weight: 700; color: #334155; font-size: 0.85rem;">{{ $broadcast->created_at->format('Y/m/d') }}</div>
                            <div style="font-size: 0.75rem; color: #64748b; font-weight: 600;">{{ $broadcast->created_at->format('h:i A') }}</div>
                        </td>
                        <td style="padding: 1.25rem 2rem; text-align: center;">
                            <a href="{{ route('administrative.notifications.show', $broadcast->batch_id) }}" 
                               style="display: inline-flex; align-items: center; justify-content: center; width: 40px; height: 40px; border-radius: 12px; background: #f1f5f9; color: #1e293b; transition: all 0.2s; text-decoration: none; border: 1px solid #e2e8f0;">
                                <i class="fa-solid fa-chart-line"></i>
                            </a>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="5" style="text-align: center; padding: 6rem 2rem;">
                            <div style="color: #cbd5e1; font-size: 4rem; margin-bottom: 1.5rem;"><i class="fa-solid fa-envelope-open-text"></i></div>
                            <h3 style="color: #64748b; font-size: 1.25rem; font-weight: 800;">لا توجد سجلات مطابقة</h3>
                            <p style="color: #94a3b8; font-weight: 500; margin-top: 0.5rem;">حاول تغيير معايير البحث أو ابدأ بإرسال إعلان جديد</p>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if($broadcasts->hasPages())
        <div style="padding: 1.5rem 2rem; background: #fcfdfe; border-top: 1px solid #f1f5f9;">
            {{ $broadcasts->links() }}
        </div>
    @endif
</div>

@endsection
