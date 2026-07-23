@extends('layouts.doctor')

@section('title', 'المهام السريرية')

@section('content')
<style>
    .page-grid {
        display: grid;
        grid-template-columns: 360px 1fr;
        gap: 1.5rem;
        align-items: start;
    }

    @media (max-width: 992px) {
        .page-grid {
            grid-template-columns: 1fr;
        }
    }

    .panel {
        background: #fff;
        border: 1px solid #e5e7eb;
        border-radius: 20px;
        box-shadow: 0 10px 28px rgba(15, 23, 42, 0.05);
        padding: 1.35rem;
    }

    .field {
        margin-bottom: 1rem;
    }

    .field label {
        display: block;
        font-weight: 700;
        margin-bottom: 0.45rem;
        color: #0f172a;
    }

    .field input,
    .field select,
    .field textarea {
        width: 100%;
        border: 1px solid #dbe2ea;
        border-radius: 12px;
        padding: 0.8rem 0.9rem;
        font: inherit;
        background: #fff;
    }

    .submit-btn,
    .approve-btn,
    .reject-btn,
    .filter-btn {
        border: none;
        border-radius: 12px;
        padding: 0.8rem 1rem;
        font-weight: 800;
        cursor: pointer;
    }

    .submit-btn,
    .filter-btn,
    .approve-btn {
        background: #1d4ed8;
        color: #fff;
    }

    .reject-btn {
        background: #fef2f2;
        color: #b91c1c;
        border: 1px solid #fecaca;
    }

    .task-table {
        width: 100%;
        border-collapse: collapse;
    }

    .task-table th,
    .task-table td {
        padding: 0.9rem 0.75rem;
        border-bottom: 1px solid #eef2f7;
        vertical-align: top;
    }

    .task-table th {
        color: #64748b;
        font-size: 0.82rem;
        text-transform: uppercase;
        letter-spacing: 0.04em;
    }

    .badge-status,
    .task-type {
        display: inline-flex;
        align-items: center;
        padding: 0.35rem 0.65rem;
        border-radius: 999px;
        font-weight: 800;
        font-size: 0.78rem;
    }

    .badge-status.assigned { background: #fef3c7; color: #92400e; }
    .badge-status.submitted_for_review { background: #dbeafe; color: #1d4ed8; }
    .badge-status.approved { background: #dcfce7; color: #166534; }
    .badge-status.rejected { background: #fee2e2; color: #991b1b; }
    .task-type.history_taking { background: #e0f2fe; color: #0369a1; }
    .task-type.clinical_examination { background: #fce7f3; color: #be185d; }
    .task-type.follow_up { background: #dcfce7; color: #166534; }

    .small-note {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        padding: 0.7rem 0.8rem;
        font-size: 0.85rem;
        color: #334155;
        margin-top: 0.55rem;
    }

    .filter-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
        gap: 0.85rem;
        margin-bottom: 1rem;
    }
</style>

<div class="d-flex justify-content-between align-items-start flex-wrap gap-3 mb-4">
    <div>
        <div class="text-uppercase text-muted fw-bold small mb-2">Clinical tasks</div>
        <h1 class="h3 fw-bold mb-2">إدارة المهام السريرية</h1>
        <p class="text-muted mb-0">إنشاء مهام للطالب ثم مراجعة رسالة الإنجاز واعتمادها أو رفضها.</p>
    </div>
    <a href="{{ route('doctor.clinical.index') }}" class="btn btn-outline-secondary">القسم العملي</a>
</div>

@if(session('success'))
    <div class="alert alert-success">{{ session('success') }}</div>
@endif
@if(session('error'))
    <div class="alert alert-danger">{{ session('error') }}</div>
@endif

<div class="page-grid">
    <div class="panel">
        <h2 class="h5 fw-bold mb-3">تكليف جديد</h2>
        <form action="{{ route('doctor.clinical.assignments.store') }}" method="POST">
            @csrf
            <div class="field">
                <label>الطالب</label>
                <select name="student_id" required>
                    <option value="">اختر الطالب</option>
                    @foreach($students as $student)
                        <option value="{{ $student->id }}">{{ $student->name }}{{ $student->student_number ? ' (' . $student->student_number . ')' : '' }}</option>
                    @endforeach
                </select>
            </div>
            <div class="field">
                <label>الحالة السريرية</label>
                <select name="clinical_case_id" required>
                    <option value="">اختر الحالة</option>
                    @foreach($cases as $case)
                        <option value="{{ $case->id }}">{{ $case->patient_name }}{{ $case->trainingCenter?->name ? ' - ' . $case->trainingCenter->name : '' }}</option>
                    @endforeach
                </select>
            </div>
            <div class="field">
                <label>نوع المهمة</label>
                <select name="task_type" required>
                    <option value="history_taking">قصة مرضية</option>
                    <option value="clinical_examination">فحص سريري</option>
                    <option value="follow_up">متابعة ومرور</option>
                </select>
            </div>
            <div class="field">
                <label>تعليمات إضافية</label>
                <textarea name="instructions" rows="4" placeholder="تعليمات مختصرة للطالب"></textarea>
            </div>
            <button type="submit" class="submit-btn w-100">إرسال التكليف</button>
        </form>
    </div>

    <div class="panel">
        <h2 class="h5 fw-bold mb-3">سجل المهام</h2>
        <form action="{{ route('doctor.clinical.assignments.index') }}" method="GET">
            <div class="filter-grid">
                <div class="field mb-0">
                    <label>الطالب</label>
                    <select name="filter_student_id">
                        <option value="">الكل</option>
                        @foreach($students as $student)
                            <option value="{{ $student->id }}" {{ request('filter_student_id') == $student->id ? 'selected' : '' }}>{{ $student->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="field mb-0">
                    <label>الحالة السريرية</label>
                    <select name="filter_case_id">
                        <option value="">الكل</option>
                        @foreach($cases as $case)
                            <option value="{{ $case->id }}" {{ request('filter_case_id') == $case->id ? 'selected' : '' }}>{{ $case->patient_name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="field mb-0">
                    <label>نوع المهمة</label>
                    <select name="filter_task_type">
                        <option value="">الكل</option>
                        <option value="history_taking" {{ request('filter_task_type') === 'history_taking' ? 'selected' : '' }}>قصة مرضية</option>
                        <option value="clinical_examination" {{ request('filter_task_type') === 'clinical_examination' ? 'selected' : '' }}>فحص سريري</option>
                        <option value="follow_up" {{ request('filter_task_type') === 'follow_up' ? 'selected' : '' }}>متابعة ومرور</option>
                    </select>
                </div>
                <div class="field mb-0">
                    <label>الحالة</label>
                    <select name="filter_status">
                        <option value="">الكل</option>
                        <option value="assigned" {{ request('filter_status') === 'assigned' ? 'selected' : '' }}>مكلف</option>
                        <option value="submitted_for_review" {{ request('filter_status') === 'submitted_for_review' ? 'selected' : '' }}>قيد المراجعة</option>
                        <option value="approved" {{ request('filter_status') === 'approved' ? 'selected' : '' }}>تم الاعتماد</option>
                        <option value="rejected" {{ request('filter_status') === 'rejected' ? 'selected' : '' }}>مرفوض</option>
                    </select>
                </div>
            </div>
            <button type="submit" class="filter-btn">تطبيق الفلاتر</button>
        </form>

        <div class="table-responsive mt-3">
            <table class="task-table">
                <thead>
                    <tr>
                        <th>الطالب</th>
                        <th>الحالة</th>
                        <th>المهمة</th>
                        <th>الحالة الحالية</th>
                        <th>الإجراء</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($assignments as $assignment)
                        <tr>
                            <td>
                                <div class="fw-bold">{{ $assignment->student->name ?? '-' }}</div>
                                <div class="text-muted small">{{ $assignment->student->student_number ?? '' }}</div>
                            </td>
                            <td>
                                <div class="fw-bold">{{ $assignment->clinicalCase->patient_name ?? '-' }}</div>
                                <div class="text-muted small">{{ $assignment->clinicalCase->trainingCenter->name ?? '' }}</div>
                            </td>
                            <td>
                                <span class="task-type {{ $assignment->task_type }}">{{ $assignment->task_type_label }}</span>
                                @if($assignment->instructions)
                                    <div class="small-note"><strong>تعليمات:</strong> {{ $assignment->instructions }}</div>
                                @endif
                            </td>
                            <td>
                                <span class="badge-status {{ $assignment->status }}">{{ $assignment->status_label }}</span>
                                @if($assignment->student_completion_message)
                                    <div class="small-note"><strong>رسالة الطالب:</strong> {{ $assignment->student_completion_message }}</div>
                                @endif
                                @if($assignment->review_notes)
                                    <div class="small-note"><strong>{{ $assignment->status === 'rejected' ? 'سبب الرفض' : 'ملاحظات المراجعة' }}:</strong> {{ $assignment->review_notes }}</div>
                                @endif
                            </td>
                            <td>
                                @if($assignment->status === 'submitted_for_review')
                                    <form action="{{ route('doctor.clinical.assignments.review', $assignment) }}" method="POST" class="mb-2">
                                        @csrf
                                        <input type="hidden" name="action" value="approve">
                                        <button type="submit" class="approve-btn w-100">اعتماد الإنجاز</button>
                                    </form>
                                    <form action="{{ route('doctor.clinical.assignments.review', $assignment) }}" method="POST">
                                        @csrf
                                        <input type="hidden" name="action" value="reject">
                                        <textarea name="review_notes" rows="3" placeholder="سبب الرفض" required class="mb-2"></textarea>
                                        <button type="submit" class="reject-btn w-100">رفض الإنجاز</button>
                                    </form>
                                @elseif($assignment->status === 'approved')
                                    <div class="text-success small fw-bold">تم اعتماد المهمة</div>
                                @elseif($assignment->status === 'rejected')
                                    <div class="text-danger small fw-bold">بانتظار إعادة إرسال الطالب</div>
                                @else
                                    <div class="text-muted small">لم يرسل الطالب الإنجاز بعد</div>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="text-center text-muted py-4">لا توجد مهام مطابقة للفلاتر الحالية.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($assignments->hasPages())
            <div class="mt-3">{{ $assignments->links() }}</div>
        @endif
    </div>
</div>
@endsection
