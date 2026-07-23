@extends('layouts.doctor')

@section('title', 'لوحة اعتمادات الدرجات - ' . $subject->name)

@section('content')
<div class="dashboard-header mb-4 d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3">
    <div>
        <h1 class="fw-900 mb-1" style="font-size: 1.8rem;">لوحة اعتمادات الدرجات المعلقة</h1>
        <p class="text-secondary fw-700 m-0">{{ $subject->name }} | بانتظار مراجعتك</p>
    </div>
    <div class="d-flex gap-2">
        <a href="{{ route('doctor.grades.categories.index', $subject->id) }}" class="btn btn-outline-secondary px-4 rounded-4 fw-800">إدارة التقسيمات</a>
        <a href="{{ route('doctor.grades.show', $subject->id) }}" class="btn btn-primary px-4 rounded-4 fw-800 shadow-sm">سجل الدرجات النهائي</a>
    </div>
</div>

@if(session('success'))
    <div class="alert alert-success border-0 shadow-sm rounded-4 mb-4 fw-700">{{ session('success') }}</div>
@endif

<div class="card border-0 shadow-sm rounded-4 overflow-hidden">
    <div class="card-body p-0">
        <form id="bulkForm" action="{{ route('doctor.grades.approvals.bulk') }}" method="POST">
            @csrf
            <div class="p-4 border-bottom bg-light bg-opacity-50 d-flex justify-content-between align-items-center">
                <div class="d-flex align-items-center gap-3">
                    <div class="form-check">
                        <input class="form-check-input" type="checkbox" id="selectAll">
                        <label class="form-check-label fw-800" for="selectAll">تحديد الكل</label>
                    </div>
                    <div class="bulk-actions d-none">
                        <button type="submit" name="action" value="approve" class="btn btn-success btn-sm rounded-3 px-3 fw-800 me-2">اعتماد المحددة <i class="fa-solid fa-check ms-1"></i></button>
                        <button type="submit" name="action" value="reject" class="btn btn-danger btn-sm rounded-3 px-3 fw-800">رفض المحددة <i class="fa-solid fa-xmark ms-1"></i></button>
                    </div>
                </div>
                <span class="text-secondary small fw-700"><i class="fa-solid fa-circle-info me-1"></i> الدرجات المرفوضة لن تدخل في مجموع الطالب وسيُطلب من المفوض إعادة رصدها.</span>
            </div>

            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="bg-light text-secondary">
                        <tr>
                            <th class="ps-4" style="width: 50px;"></th>
                            <th>الطالب</th>
                            <th>التصنيف</th>
                            <th>الدرجة</th>
                            <th>بواسطة</th>
                            <th>تاريخ الرصد</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($pendingGrades as $grade)
                        <tr>
                            <td class="ps-4">
                                <input class="form-check-input grade-checkbox" type="checkbox" name="grade_ids[]" value="{{ $grade->id }}">
                            </td>
                            <td>
                                <div class="fw-800 text-dark">{{ $grade->student->name }}</div>
                                <div class="small text-secondary fw-700">{{ $grade->student->student_number }}</div>
                            </td>
                            <td>
                                <span class="badge bg-secondary-subtle text-secondary px-3 py-2 rounded-3 fw-800">
                                    {{ $grade->gradeCategory->name }}
                                </span>
                            </td>
                            <td>
                                <div class="fw-900 h5 m-0 text-primary">{{ $grade->score }} <small class="text-secondary" style="font-size: 10px;">/ {{ $grade->max_score }}</small></div>
                            </td>
                            <td>
                                <div class="d-flex align-items-center gap-2">
                                    <div class="avatar-sm bg-info-subtle text-info rounded-circle d-flex align-items-center justify-content-center fw-900" style="width: 28px; height: 28px; font-size: 10px;">
                                        {{ mb_substr($grade->creator->name, 0, 1) }}
                                    </div>
                                    <span class="small fw-700 text-dark">{{ $grade->creator->name }}</span>
                                </div>
                            </td>
                            <td class="small fw-700 text-secondary">
                                {{ $grade->created_at->format('Y-m-d H:i') }}
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="6" class="text-center py-5">
                                <i class="fa-solid fa-clipboard-check fa-4x text-light mb-3"></i>
                                <p class="text-secondary h5 fw-800">عظيم! لا توجد أي درجات معلقة بانتظار الاعتماد.</p>
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </form>
    </div>
</div>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        const selectAll = document.getElementById('selectAll');
        const checkboxes = document.querySelectorAll('.grade-checkbox');
        const bulkActions = document.querySelector('.bulk-actions');

        function toggleBulkActions() {
            const checkedCount = document.querySelectorAll('.grade-checkbox:checked').length;
            if (checkedCount > 0) {
                bulkActions.classList.remove('d-none');
            } else {
                bulkActions.classList.add('d-none');
            }
        }

        selectAll?.addEventListener('change', function() {
            checkboxes.forEach(cb => cb.checked = selectAll.checked);
            toggleBulkActions();
        });

        checkboxes.forEach(cb => {
            cb.addEventListener('change', toggleBulkActions);
        });
    });
</script>
@endsection
