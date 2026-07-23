@extends('layouts.student')

@section('title', 'سجلي السريري')

@section('content')
<style>
    .log-wrapper {
        display: grid;
        gap: 1rem;
    }

    .log-card {
        background: #fff;
        border: 1px solid #e5e7eb;
        border-radius: 20px;
        box-shadow: 0 10px 26px rgba(15, 23, 42, 0.04);
        padding: 1.2rem 1.3rem;
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

    .meta-row,
    .group-items {
        display: flex;
        gap: 0.6rem;
        flex-wrap: wrap;
        color: #64748b;
        font-size: 0.85rem;
    }

    .approval-box {
        margin-top: 0.9rem;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 16px;
        padding: 0.9rem 1rem;
    }

    .approval-box h3 {
        font-size: 0.95rem;
        margin-bottom: 0.6rem;
        font-weight: 800;
        color: #0f172a;
    }

    .item-pill {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        padding: 0.3rem 0.6rem;
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
        <div class="text-uppercase text-muted fw-bold small mb-2">Logbook</div>
        <h1 class="h3 fw-bold mb-2">سجلي السريري</h1>
        <p class="text-muted mb-0">تفاصيل ما سجلته يوميًا وما اعتمده الدكتور فعليًا لكل قسم.</p>
    </div>
    <div class="d-flex gap-2 flex-wrap">
        <a href="{{ route('student.clinical.logbook.export_pdf') }}" class="btn btn-outline-danger">تصدير PDF</a>
        <a href="{{ route('student.clinical.index') }}" class="btn btn-outline-secondary">العودة للقسم</a>
    </div>
</div>

<div class="log-wrapper">
    @forelse($entries as $entry)
        <div class="log-card">
            <div class="d-flex justify-content-between align-items-start flex-wrap gap-3 mb-2">
                <div>
                    <div class="fw-bold fs-5">{{ $entry->log_date->format('Y-m-d') }}</div>
                    <div class="meta-row mt-2">
                        <span>{{ $entry->trainingCenter->name ?? '-' }}</span>
                        <span>{{ $entry->department->name ?? '-' }}</span>
                        <span>د. {{ $entry->doctor->name ?? '-' }}</span>
                    </div>
                </div>
                <span class="status-pill {{ $entry->status }}">{{ $entry->status_label }}</span>
            </div>

            @foreach($entry->groupedActivities() as $group)
                @php
                    $items = $group['items'];
                    $diagnosis = $items->pluck('diagnosis')->filter()->first();
                    $allConfirmed = $items->every(fn ($item) => $item->is_confirmed);
                @endphp
                <div class="approval-box">
                    <h3>{{ $group['label'] }} <span class="text-muted small">({{ $items->count() }})</span></h3>
                    <div class="group-items">
                        @foreach($items as $item)
                            <span class="item-pill {{ $item->is_confirmed ? 'confirmed' : '' }}">
                                {{ $item->activity_type === 'round' ? ($item->case_name ?: 'Round case') : ($item->bodySystem->name ?? '-') }}
                            </span>
                        @endforeach
                    </div>
                    <div class="mt-2 small {{ $allConfirmed ? 'text-success' : 'text-muted' }}">
                        {{ $allConfirmed ? 'تم اعتماد هذا القسم بالكامل' : 'هذا القسم لم يعتمد بالكامل بعد' }}
                    </div>
                    @if($diagnosis)
                        <div class="mt-2"><strong>التشخيص:</strong> {{ $diagnosis }}</div>
                    @endif
                </div>
            @endforeach

            @if($entry->doctor_notes)
                <div class="approval-box"><strong>ملاحظات الدكتور:</strong> {{ $entry->doctor_notes }}</div>
            @endif
        </div>
    @empty
        <div class="log-card text-center text-muted py-5">لا توجد سجلات سريرية بعد.</div>
    @endforelse
</div>

@if($entries->hasPages())
    <div class="mt-4">{{ $entries->links() }}</div>
@endif
@endsection
