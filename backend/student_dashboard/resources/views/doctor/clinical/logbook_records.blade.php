@extends('layouts.doctor')

@section('title', 'سجل السجلات السريرية')

@section('content')
<style>
    .records-grid {
        display: grid;
        gap: 1rem;
    }

    .record-card {
        background: #fff;
        border: 1px solid #e5e7eb;
        border-radius: 20px;
        padding: 1.2rem 1.3rem;
        box-shadow: 0 10px 28px rgba(15, 23, 42, 0.04);
    }

    .status-pill {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        padding: 0.35rem 0.75rem;
        border-radius: 999px;
        font-size: 0.8rem;
        font-weight: 800;
    }

    .status-pill.pending { background: #fef3c7; color: #92400e; }
    .status-pill.partially_confirmed { background: #dbeafe; color: #1d4ed8; }
    .status-pill.confirmed { background: #dcfce7; color: #166534; }
    .status-pill.rejected { background: #fee2e2; color: #991b1b; }

    .group-box {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 16px;
        padding: 0.9rem 1rem;
        margin-top: 0.9rem;
    }

    .group-label {
        font-weight: 800;
        color: #0f172a;
        margin-bottom: 0.55rem;
    }

    .pill-row {
        display: flex;
        gap: 0.5rem;
        flex-wrap: wrap;
    }

    .item-pill {
        padding: 0.28rem 0.6rem;
        border-radius: 999px;
        font-size: 0.78rem;
        font-weight: 700;
        background: #fff;
        border: 1px solid #e2e8f0;
        color: #334155;
    }

    .item-pill.confirmed {
        background: #dcfce7;
        border-color: #86efac;
        color: #166534;
    }
</style>

<div class="d-flex justify-content-between align-items-start flex-wrap gap-3 mb-4">
    <div>
        <div class="text-uppercase text-muted fw-bold small mb-2">Clinical records</div>
        <h1 class="h3 fw-bold mb-2">سجل السجلات اليومية</h1>
        <p class="text-muted mb-0">يعرض ما تم تسجيله من الطالب وما تم اعتماده فعليًا لكل قسم.</p>
    </div>
    <a href="{{ route('doctor.clinical.index') }}" class="btn btn-outline-secondary">القسم العملي</a>
</div>

<form class="row g-3 mb-4">
    <div class="col-md-4">
        <label class="form-label fw-bold">الحالة</label>
        <select name="status" class="form-select">
            <option value="">الكل</option>
            <option value="pending" {{ request('status') === 'pending' ? 'selected' : '' }}>بانتظار التأكيد</option>
            <option value="partially_confirmed" {{ request('status') === 'partially_confirmed' ? 'selected' : '' }}>اعتماد جزئي</option>
            <option value="confirmed" {{ request('status') === 'confirmed' ? 'selected' : '' }}>مؤكد</option>
            <option value="rejected" {{ request('status') === 'rejected' ? 'selected' : '' }}>مرفوض</option>
        </select>
    </div>
    <div class="col-md-4">
        <label class="form-label fw-bold">التاريخ</label>
        <input type="date" name="date" value="{{ request('date') }}" class="form-control">
    </div>
    <div class="col-md-4 d-flex align-items-end">
        <button type="submit" class="btn btn-primary w-100">تصفية</button>
    </div>
</form>

<div class="records-grid">
    @forelse($logs as $log)
        <div class="record-card">
            <div class="d-flex justify-content-between align-items-start flex-wrap gap-3 mb-2">
                <div>
                    <div class="fw-bold fs-5">{{ $log->student->name ?? '-' }}</div>
                    <div class="text-muted small mt-2">
                        {{ $log->trainingCenter->name ?? '-' }} |
                        {{ $log->department->name ?? '-' }} |
                        {{ $log->log_date->format('Y-m-d') }}
                    </div>
                </div>
                <span class="status-pill {{ $log->status }}">{{ $log->status_label }}</span>
            </div>

            @foreach($log->groupedActivities() as $group)
                @php
                    $items = $group['items'];
                    $diagnosis = $items->pluck('diagnosis')->filter()->first();
                @endphp
                <div class="group-box">
                    <div class="group-label">{{ $group['label'] }}</div>
                    <div class="pill-row">
                        @foreach($items as $item)
                            <span class="item-pill {{ $item->is_confirmed ? 'confirmed' : '' }}">
                                {{ $item->activity_type === 'round' ? ($item->case_name ?: 'Round case') : ($item->bodySystem->name ?? '-') }}
                            </span>
                        @endforeach
                    </div>
                    @if($diagnosis)
                        <div class="mt-2 small"><strong>التشخيص:</strong> {{ $diagnosis }}</div>
                    @endif
                </div>
            @endforeach

            @if($log->doctor_notes)
                <div class="group-box"><strong>ملاحظات الدكتور:</strong> {{ $log->doctor_notes }}</div>
            @endif
        </div>
    @empty
        <div class="record-card text-center text-muted py-5">لا توجد سجلات مطابقة.</div>
    @endforelse
</div>

@if($logs->hasPages())
    <div class="mt-4">{{ $logs->links() }}</div>
@endif
@endsection
