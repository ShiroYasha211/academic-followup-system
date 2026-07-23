@extends('layouts.administrative')

@section('title', 'إدارة التخصصات - ' . $college->name)

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

    .form-card {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        padding: 1.5rem;
        box-shadow: var(--shadow-sm);
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
        margin: 0;
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

    .table-card {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        padding: 1.5rem;
        box-shadow: var(--shadow-sm);
    }

    .table-card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.5rem;
        padding-bottom: 1rem;
        border-bottom: 1px solid var(--border-color);
    }

    .count-badge {
        background: #10b981;
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

    .modern-table tbody td {
        padding: 1rem;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
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

    .action-btn.edit { background: #eff6ff; color: #3b82f6; }
    .action-btn.delete { background: #fef2f2; color: #ef4444; }

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
        border: 1px solid #dcfce7;
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
    editHasClinical: false,
    editHasSemesters: false
}">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
                <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
            </svg>
        </div>
        <div class="page-header-text">
            <h1>إدارة التخصصات</h1>
            <p>إعداد التخصصات الأكاديمية والهياكل التعليمية لكلية {{ $college->name }}</p>
        </div>
    </div>

    <div style="display: grid; grid-template-columns: 1fr 2fr; gap: 1.5rem; align-items: start;">

        <!-- Create Form -->
        <div class="form-card">
            <div class="form-card-header">
                <div class="icon">
                    <i class="fas fa-plus"></i>
                </div>
                <h3>إضافة تخصص جديد</h3>
            </div>

            <form action="{{ route('administrative.majors.store') }}" method="POST">
                @csrf

                <div class="form-group mb-4">
                    <label class="form-label font-weight-bold mb-2">اسم التخصص</label>
                    <input type="text" name="name" class="form-control" placeholder="مثال: هندسة البرمجيات" required>
                </div>

                <!-- Automation Section -->
                <div class="automation-section">
                    <h4>
                        <i class="fas fa-magic"></i>
                        الإعداد التلقائي للهيكل
                    </h4>
                    <div class="automation-grid">
                        <div class="form-group">
                            <label class="form-label font-weight-bold mb-2">عدد المستويات</label>
                            <input type="number" name="levels_count" class="form-control" value="4" min="1" max="8" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label font-weight-bold mb-2">الفصول لكل مستوى</label>
                            <input type="number" name="terms_count" class="form-control" value="2" min="1" max="4" required>
                        </div>
                    </div>
                    <small style="color: #166534; font-size: 0.75rem; margin-top: 0.5rem; display: block;">سيقوم النظام بإنشاء المستويات والفصول تلقائياً بضغطة زر</small>
                </div>

                <div style="margin-top: 1rem; padding: 1rem; background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 12px;">
                    <label style="display: flex; align-items: center; gap: 0.75rem; cursor: pointer; font-weight: 600; color: #1e40af;">
                        <input type="checkbox" name="has_clinical" value="1" style="width: 18px; height: 18px; accent-color: #3b82f6;">
                        <span>يحتوي على تدريب عملي (سريري)</span>
                    </label>
                </div>

                <div x-data="{ hasSemesters: false }" style="margin-top: 1rem; padding: 1rem; background: #faf5ff; border: 1px solid #e9d5ff; border-radius: 12px;">
                    <label style="display: flex; align-items: center; gap: 0.75rem; cursor: pointer; font-weight: 600; color: #6b21a8;">
                        <input type="checkbox" name="has_semesters" value="1" x-model="hasSemesters" style="width: 18px; height: 18px; accent-color: #a855f7;">
                        <span>يحتوي على نظام سيمسترات</span>
                    </label>
                    <div x-show="hasSemesters" x-transition style="margin-top: 1rem; padding-top: 1rem; border-top: 1px dashed #d8b4fe;">
                        <label class="form-label" style="color: #6b21a8;">عدد السيمسترات في كل ترم</label>
                        <input type="number" name="semesters_per_term" class="form-control" value="0" min="0" max="10">
                    </div>
                </div>

                <button type="submit" class="btn-submit">
                    <i class="fas fa-save"></i>
                    <span>حفظ وإنشاء الهيكل</span>
                </button>
            </form>
        </div>

        <!-- Table Card -->
        <div class="table-card">
            <div class="table-card-header">
                <h3><i class="fas fa-list-ul" style="color: #10b981;"></i> قائمة التخصصات</h3>
                <span class="count-badge">{{ $majors->count() }} تخصص</span>
            </div>

            <div class="table-responsive">
                <table class="modern-table">
                    <thead>
                        <tr>
                            <th>التخصص</th>
                            <th>الهيكل الأكاديمي</th>
                            <th style="width: 150px;">الإجراءات</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($majors as $major)
                        <tr>
                            <td style="font-weight: 700; color: #1e293b;">
                                {{ $major->name }}
                                @if($major->has_clinical)
                                <span style="background: #dbeafe; color: #1e40af; padding: 0.15rem 0.4rem; border-radius: 4px; font-size: 0.7rem; margin-right: 0.5rem;">عملي</span>
                                @endif
                            </td>
                            <td>
                                <div style="display: flex; gap: 0.5rem;">
                                    <span class="structure-badge">
                                        <i class="fas fa-layer-group" style="font-size: 0.7rem;"></i>
                                        {{ $major->levels->count() }} مستويات
                                    </span>
                                    <span class="structure-badge">
                                        <i class="fas fa-calendar-alt" style="font-size: 0.7rem;"></i>
                                        {{ $major->levels->sum(fn($l) => $l->terms->count()) }} أترام
                                    </span>
                                </div>
                            </td>
                            <td>
                                <div style="display: flex; gap: 0.5rem;">
                                    <button @click="
                                        showEditModal = true;
                                        modalTitle = 'تعديل: {{ $major->name }}';
                                        editUrl = '{{ route('administrative.majors.update', $major) }}';
                                        editName = '{{ $major->name }}';
                                        editHasClinical = {{ $major->has_clinical ? 'true' : 'false' }};
                                        editHasSemesters = {{ $major->has_semesters ? 'true' : 'false' }};
                                    " class="action-btn edit" title="تعديل">
                                        <i class="fas fa-edit"></i>
                                    </button>

                                    <button @click="
                                        showDeleteModal = true;
                                        deleteUrl = '{{ route('administrative.majors.destroy', $major) }}';
                                        modalTitle = 'حذف {{ $major->name }}';
                                        modalMessage = 'سيؤدي هذا لحذف التخصص بجميع مستوياته. لا يمكن التراجع عن هذا الإجراء.';
                                    " class="action-btn delete" title="حذف">
                                        <i class="fas fa-trash-alt"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="3" style="text-align: center; padding: 4rem;">
                                <div style="color: #94a3b8; font-weight: 600;">لا توجد تخصصات مضافة حالياً</div>
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

            <div style="background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af; padding: 1rem; border-radius: 12px; font-size: 0.85rem; margin-bottom: 1.5rem;">
                <i class="fas fa-info-circle"></i> يمكن تعديل الاسم والإعدادات العامة فقط. لا يمكن تغيير عدد المستويات بعد إنشائها.
            </div>

            <div class="form-group mb-4">
                <label class="form-label font-weight-bold mb-2">اسم التخصص</label>
                <input type="text" name="name" class="form-control" x-model="editName" required>
            </div>

            <div style="margin-bottom: 1rem; padding: 1rem; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px;">
                <label style="display: flex; align-items: center; gap: 0.75rem; cursor: pointer; font-weight: 600;">
                    <input type="checkbox" name="has_clinical" value="1" :checked="editHasClinical" style="width: 18px; height: 18px; accent-color: #3b82f6;">
                    <span>تدريب عملي (سريري)</span>
                </label>
            </div>

            <div style="padding: 1rem; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; margin-bottom: 2rem;">
                <label style="display: flex; align-items: center; gap: 0.75rem; cursor: pointer; font-weight: 600;">
                    <input type="checkbox" name="has_semesters" value="1" :checked="editHasSemesters" style="width: 18px; height: 18px; accent-color: #a855f7;">
                    <span>نظام سيمسترات</span>
                </label>
            </div>

            <div class="modal-actions" style="display: flex; gap: 0.75rem;">
                <button type="submit" class="btn btn-primary" style="flex: 2; padding: 0.8rem; border-radius: 12px; font-weight: 700;">حفظ التغييرات</button>
                <button type="button" class="btn btn-secondary" @click="showEditModal = false" style="flex: 1; padding: 0.8rem; border-radius: 12px; font-weight: 600;">إلغاء</button>
            </div>
        </form>
    </x-edit-modal>

</div>

@endsection
