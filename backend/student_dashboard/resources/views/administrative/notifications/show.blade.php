@extends('layouts.administrative')

@section('title', 'تفاصيل الإعلان')

@section('content')

<style>
    .page-header {
        background: linear-gradient(135deg, #1e1b4b 0%, #312e81 100%);
        border-radius: 20px;
        padding: 2.5rem;
        color: white;
        margin-bottom: 2.5rem;
        box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
        position: relative;
        overflow: hidden;
    }

    .input-premium:focus {
        border-color: #6366f1;
        background-color: white;
        box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.1);
    }

    select.input-premium {
        padding-top: 0;
        padding-bottom: 0;
        appearance: none;
        background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='%23475569' stroke-width='2'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' d='M19 9l-7 7-7-7'%3E%3C/path%3E%3C/svg%3E");
        background-repeat: no-repeat;
        background-position: left 1rem center;
        background-size: 1.2rem;
    }

    .header-bg-icon {
        position: absolute;
        left: 5%;
        top: 50%;
        transform: translateY(-50%);
        font-size: 8rem;
        opacity: 0.1;
        pointer-events: none;
    }

    .glass-card {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        padding: 2rem;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .stat-card-premium {
        background: white;
        border-radius: 20px;
        padding: 1.5rem;
        border: 1px solid #f1f5f9;
        display: flex;
        align-items: center;
        gap: 1.25rem;
        transition: all 0.3s ease;
    }

    .stat-card-premium:hover {
        transform: translateY(-5px);
        box-shadow: 0 12px 20px -5px rgba(0, 0, 0, 0.05);
    }

    .stat-icon {
        width: 56px;
        height: 56px;
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.5rem;
    }

    .announcement-body {
        font-size: 1.15rem;
        line-height: 1.8;
        color: #334155;
        white-space: pre-wrap;
    }

    .poll-bar-container {
        height: 12px;
        background: #f1f5f9;
        border-radius: 10px;
        overflow: hidden;
        margin: 0.75rem 0;
    }

    .poll-bar-fill {
        height: 100%;
        background: linear-gradient(90deg, #6366f1, #818cf8);
        border-radius: 10px;
        transition: width 1s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .badge-premium {
        padding: 0.5rem 1rem;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.85rem;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
    }

    .table-premium th {
        padding: 1rem 1.5rem;
        background: #f8fafc;
        color: #64748b;
        font-weight: 800;
        font-size: 0.75rem;
        text-transform: uppercase;
        border-bottom: 2px solid #f1f5f9;
    }

    .table-premium td {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid #f1f5f9;
    }
</style>

<div class="page-header">
    <div class="header-bg-icon">
        <i class="fa-solid fa-bullhorn"></i>
    </div>
    <div style="position: relative; z-index: 1;">
        <nav style="margin-bottom: 1.5rem;">
            <a href="{{ route('administrative.notifications.index') }}" style="color: rgba(255,255,255,0.8); text-decoration: none; font-size: 0.95rem; font-weight: 700; display: flex; align-items: center; gap: 0.6rem;">
                <i class="fa-solid fa-arrow-right"></i> العودة للمركز
            </a>
        </nav>
        <div style="display: flex; align-items: center; gap: 1rem; margin-bottom: 0.75rem;">
            <span class="badge-premium" style="background: rgba(255,255,255,0.15); color: white; border: 1px solid rgba(255,255,255,0.2);">
                @php
                    $types = [
                        'announcement' => ['📢', 'إعلان عام'],
                        'exam' => ['📅', 'موعد اختبار'],
                        'assignment' => ['📄', 'تكليف دراسي'],
                        'attendance' => ['🛑', 'تنبيه حضور'],
                        'poll' => ['📊', 'استفتاء رأي']
                    ];
                    $t = $types[$stats['type']] ?? ['🔔', 'إشعار'];
                @endphp
                {{ $t[0] }} {{ $t[1] }}
            </span>
            <span style="color: rgba(255,255,255,0.6); font-weight: 600;">• {{ $stats['created_at']->translatedFormat('j F Y - h:i A') }}</span>
        </div>
        <h1 style="font-size: 2.25rem; font-weight: 900; margin: 0; line-height: 1.2;">{{ $stats['title'] }}</h1>
    </div>
</div>

<div style="display: grid; grid-template-columns: 1fr 380px; gap: 2rem;">
    <!-- Main Content Area -->
    <div style="display: flex; flex-direction: column; gap: 2rem;">
        <div class="glass-card">
            <h3 style="font-size: 1.25rem; font-weight: 800; color: #1e293b; margin-bottom: 1.5rem; display: flex; align-items: center; gap: 0.75rem;">
                <i class="fa-solid fa-align-right" style="color: #6366f1;"></i> محتوى الإعلان
            </h3>
            <div class="announcement-body">
                {{ $stats['message'] }}
            </div>

            @if($stats['attachment_path'])
            <div style="margin-top: 3rem; padding-top: 2rem; border-top: 2px dashed #f1f5f9;">
                <h4 style="font-size: 1rem; font-weight: 800; color: #64748b; margin-bottom: 1.25rem;">المرفقات الملحقة</h4>
                @php
                    $ext = strtolower(pathinfo($stats['attachment_name'], PATHINFO_EXTENSION));
                    $icon = 'fa-file';
                    $color = '#64748b';
                    
                    if (in_array($ext, ['jpg', 'jpeg', 'png', 'gif', 'webp'])) {
                        $icon = 'fa-file-image';
                        $color = '#10b981';
                    } elseif ($ext == 'pdf') {
                        $icon = 'fa-file-pdf';
                        $color = '#e11d48';
                    } elseif (in_array($ext, ['doc', 'docx'])) {
                        $icon = 'fa-file-word';
                        $color = '#2563eb';
                    }
                @endphp
                <a href="{{ $stats['attachment_url'] }}" target="_blank" 
                   style="display: inline-flex; align-items: center; gap: 1rem; padding: 1rem 1.5rem; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 16px; text-decoration: none; color: #1e293b; font-weight: 700; transition: all 0.2s;">
                    <i class="fa-solid {{ $icon }}" style="font-size: 1.5rem; color: {{ $color }};"></i>
                    <div style="display: flex; flex-direction: column;">
                        <span style="font-size: 0.95rem;">{{ $stats['attachment_name'] }}</span>
                        <span style="font-size: 0.75rem; color: #94a3b8;">فتح المعاينة</span>
                    </div>
                    <i class="fa-solid fa-download" style="margin-right: 1.5rem; color: #6366f1;"></i>
                </a>
            </div>
            @endif
        </div>

        @if($stats['type'] == 'poll')
        <div class="glass-card">
            <h3 style="font-size: 1.25rem; font-weight: 800; color: #1e293b; margin-bottom: 2rem; display: flex; align-items: center; gap: 0.75rem;">
                <i class="fa-solid fa-chart-simple" style="color: #6366f1;"></i> نتائج الاستفتاء الحالية
            </h3>
            <div style="display: flex; flex-direction: column; gap: 1.5rem;">
                @foreach($stats['poll_options'] as $option)
                <div>
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem;">
                        <span style="font-weight: 700; color: #334155;">{{ $option['text'] }}</span>
                        <span style="font-weight: 800; color: #6366f1;">{{ round($option['percentage']) }}% <small style="color: #94a3b8; font-weight: 600; margin-right: 0.5rem;">({{ $option['count'] }} صوت)</small></span>
                    </div>
                    <div class="poll-bar-container">
                        <div class="poll-bar-fill" style="width: {{ $option['percentage'] }}%"></div>
                    </div>
                </div>
                @endforeach
            </div>
            <div style="margin-top: 2rem; text-align: center; color: #64748b; font-weight: 700;">
                <i class="fa-solid fa-users" style="margin-left: 0.5rem;"></i> إجمالي المشاركين: {{ $stats['total_votes'] }} صوت
            </div>
        </div>
        @endif

        <!-- Recipients Table -->
        <div class="glass-card" style="padding: 0; overflow: hidden;">
            <div style="padding: 1.5rem 2rem; border-bottom: 1px solid #f1f5f9; background: #fcfdfe; display: flex; justify-content: space-between; align-items: center;">
                <h3 style="font-size: 1.1rem; font-weight: 800; color: #1e293b;">بيانات الوصول التفصيلية</h3>
                <span style="background: white; border: 1px solid #e2e8f0; padding: 0.4rem 0.75rem; border-radius: 8px; font-size: 0.8rem; font-weight: 700; color: #64748b;">
                    {{ $notifications->count() }} مستلم
                </span>
            </div>
            <div class="table-responsive" style="max-height: 500px; overflow-y: auto;">
                <table style="width: 100%; border-collapse: collapse;" class="table-premium">
                    <thead style="position: sticky; top: 0; z-index: 10;">
                        <tr>
                            <th style="text-align: right;">المستخدم</th>
                            <th style="text-align: right;">القسم / المستوى</th>
                            <th style="text-align: right;">الحالة</th>
                            <th style="text-align: right;">التوقيت</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($notifications as $notification)
                        <tr onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='white'">
                            <td>
                                <div style="display: flex; align-items: center; gap: 0.75rem;">
                                    <div style="width: 32px; height: 32px; border-radius: 8px; background: #f1f5f9; display: flex; align-items: center; justify-content: center; font-weight: 800; color: #64748b; font-size: 0.8rem;">
                                        {{ mb_substr($notification->user->name, 0, 1) }}
                                    </div>
                                    <div style="font-weight: 700; color: #1e293b; font-size: 0.9rem;">{{ $notification->user->name }}</div>
                                </div>
                            </td>
                            <td>
                                <div style="font-size: 0.85rem; font-weight: 600; color: #475569;">{{ $notification->user->major->name ?? '-' }}</div>
                                <div style="font-size: 0.75rem; color: #94a3b8;">{{ $notification->user->level->name ?? '-' }}</div>
                            </td>
                            <td>
                                @if($notification->read_at)
                                <span style="display: inline-flex; align-items: center; gap: 0.35rem; padding: 0.3rem 0.6rem; border-radius: 6px; background: #ecfdf5; color: #059669; font-size: 0.75rem; font-weight: 800;">
                                    <i class="fa-solid fa-check-double"></i> مقروء
                                </span>
                                @else
                                <span style="display: inline-flex; align-items: center; gap: 0.35rem; padding: 0.3rem 0.6rem; border-radius: 6px; background: #f1f5f9; color: #94a3b8; font-size: 0.75rem; font-weight: 700;">
                                    <i class="fa-regular fa-envelope"></i> معلق
                                </span>
                                @endif
                            </td>
                            <td style="font-size: 0.8rem; color: #64748b; font-weight: 600;">
                                {{ $notification->read_at ? $notification->read_at->translatedFormat('j M, h:i A') : '-' }}
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Sidebar Stats -->
    <div style="display: flex; flex-direction: column; gap: 1.5rem;">
        <div class="glass-card" style="padding: 1.5rem;">
            <h3 style="font-size: 1.1rem; font-weight: 800; color: #1e293b; margin-bottom: 1.5rem; border-bottom: 2px solid #f1f5f9; padding-bottom: 1rem;">إحصائيات الأداء</h3>
            
            <div style="display: flex; flex-direction: column; gap: 1rem;">
                <div class="stat-card-premium">
                    <div class="stat-icon" style="background: rgba(99, 102, 241, 0.1); color: #6366f1;">
                        <i class="fa-solid fa-users"></i>
                    </div>
                    <div>
                        <div style="font-size: 0.85rem; color: #64748b; font-weight: 700;">إجمالي المستهدفين</div>
                        <div style="font-size: 1.5rem; font-weight: 900; color: #1e293b;">{{ $stats['total_count'] }}</div>
                    </div>
                </div>

                <div class="stat-card-premium">
                    <div class="stat-icon" style="background: rgba(16, 185, 129, 0.1); color: #10b981;">
                        <i class="fa-solid fa-eye"></i>
                    </div>
                    <div>
                        <div style="font-size: 0.85rem; color: #64748b; font-weight: 700;">تمت القراءة من</div>
                        <div style="font-size: 1.5rem; font-weight: 900; color: #1e293b;">{{ $stats['read_count'] }}</div>
                    </div>
                </div>

                <div class="stat-card-premium">
                    <div class="stat-icon" style="background: rgba(245, 158, 11, 0.1); color: #f59e0b;">
                        <i class="fa-solid fa-percent"></i>
                    </div>
                    <div>
                        <div style="font-size: 0.85rem; color: #64748b; font-weight: 700;">نسبة التفاعل</div>
                        @php
                            $rate = $stats['total_count'] > 0 ? round(($stats['read_count'] / $stats['total_count']) * 100) : 0;
                        @endphp
                        <div style="font-size: 1.5rem; font-weight: 900; color: #1e293b;">{{ $rate }}%</div>
                    </div>
                </div>
            </div>
        </div>

        <div class="glass-card" style="padding: 1.5rem;">
            <h4 style="font-size: 1rem; font-weight: 800; color: #1e293b; margin-bottom: 1rem;">الإجراءات الإدارية</h4>
            <button onclick="confirmDelete()" style="width: 100%; height: 50px; background: #fff1f2; color: #e11d48; border: 1px solid #fecdd3; border-radius: 14px; font-weight: 800; cursor: pointer; transition: all 0.2s; display: flex; align-items: center; justify-content: center; gap: 0.5rem;">
                <i class="fa-solid fa-trash-can"></i> حذف السجل نهائياً
            </button>
            <form id="delete-form" action="{{ route('administrative.notifications.destroy', $batchId) }}" method="POST" style="display: none;">
                @csrf @method('DELETE')
            </form>
            <p style="margin-top: 1rem; font-size: 0.8rem; color: #94a3b8; text-align: center; font-weight: 600; line-height: 1.5;">
                سيؤدي الحذف إلى إزالة الإعلان من صناديق بريد جميع الطلاب وإخفاء تقرير الأداء.
            </p>
        </div>
    </div>
</div>

@push('scripts')
<script>
    function confirmDelete() {
        if(confirm('🚨 تحذير: أنت على وشك حذف هذا البث بالكامل من جميع حسابات الطلاب. هل ترغب في الاستمرار؟')) {
            document.getElementById('delete-form').submit();
        }
    }
</script>
@endpush

@endsection
