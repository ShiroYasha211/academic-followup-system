@extends(Auth::user()->role === \App\Enums\UserRole::DELEGATE ? 'layouts.delegate' : 'layouts.student')

@section('title', 'رصد درجات ' . $category->name)

@push('styles')
<style>
    .premium-header {
        background: linear-gradient(135deg, #0f172a 0%, #1d4ed8 100%);
        border-radius: 24px;
        padding: 2.25rem;
        color: white;
        position: relative;
        overflow: hidden;
        margin-bottom: 2rem;
        box-shadow: 0 20px 40px -18px rgba(29, 78, 216, 0.35);
    }

    .premium-header::after {
        content: '';
        position: absolute;
        top: -50%;
        left: -10%;
        width: 360px;
        height: 360px;
        background: rgba(255, 255, 255, 0.08);
        border-radius: 50%;
        filter: blur(60px);
    }

    .glass-card {
        background: rgba(255, 255, 255, 0.78);
        backdrop-filter: blur(12px);
        -webkit-backdrop-filter: blur(12px);
        border: 1px solid rgba(255, 255, 255, 0.35);
        border-radius: 24px;
        box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.07);
    }

    .meta-chip {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        background: #f8fafc;
        color: #475569;
        border-radius: 999px;
        padding: 0.42rem 0.8rem;
        font-size: 0.82rem;
        font-weight: 800;
    }

    .scope-box {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 18px;
        padding: 1rem;
        height: 100%;
    }

    .grade-input {
        max-width: 120px;
        text-align: center;
        border-radius: 14px;
        font-weight: 800;
    }

    .delegate-pill {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        padding: 0.38rem 0.8rem;
        background: #eff6ff;
        color: #1d4ed8;
        border-radius: 999px;
        font-size: 0.78rem;
        font-weight: 800;
    }

    .assigned-badge {
        background: #f0fdf4;
        color: #16a34a;
        border: 1px solid #bbf7d0;
        padding: 0.4rem 1rem;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.85rem;
    }

    .btn-delegate {
        background: linear-gradient(135deg, #0ea5e9 0%, #2563eb 100%);
        color: white;
        border: none;
        padding: 0.75rem 1.5rem;
        border-radius: 14px;
        font-weight: 800;
        transition: all 0.3s ease;
    }

    .btn-delegate:hover {
        transform: scale(1.03);
        box-shadow: 0 8px 15px -3px rgba(37, 99, 235, 0.35);
        color: white;
    }

    .avatar-circle {
        width: 45px;
        height: 45px;
        background: #e0f2fe;
        color: #0369a1;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 900;
        border-radius: 12px;
        flex-shrink: 0;
    }

    .candidate-wrapper {
        border: 1px solid #dbeafe;
        border-radius: 18px;
        overflow: hidden;
        background: white;
    }

    .candidate-table {
        margin-bottom: 0;
    }

    .candidate-table thead th {
        background: #eff6ff;
        color: #1e3a8a;
        font-size: 0.85rem;
        font-weight: 900;
        border: none;
        padding: 1rem;
    }

    .candidate-table tbody td {
        padding: 1rem;
        vertical-align: middle;
        border-color: #eef2ff;
    }

    .candidate-row {
        transition: background 0.2s ease;
    }

    .candidate-row:hover {
        background: #f8fbff;
    }

    .candidate-row.selected {
        background: #eff6ff;
    }

    .candidate-radio {
        width: 1.1rem;
        height: 1.1rem;
        accent-color: #2563eb;
        cursor: pointer;
    }

    .scope-checkbox {
        width: 1.05rem;
        height: 1.05rem;
        accent-color: #2563eb;
        cursor: pointer;
    }

    .partial-scope-panel {
        display: none;
    }

    .partial-scope-panel.is-visible {
        display: block;
    }

    .helper-table td,
    .helper-table th {
        vertical-align: middle;
    }
</style>
@endpush

@section('content')
@php
    $isDelegate = Auth::user()->role === \App\Enums\UserRole::DELEGATE;
    $routePrefix = $isDelegate ? 'delegate' : 'student';
    $roleLabels = [
        'student' => 'طالب',
        'delegate' => 'مندوب',
        'practical_delegate' => 'مندوب عملي',
    ];
@endphp

<div class="premium-header">
    <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-center gap-4 position-relative" style="z-index: 2;">
        <div>
            <span class="badge px-3 py-2 rounded-pill mb-3 fw-700" style="background: rgba(255,255,255,0.16); color: white;">
                {{ $delegationContext['scope_label'] }}
            </span>
            <h1 class="fw-900 mb-2" style="font-size: 2.2rem;">{{ $category->name }}</h1>
            <p class="text-white text-opacity-75 fw-700 m-0">
                {{ $category->subject->name }} | الحد الأعلى {{ $category->max_score }} درجة
            </p>
        </div>
        <div class="d-flex flex-wrap gap-2 justify-content-lg-end">
            <span class="meta-chip">{{ $delegationContext['major_name'] ?? '-' }}</span>
            <span class="meta-chip">{{ $delegationContext['level_name'] ?? '-' }}</span>
            <span class="meta-chip">{{ $delegationContext['student_scope_count'] }} طالب</span>
        </div>
    </div>
</div>

@if($errors->any())
    <div class="alert alert-danger border-0 rounded-4 shadow-sm">
        <div class="fw-800 mb-2">يوجد خطأ في البيانات المدخلة</div>
        <ul class="mb-0">
            @foreach($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

@if(session('error'))
    <div class="alert alert-danger border-0 rounded-4 shadow-sm">{{ session('error') }}</div>
@endif

@if(session('success'))
    <div class="alert alert-success border-0 rounded-4 shadow-sm">{{ session('success') }}</div>
@endif

<div class="row g-4 mb-4">
    <div class="col-12 col-xl-8">
        <div class="glass-card p-4 h-100">
            <h2 class="h5 fw-800 mb-3">بيانات التفويض</h2>
            <div class="row g-3">
                <div class="col-md-6">
                    <div class="scope-box">
                        <div class="small text-secondary mb-1">المادة</div>
                        <div class="fw-800">{{ $delegationContext['subject_name'] }}</div>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="scope-box">
                        <div class="small text-secondary mb-1">الدكتور المعتمد</div>
                        <div class="fw-800">{{ $delegationContext['doctor_name'] ?? '-' }}</div>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="scope-box">
                        <div class="small text-secondary mb-1">نوع الوصول</div>
                        <div class="fw-800">{{ $delegationContext['access_mode'] === 'helper_task' ? 'مهمة مساعدة' : 'تفويض مباشر' }}</div>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="scope-box">
                        <div class="small text-secondary mb-1">النطاق</div>
                        <div class="fw-800">{{ $delegationContext['scope_label'] }}</div>
                    </div>
                </div>
            </div>

            @if($helperTask)
                <div class="mt-4 p-3 rounded-4" style="background: #fff7ed; border: 1px solid #fdba74;">
                    <div class="fw-800 text-dark">{{ $helperTask->title }}</div>
                    <div class="small text-secondary mt-1">
                        أسندها لك {{ $helperTask->delegatedBy?->name ?? '-' }}
                        @if($helperTask->due_at)
                            | الموعد: {{ $helperTask->due_at->format('Y-m-d H:i') }}
                        @endif
                    </div>
                    @if($helperTask->notes)
                        <div class="small mt-2 text-secondary">{{ $helperTask->notes }}</div>
                    @endif
                </div>
            @endif
        </div>
    </div>

    <div class="col-12 col-xl-4">
        <div class="glass-card p-4 h-100">
            <h2 class="h5 fw-800 mb-3">ملاحظات العمل</h2>
            <ul class="mb-0 text-secondary">
                <li>أي درجة تدخل من خلال هذه الصفحة تحفظ بحالة معلقة.</li>
                <li>الاعتماد النهائي يبقى للدكتور فقط.</li>
                @if($isDelegate && !$helperTask)
                    <li>يمكنك إنشاء مهام مساعدة داخل نفس الفئة، لكن المساعد لا يملك الاعتماد النهائي.</li>
                @endif
                @if($helperTask)
                    <li>أنت تعمل هنا كمساعد رصد، ولن تظهر الدرجات نهائيًا إلا بعد موافقة الدكتور.</li>
                @endif
            </ul>

            <div class="mt-4">
                <a href="{{ route($routePrefix . '.authorized-grades.index') }}" class="btn btn-outline-primary w-100 rounded-4 fw-800">
                    العودة إلى المهام
                </a>
            </div>
        </div>
    </div>
</div>

<div class="glass-card overflow-hidden mb-4">
    <form action="{{ route($routePrefix . '.authorized-grades.store', $category->id) }}" method="POST">
        @csrf
        <div class="table-responsive">
            <table class="table align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th class="ps-4">الطالب</th>
                        <th>رقم القيد</th>
                        <th>الدور</th>
                        <th>الدرجة الحالية</th>
                        <th>الحالة</th>
                        <th class="text-center">أدخل الدرجة</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($students as $student)
                        @php
                            $currentGrade = $student->grades->first();
                            $roleKey = $student->role->value ?? $student->role;
                        @endphp
                        <tr>
                            <td class="ps-4 fw-700">{{ $student->name }}</td>
                            <td>{{ $student->student_number }}</td>
                            <td>{{ $roleLabels[$roleKey] ?? $roleKey }}</td>
                            <td>{{ $currentGrade?->score ?? '-' }}</td>
                            <td>
                                @if($currentGrade?->status === 'pending')
                                    <span class="badge text-bg-warning">قيد المراجعة</span>
                                @elseif($currentGrade?->status === 'approved')
                                    <span class="badge text-bg-success">معتمدة</span>
                                @elseif($currentGrade?->status === 'rejected')
                                    <span class="badge text-bg-danger">مرفوضة</span>
                                @else
                                    <span class="badge text-bg-secondary">لا توجد</span>
                                @endif
                            </td>
                            <td class="text-center">
                                <input type="hidden" name="grades[{{ $loop->index }}][student_id]" value="{{ $student->id }}">
                                <input type="number"
                                       name="grades[{{ $loop->index }}][score]"
                                       class="form-control grade-input mx-auto @error('grades.' . $loop->index . '.score') is-invalid @enderror"
                                       step="0.5"
                                       min="0"
                                       max="{{ $category->max_score }}"
                                       value="{{ old('grades.' . $loop->index . '.score', $currentGrade?->score) }}"
                                       placeholder="0.0">
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="text-center py-5 text-secondary">لا يوجد طلاب ضمن هذا النطاق.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="p-4 border-top d-flex flex-column flex-lg-row justify-content-between gap-3 align-items-lg-center">
            <div class="text-secondary small">
                أي درجة تدخلها هنا ستبقى معلقة حتى يراجعها الدكتور.
            </div>
            <button type="submit" class="btn btn-primary rounded-4 fw-800 px-4">
                حفظ وإرسال للمراجعة
            </button>
        </div>
    </form>
</div>

@if($isDelegate && !$helperTask)
    <div class="glass-card mb-4">
        <div class="p-4 border-bottom">
            <h2 class="h5 fw-800 mb-1">تفويض مساعد جديد</h2>
            <p class="text-secondary mb-0">
                استخدم نفس منطق التفويض المعتمد للدكتور: راجع الصلاحيات الحالية أولًا، ثم اختر المساعد من قائمة واضحة تعرض الاسم ورقم القيد والدور.
            </p>
        </div>

        @if($delegateHelperTasks->isNotEmpty())
            <div class="p-4 border-bottom">
                <div class="fw-800 mb-3">المهام المساعدة الحالية</div>
                <div class="row g-3">
                    @foreach($delegateHelperTasks as $task)
                        @php
                            $helperRoleKey = $task->helperUser?->role->value ?? $task->helperUser?->role;
                        @endphp
                        <div class="col-md-6">
                            <div class="p-3 rounded-4 border bg-white d-flex justify-content-between align-items-center gap-3 h-100">
                                <div class="d-flex align-items-center gap-3">
                                    <div class="avatar-circle">{{ mb_substr($task->helperUser?->name ?? '-', 0, 1) }}</div>
                                    <div>
                                        <div class="fw-900 text-dark small">{{ $task->helperUser?->name ?? '-' }}</div>
                                        <div class="text-secondary fw-700" style="font-size: 11px;">رقم القيد: {{ $task->helperUser?->student_number ?? '-' }}</div>
                                        <div class="delegate-pill mt-2">{{ $roleLabels[$helperRoleKey] ?? $helperRoleKey }}</div>
                                        <div class="small text-secondary mt-2">
                                            {{ $task->title }} |
                                            {{ $task->delegation_type === 'partial' ? 'تفويض جزئي' : 'تفويض كامل' }}
                                        </div>
                                    </div>
                                </div>
                                <form action="{{ route('delegate.authorized-grades.helpers.revoke', $task) }}" method="POST" onsubmit="return confirm('هل تريد سحب هذه المهمة؟');">
                                    @csrf
                                    @method('DELETE')
                                    <button class="btn btn-link text-danger p-2 rounded-3">
                                        <i class="fa-solid fa-user-minus"></i>
                                    </button>
                                </form>
                            </div>
                        </div>
                    @endforeach
                </div>
            </div>
        @endif

        <form action="{{ route('delegate.authorized-grades.helpers.store', $category->id) }}" method="POST" class="p-4">
            @csrf

            <div class="row g-3 mb-4">
                <div class="col-md-6">
                    <label class="form-label fw-700">عنوان المهمة</label>
                    <input type="text" name="title" class="form-control rounded-4" placeholder="مثال: رصد المجموعة الأولى" required>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-700">نوع التفويض</label>
                    <select name="delegation_type" class="form-select rounded-4" id="delegationTypeSelect" onchange="togglePartialScope()">
                        <option value="full">كامل على الفئة</option>
                        <option value="partial">جزئي على طلاب محددين</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-700">الموعد النهائي</label>
                    <input type="datetime-local" name="due_at" class="form-control rounded-4">
                </div>
                <div class="col-12">
                    <label class="form-label fw-700">ملاحظات</label>
                    <input type="text" name="notes" class="form-control rounded-4" placeholder="ملاحظات إضافية">
                </div>
            </div>

            <div class="candidate-wrapper mb-4">
                <div class="table-responsive">
                    <table class="table candidate-table">
                        <thead>
                            <tr>
                                <th style="width: 70px;" class="text-center">اختيار</th>
                                <th>الاسم</th>
                                <th>رقم القيد</th>
                                <th>الدور</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($delegateHelperCandidates as $candidate)
                                @php $candidateRoleKey = $candidate->role->value ?? $candidate->role; @endphp
                                <tr class="candidate-row">
                                    <td class="text-center">
                                        <input
                                            class="candidate-radio"
                                            type="radio"
                                            name="helper_user_id"
                                            value="{{ $candidate->id }}"
                                            onchange="highlightDelegateCandidate(this)"
                                            required
                                        >
                                    </td>
                                    <td class="fw-800">{{ $candidate->name }}</td>
                                    <td class="text-secondary fw-700">{{ $candidate->student_number ?? '-' }}</td>
                                    <td><span class="delegate-pill">{{ $roleLabels[$candidateRoleKey] ?? $candidateRoleKey }}</span></td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="4" class="text-center py-4 text-secondary fw-700">
                                        لا يوجد مستخدمون متاحون لإنشاء مهمة مساعدة حاليًا.
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>

            <div class="mb-4 partial-scope-panel" id="partialScopePanel">
                <label class="form-label fw-700">نطاق الطلاب في التفويض الجزئي</label>
                <div class="text-secondary small fw-700 mb-3">
                    اختر طالبًا واحدًا أو أكثر من الجدول التالي. هذا النطاق يطبق فقط عند اختيار التفويض الجزئي.
                </div>

                <div class="candidate-wrapper">
                    <div class="table-responsive">
                        <table class="table candidate-table mb-0">
                            <thead>
                                <tr>
                                    <th style="width: 70px;" class="text-center">تحديد</th>
                                    <th>الاسم</th>
                                    <th>رقم القيد</th>
                                    <th>الدور</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($delegateHelperStudentScope as $candidate)
                                    @php $candidateRoleKey = $candidate->role->value ?? $candidate->role; @endphp
                                    <tr class="candidate-row partial-student-row">
                                        <td class="text-center">
                                            <input
                                                class="scope-checkbox"
                                                type="checkbox"
                                                name="student_ids[]"
                                                value="{{ $candidate->id }}"
                                                onchange="highlightPartialStudent(this)"
                                            >
                                        </td>
                                        <td class="fw-800">{{ $candidate->name }}</td>
                                        <td class="text-secondary fw-700">{{ $candidate->student_number ?? '-' }}</td>
                                        <td><span class="delegate-pill">{{ $roleLabels[$candidateRoleKey] ?? $candidateRoleKey }}</span></td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="4" class="text-center py-4 text-secondary fw-700">
                                            لا يوجد طلاب متاحون لتحديد نطاق جزئي في هذه الفئة.
                                        </td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <div class="d-flex justify-content-end">
                <button type="submit" class="btn btn-delegate">
                    إنشاء مهمة مساعدة
                </button>
            </div>
        </form>
    </div>
@endif

<script>
    function highlightDelegateCandidate(input) {
        const table = input.closest('tbody');
        if (!table) return;

        table.querySelectorAll('.candidate-row').forEach((row) => row.classList.remove('selected'));
        input.closest('.candidate-row')?.classList.add('selected');
    }

    function togglePartialScope() {
        const delegationType = document.getElementById('delegationTypeSelect');
        const partialScopePanel = document.getElementById('partialScopePanel');

        if (!delegationType || !partialScopePanel) return;

        partialScopePanel.classList.toggle('is-visible', delegationType.value === 'partial');

        if (delegationType.value !== 'partial') {
            partialScopePanel.querySelectorAll('.scope-checkbox').forEach((checkbox) => {
                checkbox.checked = false;
            });

            partialScopePanel.querySelectorAll('.partial-student-row').forEach((row) => {
                row.classList.remove('selected');
            });
        }
    }

    function highlightPartialStudent(input) {
        input.closest('.partial-student-row')?.classList.toggle('selected', input.checked);
    }

    document.addEventListener('DOMContentLoaded', togglePartialScope);
</script>
@endsection
