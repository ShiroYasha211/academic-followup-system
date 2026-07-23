@extends('layouts.delegate')

@section('title', 'إدارة الطلاب')

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

    .content-grid {
        display: grid;
        grid-template-columns: 350px 1fr;
        gap: 2rem;
        align-items: start;
    }

    /* Create Form Card */
    .create-card {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        overflow: hidden;
        position: sticky;
        top: 2rem;
    }

    .create-header {
        padding: 1.25rem 1.5rem;
        background: linear-gradient(135deg, #10b981, #059669);
        color: white;
    }

    .create-header h3 {
        font-size: 1.1rem;
        font-weight: 700;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .create-body {
        padding: 1.5rem;
    }

    .info-box {
        background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
        border: 1px solid #bfdbfe;
        padding: 1rem;
        border-radius: 12px;
        margin-bottom: 1.5rem;
    }

    .info-box .title {
        font-weight: 700;
        color: #1e40af;
        font-size: 0.9rem;
        margin-bottom: 0.5rem;
        display: flex;
        align-items: center;
        gap: 0.35rem;
    }

    .info-box ul {
        margin: 0;
        padding-right: 1.25rem;
        font-size: 0.85rem;
        color: #1e3a8a;
    }

    .info-box li {
        margin-bottom: 0.25rem;
    }

    .form-group {
        margin-bottom: 1.25rem;
    }

    .form-group label {
        display: block;
        font-weight: 600;
        font-size: 0.9rem;
        margin-bottom: 0.5rem;
        color: var(--text-primary);
    }

    .input-wrapper {
        position: relative;
    }

    .input-wrapper .icon {
        position: absolute;
        right: 0.875rem;
        top: 50%;
        transform: translateY(-50%);
        color: var(--text-light);
    }

    .input-wrapper input {
        width: 100%;
        padding: 0.875rem 1rem 0.875rem 2.75rem;
        border: 1px solid var(--border-color);
        border-radius: 10px;
        font-size: 0.95rem;
        transition: all 0.2s;
        background: #fafafa;
    }

    .input-wrapper input:focus {
        border-color: #10b981;
        background: white;
        outline: none;
        box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
    }

    .btn-submit {
        width: 100%;
        padding: 0.875rem;
        background: linear-gradient(135deg, #10b981, #059669);
        color: white;
        border: none;
        border-radius: 12px;
        font-weight: 600;
        font-size: 1rem;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        transition: all 0.2s;
    }

    .btn-submit:hover {
        box-shadow: 0 4px 12px -2px rgba(16, 185, 129, 0.4);
    }

    /* List Card */
    .list-card {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        overflow: hidden;
    }

    .list-header {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid var(--border-color);
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .list-header h3 {
        font-size: 1.1rem;
        font-weight: 700;
    }

    .count-badge {
        background: linear-gradient(135deg, #10b981, #059669);
        color: white;
        padding: 0.35rem 0.875rem;
        border-radius: 20px;
        font-size: 0.85rem;
        font-weight: 600;
    }

    .students-table {
        width: 100%;
        border-collapse: collapse;
    }

    .students-table thead tr {
        background: #f8fafc;
    }

    .students-table th {
        padding: 1rem 1.5rem;
        text-align: right;
        font-weight: 600;
        color: var(--text-secondary);
        font-size: 0.85rem;
        text-transform: uppercase;
    }

    .students-table td {
        padding: 1rem 1.5rem;
        border-bottom: 1px solid #f1f5f9;
    }

    .students-table tr:hover {
        background: #fafafa;
    }

    .student-cell {
        display: flex;
        align-items: center;
        gap: 0.875rem;
    }

    .student-avatar {
        width: 42px;
        height: 42px;
        border-radius: 50%;
        background: linear-gradient(135deg, #10b981, #059669);
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        font-size: 1rem;
    }

    .student-info .name {
        font-weight: 600;
        color: var(--text-primary);
        margin-bottom: 0.15rem;
    }

    .student-info .email {
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    .student-number {
        font-family: monospace;
        background: #f1f5f9;
        padding: 0.35rem 0.75rem;
        border-radius: 6px;
        font-size: 0.9rem;
        font-weight: 600;
    }

    .action-btns {
        display: flex;
        gap: 0.5rem;
    }

    .action-btn {
        padding: 0.5rem 0.75rem;
        border: none;
        border-radius: 8px;
        font-size: 0.8rem;
        font-weight: 600;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 0.35rem;
        transition: all 0.2s;
    }

    .action-btn.view {
        background: #f3f4f6;
        color: var(--text-secondary);
    }

    .action-btn.edit {
        background: #e0f2fe;
        color: #0284c7;
    }

    .action-btn.delete {
        background: #fee2e2;
        color: #dc2626;
    }

    .action-btn:hover {
        transform: translateY(-1px);
    }

    .empty-state {
        text-align: center;
        padding: 4rem 2rem;
        color: var(--text-secondary);
    }

    .empty-state svg {
        opacity: 0.4;
        margin-bottom: 1rem;
    }

    .pagination-wrapper {
        padding: 1.25rem 1.5rem;
        border-top: 1px solid var(--border-color);
    }

    /* Modal Styling */
    .modal-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.6);
        z-index: 9999;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .modal-container {
        background: white;
        border-radius: 20px;
        width: 90%;
        max-width: 500px;
        padding: 1.5rem;
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
    }

    .modal-icon {
        width: 64px;
        height: 64px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 1rem;
    }

    .modal-title {
        font-size: 1.25rem;
        font-weight: 700;
        text-align: center;
        margin-bottom: 0.5rem;
    }

    .modal-message {
        text-align: center;
        color: var(--text-secondary);
        margin-bottom: 1.5rem;
    }

    .modal-actions {
        display: flex;
        gap: 0.75rem;
        justify-content: center;
    }
</style>

<div x-data="{ 
    showDeleteModal: false, 
    showEditModal: false,
    showDetailsModal: false,
    showImportModal: false,
    deleteUrl: '', 
    modalTitle: '', 
    modalMessage: '',
    editUrl: '',
    editName: '',
    editEmail: '',
    editStudentNumber: '',
    editGender: 'male',
    viewStudent: {},
    viewSubjects: [],
    viewDelegate: null,
    showPermissionsModal: false,
    permStudent: { id: null, name: '', permissions: [] },
    permsUrl: '',
    selectedFile: null,
    fileError: null,
    formatSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    },
    handleFileSelect(event) {
        const file = event.target.files[0];
        if (!file) {
            this.selectedFile = null;
            this.fileError = null;
            return;
        }
        
        const extension = file.name.split('.').pop().toLowerCase();
        if (extension !== 'csv') {
            this.fileError = 'عذراً، يجب اختيار ملف بصيغة CSV فقط.';
            this.selectedFile = null;
            event.target.value = ''; // Reset input
            return;
        }

        this.fileError = null;
        this.selectedFile = {
            name: file.name,
            size: this.formatSize(file.size)
        };
    }
}">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                <circle cx="9" cy="7" r="4"></circle>
                <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
            </svg>
        </div>
        <div class="page-header-text">
            <h1>إدارة الطلاب</h1>
            <p>إضافة وإدارة طلاب الدفعة</p>
        </div>
        <div style="margin-right: auto;">
            @php $canImport = Auth::user()->hasDelegatePermission('students', 'create'); @endphp
            <button 
                @if($canImport) @click="showImportModal = true" @endif
                class="btn-submit {{ !$canImport ? 'btn-locked' : '' }}" 
                style="background: linear-gradient(135deg, #0284c7, #0369a1); width: auto; padding: 0.75rem 1.5rem; font-size: 0.9rem;"
                @if(!$canImport) title="ليس لديك صلاحية الاستيراد" @endif
            >
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                    <polyline points="17 8 12 3 7 8"></polyline>
                    <line x1="12" y1="3" x2="12" y2="15"></line>
                </svg>
                إستيراد إكسل (CSV)
            </button>
        </div>
    </div>

    @if(session('success'))
    <div class="alert alert-success" style="margin-bottom: 1.5rem;">
        {{ session('success') }}
    </div>
    @endif

    @if($errors->any())
    <div style="background: #fef2f2; border: 1px solid #fecaca; border-radius: 12px; padding: 1rem; margin-bottom: 1.5rem;">
        <div style="font-weight: 600; color: #b91c1c; margin-bottom: 0.5rem; display: flex; align-items: center; gap: 0.5rem;">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="12" y1="8" x2="12" y2="12"></line>
                <line x1="12" y1="16" x2="12.01" y2="16"></line>
            </svg>
            يرجى التحقق من البيانات
        </div>
        <ul style="margin: 0; padding-right: 1.5rem; color: #dc2626; font-size: 0.9rem;">
            @foreach($errors->all() as $error)
            <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
    @endif

    @if(session('import_report'))
    @php $report = session('import_report'); @endphp
    <div style="background: white; border-radius: 16px; padding: 1.5rem; margin-bottom: 2rem; border: 1px solid var(--border-color); box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
        <h3 style="display: flex; align-items: center; gap: 0.5rem; font-size: 1.15rem; margin-bottom: 1rem; color: var(--text-primary);">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
            تقرير الاستيراد
        </h3>

        <div style="display: flex; gap: 1.5rem; margin-bottom: 1.5rem;">
            <div style="background: #ecfdf5; padding: 1rem 1.5rem; border-radius: 12px; border: 1px solid #d1fae5; flex: 1; text-align: center;">
                <div style="font-size: 1.5rem; font-weight: 700; color: #059669;">{{ $report['success_count'] }}</div>
                <div style="font-size: 0.9rem; color: #10b981; font-weight: 600;">طالب تمت إضافته بنجاح</div>
            </div>
            <div style="background: #fef2f2; padding: 1rem 1.5rem; border-radius: 12px; border: 1px solid #fee2e2; flex: 1; text-align: center;">
                <div style="font-size: 1.5rem; font-weight: 700; color: #dc2626;">{{ count($report['errors']) }}</div>
                <div style="font-size: 0.9rem; color: #ef4444; font-weight: 600;">طلاب فشلت إضافتهم</div>
            </div>
        </div>

        @if(count($report['errors']) > 0)
        <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 1rem;">
            <h4 style="margin-bottom: 0.75rem; font-size: 0.95rem; color: var(--text-primary); font-weight: 600;">تفاصيل الأخطاء:</h4>
            <ul style="margin: 0; padding-right: 1.25rem; color: #dc2626; font-size: 0.85rem; max-height: 200px; overflow-y: auto;">
                @foreach($report['errors'] as $error)
                <li style="margin-bottom: 0.35rem;">{{ $error }}</li>
                @endforeach
            </ul>
        </div>
        @endif
    </div>
    @endif

    <div class="content-grid">
        <!-- Forms Column -->
        <div style="display: flex; flex-direction: column; gap: 1.5rem;">
            <!-- Create Form Card -->
            <div class="create-card" style="position: static;">
                <div class="create-header">
                    <h3>
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                            <circle cx="8.5" cy="7" r="4"></circle>
                            <line x1="20" y1="8" x2="20" y2="14"></line>
                            <line x1="23" y1="11" x2="17" y2="11"></line>
                        </svg>
                        تسجيل طالب جديد
                    </h3>
                </div>
                <div class="create-body">
                    <div class="info-box">
                        <div class="title">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <circle cx="12" cy="12" r="10"></circle>
                                <line x1="12" y1="16" x2="12" y2="12"></line>
                                <line x1="12" y1="8" x2="12.01" y2="8"></line>
                            </svg>
                            سيتم التسجيل تلقائياً في:
                        </div>
                        <ul>
                            <li>{{ Auth::user()->university->name ?? 'الجامعة' }}</li>
                            <li>{{ Auth::user()->college->name ?? 'الكلية' }}</li>
                            <li>{{ Auth::user()->major->name ?? 'التخصص' }}</li>
                            <li>{{ Auth::user()->level->name ?? 'المستوى' }}</li>
                        </ul>
                    </div>

                    <form action="{{ route('delegate.students.store') }}" method="POST">
                        @csrf

                        <div class="form-group">
                            <label>الاسم الكامل</label>
                            <div class="input-wrapper">
                                <svg class="icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                                    <circle cx="12" cy="7" r="4"></circle>
                                </svg>
                                <input type="text" name="name" placeholder="اسم الطالب..." required>
                            </div>
                        </div>

                        <div class="form-group">
                            <label>الرقم الجامعي</label>
                            <div class="input-wrapper">
                                <svg class="icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                                    <line x1="16" y1="2" x2="16" y2="6"></line>
                                    <line x1="8" y1="2" x2="8" y2="6"></line>
                                    <line x1="3" y1="10" x2="21" y2="10"></line>
                                </svg>
                                <input type="text" name="student_number" placeholder="12345678" required>
                            </div>
                        </div>

                        <div class="form-group" style="display: none;">
                            <label>البريد الإلكتروني</label>
                            <div class="input-wrapper">
                                <svg class="icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path>
                                    <polyline points="22,6 12,13 2,6"></polyline>
                                </svg>
                                <input type="email" name="email" placeholder="student@example.com">
                            </div>
                        </div>

                        <div class="form-group">
                            <label>الجنس</label>
                            <div class="input-wrapper">
                                <svg class="icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M12 2a5 5 0 0 1 5 5c0 2-1 3-2 4l-1 1v2"></path>
                                    <path d="M9 21h6"></path>
                                    <path d="M12 14v7"></path>
                                </svg>
                                <select name="gender" required style="width: 100%; padding: 0.875rem 1rem 0.875rem 2.75rem; border: 1px solid var(--border-color); border-radius: 10px; font-size: 0.95rem; background: #fafafa;">
                                    <option value="male">ذكر</option>
                                    <option value="female">أنثى</option>
                                </select>
                            </div>
                        </div>

                        <div class="form-group" style="display: none;">
                            <label>كلمة المرور</label>
                            <div class="input-wrapper">
                                <svg class="icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                                    <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                                </svg>
                                <input type="password" name="password">
                            </div>
                        </div>

                        <div class="form-group" style="display: none;">
                            <label>تأكيد كلمة المرور</label>
                            <div class="input-wrapper">
                                <svg class="icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                                    <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                                </svg>
                                <input type="password" name="password_confirmation">
                            </div>
                        </div>

                        @php $canCreate = Auth::user()->hasDelegatePermission('students', 'create'); @endphp
                        <button type="{{ $canCreate ? 'submit' : 'button' }}" class="btn-submit {{ !$canCreate ? 'btn-locked' : '' }}" @if(!$canCreate) title="ليس لديك صلاحية إضافة طلاب" @endif>
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                                <polyline points="17 21 17 13 7 13 7 21"></polyline>
                                <polyline points="7 3 7 8 15 8"></polyline>
                            </svg>
                            {{ $canCreate ? 'حفظ البيانات' : 'ليس لديك صلاحية إضافة' }}
                        </button>
                    </form>
                </div>
            </div>
        </div>

        <!-- Students List -->
        <div class="list-card">
            <div class="list-header">
                <h3>قائمة طلاب الدفعة</h3>
                <span class="count-badge">{{ $students->total() }} طالب</span>
            </div>

            @if($students->isEmpty())
            <div class="empty-state">
                <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                    <circle cx="9" cy="7" r="4"></circle>
                </svg>
                <h3>لا يوجد طلاب مسجلين</h3>
                <p>ابدأ بإضافة طلاب جدد من النموذج</p>
            </div>
            @else
            <div class="table-responsive">
                <table class="students-table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>الطالب</th>
                            <th>الرقم الجامعي</th>
                            <th>الجنس</th>
                            <th>الإجراءات</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($students as $student)
                        <tr>
                            <td>{{ $loop->iteration }}</td>
                            <td>
                                <div class="student-cell">
                                    <div class="student-avatar">{{ mb_substr($student->name, 0, 1) }}</div>
                                    <div class="student-info">
                                        <div class="name">{{ $student->name }}</div>
                                        <div class="email">{{ $student->email }}</div>
                                    </div>
                                </div>
                            </td>
                            <td><span class="student-number">{{ $student->student_number }}</span></td>
                            <td>
                                <span style="display: inline-flex; align-items: center; gap: 0.35rem; padding: 0.35rem 0.75rem; border-radius: 999px; background: {{ $student->gender === 'female' ? '#fdf2f8' : '#eff6ff' }}; color: {{ $student->gender === 'female' ? '#db2777' : '#2563eb' }}; font-size: 0.8rem; font-weight: 700;">
                                    {{ $student->gender === 'female' ? 'أنثى' : 'ذكر' }}
                                </span>
                            </td>
                            <td>
                                <div class="action-btns">
                                    <button type="button" class="action-btn view" style="color: #6366f1; background: #eef2ff;" title="الصلاحيات"
                                        @click="
                                            showPermissionsModal = true;
                                            permStudent = {
                                                id: {{ $student->id }},
                                                name: '{{ $student->name }}',
                                                permissions: {{ json_encode($student->permissions->pluck('slug')) }}
                                            };
                                            permsUrl = '{{ route('delegate.students.permissions', $student) }}';
                                        ">
                                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
                                        </svg>
                                    </button>
                                    <button type="button" class="action-btn view" title="عرض التفاصيل"
                                        @click="
                                            showDetailsModal = true;
                                            viewStudent = {
                                                name: '{{ $student->name }}',
                                                email: '{{ $student->email }}',
                                                student_number: '{{ $student->student_number }}',
                                                gender: '{{ $student->gender }}',
                                                level: '{{ $student->level->name ?? '-' }}',
                                                major: '{{ $student->major->name ?? '-' }}',
                                                college: '{{ $student->college->name ?? '-' }}',
                                                university: '{{ $student->university->name ?? '-' }}'
                                            };
                                            viewSubjects = {{ json_encode($student->level ? $student->level->terms->flatMap->subjects->map(function($s) {
                                                return [
                                                    'name' => $s->name,
                                                    'code' => $s->code,
                                                    'doctor' => $s->doctor ? $s->doctor->name : 'غير محدد',
                                                    'term' => $s->term->name
                                                ];
                                            }) : []) }};
                                            viewDelegate = {
                                                name: '{{ Auth::user()->name }}',
                                                email: '{{ Auth::user()->email }}'
                                            };
                                        ">
                                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                                            <circle cx="12" cy="12" r="3"></circle>
                                        </svg>
                                    </button>
                                    @php $canUpdate = Auth::user()->hasDelegatePermission('students', 'update'); @endphp
                                    <button type="button" class="action-btn edit {{ !$canUpdate ? 'btn-locked' : '' }}"
                                        @if($canUpdate)
                                        @click="
                                            showEditModal = true;
                                            modalTitle = 'تعديل: {{ $student->name }}';
                                            editUrl = '{{ route('delegate.students.update', $student) }}';
                                            editName = '{{ $student->name }}';
                                            editEmail = '{{ $student->email }}';
                                            editStudentNumber = '{{ $student->student_number }}';
                                            editGender = '{{ $student->gender ?? 'male' }}';
                                        "
                                        @else
                                        title="ليس لديك صلاحية التعديل"
                                        @endif
                                    >
                                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                                        </svg>
                                        تعديل
                                    </button>

                                    @php $canDelete = Auth::user()->hasDelegatePermission('students', 'delete'); @endphp
                                    <button type="button" class="action-btn delete {{ !$canDelete ? 'btn-locked' : '' }}"
                                        @if($canDelete)
                                        @click="
                                            showDeleteModal = true;
                                            deleteUrl = '{{ route('delegate.students.destroy', $student) }}';
                                            modalTitle = 'حذف {{ $student->name }}';
                                            modalMessage = 'حذف الطالب سيؤدي لحذف جميع سجلات حضوره. هل أنت متأكد؟';
                                        "
                                        @else
                                        title="ليس لديك صلاحية الحذف"
                                        @endif
                                    >
                                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                            <polyline points="3 6 5 6 21 6"></polyline>
                                            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                                        </svg>
                                    </button>
                                </div>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            @if($students->hasPages())
            <div class="pagination-wrapper">
                {{ $students->links() }}
            </div>
            @endif
            @endif
        </div>
    </div>

    <!-- Import Modal -->
    <div x-show="showImportModal" class="modal-overlay" style="display: none;" x-transition.opacity>
        <div class="modal-container" @click.away="showImportModal = false" style="max-width: 550px;">
            <div class="modal-icon" style="background-color: #f0f9ff; color: #0284c7;">
                <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                    <polyline points="17 8 12 3 7 8"></polyline>
                    <line x1="12" y1="3" x2="12" y2="15"></line>
                </svg>
            </div>
            <h3 class="modal-title">استيراد الدفعة من CSV</h3>
            
            <div style="margin: 1.5rem 0;">
                <div class="info-box" style="background: #f8fafc; border-color: #e2e8f0; margin-bottom: 1rem;">
                    <div class="title" style="color: #475569;">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
                        تعليمات هامة:
                    </div>
                    <ul style="color: #64748b; font-size: 0.85rem;">
                        <li>يجب أن يحتوي الملف على الأعمدة التالية بالترتيب: <strong>الاسم، البريد الإلكتروني، الرقم الجامعي</strong>.</li>
                        <li>سيتم تعيين <strong>الرقم الجامعي ككلمة سر افتراضية</strong> لكل طالب.</li>
                        <li>تأكد من عدم تكرار البريد الإلكتروني أو الرقم الجامعي في النظام.</li>
                    </ul>
                </div>

                <a href="{{ route('delegate.students.template') }}" style="display: flex; align-items: center; justify-content: center; gap: 0.5rem; width: 100%; padding: 0.75rem; background: #f0f9ff; color: #0284c7; border: 1px dashed #bae6fd; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 0.9rem; margin-bottom: 1.5rem;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                    تحميل نموذج ملف (CSV)
                </a>

                <form action="{{ route('delegate.students.import') }}" method="POST" enctype="multipart/form-data">
                    @csrf
                    <div class="form-group">
                        <label>اختر ملف الـ CSV</label>
                        
                        <!-- Upload Area -->
                        <div x-show="!selectedFile" style="position: relative; border: 2px dashed #e2e8f0; border-radius: 12px; padding: 1.5rem; text-align: center; background: #fafafa; transition: all 0.2s;" onmouseover="this.style.borderColor='#0284c7'; this.style.background='#f0f9ff';" onmouseout="this.style.borderColor='#e2e8f0'; this.style.background='#fafafa';">
                            <input type="file" name="csv_file" accept=".csv" required @change="handleFileSelect" style="position: absolute; inset: 0; opacity: 0; cursor: pointer; width: 100%;">
                            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" style="margin-bottom: 0.5rem;"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
                            <div style="color: #64748b; font-weight: 600;">اسحب الملف هنا أو اضغل للاختيار</div>
                            <div style="font-size: 0.75rem; color: #94a3b8; margin-top: 0.25rem;">يدعم صيغة CSV فقط</div>
                        </div>

                        <!-- Error Message -->
                        <div x-show="fileError" x-cloak style="margin-top: 0.75rem; background: #fef2f2; color: #dc2626; padding: 0.75rem; border-radius: 8px; font-size: 0.85rem; border: 1px solid #fee2e2; display: flex; align-items: center; gap: 0.5rem;">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                            <span x-text="fileError"></span>
                        </div>

                        <!-- Selected File Status -->
                        <div x-show="selectedFile" x-cloak style="margin-top: 1rem; background: #f0fdf4; border: 2px solid #22c55e; border-radius: 12px; padding: 1rem; display: flex; align-items: center; gap: 1rem; position: relative;">
                            <div style="width: 48px; height: 48px; background: #dcfce7; border-radius: 10px; display: flex; align-items: center; justify-content: center; color: #16a34a;">
                                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/><polyline points="14 2 14 8 20 8"/></svg>
                            </div>
                            <div style="flex: 1; min-width: 0;">
                                <div style="font-weight: 700; color: #14532d; font-size: 0.95rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" x-text="selectedFile ? selectedFile.name : ''"></div>
                                <div style="font-size: 0.8rem; color: #16a34a; font-weight: 600;" x-text="selectedFile ? selectedFile.size : ''"></div>
                            </div>
                            <div style="text-align: left;">
                                <div style="display: flex; align-items: center; gap: 0.35rem; color: #16a34a; font-weight: 700; font-size: 0.85rem; margin-bottom: 0.25rem;">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
                                    الملف جاهز
                                </div>
                                <button type="button" @click="selectedFile = null; fileError = null; $refs.fileInput.value = ''" style="background: none; border: none; color: #dc2626; font-size: 0.8rem; font-weight: 600; cursor: pointer; padding: 0; text-decoration: underline;">
                                    تغيير الملف
                                </button>
                            </div>
                        </div>
                    </div>
                    <div class="modal-actions" style="margin-top: 1.5rem;">
                        <button type="button" class="btn btn-secondary" @click="showImportModal = false; selectedFile = null; fileError = null;">إلغاء</button>
                        <button type="submit" class="btn btn-primary" :disabled="!selectedFile" :style="!selectedFile ? 'background: #94a3b8; cursor: not-allowed;' : 'background: #0284c7;'">بدء عملية الاستيراد</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Delete Modal -->
    <div x-show="showDeleteModal" class="modal-overlay" style="display: none;" x-transition.opacity>
        <div class="modal-container" @click.away="showDeleteModal = false">
            <div class="modal-icon" style="background-color: #fee2e2; color: #dc2626;">
                <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M3 6h18"></path>
                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                </svg>
            </div>
            <h3 class="modal-title" x-text="modalTitle"></h3>
            <p class="modal-message" x-text="modalMessage"></p>
            <div class="modal-actions">
                <button type="button" class="btn btn-secondary" @click="showDeleteModal = false">إلغاء</button>
                <form :action="deleteUrl" method="POST">
                    @csrf
                    @method('DELETE')
                    <button type="submit" class="btn btn-danger">نعم، حذف</button>
                </form>
            </div>
        </div>
    </div>

    <!-- Edit Modal -->
    <div x-show="showEditModal" class="modal-overlay" style="display: none;" x-transition.opacity>
        <div class="modal-container" @click.away="showEditModal = false" style="text-align: right; max-width: 450px;">
            <div class="modal-icon" style="background-color: #e0f2fe; color: #0284c7;">
                <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
            </div>
            <h3 class="modal-title" x-text="modalTitle"></h3>

            <form :action="editUrl" method="POST" style="margin-top: 1.5rem;">
                @csrf
                @method('PUT')

                <div class="form-group">
                    <label>الاسم الكامل</label>
                    <input type="text" name="name" class="form-control" x-model="editName" required>
                </div>

                <div class="form-group">
                    <label>الرقم الجامعي</label>
                    <input type="text" name="student_number" class="form-control" x-model="editStudentNumber" required>
                </div>

                <div class="form-group" style="display: none;">
                    <label>البريد الإلكتروني</label>
                    <input type="email" name="email" class="form-control" x-model="editEmail">
                </div>

                <div class="form-group">
                    <label>الجنس</label>
                    <select name="gender" class="form-control" x-model="editGender" required>
                        <option value="male">ذكر</option>
                        <option value="female">أنثى</option>
                    </select>
                </div>

                <div class="form-group" style="display: none;">
                    <label>كلمة المرور الجديدة (اختياري)</label>
                    <input type="password" name="password" class="form-control" placeholder="اتركه فارغاً إذا لم ترد التغيير">
                </div>

                <div class="form-group" style="display: none;">
                    <label>تأكيد كلمة المرور</label>
                    <input type="password" name="password_confirmation" class="form-control">
                </div>

                <div class="modal-actions" style="margin-top: 1.5rem;">
                    <button type="button" class="btn btn-secondary" @click="showEditModal = false">إلغاء</button>
                    <button type="submit" class="btn btn-primary">حفظ التغييرات</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Details Modal -->
    <div x-show="showDetailsModal" class="modal-overlay" style="display: none;" x-transition.opacity>
        <div class="modal-container" @click.away="showDetailsModal = false" style="text-align: right; max-width: 600px;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; border-bottom: 1px solid var(--border-color); padding-bottom: 1rem;">
                <h3 class="modal-title" style="margin: 0;">تفاصيل الطالب</h3>
                <button @click="showDetailsModal = false" style="background: none; border: none; color: var(--text-light); cursor: pointer;">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6L6 18M6 6l12 12"/></svg>
                </button>
            </div>

            <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem;">
                <div class="detail-item">
                    <label style="display: block; font-size: 0.8rem; color: var(--text-secondary); margin-bottom: 0.25rem;">الاسم الكامل</label>
                    <div style="font-weight: 700; color: var(--text-primary);" x-text="viewStudent.name"></div>
                </div>
                <div class="detail-item">
                    <label style="display: block; font-size: 0.8rem; color: var(--text-secondary); margin-bottom: 0.25rem;">الرقم الجامعي</label>
                    <div style="font-weight: 700; color: var(--text-primary); font-family: monospace;" x-text="viewStudent.student_number"></div>
                </div>
                <div class="detail-item">
                    <label style="display: block; font-size: 0.8rem; color: var(--text-secondary); margin-bottom: 0.25rem;">البريد الإلكتروني</label>
                    <div style="font-weight: 700; color: var(--text-primary);" x-text="viewStudent.email"></div>
                </div>
                <div class="detail-item">
                    <label style="display: block; font-size: 0.8rem; color: var(--text-secondary); margin-bottom: 0.25rem;">المستوى الدراسي</label>
                    <div style="font-weight: 700; color: var(--text-primary);" x-text="viewStudent.level"></div>
                </div>
                <div class="detail-item">
                    <label style="display: block; font-size: 0.8rem; color: var(--text-secondary); margin-bottom: 0.25rem;">الجنس</label>
                    <div style="font-weight: 700; color: var(--text-primary);" x-text="viewStudent.gender === 'female' ? 'أنثى' : 'ذكر'"></div>
                </div>
            </div>

            <div style="margin-top: 2rem;">
                <h4 style="font-size: 1rem; font-weight: 700; margin-bottom: 1rem; color: var(--text-primary); display: flex; align-items: center; gap: 0.5rem;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>
                    المواد الدراسية (بناءً على المستوى)
                </h4>
                <div style="max-height: 250px; overflow-y: auto; border: 1px solid var(--border-color); border-radius: 12px;">
                    <table style="width: 100%; border-collapse: collapse; font-size: 0.85rem;">
                        <thead style="background: #f8fafc; position: sticky; top: 0;">
                            <tr>
                                <th style="padding: 0.75rem; text-align: right; border-bottom: 1px solid var(--border-color);">المادة</th>
                                <th style="padding: 0.75rem; text-align: right; border-bottom: 1px solid var(--border-color);">الدكتور</th>
                                <th style="padding: 0.75rem; text-align: right; border-bottom: 1px solid var(--border-color);">الترم</th>
                            </tr>
                        </thead>
                        <tbody>
                            <template x-for="subject in viewSubjects">
                                <tr>
                                    <td style="padding: 0.75rem; border-bottom: 1px solid #f1f5f9;">
                                        <div style="font-weight: 600;" x-text="subject.name"></div>
                                        <div style="font-size: 0.75rem; color: var(--text-secondary);" x-text="subject.code"></div>
                                    </td>
                                    <td style="padding: 0.75rem; border-bottom: 1px solid #f1f5f9;" x-text="subject.doctor"></td>
                                    <td style="padding: 0.75rem; border-bottom: 1px solid #f1f5f9;">
                                        <span style="background: #f1f5f9; padding: 0.2rem 0.5rem; border-radius: 4px;" x-text="subject.term"></span>
                                    </td>
                                </tr>
                            </template>
                        </tbody>
                    </table>
                </div>
            </div>

            <div style="margin-top: 2rem; padding: 1rem; background: #f8fafc; border-radius: 12px; display: flex; align-items: center; gap: 1rem;">
                <div style="width: 40px; height: 40px; background: #e0f2fe; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #0284c7;">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><polyline points="17 11 19 13 23 9"/></svg>
                </div>
                <div>
                    <div style="font-size: 0.8rem; color: var(--text-secondary);">المندوب المسؤول</div>
                    <div style="font-weight: 600; color: var(--text-primary);" x-text="viewDelegate ? viewDelegate.name : ''"></div>
                </div>
                <div style="margin-right: auto; font-weight: 700; color: #0284c7;" x-text="viewStudent.gender === 'female' ? 'أنثى' : 'ذكر'"></div>
            </div>
        </div>
    </div>

    <!-- Permissions Modal -->
    <div x-show="showPermissionsModal" class="modal-overlay" style="display: none;" x-transition.opacity>
        <div class="modal-container" @click.away="showPermissionsModal = false" style="max-width: 450px;">
            <div class="modal-icon" style="background-color: #eef2ff; color: #6366f1;">
                <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
                </svg>
            </div>
            <h3 class="modal-title" x-text="'صلاحيات الطالب: ' + permStudent.name"></h3>
            
            <form :action="permsUrl" method="POST" style="margin-top: 1.5rem;">
                @csrf
                <div class="form-group" style="background: #f8fafc; padding: 1rem; border-radius: 12px; border: 1px solid #e2e8f0;">
                    <label style="display: flex; align-items: center; gap: 0.75rem; cursor: pointer; margin: 0;">
                        <input type="checkbox" name="permissions[]" value="upload_shared_library" :checked="permStudent.permissions.includes('upload_shared_library')" style="width: 18px; height: 18px; accent-color: #6366f1;">
                        <div>
                            <div style="font-weight: 700; color: #1e293b;">الرفع في المكتبة المشتركة</div>
                            <div style="font-size: 0.75rem; color: #64748b;">يسمح للطالب برفع الملفات والمراجع مباشرة للمكتبة</div>
                        </div>
                    </label>
                </div>

                <div class="modal-actions" style="margin-top: 1.5rem;">
                    <button type="button" class="btn btn-secondary" @click="showPermissionsModal = false">إلغاء</button>
                    <button type="submit" class="btn btn-primary" style="background: #6366f1;">حفظ الصلاحيات</button>
                </div>
            </form>
        </div>
    </div>

</div>

@endsection
