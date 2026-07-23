@extends('layouts.admin')

@section('title', 'إدارة أعضاء هيئة التدريس')

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
        background: linear-gradient(135deg, #06b6d4 0%, #0891b2 100%);
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        box-shadow: 0 4px 12px -2px rgba(6, 182, 212, 0.4);
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
        grid-template-columns: repeat(3, 1fr);
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

    .stat-icon.cyan {
        background: rgba(6, 182, 212, 0.1);
        color: #06b6d4;
    }

    .stat-icon.blue {
        background: rgba(59, 130, 246, 0.1);
        color: #3b82f6;
    }

    .stat-icon.green {
        background: rgba(16, 185, 129, 0.1);
        color: #10b981;
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
        background: linear-gradient(135deg, #06b6d4 0%, #0891b2 100%);
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
        background: linear-gradient(135deg, #06b6d4 0%, #0891b2 100%);
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

    .action-btn.view {
        background: #f3f4f6;
        color: #6b7280;
    }

    .action-btn.view:hover {
        background: #e5e7eb;
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
        background: linear-gradient(135deg, #06b6d4 0%, #0891b2 100%);
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
        box-shadow: 0 4px 15px -3px rgba(6, 182, 212, 0.4);
        transform: translateY(-1px);
    }

    .doctor-avatar {
        width: 40px;
        height: 40px;
        background: linear-gradient(135deg, #e0f2fe, #cffafe);
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 0.9rem;
        font-weight: 700;
        color: #0891b2;
    }

    .doctors-filter-panel {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        padding: 1rem;
        margin-bottom: 1.25rem;
    }

    .doctors-filter-grid {
        display: grid;
        grid-template-columns: minmax(220px, 1.6fr) repeat(4, minmax(145px, 1fr));
        gap: 0.75rem;
        align-items: end;
    }

    .doctors-filter-field {
        min-width: 0;
    }

    .doctors-filter-field label {
        display: block;
        color: #475569;
        font-size: 0.78rem;
        font-weight: 700;
        margin-bottom: 0.4rem;
    }

    .doctors-filter-field .form-control {
        min-height: 42px;
        background: white;
        border-color: #dbe3ec;
        font-size: 0.86rem;
    }

    .doctors-filter-search {
        position: relative;
    }

    .doctors-filter-search svg {
        position: absolute;
        right: 0.85rem;
        top: 50%;
        transform: translateY(-50%);
        color: #94a3b8;
        pointer-events: none;
    }

    .doctors-filter-search input {
        padding-right: 2.6rem;
    }

    .doctors-filter-actions {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 0.75rem;
        margin-top: 0.9rem;
        padding-top: 0.9rem;
        border-top: 1px solid #e2e8f0;
    }

    .doctors-filter-buttons {
        display: flex;
        gap: 0.55rem;
    }

    .doctors-filter-apply,
    .doctors-filter-reset {
        min-height: 40px;
        border: 0;
        border-radius: 9px;
        padding: 0.6rem 1rem;
        font-size: 0.84rem;
        font-weight: 700;
        cursor: pointer;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 0.4rem;
        transition: transform 0.2s ease, background-color 0.2s ease;
    }

    .doctors-filter-apply {
        background: #0e7490;
        color: white;
    }

    .doctors-filter-apply:hover {
        background: #155e75;
        transform: translateY(-1px);
    }

    .doctors-filter-reset {
        background: white;
        color: #475569;
        border: 1px solid #dbe3ec;
    }

    .doctors-filter-reset:hover {
        background: #f1f5f9;
    }

    .doctors-filter-summary {
        color: #64748b;
        font-size: 0.82rem;
    }

    .doctors-filter-summary strong {
        color: #0f172a;
        font-variant-numeric: tabular-nums;
    }

    @media (max-width: 1200px) {
        .doctors-filter-grid {
            grid-template-columns: repeat(2, minmax(0, 1fr));
        }

        .doctors-filter-field:first-child {
            grid-column: 1 / -1;
        }
    }

    @media (max-width: 900px) {
        .stats-row,
        div[style*="grid-template-columns: 1fr 2fr"] {
            grid-template-columns: 1fr !important;
        }
    }

    @media (max-width: 640px) {
        .doctors-filter-grid {
            grid-template-columns: 1fr;
        }

        .doctors-filter-field:first-child {
            grid-column: auto;
        }

        .doctors-filter-actions {
            align-items: stretch;
            flex-direction: column;
        }

        .doctors-filter-buttons {
            width: 100%;
        }

        .doctors-filter-apply,
        .doctors-filter-reset {
            flex: 1;
        }
    }
</style>

<div x-data="{ 
    showDeleteModal: false, 
    showEditModal: false,
    showRoleModal: false,
    showDetailsModal: false,
    deleteUrl: '', 
    modalTitle: '', 
    modalMessage: '',
    
    editUrl: '',
    roleUrl: '',
    roleDoctorName: '',
    editName: '',
    editEmail: '',
    editCollegeId: '',
    editAdministrativeAccess: false,
    filterUniversity: @js((string) request('university_id', '')),
    filterCollege: @js((string) request('college_id', '')),
    filterColleges: @js($universities->flatMap(fn($university) => $university->colleges->map(fn($college) => [
        'id' => (string) $college->id,
        'university_id' => (string) $university->id,
        'name' => $college->name,
        'university_name' => $university->name,
    ]))->values()),
    get visibleFilterColleges() {
        if (!this.filterUniversity) return this.filterColleges;
        return this.filterColleges.filter(college => college.university_id === this.filterUniversity);
    },
    
    viewDoctor: {},
    viewSubjects: []
}">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                <circle cx="9" cy="7" r="4"></circle>
                <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
            </svg>
        </div>
        <div class="page-header-text">
            <h1>أعضاء هيئة التدريس</h1>
            <p>إدارة الدكاترة وتعيين المواد الدراسية</p>
        </div>
    </div>

    <!-- Alerts -->
    @if(session('success'))
    <div class="alert alert-success" style="margin-bottom: 1.5rem;">{{ session('success') }}</div>
    @endif

    @if($errors->any())
    <div style="background: linear-gradient(135deg, #fef2f2, #fff); border: 1px solid #fecaca; border-right: 4px solid #ef4444; color: #991b1b; padding: 1rem 1.25rem; border-radius: 12px; margin-bottom: 1.5rem;">
        <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem;">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="12" y1="8" x2="12" y2="12"></line>
                <line x1="12" y1="16" x2="12.01" y2="16"></line>
            </svg>
            <strong>تنبيه:</strong>
        </div>
        <ul style="margin: 0; padding-right: 1.5rem;">
            @foreach($errors->all() as $error)
            <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
    @endif

    <!-- Stats Row -->
    <div class="stats-row">
        <div class="stat-card">
            <div class="stat-icon cyan">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                    <circle cx="9" cy="7" r="4"></circle>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                </svg>
            </div>
            <div class="stat-info">
                <h3>{{ $totalDoctors }}</h3>
                <p>إجمالي الدكاترة</p>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon blue">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                </svg>
            </div>
            <div class="stat-info">
                <h3>{{ \App\Models\Academic\Subject::whereNotNull('doctor_id')->count() }}</h3>
                <p>مواد معينة لهم</p>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon green">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="4" y="4" width="16" height="16" rx="2"></rect>
                </svg>
            </div>
            <div class="stat-info">
                <h3>{{ $universities->sum(fn($u) => $u->colleges->count()) }}</h3>
                <p>الكليات</p>
            </div>
        </div>
    </div>

    <div class="alert alert-info" style="margin-bottom: 1.5rem;">
        يمكنك منح الطبيب رتبة المسؤول الإداري من نموذج إضافة الدكتور مباشرة، أو من زر <strong>رتبة</strong> داخل جدول الدكاترة.
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
                <h3>إضافة دكتور جديد</h3>
            </div>

            <form action="{{ route('admin.doctors.store') }}" method="POST">
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
                    <label for="name" class="form-label">الاسم الكامل</label>
                    <div class="input-with-icon">
                        <span class="icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                                <circle cx="12" cy="7" r="4"></circle>
                            </svg>
                        </span>
                        <input type="text" name="name" id="name" class="form-control" placeholder="د. محمد ..." required>
                    </div>
                </div>

                <div class="form-group">
                    <label for="email" class="form-label">البريد الإلكتروني</label>
                    <div class="input-with-icon">
                        <span class="icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path>
                                <polyline points="22,6 12,13 2,6"></polyline>
                            </svg>
                        </span>
                        <input type="email" name="email" id="email" class="form-control" placeholder="doctor@example.com" required>
                    </div>
                </div>

                <div class="form-group">
                    <label for="password" class="form-label">كلمة المرور</label>
                    <div class="input-with-icon">
                        <span class="icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                                <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                            </svg>
                        </span>
                        <input type="password" name="password" id="password" class="form-control" required>
                    </div>
                </div>

                <div class="form-group" style="display:flex; align-items:center; justify-content:space-between; gap:1rem; background:#f8fafc; border:1px solid var(--border-color); border-radius:12px; padding:0.9rem 1rem; margin-top:1rem;">
                    <div>
                        <label for="administrative_access" class="form-label" style="margin-bottom:0.25rem;">رتبة المسؤول الإداري</label>
                        <div style="font-size:0.85rem; color:var(--text-secondary);">تمنح هذا الطبيب وصولاً إلى لوحة المسؤول الإداري.</div>
                    </div>
                    <div class="form-check form-switch m-0">
                        <input class="form-check-input" type="checkbox" role="switch" id="administrative_access" name="administrative_access" value="1">
                    </div>
                </div>

                <button type="submit" class="btn-submit">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                        <polyline points="17 21 17 13 7 13 7 21"></polyline>
                    </svg>
                    حفظ الدكتور
                </button>
            </form>
        </div>

        <!-- Table Card -->
        <div class="table-card">
            <div class="table-card-header">
                <h3>
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                        <circle cx="9" cy="7" r="4"></circle>
                    </svg>
                    قائمة الدكاترة
                </h3>
                <span class="count-badge">{{ $doctors->total() }} دكتور</span>
            </div>

            <form method="GET" action="{{ route('admin.doctors.index') }}" class="doctors-filter-panel">
                <div class="doctors-filter-grid">
                    <div class="doctors-filter-field">
                        <label for="doctor_search">البحث</label>
                        <div class="doctors-filter-search">
                            <svg xmlns="http://www.w3.org/2000/svg" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <circle cx="11" cy="11" r="8"></circle>
                                <path d="m21 21-4.35-4.35"></path>
                            </svg>
                            <input
                                type="search"
                                id="doctor_search"
                                name="search"
                                value="{{ request('search') }}"
                                class="form-control"
                                placeholder="الاسم، البريد الإلكتروني، أو رقم الحساب"
                                autocomplete="off">
                        </div>
                    </div>

                    <div class="doctors-filter-field">
                        <label for="doctor_university_filter">الجامعة</label>
                        <select
                            id="doctor_university_filter"
                            name="university_id"
                            class="form-control"
                            x-model="filterUniversity"
                            @change="filterCollege = ''">
                            <option value="">كل الجامعات</option>
                            @foreach($universities as $university)
                                <option value="{{ $university->id }}">{{ $university->name }}</option>
                            @endforeach
                        </select>
                    </div>

                    <div class="doctors-filter-field">
                        <label for="doctor_college_filter">الكلية</label>
                        <select
                            id="doctor_college_filter"
                            name="college_id"
                            class="form-control"
                            x-model="filterCollege">
                            <option value="">كل الكليات</option>
                            <template x-for="college in visibleFilterColleges" :key="college.id">
                                <option
                                    :value="college.id"
                                    x-text="filterUniversity ? college.name : `${college.name} - ${college.university_name}`">
                                </option>
                            </template>
                        </select>
                    </div>

                    <div class="doctors-filter-field">
                        <label for="doctor_status_filter">حالة الحساب</label>
                        <select id="doctor_status_filter" name="status" class="form-control">
                            <option value="">كل الحالات</option>
                            <option value="active" @selected(request('status') === 'active')>نشط</option>
                            <option value="inactive" @selected(request('status') === 'inactive')>غير نشط</option>
                            <option value="pending" @selected(request('status') === 'pending')>بانتظار التفعيل</option>
                        </select>
                    </div>

                    <div class="doctors-filter-field">
                        <label for="doctor_rank_filter">الرتبة</label>
                        <select id="doctor_rank_filter" name="rank" class="form-control">
                            <option value="">كل الرتب</option>
                            <option value="doctor" @selected(request('rank') === 'doctor')>دكتور فقط</option>
                            <option value="administrative" @selected(request('rank') === 'administrative')>دكتور إداري</option>
                        </select>
                    </div>
                </div>

                <div class="doctors-filter-actions">
                    <div class="doctors-filter-summary">
                        عرض <strong>{{ $doctors->firstItem() ?? 0 }}-{{ $doctors->lastItem() ?? 0 }}</strong>
                        من أصل <strong>{{ $doctors->total() }}</strong> نتيجة
                    </div>
                    <div class="doctors-filter-buttons">
                        <a href="{{ route('admin.doctors.index') }}" class="doctors-filter-reset">مسح الفلاتر</a>
                        <button type="submit" class="doctors-filter-apply">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M4 4h16l-6 7v5l-4 2v-7z"></path>
                            </svg>
                            تطبيق
                        </button>
                    </div>
                </div>
            </form>

            <div class="table-responsive">
<table class="modern-table">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>الدكتور</th>
                        <th>الجهة الأكاديمية</th>
                        <th>المواد</th>
                        <th>الرتبة</th>
                        <th>الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($doctors as $doctor)
                    <tr>
                        <td style="font-weight: 600; color: var(--text-secondary);">{{ $loop->iteration }}</td>
                        <td>
                            <div style="display: flex; align-items: center; gap: 0.75rem;">
                                <div class="doctor-avatar">{{ mb_substr($doctor->name, 0, 1) }}</div>
                                <div>
                                    <div style="font-weight: 600;">{{ $doctor->name }}</div>
                                    <div style="font-size: 0.8rem; color: var(--text-secondary);">{{ $doctor->email }}</div>
                                    <div style="display:flex; flex-wrap:wrap; gap:0.35rem; margin-top:0.35rem;">
                                        @if($doctor->status === 'active')
                                            <span class="badge" style="background:#dcfce7; color:#166534; font-size:0.7rem;">نشط</span>
                                        @elseif($doctor->status === 'pending')
                                            <span class="badge" style="background:#fef3c7; color:#92400e; font-size:0.7rem;">بانتظار التفعيل</span>
                                        @else
                                            <span class="badge" style="background:#fee2e2; color:#991b1b; font-size:0.7rem;">غير نشط</span>
                                        @endif
                                        @if($doctor->administrative_access)
                                            <span class="badge" style="background:#ede9fe; color:#6d28d9; font-size:0.7rem;">مسؤول إداري</span>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div style="font-weight:600;">{{ $doctor->university->name ?? '-' }}</div>
                            <div style="font-size:0.8rem; color:var(--text-secondary);">{{ $doctor->college->name ?? '-' }}</div>
                        </td>
                        <td>
                            <span class="badge badge-info">{{ $doctor->subjects->count() }} مادة</span>
                        </td>
                        <td>
                            @if($doctor->administrative_access)
                                <span class="badge" style="background:#ede9fe; color:#6d28d9;">مسؤول إداري</span>
                            @else
                                <span class="badge" style="background:#f1f5f9; color:#64748b;">دكتور فقط</span>
                            @endif
                        </td>
                        <td>
                            <div style="display: flex; gap: 0.5rem;">
                                <button type="button" class="action-btn view" title="عرض التفاصيل"
                                    @click="
                                        showDetailsModal = true;
                                        viewDoctor = {
                                            name: '{{ $doctor->name }}',
                                            email: '{{ $doctor->email }}',
                                            college: '{{ $doctor->college->name ?? '-' }}',
                                            university: '{{ $doctor->university->name ?? '-' }}',
                                            administrative_access: {{ $doctor->administrative_access ? 'true' : 'false' }}
                                        };
                                        viewSubjects = {{ json_encode($doctor->subjects->map(function($s) {
                                            return [
                                                'name' => $s->name,
                                                'code' => $s->code,
                                                'term' => $s->term->name,
                                                'level' => $s->term->level->name,
                                                'major' => $s->term->level->major->name
                                            ];
                                        })) }};
                                    ">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                                        <circle cx="12" cy="12" r="3"></circle>
                                    </svg>
                                </button>
                                <button type="button" class="action-btn edit"
                                    @click="
                                        showEditModal = true;
                                        modalTitle = 'تعديل: {{ $doctor->name }}';
                                        editUrl = '{{ route('admin.doctors.update', $doctor) }}';
                                        editName = '{{ $doctor->name }}';
                                        editEmail = '{{ $doctor->email }}';
                                        editCollegeId = '{{ $doctor->college_id }}';
                                        editAdministrativeAccess = {{ $doctor->administrative_access ? 'true' : 'false' }};
                                    ">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                                    </svg>
                                    تعديل
                                </button>
                                <button type="button" class="action-btn" style="background:#ede9fe; color:#6d28d9;"
                                    @click="
                                        showRoleModal = true;
                                        roleDoctorName = @js($doctor->name);
                                        roleUrl = '{{ route('admin.doctors.administrative-access', $doctor) }}';
                                        editAdministrativeAccess = {{ $doctor->administrative_access ? 'true' : 'false' }};
                                    ">
                                    رتبة
                                </button>
                                <button type="button" class="action-btn delete"
                                    @click="
                                        showDeleteModal = true;
                                        deleteUrl = '{{ route('admin.doctors.destroy', $doctor) }}';
                                        modalTitle = 'حذف {{ $doctor->name }}';
                                        modalMessage = 'حذف الدكتور سيؤدي إلى فك ارتباطه بالمواد التي يدرسها.';
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
                        <td colspan="6" style="text-align: center; padding: 3rem; color: var(--text-secondary);">
                            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5" style="margin-bottom: 1rem;">
                                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                                <circle cx="9" cy="7" r="4"></circle>
                            </svg>
                            <div>{{ request()->hasAny(['search', 'university_id', 'college_id', 'status', 'rank']) ? 'لا توجد نتائج مطابقة للفلاتر الحالية' : 'لا يوجد دكاترة مسجلون' }}</div>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
</div>

            <div style="margin-top: 1.5rem;">
                {{ $doctors->links() }}
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
                <label for="edit_name" class="form-label">الاسم الكامل</label>
                <input type="text" name="name" id="edit_name" class="form-control" x-model="editName" required>
            </div>

            <div class="form-group">
                <label for="edit_email" class="form-label">البريد الإلكتروني</label>
                <input type="email" name="email" id="edit_email" class="form-control" x-model="editEmail" required>
            </div>

            <div class="form-group" style="border-top: 1px solid var(--border-color); padding-top: 1rem; margin-top: 1rem;">
                <label for="edit_password" class="form-label">كلمة المرور الجديدة (اختياري)</label>
                <input type="password" name="password" id="edit_password" class="form-control" placeholder="اتركه فارغاً إذا كنت لا تريد تغييرها">
            </div>

            <div class="modal-actions">
                <button type="button" class="btn btn-secondary" @click="showEditModal = false">إلغاء</button>
                <button type="submit" class="btn btn-primary">حفظ التغييرات</button>
            </div>
        </form>
    </x-edit-modal>

    <div x-show="showRoleModal" class="modal-overlay" style="display: none;"
        x-transition:enter="transition ease-out duration-300"
        x-transition:enter-start="opacity-0"
        x-transition:enter-end="opacity-100"
        x-transition:leave="transition ease-in duration-200"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0">
        <div class="modal-container" style="text-align: right; max-width: 520px;" @click.away="showRoleModal = false">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:1.25rem; border-bottom:1px solid var(--border-color); padding-bottom:0.9rem;">
                <h3 class="modal-title" style="margin:0;">إدارة الرتبة الإدارية</h3>
                <button @click="showRoleModal = false" style="background:none; border:none; cursor:pointer; font-size:1.5rem; color:var(--text-secondary);">&times;</button>
            </div>
            <form :action="roleUrl" method="POST">
                @csrf
                @method('PATCH')
                <div style="margin-bottom:1rem; color:var(--text-secondary);">
                    تحديث رتبة الدكتور: <strong x-text="roleDoctorName" style="color:var(--text-primary);"></strong>
                </div>
                <div class="form-group" style="display:flex; align-items:center; justify-content:space-between; gap:1rem; background:#f8fafc; border:1px solid var(--border-color); border-radius:12px; padding:0.9rem 1rem; margin-top:1rem;">
                    <div>
                        <label for="role_administrative_access" class="form-label" style="margin-bottom:0.25rem;">رتبة المسؤول الإداري</label>
                        <div style="font-size:0.85rem; color:var(--text-secondary);">تمنح هذا الطبيب وصولاً إلى لوحة المسؤول الإداري فقط.</div>
                    </div>
                    <div class="form-check form-switch m-0">
                        <input class="form-check-input" type="checkbox" role="switch" id="role_administrative_access" name="administrative_access" value="1" x-model="editAdministrativeAccess">
                    </div>
                </div>
                <div class="modal-actions" style="margin-top: 1.5rem;">
                    <button type="button" class="btn btn-secondary" @click="showRoleModal = false">إلغاء</button>
                    <button type="submit" class="btn btn-primary">حفظ الرتبة</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Details Modal -->
    <div x-show="showDetailsModal" class="modal-overlay" style="display: none;"
        x-transition:enter="transition ease-out duration-300"
        x-transition:enter-start="opacity-0"
        x-transition:enter-end="opacity-100"
        x-transition:leave="transition ease-in duration-200"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0">
        <div class="modal-container" style="text-align: right; max-width: 600px;" @click.away="showDetailsModal = false">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; border-bottom: 1px solid var(--border-color); padding-bottom: 1rem;">
                <h3 class="modal-title" style="margin: 0;">تفاصيل عضو هيئة التدريس</h3>
                <button @click="showDetailsModal = false" style="background: none; border: none; cursor: pointer; font-size: 1.5rem; color: var(--text-secondary);">&times;</button>
            </div>

            <div style="display: flex; gap: 1rem; margin-bottom: 2rem; background: linear-gradient(135deg, #ecfeff, #cffafe); padding: 1.25rem; border-radius: 12px;">
                <div style="flex: 1;">
                    <div style="color: #0e7490; font-size: 0.85rem;">الاسم</div>
                    <div style="font-weight: 700; font-size: 1.1rem; color: #155e75;" x-text="viewDoctor.name"></div>
                    <template x-if="viewDoctor.administrative_access">
                        <span class="badge" style="background:#ede9fe; color:#6d28d9; margin-top:0.5rem;">مسؤول إداري</span>
                    </template>
                </div>
                <div style="flex: 1;">
                    <div style="color: #0e7490; font-size: 0.85rem;">البريد الإلكتروني</div>
                    <div style="font-weight: 600; color: #155e75;" x-text="viewDoctor.email"></div>
                </div>
            </div>

            <div style="display: flex; gap: 1rem; margin-bottom: 2rem;">
                <div style="flex: 1;">
                    <div style="color: var(--text-secondary); font-size: 0.85rem;">الجامعة</div>
                    <div style="font-weight: 600;" x-text="viewDoctor.university"></div>
                </div>
                <div style="flex: 1;">
                    <div style="color: var(--text-secondary); font-size: 0.85rem;">الكلية</div>
                    <div style="font-weight: 600;" x-text="viewDoctor.college"></div>
                </div>
            </div>

            <h4 style="font-size: 1rem; margin-bottom: 1rem; border-bottom: 2px solid #06b6d4; display: inline-block; padding-bottom: 0.25rem;">المواد الدراسية المسندة</h4>

            <div style="max-height: 250px; overflow-y: auto;">
                <div class="table-responsive">
<table style="width: 100%; border-collapse: collapse;">
                    <thead>
                        <tr style="background-color: #f1f5f9;">
                            <th style="padding: 0.75rem; text-align: right; font-size: 0.9rem;">المادة</th>
                            <th style="padding: 0.75rem; text-align: right; font-size: 0.9rem;">الكود</th>
                            <th style="padding: 0.75rem; text-align: right; font-size: 0.9rem;">الموقع الأكاديمي</th>
                        </tr>
                    </thead>
                    <tbody>
                        <template x-for="subject in viewSubjects">
                            <tr>
                                <td style="padding: 0.75rem; border-bottom: 1px solid var(--border-color); font-weight: 600;" x-text="subject.name"></td>
                                <td style="padding: 0.75rem; border-bottom: 1px solid var(--border-color);">
                                    <span class="badge badge-warning" x-show="subject.code" x-text="subject.code"></span>
                                    <span x-show="!subject.code">-</span>
                                </td>
                                <td style="padding: 0.75rem; border-bottom: 1px solid var(--border-color); font-size: 0.85rem;">
                                    <div x-text="subject.major"></div>
                                    <div style="color: var(--text-secondary);">
                                        <span x-text="subject.level"></span> - <span x-text="subject.term"></span>
                                    </div>
                                </td>
                            </tr>
                        </template>
                        <tr x-show="viewSubjects.length === 0">
                            <td colspan="3" style="text-align: center; padding: 1.5rem; color: var(--text-secondary);">
                                هذا الدكتور لا يدرس أي مواد حاليًا.
                            </td>
                        </tr>
                    </tbody>
                </table>
</div>
            </div>

            <div class="modal-actions" style="margin-top: 2rem;">
                <button type="button" class="btn btn-secondary" @click="showDetailsModal = false">إغلاق</button>
            </div>
        </div>
    </div>

</div>

@endsection
