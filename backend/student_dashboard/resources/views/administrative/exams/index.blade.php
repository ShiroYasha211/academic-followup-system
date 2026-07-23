@extends('layouts.administrative')

@section('title', 'إدارة جداول الاختبارات')

@section('content')

<style>
    .premium-hero {
        background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
        border-radius: 24px;
        padding: 3rem;
        color: white;
        margin-bottom: 2.5rem;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
        position: relative;
        overflow: hidden;
    }

    .premium-hero::after {
        content: '';
        position: absolute;
        top: -50%;
        left: -10%;
        width: 80%;
        height: 200%;
        background: radial-gradient(circle, rgba(255,255,255,0.05) 0%, transparent 70%);
        transform: rotate(-15deg);
    }

    .stat-pill {
        background: rgba(255, 255, 255, 0.1);
        backdrop-filter: blur(10px);
        border: 1px solid rgba(255, 255, 255, 0.2);
        border-radius: 16px;
        padding: 1rem 1.5rem;
        display: flex;
        align-items: center;
        gap: 1rem;
        transition: transform 0.3s;
    }

    .stat-pill:hover {
        transform: translateY(-5px);
        background: rgba(255, 255, 255, 0.15);
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

    .premium-table-card {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
        overflow: hidden;
    }

    .premium-table thead th {
        background: #f8fafc;
        padding: 1.25rem 1rem;
        font-weight: 800;
        color: #64748b;
        font-size: 0.8rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        border-bottom: 1px solid #e2e8f0;
    }

    .premium-table tbody td {
        padding: 1.25rem 1rem;
        vertical-align: middle;
        border-bottom: 1px solid #f1f5f9;
        color: #1e293b;
        font-weight: 600;
    }

    .premium-table tbody tr:last-child td {
        border-bottom: none;
    }

    .major-pill {
        background: #eef2ff;
        color: #4f46e5;
        font-weight: 800;
        padding: 0.4rem 1rem;
        border-radius: 10px;
        font-size: 0.8rem;
        display: inline-block;
    }

    .status-badge {
        padding: 0.5rem 1rem;
        border-radius: 12px;
        font-weight: 800;
        font-size: 0.75rem;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
    }

    .status-published { background: #f0fdf4; color: #16a34a; }
    .status-draft { background: #fffbeb; color: #d97706; }

    .action-btn {
        width: 40px;
        height: 40px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.2s;
        text-decoration: none;
        border: none;
    }

    .btn-view { background: #f0f9ff; color: #0ea5e9; }
    .btn-view:hover { background: #0ea5e9; color: white; transform: scale(1.1); }
    .btn-edit { background: #f5f3ff; color: #8b5cf6; }
    .btn-edit:hover { background: #8b5cf6; color: white; transform: scale(1.1); }
    .btn-delete { background: #fef2f2; color: #ef4444; }
    .btn-delete:hover { background: #ef4444; color: white; transform: scale(1.1); }

    .creator-avatar {
        width: 40px;
        height: 40px;
        border-radius: 12px;
        background: #f1f5f9;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 900;
        color: #475569;
        border: 2px solid white;
        box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    }
</style>

<div class="container-fluid py-4">
    <!-- Hero Section -->
    <div class="premium-hero">
        <div class="row align-items-center g-4 position-relative" style="z-index: 2;">
            <div class="col-lg-6 text-end">
                <h1 style="font-size: 2.75rem; font-weight: 900; margin-bottom: 1rem; letter-spacing: -1px;">جداول الإختبارات</h1>
                <p style="font-size: 1.1rem; opacity: 0.9; font-weight: 500; margin-bottom: 2rem;">تنظيم ومتابعة مواعيد الامتحانات النهائية والفصلية لجميع التخصصات والمستويات الأكاديمية.</p>
                <a href="{{ route('administrative.exams.create') }}" class="btn btn-light btn-lg" style="border-radius: 16px; padding: 1rem 2rem; font-weight: 800; color: #1e293b; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.2);">
                    <i class="fa-solid fa-plus-circle me-2"></i> إضافة جدول اختبارات جديد
                </a>
            </div>
            <div class="col-lg-6">
                <div class="row g-3">
                    <div class="col-sm-6 text-end">
                        <div class="stat-pill">
                            <div class="stat-icon" style="background: rgba(255,255,255,0.1); color: #fff;">
                                <i class="fa-solid fa-calendar-days"></i>
                            </div>
                            <div>
                                <div style="font-size: 1.5rem; font-weight: 900;">{{ $schedules->total() }}</div>
                                <div style="font-size: 0.8rem; font-weight: 700; opacity: 0.7;">إجمالي الجداول</div>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-6 text-end">
                        <div class="stat-pill">
                            <div class="stat-icon" style="background: #fbbf24; color: #fff;">
                                <i class="fa-solid fa-file-signature"></i>
                            </div>
                            <div>
                                <div style="font-size: 1.5rem; font-weight: 900;">{{ $schedules->where('is_published', false)->count() }}</div>
                                <div style="font-size: 0.8rem; font-weight: 700; opacity: 0.7;">جداول (مسودة)</div>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-12 text-end">
                        <div class="stat-pill">
                            <div class="stat-icon" style="background: #10b981; color: #fff;">
                                <i class="fa-solid fa-check-double"></i>
                            </div>
                            <div>
                                <div style="font-size: 1.5rem; font-weight: 900;">{{ $schedules->where('is_published', true)->count() }}</div>
                                <div style="font-size: 0.8rem; font-weight: 700; opacity: 0.7;">جداول منشورة للطلاب</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Main Content -->
    @if($schedules->total() > 0)
    <div class="premium-table-card">
        <div class="table-responsive">
            <table class="table premium-table align-middle text-end mb-0">
                <thead>
                    <tr>
                        <th>المعلومات الأساسية</th>
                        <th>التخصص والمستوى</th>
                        <th>الفصل الدراسي</th>
                        <th>أنشئ بواسطة</th>
                        <th class="text-center">الحالة</th>
                        <th class="text-center">الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($schedules as $exam)
                    <tr>
                        <td>
                            <div class="d-flex align-items-center gap-3 justify-content-end">
                                <div class="text-end">
                                    <div style="font-weight: 900; color: #1e293b; font-size: 1.05rem;">{{ $exam->title }}</div>
                                    <div style="font-size: 0.85rem; color: #64748b; font-weight: 600;">
                                        <i class="fa-solid fa-layer-group me-1"></i> {{ $exam->items_count ?? $exam->items()->count() }} مواد دراسية
                                    </div>
                                </div>
                                <div style="width: 48px; height: 48px; background: #f1f5f9; border-radius: 14px; display: flex; align-items: center; justify-content: center; color: #475569; font-size: 1.25rem;">
                                    <i class="fa-solid fa-file-lines"></i>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="d-flex flex-column gap-1">
                                <span class="major-pill">{{ $exam->major->name }}</span>
                                <span style="font-size: 0.85rem; color: #64748b; font-weight: 700;">{{ $exam->level->name }}</span>
                            </div>
                        </td>
                        <td>
                            <span style="background: #f8fafc; border: 1px solid #e2e8f0; padding: 0.4rem 0.8rem; border-radius: 10px; font-weight: 800; font-size: 0.85rem; color: #334155;">
                                {{ $exam->term->name ?? 'غير محدد' }}
                            </span>
                        </td>
                        <td>
                            <div class="d-flex align-items-center gap-3 justify-content-end">
                                <div class="text-end">
                                    <div style="font-weight: 800; color: #1e293b; font-size: 0.9rem;">{{ $exam->creator->name }}</div>
                                    <div style="font-size: 0.75rem; color: #94a3b8; font-weight: 600;">{{ $exam->creator->role->value === 'administrative' ? 'إدارة' : 'مندوب' }}</div>
                                </div>
                                <div class="creator-avatar">
                                    {{ mb_substr($exam->creator->name, 0, 1) }}
                                </div>
                            </div>
                        </td>
                        <td class="text-center">
                            @if($exam->is_published)
                                <span class="status-badge status-published">
                                    <i class="fa-solid fa-circle-check"></i> منشور
                                </span>
                            @else
                                <span class="status-badge status-draft">
                                    <i class="fa-solid fa-pen-nib"></i> مسودة
                                </span>
                            @endif
                        </td>
                        <td>
                            <div class="d-flex justify-content-center gap-2">
                                <a href="{{ route('administrative.exams.show', $exam) }}" class="action-btn btn-view" title="عرض">
                                    <i class="fa-solid fa-eye"></i>
                                </a>
                                <a href="{{ route('administrative.exams.edit', $exam) }}" class="action-btn btn-edit" title="تعديل">
                                    <i class="fa-solid fa-pen"></i>
                                </a>
                                <form action="{{ route('administrative.exams.destroy', $exam) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف هذا الجدول نهائياً؟')">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="action-btn btn-delete" title="حذف">
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
        <div class="p-4 bg-light border-top">
            {{ $schedules->links() }}
        </div>
        @endif
    </div>
    @else
    <div class="premium-table-card py-5 text-center">
        <div class="card-body">
            <div class="mb-4">
                <div class="mx-auto bg-light rounded-circle d-flex align-items-center justify-content-center" style="width: 120px; height: 120px; border: 4px dashed #e2e8f0;">
                    <i class="fa-solid fa-calendar-xmark text-muted opacity-30 fa-3x"></i>
                </div>
            </div>
            <h4 class="fw-bold text-dark">لا توجد جداول اختبارات</h4>
            <p class="text-secondary mb-4 mx-auto" style="max-width: 400px; font-weight: 500;">
                لم يتم إضافة أي جداول اختبارات حتى الآن. ابدأ بتنظيم مواعيد الاختبارات لطلاب كليتك الآن.
            </p>
            <a href="{{ route('administrative.exams.create') }}" class="btn btn-primary px-5 py-3 fw-bold shadow" style="border-radius: 16px;">
                إنشاء أول جدول اختبارات
            </a>
        </div>
    </div>
    @endif
</div>

@endsection
