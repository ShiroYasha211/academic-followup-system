@extends('layouts.admin')

@section('title', 'إدارة التعيينات - Oneline Shot')

@section('content')
<style>
    :root {
        --premium-shadow: 0 10px 30px -5px rgba(0, 0, 0, 0.05);
    }
    .premium-card {
        background: white;
        border: 1px solid #f1f5f9;
        border-radius: 24px;
        box-shadow: var(--premium-shadow);
    }
    .data-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
    }
    .data-table th {
        background: #f8fafc;
        padding: 1.25rem 1.5rem;
        font-weight: 700;
        color: #64748b;
        font-size: 0.85rem;
        border-bottom: 2px solid #f1f5f9;
    }
    .data-table td {
        padding: 1.25rem 1.5rem;
        vertical-align: middle;
        border-bottom: 1px solid #f8fafc;
    }
    .table-row { transition: all 0.2s; }
    .table-row:hover { background: #fcfdff; }
    .action-btn {
        width: 36px; height: 36px;
        border-radius: 10px;
        display: inline-flex;
        align-items: center; justify-content: center;
        transition: all 0.2s; border: none; cursor: pointer;
    }
    .action-btn:hover { transform: translateY(-2px); }
</style>

<div class="mb-5 d-flex justify-content-between align-items-center flex-wrap gap-4">
    <div>
        <h1 class="mb-2 d-flex align-items-center gap-3" style="font-weight: 900;">
            <span class="d-flex align-items-center justify-content-center" style="background: rgba(14, 165, 233, 0.1); color: #0ea5e9; width: 48px; height: 48px; border-radius: 14px;">
                <i class="fa-solid fa-users-viewfinder"></i>
            </span>
            إدارة التعيينات
        </h1>
        <p class="text-secondary m-0" style="font-size: 1.1rem;">متابعة وإلغاء حزم Oneline Shot المعينة للطلاب</p>
    </div>
    <div>
        <a href="{{ route('admin.flashcards.index') }}" class="btn btn-light fw-bold rounded-pill px-4 border shadow-sm">
            <i class="fa-solid fa-arrow-right me-2"></i> عودة للإدارة
        </a>
    </div>
</div>

@if(session('success'))
    <div class="alert alert-success border-0 shadow-sm rounded-4 mb-4 p-3 px-4 fw-bold">
        <i class="fa-solid fa-check-circle me-2"></i> {{ session('success') }}
    </div>
@endif
@if(session('error'))
    <div class="alert alert-danger border-0 shadow-sm rounded-4 mb-4 p-3 px-4 fw-bold">
        <i class="fa-solid fa-circle-xmark me-2"></i> {{ session('error') }}
    </div>
@endif

<div class="premium-card p-4 p-md-5 mb-5">
    <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-3">
        <h3 class="h5 fw-bold m-0 d-flex align-items-center gap-2">
            <i class="fa-solid fa-list-check text-primary"></i>
            سجل التعيينات الحالية
        </h3>
        
        <form action="{{ route('admin.flashcards.assignments') }}" method="GET" class="d-flex gap-2">
            <div class="input-group shadow-sm" style="width: 300px; border-radius: 12px; overflow: hidden;">
                <input type="text" name="search" value="{{ request('search') }}" class="form-control border-0 bg-light px-3 fw-bold" placeholder="بحث باسم/رقم الطالب أو الحزمة...">
                <button type="submit" class="btn btn-primary border-0 px-3"><i class="fa-solid fa-magnifying-glass"></i></button>
            </div>
            @if(request('search'))
                <a href="{{ route('admin.flashcards.assignments') }}" class="btn btn-light border shadow-sm rounded-3 px-3 fw-bold" title="مسح البحث">
                    <i class="fa-solid fa-times text-danger"></i>
                </a>
            @endif
        </form>
    </div>

    <div class="table-responsive rounded-4 border border-light">
        <table class="data-table">
            <thead>
                <tr>
                    <th>الطالب</th>
                    <th>الرقم الجامعي</th>
                    <th>موضوع الحزمة</th>
                    <th>النوع</th>
                    <th>تاريخ التعيين</th>
                    <th class="text-start">الإجراءات</th>
                </tr>
            </thead>
            <tbody>
                @forelse($assignments as $assignment)
                <tr class="table-row">
                    <td>
                        <div class="fw-bold text-dark">{{ $assignment->user->name ?? 'غير معروف' }}</div>
                        <div class="text-secondary small">ID: {{ $assignment->user->id ?? '--' }}</div>
                    </td>
                    <td>
                        <span class="badge bg-light text-dark border px-2 py-1">{{ $assignment->user->student_number ?? 'غير متوفر' }}</span>
                    </td>
                    <td>
                        <div class="fw-bold text-primary">{{ $assignment->sourcePack->title ?? 'حزمة محذوفة' }}</div>
                    </td>
                    <td>
                        @if($assignment->sourcePack)
                        <span class="badge bg-primary-subtle text-primary border border-primary-subtle px-2 py-1 rounded-pill">
                            {{ $assignment->sourcePack->getDisplayModeTextAttribute() }}
                        </span>
                        @else
                        --
                        @endif
                    </td>
                    <td>
                        <div class="fw-bold text-secondary">{{ $assignment->created_at->format('Y-m-d') }}</div>
                        <div class="small text-muted">{{ $assignment->created_at->format('h:i A') }}</div>
                    </td>
                    <td class="text-start">
                        <form action="{{ route('admin.flashcards.assignments.cancel', $assignment) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من رغبتك في سحب هذه الحزمة من الطالب نهائياً؟');">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="action-btn bg-danger-subtle text-danger" title="إلغاء التعيين">
                                <i class="fa-solid fa-trash-can"></i>
                            </button>
                        </form>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="6" class="text-center py-5">
                        <div class="text-secondary mb-2"><i class="fa-solid fa-folder-open fs-1 opacity-25"></i></div>
                        <div class="fw-bold text-dark">لا توجد أي تعيينات حالية</div>
                        <div class="small text-muted">استخدم ميزة "تعيين لطالب" من صفحة إدارة الحزم لإرسال المحتوى التعليمي.</div>
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if($assignments->hasPages())
    <div class="mt-4 d-flex justify-content-center">
        {{ $assignments->links() }}
    </div>
    @endif
</div>
@endsection
