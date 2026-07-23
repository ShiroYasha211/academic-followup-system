@extends('layouts.delegate')

@section('title', 'المواد الدراسية')

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
        background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        box-shadow: 0 4px 12px -2px rgba(59, 130, 246, 0.4);
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

    /* Stats Row - Mini */
    .stats-row {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .stat-mini {
        background: white;
        border-radius: 16px;
        padding: 1.25rem;
        border: 1px solid var(--border-color);
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .stat-mini .icon {
        width: 48px;
        height: 48px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .stat-mini .value {
        font-size: 1.5rem;
        font-weight: 700;
        line-height: 1;
    }

    .stat-mini .label {
        font-size: 0.85rem;
        color: var(--text-secondary);
        margin-top: 0.25rem;
    }

    /* Create Card */
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
        background: linear-gradient(135deg, #3b82f6, #2563eb);
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

    .input-wrapper input,
    .input-wrapper select {
        width: 100%;
        padding: 0.875rem 1rem;
        border: 1px solid var(--border-color);
        border-radius: 10px;
        font-size: 0.95rem;
        transition: all 0.2s;
        background: #fafafa;
    }

    .input-wrapper input:focus,
    .input-wrapper select:focus {
        border-color: #3b82f6;
        background: white;
        outline: none;
        box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
    }

    .btn-submit {
        width: 100%;
        padding: 0.875rem;
        background: linear-gradient(135deg, #3b82f6, #2563eb);
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
        box-shadow: 0 4px 12px -2px rgba(59, 130, 246, 0.4);
    }

    /* Subjects Grid */
    .subjects-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
        gap: 1.5rem;
    }

    .subject-card {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        overflow: hidden;
        transition: all 0.3s;
        display: flex;
        flex-direction: column;
    }

    .subject-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 12px 24px -8px rgba(0, 0, 0, 0.12);
    }

    .subject-header {
        padding: 1.25rem 1.5rem;
        background: linear-gradient(135deg, #f8fafc 0%, #fff 100%);
        border-bottom: 1px solid var(--border-color);
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
    }

    .subject-icon {
        width: 52px;
        height: 52px;
        background: linear-gradient(135deg, #3b82f6, #1d4ed8);
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        box-shadow: 0 4px 12px -2px rgba(59, 130, 246, 0.3);
    }

    .subject-code {
        background: #e0f2fe;
        color: #0369a1;
        padding: 0.35rem 0.75rem;
        border-radius: 8px;
        font-size: 0.8rem;
        font-weight: 600;
        font-family: monospace;
    }

    .subject-body {
        padding: 1.25rem 1.5rem;
        flex: 1;
    }

    .subject-name {
        font-size: 1.15rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.75rem;
    }

    .subject-doctor {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        margin-bottom: 1rem;
    }

    .doctor-avatar {
        width: 36px;
        height: 36px;
        border-radius: 50%;
        background: linear-gradient(135deg, #06b6d4, #0891b2);
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        font-size: 0.9rem;
    }

    .doctor-info .name {
        font-weight: 600;
        font-size: 0.95rem;
        color: var(--text-primary);
    }

    .doctor-info .role {
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    .subject-meta {
        display: flex;
        gap: 1rem;
        padding-top: 1rem;
        border-top: 1px solid #f1f5f9;
        margin-top: 0.5rem;
    }

    .meta-item {
        display: flex;
        align-items: center;
        gap: 0.35rem;
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    .subject-actions {
        padding: 1rem 1.5rem;
        background: #fafafa;
        border-top: 1px solid var(--border-color);
        display: flex;
        gap: 0.5rem;
    }

    .btn-top {
        flex: 1;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        padding: 0.75rem;
        border: none;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.9rem;
        cursor: pointer;
        transition: all 0.2s;
        text-decoration: none;
    }

    .btn-attendance {
        background: linear-gradient(135deg, #10b981, #059669);
        color: white;
    }

    .btn-attendance:hover {
        box-shadow: 0 4px 12px -2px rgba(16, 185, 129, 0.4);
        transform: translateY(-1px);
    }

    .action-sub-btn {
        width: 40px;
        height: 40px;
        border-radius: 10px;
        border: none;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all 0.2s;
    }

    .btn-edit {
        background: #e0f2fe;
        color: #0284c7;
    }

    .btn-edit:hover {
        background: #bae6fd;
    }

    .btn-delete {
        background: #fee2e2;
        color: #dc2626;
    }

    .btn-delete:hover {
        background: #fecaca;
    }

    .empty-state {
        text-align: center;
        padding: 4rem 2rem;
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        grid-column: 1 / -1;
    }

    .empty-state svg {
        margin-bottom: 1rem;
        opacity: 0.4;
    }

    .empty-state h3 {
        font-size: 1.15rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.5rem;
    }

    .empty-state p {
        color: var(--text-secondary);
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
    deleteUrl: '', 
    modalTitle: '', 
    modalMessage: '',
    editUrl: '',
    editName: '',
    editCode: '',
    editTermId: '',
    editDoctorId: ''
}">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
            </svg>
        </div>
        <div class="page-header-text">
            <h1>المواد الدراسية</h1>
            <p>إدارة وإضافة المواد المقررة للدفعة وتعيين الدكاترة</p>
        </div>
    </div>

    @if(session('success'))
    <div class="alert alert-success" style="margin-bottom: 1.5rem;">
        {{ session('success') }}
    </div>
    @endif

    @if(session('error'))
    <div class="alert alert-danger" style="margin-bottom: 1.5rem;">
        {{ session('error') }}
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
            يرجى التحقق من المدخلات:
        </div>
        <ul style="margin: 0; padding-right: 1.5rem; color: #dc2626; font-size: 0.9rem;">
            @foreach($errors->all() as $error)
            <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
    @endif

    <div class="content-grid">
        <!-- Forms Column -->
        <div style="display: flex; flex-direction: column; gap: 1.5rem;">

            <!-- Stats -->
            <div style="display: flex; flex-direction: column; gap: 1rem;">
                <div class="stat-mini">
                    <div class="icon" style="background: rgba(59, 130, 246, 0.1); color: #3b82f6;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                            <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                        </svg>
                    </div>
                    <div>
                        <div class="value" style="color: #3b82f6;">{{ count($subjects) }}</div>
                        <div class="label">إجمالي المواد</div>
                    </div>
                </div>
            </div>

            <!-- Create Form Card -->
            <div class="create-card">
                <div class="create-header">
                    <h3>
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M12 5v14M5 12h14"></path>
                        </svg>
                        إضافة مادة جديدة
                    </h3>
                </div>
                <div class="create-body">
                    <form action="{{ route('delegate.subjects.store') }}" method="POST">
                        @csrf

                        <div class="form-group">
                            <label>اسم المادة *</label>
                            <div class="input-wrapper">
                                <input type="text" name="name" placeholder="مثال: هندسة البرمجيات..." required>
                            </div>
                        </div>

                        <div class="form-group">
                            <label>كود المادة</label>
                            <div class="input-wrapper">
                                <input type="text" name="code" placeholder="مثال: SE301">
                            </div>
                        </div>

                        <div class="form-group">
                            <label>دكتور المادة *</label>
                            <div class="input-wrapper">
                                <select name="doctor_id" required>
                                    <option value="">-- اختر الدكتور --</option>
                                    @foreach($doctors as $doctor)
                                    <option value="{{ $doctor->id }}">د. {{ $doctor->name }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </div>

                        <div class="form-group">
                            <label>الترم الدراسي *</label>
                            <div class="input-wrapper">
                                <select name="term_id" required>
                                    <option value="">-- اختر الترم --</option>
                                    @foreach($terms as $term)
                                    <option value="{{ $term->id }}">{{ $term->name }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </div>

                        @php $canCreate = Auth::user()->hasDelegatePermission('subjects', 'create'); @endphp
                        <button type="{{ $canCreate ? 'submit' : 'button' }}" class="btn-submit {{ !$canCreate ? 'btn-locked' : '' }}" @if(!$canCreate) title="ليس لديك صلاحية إضافة مواد" @endif>
                            {{ $canCreate ? 'حفظ وإضافة المادة' : 'ليس لديك صلاحية إضافة' }}
                        </button>
                    </form>
                </div>
            </div>
        </div>

        <!-- Subjects List Column -->
        <div>
            @if($subjects->isEmpty())
            <div class="empty-state">
                <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                </svg>
                <h3>لا توجد مواد دراسية</h3>
                <p>قم بإضافة المواد الدراسية للدكتور أو المقرر من النموذج الجانبي.</p>
            </div>
            @else
            <div class="subjects-grid">
                @foreach($subjects as $subject)
                <div class="subject-card">
                    <div class="subject-header">
                        <div class="subject-icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                                <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                            </svg>
                        </div>
                        <span class="subject-code">{{ $subject->code ?? 'N/A' }}</span>
                    </div>

                    <div class="subject-body">
                        <h3 class="subject-name">{{ $subject->name }}</h3>

                        <div class="subject-doctor">
                            @if($subject->doctor)
                            <div class="doctor-avatar">{{ mb_substr($subject->doctor->name, 0, 1) }}</div>
                            <div class="doctor-info">
                                <div class="name">د. {{ $subject->doctor->name }}</div>
                                <div class="role">أستاذ المادة</div>
                            </div>
                            @else
                            <div class="doctor-avatar" style="background: #e5e7eb; color: #9ca3af;">?</div>
                            <div class="doctor-info">
                                <div class="name" style="color: var(--text-secondary);">غير محدد</div>
                                <div class="role">لم يتم تعيين دكتور</div>
                            </div>
                            @endif
                        </div>

                        <div class="subject-meta">
                            <div class="meta-item">
                                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                                    <line x1="16" y1="2" x2="16" y2="6"></line>
                                    <line x1="8" y1="2" x2="8" y2="6"></line>
                                    <line x1="3" y1="10" x2="21" y2="10"></line>
                                </svg>
                                {{ $subject->term->name ?? 'الترم الحالي' }}
                            </div>
                        </div>
                    </div>

                    <div class="subject-actions">
                        <a href="{{ route('delegate.attendance.create', $subject->id) }}" class="btn-top btn-attendance">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="9 11 12 14 22 4"></polyline>
                                <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path>
                            </svg>
                            حضور
                        </a>
                        @php $canUpdate = Auth::user()->hasDelegatePermission('subjects', 'update'); @endphp
                        <button type="button" class="action-sub-btn btn-edit {{ !$canUpdate ? 'btn-locked' : '' }}"
                            @if($canUpdate)
                            @click="
                                    showEditModal = true;
                                    modalTitle = 'تعديل: {{ $subject->name }}';
                                    editUrl = '{{ route('delegate.subjects.update', $subject) }}';
                                    editName = '{{ $subject->name }}';
                                    editCode = '{{ $subject->code }}';
                                    editTermId = '{{ $subject->term_id }}';
                                    editDoctorId = '{{ $subject->doctor_id }}';
                                "
                            @else
                            title="ليس لديك صلاحية تعديل المواد"
                            @endif
                            >
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                            </svg>
                        </button>
                        @php $canDelete = Auth::user()->hasDelegatePermission('subjects', 'delete'); @endphp
                        <button type="button" class="action-sub-btn btn-delete {{ !$canDelete ? 'btn-locked' : '' }}" title="حذف المادة"
                            @if($canDelete)
                            @click="
                                    showDeleteModal = true;
                                    deleteUrl = '{{ route('delegate.subjects.destroy', $subject) }}';
                                    modalTitle = 'حذف {{ $subject->name }}';
                                    modalMessage = 'سيتم حذف المادة ولن تتمكن من استرجاعها. تأكد أنه لا يوجد سجلات حضور مسجلة عليها.';
                                "
                            @else
                            title="ليس لديك صلاحية حذف المواد"
                            @endif
                            >
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="3 6 5 6 21 6"></polyline>
                                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                            </svg>
                        </button>
                    </div>
                </div>
                @endforeach
            </div>
            @endif
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
                    <button type="submit" class="btn btn-danger">نعم، حذف المادة</button>
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
                    <label>اسم المادة *</label>
                    <div class="input-wrapper">
                        <input type="text" name="name" x-model="editName" required>
                    </div>
                </div>

                <div class="form-group">
                    <label>كود المادة</label>
                    <div class="input-wrapper">
                        <input type="text" name="code" x-model="editCode">
                    </div>
                </div>

                <div class="form-group">
                    <label>دكتور المادة *</label>
                    <div class="input-wrapper">
                        <select name="doctor_id" x-model="editDoctorId" required>
                            <option value="">-- اختر الدكتور --</option>
                            @foreach($doctors as $doctor)
                            <option value="{{ $doctor->id }}">د. {{ $doctor->name }}</option>
                            @endforeach
                        </select>
                    </div>
                </div>

                <div class="form-group">
                    <label>الترم الدراسي *</label>
                    <div class="input-wrapper">
                        <select name="term_id" x-model="editTermId" required>
                            <option value="">-- اختر الترم --</option>
                            @foreach($terms as $term)
                            <option value="{{ $term->id }}">{{ $term->name }}</option>
                            @endforeach
                        </select>
                    </div>
                </div>

                <div class="modal-actions" style="margin-top: 1.5rem;">
                    <button type="button" class="btn btn-secondary" @click="showEditModal = false">إلغاء</button>
                    <button type="submit" class="btn btn-primary" style="background: linear-gradient(135deg, #0284c7, #0369a1); border: none;">حفظ التغييرات</button>
                </div>
            </form>
        </div>
    </div>

</div>


@endsection