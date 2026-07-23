@extends('layouts.admin')

@section('title', 'إدارة التخصصات')

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
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        box-shadow: 0 4px 12px -2px rgba(16, 185, 129, 0.4);
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

    .stat-icon.green {
        background: rgba(16, 185, 129, 0.1);
        color: #10b981;
    }

    .stat-icon.blue {
        background: rgba(59, 130, 246, 0.1);
        color: #3b82f6;
    }

    .stat-icon.purple {
        background: rgba(124, 58, 237, 0.1);
        color: #7c3aed;
    }

    .stat-icon.amber {
        background: rgba(245, 158, 11, 0.1);
        color: #f59e0b;
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
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
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

    .automation-section {
        margin-top: 1.5rem;
        padding: 1.25rem;
        background: linear-gradient(135deg, #f0fdf4, #ecfdf5);
        border: 1px solid #bbf7d0;
        border-radius: 12px;
    }

    .automation-section h4 {
        font-size: 0.95rem;
        font-weight: 700;
        color: #166534;
        margin-bottom: 1rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .automation-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1rem;
    }

    .automation-section small {
        display: block;
        margin-top: 0.75rem;
        color: #16a34a;
        font-size: 0.8rem;
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
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
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
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
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
        margin-top: 1.5rem;
    }

    .btn-submit:hover {
        box-shadow: 0 4px 15px -3px rgba(16, 185, 129, 0.4);
        transform: translateY(-1px);
    }

    .structure-badge {
        display: inline-flex;
        align-items: center;
        gap: 0.25rem;
        background: #f0fdf4;
        color: #166534;
        padding: 0.25rem 0.5rem;
        border-radius: 6px;
        font-size: 0.75rem;
        font-weight: 600;
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
    editCollegeId: '',
    editHasClinical: false,
    editHasSemesters: false
}">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
                <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
            </svg>
        </div>
        <div class="page-header-text">
            <h1>إدارة التخصصات</h1>
            <p>إضافة وتعديل التخصصات الأكاديمية وإنشاء الهياكل التعليمية</p>
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
            <div class="stat-icon green">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
                    <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
                </svg>
            </div>
            <div class="stat-info">
                <h3>{{ $majors->count() }}</h3>
                <p>إجمالي التخصصات</p>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon blue">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="4" y="4" width="16" height="16" rx="2"></rect>
                </svg>
            </div>
            <div class="stat-info">
                <h3>{{ $majors->sum(fn($m) => $m->levels->count()) }}</h3>
                <p>إجمالي المستويات</p>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon purple">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                    <line x1="16" y1="2" x2="16" y2="6"></line>
                    <line x1="8" y1="2" x2="8" y2="6"></line>
                    <line x1="3" y1="10" x2="21" y2="10"></line>
                </svg>
            </div>
            <div class="stat-info">
                <h3>{{ $majors->sum(fn($m) => $m->levels->sum(fn($l) => $l->terms->count())) }}</h3>
                <p>إجمالي الفصول</p>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon amber">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                    <circle cx="9" cy="7" r="4"></circle>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                </svg>
            </div>
            <div class="stat-info">
                <h3>{{ \App\Models\User::where('role', 'student')->count() }}</h3>
                <p>إجمالي الطلاب</p>
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
                <h3>إضافة تخصص جديد</h3>
            </div>

            <form action="{{ route('admin.majors.store') }}" method="POST">
                @csrf

                <div class="form-group">
                    <label for="college_id" class="form-label">الكلية التابعة لها</label>
                    <div class="input-with-icon">
                        <span class="icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="4" y="4" width="16" height="16" rx="2"></rect>
                            </svg>
                        </span>
                        <select name="college_id" id="college_id" class="form-control" required>
                            <option value="">اختر الكلية...</option>
                            @foreach($universities as $university)
                            <optgroup label="{{ $university->name }}">
                                @foreach($university->colleges as $college)
                                <option value="{{ $college->id }}">{{ $college->name }}</option>
                                @endforeach
                            </optgroup>
                            @endforeach
                        </select>
                    </div>
                </div>

                <div class="form-group">
                    <label for="name" class="form-label">اسم التخصص</label>
                    <div class="input-with-icon">
                        <span class="icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
                            </svg>
                        </span>
                        <input type="text" name="name" id="name" class="form-control" placeholder="مثال: هندسة البرمجيات" required>
                    </div>
                </div>

                <!-- Automation Section -->
                <div class="automation-section">
                    <h4>
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"></path>
                        </svg>
                        الإعداد التلقائي للهيكل
                    </h4>
                    <div class="automation-grid">
                        <div class="form-group" style="margin-bottom: 0;">
                            <label for="levels_count" class="form-label">عدد المستويات</label>
                            <input type="number" name="levels_count" id="levels_count" class="form-control" value="4" min="1" max="7" required>
                        </div>
                        <div class="form-group" style="margin-bottom: 0;">
                            <label for="terms_count" class="form-label">الفصول لكل مستوى</label>
                            <input type="number" name="terms_count" id="terms_count" class="form-control" value="2" min="1" max="4" required>
                        </div>
                    </div>
                    <small>سيقوم النظام بإنشاء المستويات والفصول تلقائياً</small>
                </div>

                @if($ownerPresentationMode)
                <input type="hidden" name="has_clinical" value="0">
                <input type="hidden" name="has_semesters" value="0">
                <input type="hidden" name="semesters_per_term" value="0">
                @else
                {{-- Clinical Training Toggle --}}
                <div style="margin-top: 1rem; padding: 0.875rem; background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 10px;">
                    <label style="display: flex; align-items: center; gap: 0.75rem; cursor: pointer; font-weight: 600; color: #1e40af; font-size: 0.9rem;">
                        <input type="checkbox" name="has_clinical" value="1" style="width: 18px; height: 18px; accent-color: #3b82f6;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                            <circle cx="8.5" cy="7" r="4"></circle>
                            <polyline points="17 11 19 13 23 9"></polyline>
                        </svg>
                        يحتوي على تدريب عملي (سريري)
                    </label>
                    <small style="display: block; margin-top: 0.5rem; color: #3b82f6; font-size: 0.78rem;">فعّل هذا الخيار إذا كان التخصص يتطلب تدريباً عملياً ويحتاج مندوب عملي</small>
                </div>

                {{-- Semester System Toggle --}}
                <div x-data="{ hasSemesters: false }" style="margin-top: 1rem; padding: 0.875rem; background: #faf5ff; border: 1px solid #e9d5ff; border-radius: 10px;">
                    <label style="display: flex; align-items: center; gap: 0.75rem; cursor: pointer; font-weight: 600; color: #6b21a8; font-size: 0.9rem;">
                        <input type="checkbox" name="has_semesters" value="1" x-model="hasSemesters" style="width: 18px; height: 18px; accent-color: #a855f7;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M4 7V4a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v3"></path>
                            <path d="M9 2v4"></path>
                            <path d="M15 2v4"></path>
                            <rect x="2" y="7" width="20" height="14" rx="2"></rect>
                            <path d="M2 12h20"></path>
                        </svg>
                        يحتوي على نظام سيمسترات (داخل الأترام)
                    </label>
                    <div x-show="hasSemesters" x-transition style="margin-top: 1rem; padding-top: 1rem; border-top: 1px dashed #d8b4fe;">
                        <label for="semesters_per_term" class="form-label" style="color: #6b21a8;">عدد السيمسترات في كل ترم</label>
                        <input type="number" name="semesters_per_term" id="semesters_per_term" class="form-control" value="0" min="0" max="10" style="border-color: #d8b4fe;">
                        <small style="display: block; margin-top: 0.5rem; color: #7e22ce; font-size: 0.78rem;">سيتم تقسيم كل ترم إلى هذا العدد من السيمسترات</small>
                    </div>
                </div>
                @endif

                <button type="submit" class="btn-submit">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                        <polyline points="17 21 17 13 7 13 7 21"></polyline>
                    </svg>
                    حفظ وإنشاء الهيكل
                </button>
            </form>
        </div>

        <!-- Table Card -->
        <div class="table-card">
            <div class="table-card-header">
                <h3>
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
                    </svg>
                    قائمة التخصصات
                </h3>
                <span class="count-badge">{{ $majors->count() }} تخصص</span>
            </div>

            <div class="table-responsive">
<table class="modern-table">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>التخصص</th>
                        <th>الكلية / الجامعة</th>
                        <th>الهيكل الأكاديمي</th>
                        <th>الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($majors as $major)
                    <tr>
                        <td style="font-weight: 600; color: var(--text-secondary);">{{ $loop->iteration }}</td>
                        <td style="font-weight: 600;">
                            {{ $major->name }}
                            @if($major->has_clinical)
                            <span style="display: inline-flex; align-items: center; gap: 0.2rem; background: #dbeafe; color: #1d4ed8; padding: 0.15rem 0.4rem; border-radius: 5px; font-size: 0.7rem; font-weight: 700; margin-right: 0.35rem;">🏥 عملي</span>
                            @endif
                            @if($major->has_semesters)
                            <span style="display: inline-flex; align-items: center; gap: 0.2rem; background: #f3e8ff; color: #7e22ce; padding: 0.15rem 0.4rem; border-radius: 5px; font-size: 0.7rem; font-weight: 700; margin-right: 0.35rem;">🗓️ سيمسترات</span>
                            @endif
                        </td>
                        <td>
                            <span class="badge badge-warning">{{ $major->college->name }}</span>
                            <div style="font-size: 0.75rem; color: var(--text-secondary); margin-top: 0.25rem;">{{ $major->college->university->name }}</div>
                        </td>
                        <td>
                            <div style="display: flex; gap: 0.5rem;">
                                <span class="structure-badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <rect x="3" y="3" width="7" height="7"></rect>
                                        <rect x="14" y="3" width="7" height="7"></rect>
                                        <rect x="14" y="14" width="7" height="7"></rect>
                                        <rect x="3" y="14" width="7" height="7"></rect>
                                    </svg>
                                    {{ $major->levels->count() }} مستوى
                                </span>
                                <span class="structure-badge">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                                        <line x1="3" y1="10" x2="21" y2="10"></line>
                                    </svg>
                                    {{ $major->levels->sum(fn($l) => $l->terms->count()) }} ترم
                                </span>
                            </div>
                        </td>
                        <td>
                            <div style="display: flex; gap: 0.5rem;">
                                <button type="button" class="action-btn edit"
                                    @click="
                                        showEditModal = true;
                                        modalTitle = 'تعديل: {{ $major->name }}';
                                        editUrl = '{{ route('admin.majors.update', $major) }}';
                                        editName = '{{ $major->name }}';
                                        editCollegeId = '{{ $major->college_id }}';
                                        editHasClinical = {{ $major->has_clinical ? 'true' : 'false' }};
                                        editHasSemesters = {{ $major->has_semesters ? 'true' : 'false' }};
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
                                        deleteUrl = '{{ route('admin.majors.destroy', $major) }}';
                                        modalTitle = 'حذف {{ $major->name }}';
                                        modalMessage = 'سيؤدي حذف التخصص إلى حذف جميع المستويات ({{ $major->levels->count() }}) والترمات والمواد والطلاب.';
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
                                <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
                            </svg>
                            <div>لا توجد تخصصات مضافة حتى الآن</div>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
</div>
        </div>

    </div>

    <!-- Modals -->
    <x-delete-modal />

    <x-edit-modal>
        <form :action="editUrl" method="POST">
            @csrf
            @method('PUT')

            <div class="alert alert-info" style="font-size: 0.85rem; margin-bottom: 1.5rem;">
                ملاحظة: يمكنك تعديل الاسم والكلية فقط. لا يمكن تعديل عدد المستويات والترمات بعد الإنشاء.
            </div>

            <div class="form-group">
                <label for="edit_college_id" class="form-label">الكلية التابعة لها</label>
                <select name="college_id" id="edit_college_id" class="form-control" x-model="editCollegeId" required>
                    <option value="">اختر الكلية...</option>
                    @foreach($universities as $university)
                    <optgroup label="{{ $university->name }}">
                        @foreach($university->colleges as $college)
                        <option value="{{ $college->id }}">{{ $college->name }}</option>
                        @endforeach
                    </optgroup>
                    @endforeach
                </select>
            </div>

            <div class="form-group">
                <label for="edit_name" class="form-label">اسم التخصص</label>
                <input type="text" name="name" id="edit_name" class="form-control" x-model="editName" required>
            </div>

            @if($ownerPresentationMode)
            <input type="hidden" name="has_clinical" :value="editHasClinical ? 1 : 0">
            <input type="hidden" name="has_semesters" :value="editHasSemesters ? 1 : 0">
            @else
            {{-- Clinical Training Toggle --}}
            <div style="padding: 0.875rem; background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 10px;">
                <label style="display: flex; align-items: center; gap: 0.75rem; cursor: pointer; font-weight: 600; color: #1e40af; font-size: 0.9rem;">
                    <input type="checkbox" name="has_clinical" value="1" :checked="editHasClinical" style="width: 18px; height: 18px; accent-color: #3b82f6;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                        <circle cx="8.5" cy="7" r="4"></circle>
                        <polyline points="17 11 19 13 23 9"></polyline>
                    </svg>
                    يحتوي على تدريب عملي (سريري)
                </label>
            </div>

            {{-- Semester System Toggle Edit --}}
            <div style="margin-top: 1rem; padding: 0.875rem; background: #faf5ff; border: 1px solid #e9d5ff; border-radius: 10px;">
                <label style="display: flex; align-items: center; gap: 0.75rem; cursor: pointer; font-weight: 600; color: #6b21a8; font-size: 0.9rem;">
                    <input type="checkbox" name="has_semesters" value="1" :checked="editHasSemesters" style="width: 18px; height: 18px; accent-color: #a855f7;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M4 7V4a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v3"></path>
                        <rect x="2" y="7" width="20" height="14" rx="2"></rect>
                    </svg>
                    يحتوي على نظام سيمسترات
                </label>
                <small style="display: block; margin-top: 0.5rem; color: #7e22ce; font-size: 0.75rem;">تنبيه: تغيير هذا الخيار لن يغير الهيكل المنشأ مسبقاً.</small>
            </div>
            @endif

            <div class="modal-actions">
                <button type="button" class="btn btn-secondary" @click="showEditModal = false">إلغاء</button>
                <button type="submit" class="btn btn-primary">حفظ التغييرات</button>
            </div>
        </form>
    </x-edit-modal>

</div>

@endsection
