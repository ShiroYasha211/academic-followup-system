@extends('layouts.delegate')

@section('title', 'تفاصيل جدول الاختبارات')

@section('content')
<div class="container-fluid px-0">
    <!-- Header Controls -->
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
        <div>
            <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">
                {{ $exam->title }}
            </h1>
            <div style="display: flex; gap: 1rem; color: var(--text-secondary); font-size: 0.9rem;">
                <span style="display: flex; align-items: center; gap: 0.5rem;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                        <line x1="16" y1="2" x2="16" y2="6"></line>
                        <line x1="8" y1="2" x2="8" y2="6"></line>
                        <line x1="3" y1="10" x2="21" y2="10"></line>
                    </svg>
                    {{ $exam->term->name ?? '-' }}
                </span>
                <span style="display: flex; align-items: center; gap: 0.5rem;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"></circle>
                        <polyline points="12 6 12 12 16 14"></polyline>
                    </svg>
                    تم الإنشاء: {{ $exam->created_at->format('Y/m/d') }}
                </span>
            </div>
        </div>

        <div style="display: flex; gap: 0.75rem;">
            <a href="{{ route('delegate.exams.index') }}" class="btn btn-secondary" style="display: flex; align-items: center; gap: 0.5rem;">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="19" y1="12" x2="5" y2="12"></line>
                    <polyline points="12 19 5 12 12 5"></polyline>
                </svg>
                <span>عودة</span>
            </a>
            <a href="{{ route('delegate.exams.edit', $exam->id) }}" class="btn btn-primary" style="display: flex; align-items: center; gap: 0.5rem;">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
                <span>تعديل الجدول</span>
            </a>
        </div>
    </div>

    <div class="row" style="display: grid; grid-template-columns: 350px 1fr; gap: 1.5rem;">

        <!-- Info Card -->
        <div>
            <div class="card" style="position: sticky; top: 2rem;">
                <div style="padding: 1.5rem; border-bottom: 1px solid var(--border-color); background: #f8fafc; border-radius: var(--radius-md) var(--radius-md) 0 0;">
                    <h3 style="font-size: 1.1rem; font-weight: 700; color: var(--text-primary); margin: 0;">بيانات الجدول</h3>
                </div>

                <div style="padding: 1.5rem;">
                    <div style="margin-bottom: 1.5rem;">
                        <label style="display: block; font-size: 0.85rem; color: var(--text-secondary); margin-bottom: 0.5rem;">حالة النشر</label>
                        @if($exam->is_published)
                        <div style="display: flex; align-items: center; gap: 0.5rem; color: var(--success-color); font-weight: 600; background: #d1fae5; padding: 0.75rem; border-radius: var(--radius-sm); border: 1px solid #10b98133;">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                                <polyline points="22 4 12 14.01 9 11.01"></polyline>
                            </svg>
                            <span>منشور للطلاب</span>
                        </div>
                        @else
                        <div style="display: flex; align-items: center; gap: 0.5rem; color: var(--warning-color); font-weight: 600; background: #fef3c7; padding: 0.75rem; border-radius: var(--radius-sm); border: 1px solid #f59e0b33;">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="10"></circle>
                                <line x1="12" y1="16" x2="12" y2="12"></line>
                                <line x1="12" y1="8" x2="12.01" y2="8"></line>
                            </svg>
                            <span>مسودة (غير مرئي)</span>
                        </div>
                        @endif
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1.5rem;">
                        <div style="background: #f8fafc; padding: 1rem; border-radius: var(--radius-sm); text-align: center;">
                            <div style="font-size: 1.5rem; font-weight: 700; color: var(--primary-color);">{{ $exam->items->count() }}</div>
                            <div style="font-size: 0.8rem; color: var(--text-secondary);">عدد المواد</div>
                        </div>
                        <div style="background: #f8fafc; padding: 1rem; border-radius: var(--radius-sm); text-align: center;">
                            <div style="font-size: 1.5rem; font-weight: 700; color: var(--info-color);">{{ $exam->term->name }}</div>
                            <div style="font-size: 0.8rem; color: var(--text-secondary);">الفصل</div>
                        </div>
                    </div>

                    @if($exam->description)
                    <div>
                        <label style="display: block; font-size: 0.85rem; color: var(--text-secondary); margin-bottom: 0.5rem;">ملاحظات</label>
                        <p style="background: #fff; border: 1px solid var(--border-color); padding: 1rem; border-radius: var(--radius-sm); font-size: 0.9rem; margin: 0; line-height: 1.6;">
                            {{ $exam->description }}
                        </p>
                    </div>
                    @endif
                </div>
            </div>
        </div>

        <!-- Timetable -->
        <div class="card">
            <div style="padding: 1.5rem; border-bottom: 1px solid var(--border-color); display: flex; align-items: center; justify-content: space-between;">
                <h3 style="font-size: 1.1rem; font-weight: 700; color: var(--text-primary); margin: 0;">الجدول الزمني</h3>
                <span class="badge badge-info" style="font-size: 0.8rem;">مرتب زمنياً</span>
            </div>

            <div class="table-container">
                <div class="table-responsive">
<table style="width: 100%; border-collapse: separate; border-spacing: 0;">
                    <thead>
                        <tr style="background: #f8fafc;">
                            <th style="padding: 1rem 1.5rem; text-align: right; color: var(--text-secondary); font-weight: 600; border-bottom: 1px solid var(--border-color);">المادة</th>
                            <th style="padding: 1rem 1.5rem; text-align: right; color: var(--text-secondary); font-weight: 600; border-bottom: 1px solid var(--border-color);">اليوم والتاريخ</th>
                            <th style="padding: 1rem 1.5rem; text-align: center; color: var(--text-secondary); font-weight: 600; border-bottom: 1px solid var(--border-color);">الوقت</th>
                            <th style="padding: 1rem 1.5rem; text-align: right; color: var(--text-secondary); font-weight: 600; border-bottom: 1px solid var(--border-color);">المكان</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($exam->items->sortBy('exam_date') as $item)
                        <tr style="transition: background 0.2s;">
                            <td style="padding: 1.25rem 1.5rem; border-bottom: 1px solid var(--border-color); vertical-align: middle;">
                                <div style="font-weight: 700; color: var(--text-primary); font-size: 0.95rem;">{{ $item->subject->name }}</div>
                                <div style="font-size: 0.8rem; color: var(--text-secondary);">{{ $item->subject->code ?? '' }}</div>
                            </td>
                            <td style="padding: 1.25rem 1.5rem; border-bottom: 1px solid var(--border-color); vertical-align: middle;">
                                <div style="display: flex; align-items: center; gap: 0.5rem;">
                                    <div style="background: #e0e7ff; color: var(--primary-color); padding: 0.25rem 0.5rem; border-radius: 4px; font-weight: 700; font-size: 0.8rem; min-width: 80px; text-align: center;">
                                        {{ $item->exam_date->locale('ar')->translatedFormat('l') }}
                                    </div>
                                    <span style="font-weight: 500; font-family: monospace; font-size: 0.95rem;">{{ $item->exam_date->format('Y/m/d') }}</span>
                                </div>
                            </td>
                            <td style="padding: 1.25rem 1.5rem; border-bottom: 1px solid var(--border-color); text-align: center; vertical-align: middle;">
                                <div style="display: inline-flex; align-items: center; gap: 0.5rem; background: #fff; border: 1px solid var(--border-color); padding: 0.4rem 0.75rem; border-radius: 20px; font-size: 0.85rem; color: var(--text-primary);">
                                    <span style="color: var(--text-secondary); font-size: 0.8rem;">من</span>
                                    <span style="font-weight: 600;">{{ \Carbon\Carbon::parse($item->start_time)->format('h:i') }}</span>
                                    <span style="color: var(--text-secondary); font-size: 0.8rem;">إلى</span>
                                    <span style="font-weight: 600;">{{ \Carbon\Carbon::parse($item->end_time)->format('h:i') }}</span>
                                    <span style="font-size: 0.75rem; color: var(--text-secondary); margin-right: 0.2rem;">{{ \Carbon\Carbon::parse($item->start_time)->format('A') }}</span>
                                </div>
                            </td>
                            <td style="padding: 1.25rem 1.5rem; border-bottom: 1px solid var(--border-color); vertical-align: middle;">
                                @if($item->location)
                                <div style="display: flex; align-items: center; gap: 0.5rem; color: var(--text-secondary);">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color: var(--danger-color);">
                                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                                        <circle cx="12" cy="10" r="3"></circle>
                                    </svg>
                                    <span>{{ $item->location }}</span>
                                </div>
                                @else
                                <span style="color: var(--text-light); font-size: 0.85rem;">غير محدد</span>
                                @endif
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="4" style="text-align: center; padding: 3rem; color: var(--text-secondary);">
                                لا توجد مواد مضافة لهذا الجدول بعد.
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
</div>
            </div>
        </div>
    </div>
</div>

<style>
    @media print {

        .sidebar,
        .top-header,
        .btn-group,
        .btn {
            display: none !important;
        }

        .main-content {
            margin: 0 !important;
            width: 100% !important;
        }

        .card {
            box-shadow: none !important;
            border: 1px solid #ccc !important;
        }

        .badge {
            border: 1px solid #000;
            color: #000 !important;
        }
    }
</style>
@endsection