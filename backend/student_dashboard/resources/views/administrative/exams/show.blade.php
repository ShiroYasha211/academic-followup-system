@extends('layouts.administrative')

@section('title', 'معاينة جدول الاختبارات')

@section('content')

<style>
    .view-hero {
        background: linear-gradient(135deg, #1e1b4b 0%, #312e81 100%);
        border-radius: 24px;
        padding: 2.5rem;
        color: white;
        margin-bottom: 2.5rem;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
        position: relative;
        overflow: hidden;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .view-hero::after {
        content: '';
        position: absolute;
        top: -50%;
        left: -10%;
        width: 80%;
        height: 200%;
        background: radial-gradient(circle, rgba(255,255,255,0.05) 0%, transparent 70%);
        transform: rotate(-15deg);
    }

    .premium-card {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        padding: 2rem;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
        height: 100%;
    }

    .schedule-container {
        border: 1px solid #e2e8f0;
        border-radius: 20px;
        overflow: hidden;
        background: white;
    }

    .schedule-header-mini {
        background: #f8fafc;
        border-bottom: 1px solid #e2e8f0;
        padding: 1.5rem;
        text-align: right;
    }

    .exam-row:hover {
        background-color: #f8fafc;
    }

    .day-badge {
        background: #eef2ff;
        color: #6366f1;
        padding: 0.4rem 1rem;
        border-radius: 10px;
        font-weight: 800;
        font-size: 0.8rem;
    }

    .time-badge {
        background: #f1f5f9;
        color: #475569;
        padding: 0.4rem 0.8rem;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.85rem;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
    }

    .status-badge {
        padding: 0.5rem 1rem;
        border-radius: 12px;
        font-weight: 800;
        font-size: 0.8rem;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
    }

    .status-published {
        background: #ecfdf5;
        color: #059669;
    }

    .status-draft {
        background: #fff7ed;
        color: #ea580c;
    }

    .info-item {
        margin-bottom: 1.5rem;
        text-align: right;
    }

    .info-label {
        font-weight: 800;
        color: #64748b;
        font-size: 0.8rem;
        margin-bottom: 0.4rem;
        display: block;
    }

    .info-value {
        font-weight: 700;
        color: #1e293b;
        font-size: 1rem;
        display: block;
    }
</style>

<div class="view-hero">
    <div style="display: flex; gap: 1.5rem; align-items: center; position: relative; z-index: 2;">
        <a href="{{ route('administrative.exams.index') }}" style="width: 50px; height: 50px; background: rgba(255,255,255,0.2); border-radius: 16px; display: flex; align-items: center; justify-content: center; color: white; text-decoration: none; backdrop-filter: blur(10px); transition: all 0.3s;">
            <i class="fa-solid fa-arrow-right"></i>
        </a>
        <div class="text-end">
            <span style="font-size: 0.85rem; font-weight: 800; opacity: 0.8; text-transform: uppercase;">معاينة المخطط</span>
            <h1 style="font-size: 1.75rem; font-weight: 900; margin: 0;">{{ $exam->title }}</h1>
        </div>
    </div>
    
    <div style="display: flex; gap: 1rem; position: relative; z-index: 2;">
        <a href="{{ route('administrative.exams.edit', $exam) }}" class="btn btn-light fw-bold px-4" style="border-radius: 14px; padding: 0.75rem 1.5rem;">
            <i class="fa-solid fa-pen-to-square me-2"></i> تعديل الجدول
        </a>
    </div>
</div>

<div class="container-fluid">
    <div class="row g-4 overflow-visible">
        <div class="col-lg-8">
            <div class="premium-card">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <span class="status-badge {{ $exam->is_published ? 'status-published' : 'status-draft' }}">
                        <i class="fa-solid {{ $exam->is_published ? 'fa-circle-check' : 'fa-circle-pause' }}"></i>
                        {{ $exam->is_published ? 'جدول منشور للطلاب' : 'مسودة (غير ظاهر للطلاب)' }}
                    </span>
                    <h5 style="font-weight: 900; color: #1e293b; margin: 0;">الخطة الزمنية للاختبارات</h5>
                </div>

                <div class="schedule-container text-end">
                    <div class="table-responsive">
                        <table class="table align-middle mb-0">
                            <thead style="background: #f8fafc;">
                                <tr>
                                    <th style="padding: 1.25rem; border: none; color: #64748b; font-weight: 800; font-size: 0.8rem;">المادة الدراسية</th>
                                    <th style="padding: 1.25rem; border: none; color: #64748b; font-weight: 800; font-size: 0.8rem;">اليوم والتاريخ</th>
                                    <th style="padding: 1.25rem; border: none; color: #64748b; font-weight: 800; font-size: 0.8rem;">التوقيت</th>
                                    <th style="padding: 1.25rem; border: none; color: #64748b; font-weight: 800; font-size: 0.8rem;">المكان</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($exam->items->sortBy('exam_date') as $item)
                                    <tr class="exam-row">
                                        <td style="padding: 1.25rem;">
                                            <div style="font-weight: 800; color: #1e293b;">{{ $item->subject->name }}</div>
                                            <div style="font-size: 0.75rem; color: #64748b; font-weight: 600;">{{ $item->subject->code ?? 'N/A' }}</div>
                                        </td>
                                        <td style="padding: 1.25rem;">
                                            <div class="day-badge mb-1 d-inline-block">{{ $item->exam_date->locale('ar')->translatedFormat('l') }}</div>
                                            <div style="font-weight: 700; color: #475569; font-size: 0.9rem;">{{ $item->exam_date->format('Y-m-d') }}</div>
                                        </td>
                                        <td style="padding: 1.25rem;">
                                            <div class="time-badge">
                                                <span>{{ \Carbon\Carbon::parse($item->end_time)->format('h:i') }}</span>
                                                <i class="fa-solid fa-arrow-left-long mx-1" style="font-size: 0.7rem; opacity: 0.5;"></i>
                                                <span>{{ \Carbon\Carbon::parse($item->start_time)->format('h:i') }}</span>
                                                <span style="font-size: 0.7rem; margin-top: 1px;">{{ \Carbon\Carbon::parse($item->start_time)->format('A') == 'AM' ? 'صباحاً' : 'مساءً' }}</span>
                                            </div>
                                        </td>
                                        <td style="padding: 1.25rem;">
                                            @if($item->location)
                                                <div style="font-weight: 700; color: #1e293b;">
                                                    <i class="fa-solid fa-location-dot text-danger me-1"></i>
                                                    {{ $item->location }}
                                                </div>
                                            @else
                                                <span class="text-muted small fw-bold">لم يحدد بعد</span>
                                            @endif
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="4" class="text-center py-5">
                                            <div style="opacity: 0.2; transform: scale(3); margin-bottom: 2rem;">
                                                <i class="fa-solid fa-calendar-xmark"></i>
                                            </div>
                                            <h6 class="fw-bold text-muted">لا توجد مواد مضافة في هذا الجدول</h6>
                                        </td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="premium-card">
                <h5 style="font-weight: 900; color: #1e293b; margin-bottom: 2rem; border-right: 4px solid #6366f1; padding-right: 1rem;">تفاصيل الجدولة</h5>
                
                <div class="info-item">
                    <span class="info-label">التخصص / القسم</span>
                    <span class="info-value">{{ $exam->major->name }}</span>
                </div>

                <div class="info-item">
                    <span class="info-label">المستوى / الفصل</span>
                    <span class="info-value">{{ $exam->level->name }} - {{ $exam->term->name ?? 'غير محدد' }}</span>
                </div>

                <div class="info-item">
                    <span class="info-label">إجمالي المواد</span>
                    <span class="info-value">{{ $exam->items->count() }} مقرر دراسي</span>
                </div>

                <hr style="opacity: 0.05; margin: 2rem 0;">

                <div class="info-item">
                    <span class="info-label">وصف إضافي تعليمات</span>
                    <div style="background: #f8fafc; border-radius: 12px; padding: 1rem; color: #475569; font-weight: 600; font-size: 0.9rem; line-height: 1.6;">
                        {{ $exam->description ?: 'لا توجد ملاحظات إضافية لهذا الجدول.' }}
                    </div>
                </div>

                <div style="background: #eef2ff; border-radius: 16px; padding: 1.5rem; margin-top: 2rem; text-align: center;">
                    <i class="fa-solid fa-shield-halved text-primary mb-3" style="font-size: 1.5rem;"></i>
                    <h6 style="font-weight: 800; color: #1e293b; font-size: 0.9rem;">نظام الجدولة الذكي</h6>
                    <p style="color: #64748b; font-size: 0.75rem; font-weight: 500; margin: 0;">يتم مزامنة هذه البيانات فوراً مع تطبيقات الهواتف الذكية للطلاب بمجرد النشر.</p>
                </div>
            </div>
        </div>
    </div>
</div>

@endsection
