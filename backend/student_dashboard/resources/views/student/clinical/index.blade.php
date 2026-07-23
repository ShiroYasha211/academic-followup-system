@extends('layouts.student')

@section('title', 'القسم السريري العملي')

@section('content')
<style>
    .clinical-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 1rem;
        flex-wrap: wrap;
        margin-bottom: 1.5rem;
    }

    .quick-actions {
        display: flex;
        gap: 0.75rem;
        flex-wrap: wrap;
    }

    .action-btn,
    .ghost-btn {
        border-radius: 12px;
        padding: 0.7rem 1.1rem;
        font-weight: 700;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
    }

    .action-btn {
        background: linear-gradient(135deg, #2563eb, #1d4ed8);
        color: #fff;
        box-shadow: 0 10px 22px rgba(37, 99, 235, 0.18);
    }

    .ghost-btn {
        background: #fff;
        color: #334155;
        border: 1px solid #dbe2ea;
    }

    .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
        gap: 1rem;
        margin-bottom: 1.5rem;
    }

    .stat-card,
    .section-card,
    .task-card,
    .pending-card {
        background: #fff;
        border: 1px solid #e5e7eb;
        border-radius: 18px;
        box-shadow: 0 10px 28px rgba(15, 23, 42, 0.04);
    }

    .stat-card {
        padding: 1.15rem 1.25rem;
    }

    .stat-number {
        font-size: 1.8rem;
        font-weight: 800;
        color: #0f172a;
    }

    .stat-label {
        color: #64748b;
        font-size: 0.85rem;
        margin-top: 0.2rem;
    }

    .section-card {
        padding: 1.4rem;
        margin-bottom: 1.25rem;
    }

    .section-head {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 1rem;
        margin-bottom: 1rem;
    }

    .section-title {
        font-size: 1.05rem;
        font-weight: 800;
        color: #0f172a;
        margin: 0;
    }

    .pending-card,
    .task-card {
        padding: 1rem 1.1rem;
        margin-bottom: 0.9rem;
    }

    .pending-meta,
    .task-meta {
        display: flex;
        gap: 0.6rem;
        flex-wrap: wrap;
        color: #64748b;
        font-size: 0.84rem;
    }

    .badge-status,
    .task-type {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        padding: 0.35rem 0.7rem;
        border-radius: 999px;
        font-size: 0.8rem;
        font-weight: 800;
    }

    .badge-status.assigned {
        background: #fef3c7;
        color: #92400e;
    }

    .badge-status.submitted_for_review {
        background: #dbeafe;
        color: #1d4ed8;
    }

    .badge-status.approved {
        background: #dcfce7;
        color: #166534;
    }

    .badge-status.rejected {
        background: #fee2e2;
        color: #991b1b;
    }

    .task-type.history_taking {
        background: #e0f2fe;
        color: #0369a1;
    }

    .task-type.clinical_examination {
        background: #fce7f3;
        color: #be185d;
    }

    .task-type.follow_up {
        background: #dcfce7;
        color: #166534;
    }

    .note-box {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        padding: 0.85rem 0.95rem;
        margin-top: 0.8rem;
        color: #334155;
        font-size: 0.88rem;
    }

    .submit-box textarea {
        width: 100%;
        border: 1px solid #dbe2ea;
        border-radius: 14px;
        padding: 0.85rem 0.95rem;
        min-height: 110px;
        font: inherit;
        margin-top: 0.85rem;
    }

    .submit-box button,
    .show-qr-btn {
        margin-top: 0.75rem;
        border: none;
        border-radius: 12px;
        padding: 0.7rem 1rem;
        font-weight: 700;
        cursor: pointer;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
    }

    .submit-box button,
    .show-qr-btn {
        background: #1d4ed8;
        color: #fff;
    }

    .empty-state {
        text-align: center;
        color: #64748b;
        padding: 2rem 1rem;
    }
</style>

<div class="clinical-header">
    <div>
        <div class="text-uppercase text-muted fw-bold small mb-2">Clinical hub</div>
        <h1 class="h3 fw-bold mb-2">القسم السريري العملي</h1>
        <p class="text-muted mb-0">مهامك السريرية، السجلات اليومية، وما تم اعتماده من الدكتور.</p>
    </div>
    <div class="quick-actions">
        <a href="{{ route('student.clinical.daily-log.create') }}" class="action-btn">تسجيل بيانات اليوم</a>
        <a href="{{ route('student.clinical.evaluations') }}" class="ghost-btn">تقييماتي</a>
        <a href="{{ route('student.clinical.logbook') }}" class="ghost-btn">سجلي</a>
    </div>
</div>

<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-number">{{ $assignments->count() }}</div>
        <div class="stat-label">إجمالي المهام السريرية</div>
    </div>
    <div class="stat-card">
        <div class="stat-number">{{ $confirmedCount }}</div>
        <div class="stat-label">سجلات معتمدة بالكامل</div>
    </div>
    <div class="stat-card">
        <div class="stat-number">{{ $pendingCount }}</div>
        <div class="stat-label">سجلات بانتظار أو اعتماد جزئي</div>
    </div>
</div>

@if($pendingLogs->count() > 0)
<div class="section-card">
    <div class="section-head">
        <h2 class="section-title">سجلات بانتظار التأكيد</h2>
        <span class="text-muted small">{{ $pendingLogs->count() }} سجل</span>
    </div>
    @foreach($pendingLogs as $log)
        <div class="pending-card">
            <div class="d-flex justify-content-between align-items-start gap-3 flex-wrap">
                <div>
                    <div class="fw-bold mb-2">{{ $log->log_date->format('Y-m-d') }}</div>
                    <div class="pending-meta">
                        <span>{{ $log->trainingCenter->name ?? '-' }}</span>
                        <span>{{ $log->department->name ?? '-' }}</span>
                        <span>د. {{ $log->doctor->name ?? '-' }}</span>
                    </div>
                </div>
                <a href="{{ route('student.clinical.show-qr', $log->id) }}" class="show-qr-btn">عرض QR</a>
            </div>
        </div>
    @endforeach
</div>
@endif

<div class="section-card">
    <div class="section-head">
        <h2 class="section-title">المهام السريرية</h2>
    </div>

    @forelse($assignments as $assignment)
        <div class="task-card">
            <div class="d-flex justify-content-between align-items-start gap-3 flex-wrap">
                <div>
                    <div class="fw-bold fs-5 mb-2">{{ $assignment->clinicalCase->patient_name ?? '-' }}</div>
                    <div class="task-meta mb-2">
                        <span>{{ $assignment->clinicalCase->trainingCenter->name ?? '-' }}</span>
                        <span>{{ $assignment->clinicalCase->bodySystem->name ?? '-' }}</span>
                        <span>د. {{ $assignment->assigner->name ?? '-' }}</span>
                    </div>
                </div>
                <div class="d-flex gap-2 flex-wrap">
                    <span class="task-type {{ $assignment->task_type }}">{{ $assignment->task_type_label ?? $assignment->task_type }}</span>
                    <span class="badge-status {{ $assignment->status }}">{{ $assignment->status_label }}</span>
                </div>
            </div>

            @if($assignment->instructions)
                <div class="note-box"><strong>تعليمات:</strong> {{ $assignment->instructions }}</div>
            @endif

            @if($assignment->student_completion_message)
                <div class="note-box"><strong>رسالة الإنجاز المرسلة:</strong> {{ $assignment->student_completion_message }}</div>
            @endif

            @if($assignment->review_notes)
                <div class="note-box"><strong>{{ $assignment->status === 'rejected' ? 'سبب الرفض' : 'ملاحظات الدكتور' }}:</strong> {{ $assignment->review_notes }}</div>
            @endif

            @if($assignment->status === 'approved' && $assignment->reviewed_at)
                <div class="note-box"><strong>اعتمدت في:</strong> {{ $assignment->reviewed_at->format('Y-m-d H:i') }}</div>
            @endif

            @if(in_array($assignment->status, ['assigned', 'rejected'], true))
                <form action="{{ route('student.clinical.assignments.submit', $assignment) }}" method="POST" class="submit-box">
                    @csrf
                    <label class="form-label fw-bold mt-3">{{ $assignment->status === 'rejected' ? 'إعادة إرسال الإنجاز' : 'إرسال الإنجاز للدكتور' }}</label>
                    <textarea name="student_completion_message" placeholder="اكتب ما الذي أنجزته في هذه المهمة، والخطوات التي قمت بها..." required>{{ old('student_completion_message') }}</textarea>
                    <button type="submit">{{ $assignment->status === 'rejected' ? 'إعادة الإرسال' : 'إرسال الإنجاز' }}</button>
                </form>
            @elseif($assignment->status === 'submitted_for_review')
                <div class="note-box"><strong>الحالة الحالية:</strong> تم إرسال الإنجاز وبانتظار اعتماد الدكتور.</div>
            @endif
        </div>
    @empty
        <div class="empty-state">لا توجد مهام سريرية مكلّف بها حاليًا.</div>
    @endforelse
</div>
@endsection
