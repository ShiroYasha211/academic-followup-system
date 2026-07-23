@extends('layouts.doctor')

@section('title', 'تسليمات التكليف')

@section('content')

<style>
    .back-link {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        color: var(--text-secondary);
        text-decoration: none;
        font-weight: 600;
        margin-bottom: 1.5rem;
    }

    .back-link:hover {
        color: var(--primary-color);
    }

    .page-header {
        margin-bottom: 2rem;
    }

    .page-title {
        font-size: 1.5rem;
        font-weight: 800;
        color: var(--text-primary);
    }

    .assignment-info {
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        border-radius: 16px;
        padding: 1.5rem;
        color: white;
        margin-bottom: 2rem;
    }

    .submissions-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
    }

    .submissions-header {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid #e2e8f0;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .submissions-table {
        width: 100%;
        border-collapse: collapse;
    }

    .submissions-table th {
        padding: 1rem 1.25rem;
        background: #f8fafc;
        font-weight: 700;
        color: var(--text-primary);
        text-align: right;
        font-size: 0.85rem;
        border-bottom: 1px solid #e2e8f0;
    }

    .submissions-table td {
        padding: 1rem 1.25rem;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
    }

    .submissions-table tr:hover {
        background: #f8fafc;
    }

    .student-cell {
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .student-avatar {
        width: 36px;
        height: 36px;
        border-radius: 10px;
        background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        color: #4f46e5;
        font-size: 0.85rem;
    }

    .status-badge {
        font-size: 0.75rem;
        padding: 0.3rem 0.6rem;
        border-radius: 6px;
        font-weight: 600;
    }

    .status-pending {
        background: #fef3c7;
        color: #92400e;
    }

    .status-reviewed {
        background: #e0e7ff;
        color: #4338ca;
    }

    .status-accepted {
        background: #d1fae5;
        color: #065f46;
    }

    .status-rejected {
        background: #fee2e2;
        color: #991b1b;
    }

    .late-badge {
        font-size: 0.7rem;
        padding: 0.2rem 0.4rem;
        background: #fee2e2;
        color: #991b1b;
        border-radius: 4px;
        margin-right: 0.5rem;
    }

    .btn-download {
        padding: 0.4rem 0.75rem;
        background: #e0e7ff;
        color: #4f46e5;
        border: none;
        border-radius: 8px;
        font-weight: 600;
        text-decoration: none;
        font-size: 0.85rem;
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
    }

    .btn-review {
        padding: 0.4rem 0.75rem;
        background: #f1f5f9;
        color: var(--text-primary);
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        font-weight: 600;
        cursor: pointer;
        font-size: 0.85rem;
    }

    .btn-review:hover {
        background: #eff6ff;
        border-color: var(--primary-color);
    }

    .empty-state {
        text-align: center;
        padding: 4rem;
    }

    /* Modal */
    .modal-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.5);
        display: none;
        align-items: center;
        justify-content: center;
        z-index: 1000;
    }

    .modal-overlay.active {
        display: flex;
    }

    .modal-content {
        background: white;
        border-radius: 16px;
        width: 90%;
        max-width: 500px;
        max-height: 90vh;
        overflow: auto;
    }

    .modal-header {
        padding: 1.25rem;
        border-bottom: 1px solid #e2e8f0;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .modal-body {
        padding: 1.25rem;
    }

    .modal-footer {
        padding: 1.25rem;
        border-top: 1px solid #e2e8f0;
        display: flex;
        justify-content: flex-end;
        gap: 0.75rem;
    }

    .form-group {
        margin-bottom: 1rem;
    }

    .form-label {
        font-weight: 600;
        display: block;
        margin-bottom: 0.5rem;
    }

    .form-control {
        width: 100%;
        padding: 0.6rem 0.75rem;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
    }
</style>

<a href="{{ route('doctor.assignments.index') }}" class="back-link">
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="15 18 9 12 15 6"></polyline>
    </svg>
    العودة للتكاليف
</a>

<!-- Assignment Info -->
<div class="assignment-info">
    <h1 style="font-size: 1.5rem; font-weight: 700; margin-bottom: 0.5rem;">{{ $assignment->title }}</h1>
    <div style="opacity: 0.9;">
        {{ $assignment->subject->name }} • تاريخ التسليم: {{ $assignment->due_date->format('Y-m-d') }}
        @if($assignment->isOverdue())
        <span style="background: rgba(255,255,255,0.2); padding: 0.2rem 0.5rem; border-radius: 4px; margin-right: 0.5rem;">منتهي</span>
        @endif
        <a href="{{ route('doctor.assignments.submissions.export', $assignment) }}" class="btn-download">
            <i class="fa-solid fa-file-excel"></i>
            تصدير Excel
        </a>
    </div>
</div>

@if(session('success'))
<div class="alert alert-success mb-4">{{ session('success') }}</div>
@endif

<!-- Submissions Table -->
<div class="submissions-card">
    <div class="submissions-header">
        <h3 style="font-weight: 700;">التسليمات ({{ $submissions->count() }})</h3>
    </div>

    <div class="table-responsive">
<table class="submissions-table">
        <thead>
            <tr>
                <th>#</th>
                <th>الطالب</th>
                <th>الملف</th>
                <th>تاريخ التسليم</th>
                <th>الحالة</th>
                <th>الدرجة</th>
                <th>الإجراءات</th>
            </tr>
        </thead>
        <tbody>
            @forelse($submissions as $index => $submission)
            <tr>
                <td>{{ $index + 1 }}</td>
                <td>
                    <div class="student-cell">
                        <div class="student-avatar">{{ mb_substr($submission->student->name ?? '?', 0, 1) }}</div>
                        <div>
                            <div style="font-weight: 600;">{{ $submission->student->name ?? 'طالب' }}</div>
                            <div style="font-size: 0.8rem; color: var(--text-secondary);">{{ $submission->student->student_number ?? '' }}</div>
                        </div>
                    </div>
                </td>
                <td>
                    <a href="{{ asset('storage/' . $submission->file_path) }}" target="_blank" class="btn-download">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                            <polyline points="7 10 12 15 17 10"></polyline>
                            <line x1="12" y1="15" x2="12" y2="3"></line>
                        </svg>
                        {{ Str::limit($submission->file_name, 20) }}
                    </a>
                    <div style="font-size: 0.75rem; color: var(--text-secondary);">{{ $submission->formatted_file_size }}</div>
                </td>
                <td>
                    @if($submission->isLate())
                    <span class="late-badge">متأخر</span>
                    @endif
                    {{ $submission->submitted_at->format('Y-m-d H:i') }}
                </td>
                <td>
                    <span class="status-badge status-{{ $submission->status }}">
                        @switch($submission->status)
                        @case('pending') قيد المراجعة @break
                        @case('reviewed') تمت المراجعة @break
                        @case('accepted') مقبول @break
                        @case('rejected') مرفوض @break
                        @endswitch
                    </span>
                </td>
                <td>
                    @if($submission->grade)
                    <span style="font-weight: 700; color: {{ $submission->grade >= 60 ? '#10b981' : '#ef4444' }};">{{ $submission->grade }}</span>
                    @else
                    <span style="color: var(--text-secondary);">-</span>
                    @endif
                </td>
                <td>
                    <button class="btn-review" onclick="openReviewModal({{ $submission->id }}, '{{ $submission->student->name }}', '{{ $submission->status }}', '{{ $submission->feedback }}', {{ $submission->grade ?? 'null' }})">
                        تقييم
                    </button>
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="7">
                    <div class="empty-state">
                        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color: #cbd5e1; margin-bottom: 1rem;">
                            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                            <polyline points="14 2 14 8 20 8"></polyline>
                        </svg>
                        <h3 style="font-size: 1.1rem; font-weight: 700; margin-bottom: 0.5rem;">لا توجد تسليمات</h3>
                        <p style="color: var(--text-secondary);">لم يقم أي طالب بتسليم هذا التكليف بعد</p>
                    </div>
                </td>
            </tr>
            @endforelse
        </tbody>
    </table>
</div>
</div>

<!-- Review Modal -->
<div class="modal-overlay" id="reviewModal">
    <div class="modal-content">
        <div class="modal-header">
            <h4 style="font-weight: 700;">تقييم التسليم: <span id="modalStudentName"></span></h4>
            <button onclick="closeReviewModal()" style="background: none; border: none; cursor: pointer;">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>
        </div>
        <form id="reviewForm" method="POST">
            @csrf
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label">الحالة</label>
                    <select name="status" id="reviewStatus" class="form-control" required>
                        <option value="accepted">مقبول</option>
                        <option value="rejected">مرفوض</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">الدرجة (0-100)</label>
                    <input type="number" name="grade" id="reviewGrade" class="form-control" min="0" max="100">
                </div>
                <div class="form-group">
                    <label class="form-label">ملاحظات</label>
                    <textarea name="feedback" id="reviewFeedback" class="form-control" rows="3" placeholder="ملاحظات للطالب..."></textarea>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" onclick="closeReviewModal()" style="padding: 0.6rem 1.25rem; border: 1px solid #e2e8f0; background: white; border-radius: 10px; cursor: pointer;">
                    إلغاء
                </button>
                <button type="submit" style="padding: 0.6rem 1.25rem; background: linear-gradient(135deg, #10b981, #059669); color: white; border: none; border-radius: 10px; font-weight: 600; cursor: pointer;">
                    حفظ التقييم
                </button>
            </div>
        </form>
    </div>
</div>

<script>
    function openReviewModal(submissionId, studentName, status, feedback, grade) {
        document.getElementById('modalStudentName').textContent = studentName;
        document.getElementById('reviewForm').action = "{{ url('doctor/submissions') }}/" + submissionId + "/review";
        document.getElementById('reviewStatus').value = status === 'pending' ? 'accepted' : status;
        document.getElementById('reviewFeedback').value = feedback || '';
        document.getElementById('reviewGrade').value = grade || '';
        document.getElementById('reviewModal').classList.add('active');
    }

    function closeReviewModal() {
        document.getElementById('reviewModal').classList.remove('active');
    }

    document.getElementById('reviewModal').addEventListener('click', function(e) {
        if (e.target === this) closeReviewModal();
    });
</script>

@endsection
