@extends('layouts.admin')

@section('title', 'إدارة المواد الدراسية')

@section('content')

<style>
    .page-header {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .page-header-icon {
        width: 56px;
        height: 56px;
        background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        box-shadow: 0 4px 12px -2px rgba(245, 158, 11, 0.4);
    }

    .page-header-text h1 {
        font-size: 1.5rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.25rem;
    }

    .page-header-text p {
        color: var(--text-secondary);
        font-size: 0.9rem;
    }

    .stats-row {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: white;
        border-radius: 16px;
        padding: 1.25rem;
        border: 1px solid var(--border-color);
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .stat-icon {
        width: 48px;
        height: 48px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .stat-icon.amber {
        background: rgba(245, 158, 11, 0.1);
        color: #f59e0b;
    }

    .stat-icon.blue {
        background: rgba(59, 130, 246, 0.1);
        color: #3b82f6;
    }

    .stat-icon.green {
        background: rgba(16, 185, 129, 0.1);
        color: #10b981;
    }

    .stat-icon.purple {
        background: rgba(124, 58, 237, 0.1);
        color: #7c3aed;
    }

    .stat-info h3 {
        font-size: 1.75rem;
        font-weight: 700;
        line-height: 1;
        margin-bottom: 0.25rem;
    }

    .stat-info p {
        color: var(--text-secondary);
        font-size: 0.85rem;
    }

    .form-card {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        padding: 1.5rem;
    }

    .form-card-header {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        margin-bottom: 1.5rem;
        padding-bottom: 1rem;
        border-bottom: 1px solid var(--border-color);
    }

    .form-card-header .icon {
        width: 40px;
        height: 40px;
        background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
    }

    .form-card-header h3 {
        font-size: 1.1rem;
        font-weight: 700;
    }

    .input-with-icon {
        position: relative;
    }

    .input-with-icon .icon {
        position: absolute;
        right: 12px;
        top: 50%;
        transform: translateY(-50%);
        color: var(--text-light);
    }

    .input-with-icon input,
    .input-with-icon select {
        padding-right: 2.75rem;
    }

    .table-card {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        padding: 1.5rem;
    }

    .table-card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.5rem;
        padding-bottom: 1rem;
        border-bottom: 1px solid var(--border-color);
    }

    .table-card-header h3 {
        font-size: 1.1rem;
        font-weight: 700;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .count-badge {
        background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
        color: white;
        padding: 0.35rem 0.75rem;
        border-radius: 20px;
        font-size: 0.8rem;
        font-weight: 600;
    }

    .modern-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
    }

    .modern-table thead th {
        background: #f8fafc;
        padding: 1rem;
        text-align: right;
        font-weight: 600;
        color: var(--text-secondary);
        font-size: 0.85rem;
        border-bottom: 1px solid var(--border-color);
    }

    .modern-table thead th:first-child {
        border-radius: 0 12px 0 0;
    }

    .modern-table thead th:last-child {
        border-radius: 12px 0 0 0;
    }

    .modern-table tbody td {
        padding: 1rem;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
    }

    .modern-table tbody tr:hover {
        background: #fafafa;
    }

    .action-btn {
        padding: 0.5rem 0.875rem;
        border-radius: 8px;
        font-size: 0.8rem;
        font-weight: 600;
        border: none;
        cursor: pointer;
        transition: all 0.2s;
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
    }

    .action-btn.edit {
        background: #eff6ff;
        color: #3b82f6;
    }

    .action-btn.edit:hover {
        background: #dbeafe;
    }

    .action-btn.delete {
        background: #fef2f2;
        color: #ef4444;
    }

    .action-btn.delete:hover {
        background: #fee2e2;
    }

    .btn-submit {
        width: 100%;
        padding: 0.875rem;
        background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
        color: white;
        border: none;
        border-radius: 12px;
        font-size: 1rem;
        font-weight: 700;
        cursor: pointer;
        transition: all 0.3s;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
    }

    .btn-submit:hover {
        box-shadow: 0 4px 15px -3px rgba(245, 158, 11, 0.4);
        transform: translateY(-1px);
    }

    .doctor-avatar {
        width: 32px;
        height: 32px;
        background: linear-gradient(135deg, #e0e7ff, #c7d2fe);
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 0.75rem;
        font-weight: 700;
        color: #4f46e5;
    }

    .subject-code {
        display: inline-block;
        background: #fef3c7;
        color: #92400e;
        padding: 0.2rem 0.5rem;
        border-radius: 6px;
        font-size: 0.7rem;
        font-weight: 600;
        margin-top: 0.25rem;
    }

    .semester-badge {
        display: inline-flex;
        align-items: center;
        gap: 0.25rem;
        background: #f3e8ff;
        color: #7e22ce;
        padding: 0.15rem 0.4rem;
        border-radius: 5px;
        font-size: 0.7rem;
        font-weight: 700;
        margin-top: 0.25rem;
    }
</style>

<div x-data="{ 
    showDeleteModal: false, 
    showEditModal: false,
    deleteUrl: '', 
    modalTitle: '', 
    modalMessage: '',
    editUrl: '',
    editName: '',
    editCode: '',
    editTermId: '',
    editSemesterId: '',
    editDoctorId: '',
    
    // Terms data for dynamic semester filtering
    terms: [
        @foreach($terms as $term)
        {
            id: '{{ $term->id }}',
            has_semesters: {{ $term->level->major->has_semesters ? 'true' : 'false' }},
            semesters: [
                @foreach($term->semesters as $semester)
                { id: '{{ $semester->id }}', name: '{{ $semester->name }}' },
                @endforeach
            ]
        },
        @endforeach
    ],

    // State for create form
    selectedTermId: '',
    get selectedTerm() {
        return this.terms.find(t => t.id == this.selectedTermId);
    },

    // State for edit form
    editSelectedTermId: '',
    get editSelectedTerm() {
        return this.terms.find(t => t.id == this.editSelectedTermId);
    }
}">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
            </svg>
        </div>
        <div class="page-header-text">
            <h1>إدارة المواد الدراسية</h1>
            <p>إضافة وتعديل المواد الدراسية وتعيين المدرسين</p>
        </div>
    </div>

    <!-- Alerts -->
    @if(session('success'))
    <div class="alert alert-success" style="margin-bottom: 1.5rem;">{{ session('success') }}</div>
    @endif

    @if(session('error'))
    <div style="background: linear-gradient(135deg, #fef2f2, #fff); border: 1px solid #fecaca; border-right: 4px solid #ef4444; color: #991b1b; padding: 1rem 1.25rem; border-radius: 12px; margin-bottom: 1.5rem; display: flex; align-items: center; gap: 0.75rem;">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="12" y1="8" x2="12" y2="12"></line>
            <line x1="12" y1="16" x2="12.01" y2="16"></line>
        </svg>
        <span>{{ session('error') }}</span>
    </div>
    @endif

    <!-- Stats Row -->
    <div class="stats-row">
        <div class="stat-card">
            <div class="stat-icon amber">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                </svg>
            </div>
            <div class="stat-info">
                <h3>{{ $subjects->total() }}</h3>
                <p>إجمالي المواد</p>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon blue">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                    <circle cx="12" cy="7" r="4"></circle>
                </svg>
            </div>
            <div class="stat-info">
                <h3>{{ $doctors->count() }}</h3>
                <p>أعضاء هيئة التدريس</p>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon green">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
            </div>
            <div class="stat-info">
                <h3>{{ $subjects->where('doctor_id', '!=', null)->count() }}</h3>
                <p>مواد معين لها مدرس</p>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon purple">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="12" y1="8" x2="12" y2="12"></line>
                    <line x1="12" y1="16" x2="12.01" y2="16"></line>
                </svg>
            </div>
            <div class="stat-info">
                <h3>{{ $subjects->where('doctor_id', null)->count() }}</h3>
                <p>مواد بدون مدرس</p>
            </div>
        </div>
    </div>

    <!-- Main Grid -->
    <div style="display: grid; grid-template-columns: 1fr 2fr; gap: 1.5rem; align-items: start;">

        <!-- Create Form -->
        <div class="form-card">
            <div class="form-card-header">
                <div class="icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="12" y1="5" x2="12" y2="19"></line>
                        <line x1="5" y1="12" x2="19" y2="12"></line>
                    </svg>
                </div>
                <h3>إضافة مادة جديدة</h3>
            </div>

            <form action="{{ route('admin.subjects.store') }}" method="POST">
                @csrf

                <div class="form-group">
                    <label for="name" class="form-label">اسم المادة</label>
                    <div class="input-with-icon">
                        <span class="icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                                <path d="M6.5 2H20v20H6.5"></path>
                            </svg>
                        </span>
                        <input type="text" name="name" id="name" class="form-control" placeholder="مثال: برمجة 1" required>
                    </div>
                </div>

                <div class="form-group">
                    <label for="code" class="form-label">كود المادة (اختياري)</label>
                    <div class="input-with-icon">
                        <span class="icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="16 18 22 12 16 6"></polyline>
                                <polyline points="8 6 2 12 8 18"></polyline>
                            </svg>
                        </span>
                        <input type="text" name="code" id="code" class="form-control" placeholder="CS-101">
                    </div>
                </div>

                <div class="form-group">
                    <label for="term_id" class="form-label">الفصل الدراسي</label>
                    <div class="input-with-icon">
                        <span class="icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                                <line x1="3" y1="10" x2="21" y2="10"></line>
                            </svg>
                        </span>
                        <select name="term_id" id="term_id" class="form-control" required x-model="selectedTermId">
                            <option value="">اختر الترم...</option>
                            @foreach($terms as $term)
                            <option value="{{ $term->id }}">
                                {{ $term->name }} - {{ $term->level->name }}
                                ({{ $term->level->major->name }})
                            </option>
                            @endforeach
                        </select>
                    </div>
                </div>

                {{-- Dynamic Semester Selection --}}
                <div x-show="selectedTerm && selectedTerm.has_semesters" x-transition class="form-group" style="margin-top: 1rem; padding: 1rem; background: #faf5ff; border: 1px solid #e9d5ff; border-radius: 12px;">
                    <label for="semester_id" class="form-label" style="color: #6b21a8; font-weight: 700;">السيمستر</label>
                    <div class="input-with-icon">
                        <span class="icon" style="color: #a855f7;">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M4 7V4a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v3"></path>
                                <rect x="2" y="7" width="20" height="14" rx="2"></rect>
                            </svg>
                        </span>
                        <select name="semester_id" id="semester_id" class="form-control" style="border-color: #d8b4fe;" :required="selectedTerm && selectedTerm.has_semesters">
                            <option value="">اختر السيمستر...</option>
                            <template x-for="sem in (selectedTerm ? selectedTerm.semesters : [])" :key="sem.id">
                                <option :value="sem.id" x-text="sem.name"></option>
                            </template>
                        </select>
                    </div>
                    <small style="color: #7e22ce; font-size: 0.8rem; margin-top: 0.25rem; display: block;">يرجى تحديد السيمستر الصحيح داخل هذا الترم</small>
                </div>

                <div class="form-group">
                    <label for="doctor_id" class="form-label">مدرس المادة</label>
                    <div class="input-with-icon">
                        <span class="icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                                <circle cx="12" cy="7" r="4"></circle>
                            </svg>
                        </span>
                        <select name="doctor_id" id="doctor_id" class="form-control">
                            <option value="">بدون مدرس حالياً</option>
                            @foreach($doctors as $doctor)
                            <option value="{{ $doctor->id }}">{{ $doctor->name }}</option>
                            @endforeach
                        </select>
                    </div>
                </div>

                <button type="submit" class="btn-submit">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                        <polyline points="17 21 17 13 7 13 7 21"></polyline>
                    </svg>
                    حفظ المادة
                </button>
            </form>
        </div>

        <!-- Table Card -->
        <div class="table-card">
            <div class="table-card-header">
                <h3>
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                        <path d="M6.5 2H20v20H6.5"></path>
                    </svg>
                    قائمة المواد الدراسية
                </h3>
                <span class="count-badge">{{ $subjects->total() }} مادة</span>
            </div>

            {{-- Filter Bar --}}
            <div style="display: flex; gap: 0.75rem; margin-bottom: 1.25rem; flex-wrap: wrap;">
                <div style="flex: 1; min-width: 200px; position: relative;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" style="position: absolute; right: 12px; top: 50%; transform: translateY(-50%); pointer-events: none;">
                        <circle cx="11" cy="11" r="8"></circle>
                        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                    </svg>
                    <input type="text" id="subjectSearch" placeholder="ابحث عن مادة..." class="form-control" style="padding-right: 2.5rem; font-size: 0.88rem;" onkeyup="filterSubjects()">
                </div>
                <select id="majorFilter" class="form-control" style="flex: 0 0 220px; font-size: 0.88rem;" onchange="filterSubjects()">
                    <option value="">كل التخصصات</option>
                    @php
                    $uniqueMajors = $subjects->pluck('major.name')->unique()->filter()->sort();
                    @endphp
                    @foreach($uniqueMajors as $majorName)
                    <option value="{{ $majorName }}">{{ $majorName }}</option>
                    @endforeach
                </select>
            </div>

            <div class="table-responsive">
<table class="modern-table">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>المادة</th>
                        <th>الفصل / التخصص</th>
                        <th>المدرس</th>
                        <th>الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($subjects as $subject)
                    <tr data-name="{{ $subject->name }}" data-major="{{ $subject->major->name ?? '' }}">
                        <td style="font-weight: 600; color: var(--text-secondary);">{{ $loop->iteration }}</td>
                        <td>
                            <div style="font-weight: 600;">{{ $subject->name }}</div>
                            @if($subject->code)
                            <span class="subject-code">{{ $subject->code }}</span>
                            @endif
                        </td>
                        <td>
                            <div style="font-size: 0.9rem; font-weight: 600;">{{ $subject->term->name ?? '-' }}</div>
                            @if($subject->semester)
                            <div class="semester-badge">
                                <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M4 7V4a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v3"></path>
                                    <rect x="2" y="7" width="20" height="14" rx="2"></rect>
                                </svg>
                                {{ $subject->semester->name }}
                            </div>
                            @endif
                            <div style="font-size: 0.8rem; color: var(--text-secondary); margin-top: 0.2rem;">{{ $subject->major->name ?? '-' }}</div>
                        </td>
                        <td>
                            @if($subject->doctor)
                            <div style="display: flex; align-items: center; gap: 0.5rem;">
                                <div class="doctor-avatar">
                                    {{ mb_substr($subject->doctor->name, 0, 1) }}
                                </div>
                                <span style="font-size: 0.9rem;">{{ $subject->doctor->name }}</span>
                            </div>
                            @else
                            <span style="color: var(--text-light); font-size: 0.85rem;">غير معين</span>
                            @endif
                        </td>
                        <td>
                            <div style="display: flex; gap: 0.5rem;">
                                <button type="button" class="action-btn edit"
                                    @click="
                                        showEditModal = true;
                                        modalTitle = 'تعديل: {{ $subject->name }}';
                                        editUrl = '{{ route('admin.subjects.update', $subject) }}';
                                        editName = '{{ $subject->name }}';
                                        editCode = '{{ $subject->code }}';
                                        editTermId = '{{ $subject->term_id }}';
                                        editSelectedTermId = '{{ $subject->term_id }}';
                                        @if($subject->semester_id)
                                        editSemesterId = '{{ $subject->semester_id }}';
                                        @else
                                        editSemesterId = '';
                                        @endif
                                        editDoctorId = '{{ $subject->doctor_id }}';
                                    ">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                                    </svg>
                                    تعديل
                                </button>
                                <button type="button" class="action-btn delete"
                                    @click="
                                        showDeleteModal = true;
                                        deleteUrl = '{{ route('admin.subjects.destroy', $subject) }}';
                                        modalTitle = 'حذف {{ $subject->name }}';
                                        modalMessage = 'سيؤدي حذف المادة إلى حذف جميع سجلات الحضور الخاصة بها.';
                                    ">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <polyline points="3 6 5 6 21 6"></polyline>
                                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                                    </svg>
                                    حذف
                                </button>
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" style="text-align: center; padding: 3rem; color: var(--text-secondary);">
                            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5" style="margin-bottom: 1rem;">
                                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                                <path d="M6.5 2H20v20H6.5"></path>
                            </svg>
                            <div>لا توجد مواد مسجلة حتى الآن</div>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
</div>

            <!-- Pagination -->
            <div style="margin-top: 1.5rem;">
                {{ $subjects->links() }}
            </div>
        </div>

    </div>

    <!-- Modals -->
    <x-delete-modal />

    <x-edit-modal>
        <form :action="editUrl" method="POST">
            @csrf
            @method('PUT')

            <div class="form-group">
                <label for="edit_name" class="form-label">اسم المادة</label>
                <input type="text" name="name" id="edit_name" class="form-control" x-model="editName" required>
            </div>

            <div class="form-group">
                <label for="edit_code" class="form-label">كود المادة</label>
                <input type="text" name="code" id="edit_code" class="form-control" x-model="editCode">
            </div>

            <div class="form-group">
                <label for="edit_term_id" class="form-label">الفصل الدراسي</label>
                <select name="term_id" id="edit_term_id" class="form-control" x-model="editSelectedTermId" required>
                    <option value="">اختر الترم...</option>
                    @foreach($terms as $term)
                    <option value="{{ $term->id }}">
                        {{ $term->name }} - {{ $term->level->name }}
                        ({{ $term->level->major->name }})
                    </option>
                    @endforeach
                </select>
            </div>

            {{-- Dynamic Semester Selection Edit --}}
            <div x-show="editSelectedTerm && editSelectedTerm.has_semesters" x-transition class="form-group" style="margin-top: 1rem; padding: 1rem; background: #faf5ff; border: 1px solid #e9d5ff; border-radius: 12px;">
                <label for="edit_semester_id" class="form-label" style="color: #6b21a8; font-weight: 700;">السيمستر</label>
                <div class="input-with-icon">
                    <span class="icon" style="color: #a855f7;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M4 7V4a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v3"></path>
                            <rect x="2" y="7" width="20" height="14" rx="2"></rect>
                        </svg>
                    </span>
                    <select name="semester_id" id="edit_semester_id" class="form-control" style="border-color: #d8b4fe;" x-model="editSemesterId" :required="editSelectedTerm && editSelectedTerm.has_semesters">
                        <option value="">اختر السيمستر...</option>
                        <template x-for="sem in (editSelectedTerm ? editSelectedTerm.semesters : [])" :key="sem.id">
                            <option :value="sem.id" x-text="sem.name"></option>
                        </template>
                    </select>
                </div>
            </div>

            <div class="form-group">
                <label for="edit_doctor_id" class="form-label">مدرس المادة</label>
                <select name="doctor_id" id="edit_doctor_id" class="form-control" x-model="editDoctorId">
                    <option value="">بدون مدرس حالياً</option>
                    @foreach($doctors as $doctor)
                    <option value="{{ $doctor->id }}">{{ $doctor->name }}</option>
                    @endforeach
                </select>
            </div>

            <div class="modal-actions">
                <button type="button" class="btn btn-secondary" @click="showEditModal = false">إلغاء</button>
                <button type="submit" class="btn btn-primary">حفظ التغييرات</button>
            </div>
        </form>
    </x-edit-modal>

</div>

@endsection

@push('scripts')
<script>
    function filterSubjects() {
        const search = document.getElementById('subjectSearch').value.toLowerCase();
        const major = document.getElementById('majorFilter').value;
        const rows = document.querySelectorAll('.modern-table tbody tr[data-name]');
        rows.forEach(row => {
            const name = row.getAttribute('data-name').toLowerCase();
            const rowMajor = row.getAttribute('data-major');
            const matchSearch = !search || name.includes(search);
            const matchMajor = !major || rowMajor === major;
            row.style.display = (matchSearch && matchMajor) ? '' : 'none';
        });
    }
</script>
@endpush