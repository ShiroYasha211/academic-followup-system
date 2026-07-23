@extends('layouts.doctor')

@section('title', 'درجات ' . $subject->name)

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
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 1.5rem;
        flex-wrap: wrap;
        gap: 1rem;
    }

    .page-title {
        font-size: 1.5rem;
        font-weight: 800;
        color: var(--text-primary);
    }

    .header-actions {
        display: flex;
        gap: 0.75rem;
        align-items: center;
        flex-wrap: wrap;
    }

    .search-box {
        display: flex;
        align-items: center;
        background: white;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
        padding: 0.5rem 1rem;
        gap: 0.5rem;
    }

    .search-box input {
        border: none;
        outline: none;
        font-size: 0.9rem;
        width: 180px;
    }

    .btn-report {
        padding: 0.6rem 1.25rem;
        background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
        color: white;
        border: none;
        border-radius: 10px;
        font-weight: 600;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
    }

    .stats-row {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
        gap: 1rem;
        margin-bottom: 1.5rem;
    }

    .stat-mini {
        background: white;
        border-radius: 12px;
        border: 1px solid #e2e8f0;
        padding: 1rem;
        text-align: center;
    }

    .stat-mini-value {
        font-size: 1.5rem;
        font-weight: 700;
    }

    .stat-mini-label {
        font-size: 0.75rem;
        color: var(--text-secondary);
    }

    .grades-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
    }

    .grades-header {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid #e2e8f0;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .grades-table {
        width: 100%;
        border-collapse: collapse;
    }

    .grades-table th {
        padding: 0.875rem 1rem;
        background: #f8fafc;
        font-weight: 700;
        color: var(--text-primary);
        text-align: right;
        font-size: 0.8rem;
        border-bottom: 1px solid #e2e8f0;
    }

    .grades-table td {
        padding: 0.75rem 1rem;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
    }

    .grades-table tr:hover {
        background: #f8fafc;
    }

    .student-cell {
        display: flex;
        align-items: center;
        gap: 0.6rem;
    }

    .student-avatar {
        width: 32px;
        height: 32px;
        border-radius: 8px;
        background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        color: #4f46e5;
        font-size: 0.8rem;
    }

    .student-name {
        font-weight: 600;
        color: var(--text-primary);
        font-size: 0.9rem;
    }

    .student-number {
        font-size: 0.75rem;
        color: var(--text-secondary);
    }

    .grade-input {
        width: 70px;
        padding: 0.4rem 0.6rem;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        text-align: center;
        font-size: 0.9rem;
        font-weight: 600;
    }

    .grade-input:focus {
        outline: none;
        border-color: var(--primary-color);
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
    }

    .total-cell {
        font-weight: 700;
        font-size: 1rem;
    }

    .total-cell.pass {
        color: #10b981;
    }

    .total-cell.fail {
        color: #ef4444;
    }

    .btn-save {
        padding: 0.75rem 1.5rem;
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        color: white;
        border: none;
        border-radius: 12px;
        font-weight: 700;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
    }

    .btn-save:hover {
        box-shadow: 0 4px 12px -2px rgba(16, 185, 129, 0.4);
    }

    .grades-footer {
        padding: 1.25rem 1.5rem;
        border-top: 1px solid #e2e8f0;
        display: flex;
        justify-content: flex-end;
    }

    .btn-note {
        width: 28px;
        height: 28px;
        border-radius: 6px;
        border: 1px solid #e2e8f0;
        background: white;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--text-secondary);
        transition: all 0.2s;
    }

    .btn-note:hover {
        background: #eff6ff;
        border-color: var(--primary-color);
        color: var(--primary-color);
    }

    .btn-note.has-notes {
        background: #fef3c7;
        border-color: #f59e0b;
        color: #92400e;
    }

    /* Modal styles */
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

    .note-textarea {
        width: 100%;
        padding: 0.75rem;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
        resize: vertical;
        min-height: 100px;
        font-family: inherit;
    }

    .notes-list {
        margin-bottom: 1rem;
    }

    .note-item {
        padding: 0.75rem;
        background: #f8fafc;
        border-radius: 8px;
        margin-bottom: 0.5rem;
        border-right: 3px solid #4f46e5;
    }

    .note-date {
        font-size: 0.75rem;
        color: var(--text-secondary);
        margin-bottom: 0.25rem;
    }
</style>

<a href="{{ route('doctor.grades.index') }}" class="back-link">
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="15 18 9 12 15 6"></polyline>
    </svg>
    العودة للمقررات
</a>

<div class="page-header">
    <div>
        <h1 class="page-title">{{ $subject->name }}</h1>
        <div style="font-size: 0.85rem; color: var(--text-secondary); margin-top: 0.25rem;">
            {{ $subject->major->name ?? '' }} • {{ $subject->level->name ?? '' }}
        </div>
    </div>
    <div class="header-actions">
        <form method="GET" class="search-box">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--text-secondary);">
                <circle cx="11" cy="11" r="8"></circle>
                <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
            </svg>
            <input type="text" name="search" placeholder="بحث عن طالب..." value="{{ $search ?? '' }}">
        </form>
        <a href="{{ route('doctor.grades.categories.index', $subject->id) }}" class="btn-report" style="background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="3" width="7" height="7"></rect>
                <rect x="14" y="3" width="7" height="7"></rect>
                <rect x="14" y="14" width="7" height="7"></rect>
                <rect x="3" y="14" width="7" height="7"></rect>
            </svg>
            تقسيم أعمال السنة
        </a>
        <a href="{{ route('doctor.grades.delegations.index', $subject->id) }}" class="btn-report" style="background: linear-gradient(135deg, #0ea5e9 0%, #2563eb 100%);">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                <circle cx="9" cy="7" r="4"></circle>
                <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
            </svg>
            مركز تفويض الطلاب
        </a>
        <a href="{{ route('doctor.grades.approvals.index', $subject->id) }}" class="btn-report position-relative" style="background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
            مراجعة الاعتمادات
            @if($pendingCount > 0)
                <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger border border-light" style="font-size: 0.6rem;">
                    {{ $pendingCount }}
                </span>
            @endif
        </a>
        <a href="{{ route('doctor.grades.report', $subject->id) }}" class="btn-report">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="18" y1="20" x2="18" y2="10"></line>
                <line x1="12" y1="20" x2="12" y2="4"></line>
                <line x1="6" y1="20" x2="6" y2="14"></line>
            </svg>
            التقرير الشامل
        </a>
    </div>
</div>

@if($pendingCount > 0)
    <div class="alert alert-warning border-0 shadow-sm rounded-4 mb-4 fw-700 p-3 d-flex justify-content-between align-items-center">
        <div class="d-flex align-items-center gap-3">
            <div class="bg-warning bg-opacity-20 p-2 rounded-3 text-warning">
                <i class="fa-solid fa-clock-rotate-left fs-4"></i>
            </div>
            <div>
                <div class="text-dark">يوجد درجات معلقة بانتظار مراجعتك</div>
                <div class="small text-secondary opacity-75">قام الطلاب المفوضون برصد {{ $pendingCount }} درجة جديدة تحتاج لاعتمادك لتظهر في السجل.</div>
            </div>
        </div>
        <a href="{{ route('doctor.grades.approvals.index', $subject->id) }}" class="btn btn-warning btn-sm rounded-3 px-3 fw-800">انتقل للمراجعة</a>
    </div>
@endif

<!-- Quick Stats -->
<div class="stats-row">
    <div class="stat-mini">
        <div class="stat-mini-value" style="color: #3b82f6;">{{ $stats['students_count'] }}</div>
        <div class="stat-mini-label">طالب</div>
    </div>
    <div class="stat-mini">
        <div class="stat-mini-value" style="color: #8b5cf6;">{{ $stats['average'] }}</div>
        <div class="stat-mini-label">المعدل</div>
    </div>
    <div class="stat-mini">
        <div class="stat-mini-value" style="color: #10b981;">{{ $stats['passed'] }}</div>
        <div class="stat-mini-label">ناجح</div>
    </div>
    <div class="stat-mini">
        <div class="stat-mini-value" style="color: #ef4444;">{{ $stats['failed'] }}</div>
        <div class="stat-mini-label">راسب</div>
    </div>
    <div class="stat-mini">
        <div class="stat-mini-value" style="color: {{ $stats['pass_rate'] >= 60 ? '#10b981' : '#f59e0b' }};">{{ $stats['pass_rate'] }}%</div>
        <div class="stat-mini-label">نسبة النجاح</div>
    </div>
</div>

@if(session('success'))
<div class="alert alert-success mb-4">{{ session('success') }}</div>
@endif

<form action="{{ route('doctor.grades.store', $subject->id) }}" method="POST">
    @csrf

    <div class="grades-card">
        <div class="grades-header">
            <h3 style="font-weight: 700; font-size: 1rem;">
                الطلاب ({{ $students->count() }})
            </h3>
            <div style="font-size: 0.8rem; color: var(--text-secondary);">
                أعمال السنة مجموعها (40) | النهائي (60)
            </div>
        </div>

        <div class="table-responsive">
        <table class="grades-table">
            <thead>
                <tr>
                    <th style="width: 40px;">#</th>
                    <th>الطالب</th>
                    <th style="width: 100px;">أعمال (أخرى)</th>
                    <th>تفصيل الأعمال</th>
                    <th style="width: 100px;">إجمالي (40)</th>
                    <th style="width: 100px;">نهائي (60)</th>
                    <th style="width: 80px;">المجموع</th>
                    <th style="width: 60px;">ملاحظة</th>
                </tr>
            </thead>
            <tbody>
                @forelse($students as $index => $student)
                @php
                    $generalContinuous = $student->grades->where('type', 'continuous')->where('category_id', null)->first()->score ?? 0;
                    $final = $student->final_grade->score ?? 0;
                    $total = $student->total;
                @endphp
                <tr>
                    <td>{{ $index + 1 }}</td>
                    <td>
                        <div class="student-cell">
                            <div class="student-avatar">{{ mb_substr($student->name, 0, 1) }}</div>
                            <div>
                                <div class="student-name">{{ $student->name }}</div>
                                <div class="student-number">{{ $student->student_number ?? '-' }}</div>
                            </div>
                        </div>
                    </td>
                    <td>
                        <input type="hidden" name="grades[{{ $index }}][student_id]" value="{{ $student->id }}">
                        <input
                            type="number"
                            name="grades[{{ $index }}][continuous]"
                            class="grade-input continuous-input"
                            data-row="{{ $index }}"
                            value="{{ $generalContinuous }}"
                            min="0"
                            max="40"
                            step="0.5">
                    </td>
                    <td>
                        <div class="d-flex flex-wrap gap-2">
                            @foreach($categories as $cat)
                                @php 
                                    $catGrade = $student->grades->where('category_id', $cat->id)->first();
                                @endphp
                                <div class="d-flex flex-column align-items-center gap-1 p-1 rounded-3 {{ $catGrade ? ($catGrade->status === 'pending' ? 'bg-warning-subtle' : '') : '' }}" style="min-width: 60px; border: 1px dashed #e2e8f0;">
                                    <label class="small fw-800 text-secondary mb-0" style="font-size: 0.6rem;">{{ $cat->name }}</label>
                                    <input
                                        type="number"
                                        name="grades[{{ $index }}][categories][{{ $cat->id }}]"
                                        class="grade-input category-input"
                                        data-row="{{ $index }}"
                                        data-max="{{ $cat->max_score }}"
                                        value="{{ $catGrade ? $catGrade->score : 0 }}"
                                        min="0"
                                        max="{{ $cat->max_score }}"
                                        step="0.5"
                                        style="width: 50px; font-size: 0.75rem; padding: 0.2rem;"
                                        title="الدرجة العظمى: {{ $cat->max_score }}">
                                </div>
                            @endforeach
                            @if($categories->isEmpty())
                                <span class="text-secondary opacity-50 small text-center w-100">لا يوجد تقسيم مضاف</span>
                            @endif
                        </div>
                    </td>
                    <td>
                        <span class="total-cell" id="total-continuous-{{ $index }}" data-category-sum="{{ $student->continuous_grade_score - $generalContinuous }}" style="color: var(--primary-color);">
                            {{ $student->continuous_grade_score }}
                        </span>
                    </td>
                    <td>
                        <input
                            type="number"
                            name="grades[{{ $index }}][final]"
                            class="grade-input final-input"
                            data-row="{{ $index }}"
                            value="{{ $final }}"
                            min="0"
                            max="60"
                            step="0.5">
                    </td>
                    <td>
                        <span class="total-cell {{ $total >= 60 ? 'pass' : 'fail' }}" id="total-{{ $index }}">
                            {{ $total }}
                        </span>
                    </td>
                    <td>
                        <button type="button" class="btn-note {{ $student->notes->count() > 0 ? 'has-notes' : '' }}"
                            onclick="openNoteModal({{ $student->id }}, '{{ $student->name }}', {{ json_encode($student->notes) }})"
                            title="{{ $student->notes->count() }} ملاحظات">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
                            </svg>
                        </button>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="8" style="text-align: center; padding: 3rem;">
                        @if($search)
                        لا يوجد نتائج للبحث "{{ $search }}"
                        @else
                        لا يوجد طلاب في هذا المقرر
                        @endif
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
        </div>

        @if($students->count() > 0)
        <div class="grades-footer">
            <button type="submit" class="btn-save">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                    <polyline points="17 21 17 13 7 13 7 21"></polyline>
                    <polyline points="7 3 7 8 15 8"></polyline>
                </svg>
                حفظ الدرجات
            </button>
        </div>
        @endif
    </div>
</form>

<!-- Note Modal -->
<div class="modal-overlay" id="noteModal">
    <div class="modal-content">
        <div class="modal-header">
            <h4 style="font-weight: 700;">ملاحظات الطالب: <span id="modalStudentName"></span></h4>
            <button onclick="closeNoteModal()" style="background: none; border: none; cursor: pointer;">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>
        </div>
        <form id="noteForm" method="POST">
            @csrf
            <div class="modal-body">
                <div class="notes-list" id="notesList"></div>
                <label style="font-weight: 600; display: block; margin-bottom: 0.5rem;">إضافة ملاحظة جديدة:</label>
                <textarea name="note" class="note-textarea" placeholder="اكتب ملاحظتك للطالب... (ستظهر له كإشعار)" required></textarea>
                <p style="font-size: 0.8rem; color: var(--text-secondary); margin-top: 0.5rem;">
                    ⚡ الطالب سيرى هذه الملاحظة كإشعار ولن يستطيع الرد عليها
                </p>
            </div>
            <div class="modal-footer">
                <button type="button" onclick="closeNoteModal()" style="padding: 0.6rem 1.25rem; border: 1px solid #e2e8f0; background: white; border-radius: 10px; cursor: pointer;">
                    إلغاء
                </button>
                <button type="submit" class="btn-save" style="padding: 0.6rem 1.25rem;">
                    إرسال الملاحظة
                </button>
            </div>
        </form>
    </div>
</div>

<script>
    // Grade calculation
    document.querySelectorAll('.grade-input').forEach(input => {
        input.addEventListener('input', function() {
            const row = this.dataset.row;
            const continuousInput = document.querySelector(`.continuous-input[data-row="${row}"]`);
            const finalInput = document.querySelector(`.final-input[data-row="${row}"]`);
            const categoryInputs = document.querySelectorAll(`.category-input[data-row="${row}"]`);
            
            const totalContinuousCell = document.getElementById(`total-continuous-${row}`);
            
            // Calculate sum of categories
            let categorySum = 0;
            categoryInputs.forEach(catInput => {
                categorySum += parseFloat(catInput.value) || 0;
            });
            
            const generalContinuous = parseFloat(continuousInput.value) || 0;
            const final = parseFloat(finalInput.value) || 0;
            
            const totalContinuous = generalContinuous + categorySum;
            totalContinuousCell.textContent = totalContinuous;
            
            const total = totalContinuous + final;

            const totalCell = document.getElementById(`total-${row}`);
            totalCell.textContent = total;
            totalCell.className = 'total-cell ' + (total >= 60 ? 'pass' : 'fail');
        });
    });

    // Note modal
    const noteBaseUrl = "{{ url('doctor/grades/' . $subject->id . '/note') }}";

    function openNoteModal(studentId, studentName, notes) {
        document.getElementById('modalStudentName').textContent = studentName;
        document.getElementById('noteForm').action = noteBaseUrl + '/' + studentId;

        const notesList = document.getElementById('notesList');
        notesList.innerHTML = '';

        if (notes && notes.length > 0) {
            notes.forEach(note => {
                const date = new Date(note.created_at);
                notesList.innerHTML += `
                    <div class="note-item">
                        <div class="note-date">${date.toLocaleDateString('ar-SA')}</div>
                        <div>${note.note}</div>
                    </div>
                `;
            });
        } else {
            notesList.innerHTML = '<p style="color: var(--text-secondary); text-align: center; padding: 1rem;">لا توجد ملاحظات سابقة</p>';
        }

        document.getElementById('noteModal').classList.add('active');
    }

    function closeNoteModal() {
        document.getElementById('noteModal').classList.remove('active');
    }

    // Close modal on outside click
    document.getElementById('noteModal').addEventListener('click', function(e) {
        if (e.target === this) closeNoteModal();
    });
</script>

@endsection