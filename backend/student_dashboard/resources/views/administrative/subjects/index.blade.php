@extends('layouts.administrative')

@section('title', 'إدارة المواد - ' . $college->name)

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
        background: linear-gradient(135deg, #8b5cf6 0%, #6d28d9 100%);
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        box-shadow: 0 4px 12px -2px rgba(139, 92, 246, 0.4);
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
        background: linear-gradient(135deg, #8b5cf6 0%, #6d28d9 100%);
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
        background: #8b5cf6;
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
        background: linear-gradient(135deg, #8b5cf6 0%, #6d28d9 100%);
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

    .code-badge {
        font-family: 'JetBrains Mono', monospace;
        background: #f1f5f9;
        color: #475569;
        padding: 0.25rem 0.5rem;
        border-radius: 6px;
        font-size: 0.75rem;
        font-weight: 700;
        border: 1px solid #e2e8f0;
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
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
            </svg>
        </div>
        <div class="page-header-text">
            <h1>إدارة المواد الدراسية</h1>
            <p>تثبيت المناهج الدراسية وتعيين الأساتذة لكلية {{ $college->name }}</p>
        </div>
    </div>

    <div style="display: grid; grid-template-columns: 1fr 2.5fr; gap: 1.5rem; align-items: start;">

        <!-- Create Form -->
        <div class="form-card">
            <div class="form-card-header">
                <div class="icon">
                    <i class="fas fa-plus"></i>
                </div>
                <h3>إضافة مادة جديدة</h3>
            </div>

            <form action="{{ route('administrative.subjects.store') }}" method="POST">
                @csrf

                <div class="form-group mb-3">
                    <label class="form-label font-weight-bold mb-2">اسم المادة</label>
                    <input type="text" name="name" class="form-control" placeholder="اسم المادة..." required>
                </div>

                <div class="form-group mb-3">
                    <label class="form-label font-weight-bold mb-2">كود المادة (اختياري)</label>
                    <input type="text" name="code" class="form-control" placeholder="مثال: CS101">
                </div>

                <div class="form-group mb-3">
                    <label class="form-label font-weight-bold mb-2">التخصص والمستوى (الترم)</label>
                    <select name="term_id" class="form-control" required>
                        <option value="">اختر الترم...</option>
                        @foreach($terms as $term)
                        <option value="{{ $term->id }}">
                            {{ $term->level->major->name }} - {{ $term->level->name }} - {{ $term->name }}
                        </option>
                        @endforeach
                    </select>
                </div>

                <div class="form-group mb-4">
                    <label class="form-label font-weight-bold mb-2">أستاذ المادة</label>
                    <select name="doctor_id" class="form-control">
                        <option value="">اختر الدكتور (اختياري)...</option>
                        @foreach($doctors as $doctor)
                        <option value="{{ $doctor->id }}">{{ $doctor->name }}</option>
                        @endforeach
                    </select>
                </div>

                <button type="submit" class="btn-submit">
                    <i class="fas fa-check-circle"></i>
                    <span>تأكيد الإضافة</span>
                </button>
            </form>
        </div>

        <!-- Table Card -->
        <div class="table-card">
            <div class="table-card-header">
                <h3><i class="fas fa-book" style="color: #8b5cf6;"></i> قائمة المواد الدراسية</h3>
                <span class="count-badge">{{ $subjects->total() }} مادة</span>
            </div>

            <div class="table-responsive">
                <table class="modern-table">
                    <thead>
                        <tr>
                            <th>المادة</th>
                            <th>التخصص / المستوى / الترم</th>
                            <th>أستاذ المادة</th>
                            <th style="width: 140px;">الإجراءات</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($subjects as $subject)
                        <tr>
                            <td>
                                <div style="font-weight: 700; color: #1e293b; margin-bottom: 0.25rem;">{{ $subject->name }}</div>
                                @if($subject->code)
                                    <span class="code-badge">{{ $subject->code }}</span>
                                @endif
                            </td>
                            <td>
                                <div style="font-weight: 600; color: #475569; font-size: 0.85rem;">{{ $subject->major->name ?? '-' }}</div>
                                <div style="font-size: 0.75rem; color: #94a3b8;">{{ $subject->level->name ?? '-' }} | {{ $subject->term->name ?? '-' }}</div>
                            </td>
                            <td>
                                @if($subject->doctor)
                                    <div style="display: flex; align-items: center; gap: 0.5rem;">
                                        <div style="width: 32px; height: 32px; background: #f3f4f6; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 0.75rem; font-weight: 700;">{{ mb_substr($subject->doctor->name, 0, 1) }}</div>
                                        <div style="font-weight: 600; color: #1e293b; font-size: 0.85rem;">{{ $subject->doctor->name }}</div>
                                    </div>
                                @else
                                    <span style="color: #cbd5e1; font-size: 0.8rem; font-style: italic;">لم يحدد</span>
                                @endif
                            </td>
                            <td>
                                <div style="display: flex; gap: 0.5rem;">
                                    <button @click="
                                        showEditModal = true;
                                        modalTitle = 'تعديل: {{ $subject->name }}';
                                        editUrl = '{{ route('administrative.subjects.update', $subject) }}';
                                        editName = '{{ $subject->name }}';
                                        editCode = '{{ $subject->code }}';
                                        editTermId = '{{ $subject->term_id }}';
                                        editDoctorId = '{{ $subject->doctor_id }}';
                                    " class="action-btn edit" title="تعديل">
                                        <i class="fas fa-edit"></i>
                                    </button>

                                    <button @click="
                                        showDeleteModal = true;
                                        deleteUrl = '{{ route('administrative.subjects.destroy', $subject) }}';
                                        modalTitle = 'حذف مادة: {{ $subject->name }}';
                                        modalMessage = 'سيتم حذف المادة وجميع سجلات الحضور المرتبطة بها. هل أنت متأكد؟';
                                    " class="action-btn delete" title="حذف">
                                        <i class="fas fa-trash-alt"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="4" style="text-align: center; padding: 4rem;">
                                <div style="color: #94a3b8; font-weight: 600;">لا توجد مواد دراسية مضافة حالياً</div>
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <div style="margin-top: 2rem;">
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

            <div class="form-group mb-3">
                <label class="form-label font-weight-bold">اسم المادة</label>
                <input type="text" name="name" class="form-control" x-model="editName" required>
            </div>

            <div class="form-group mb-3">
                <label class="form-label font-weight-bold">كود المادة</label>
                <input type="text" name="code" class="form-control" x-model="editCode">
            </div>

            <div class="form-group mb-3">
                <label class="form-label font-weight-bold">الترم الدراسي</label>
                <select name="term_id" class="form-control" x-model="editTermId" required>
                    @foreach($terms as $term)
                    <option value="{{ $term->id }}">
                        {{ $term->level->major->name }} - {{ $term->level->name }} - {{ $term->name }}
                    </option>
                    @endforeach
                </select>
            </div>

            <div class="form-group mb-4">
                <label class="form-label font-weight-bold">أستاذ المادة</label>
                <select name="doctor_id" class="form-control" x-model="editDoctorId">
                    <option value="">لم يحدد</option>
                    @foreach($doctors as $doctor)
                    <option value="{{ $doctor->id }}">{{ $doctor->name }}</option>
                    @endforeach
                </select>
            </div>

            <div class="modal-actions" style="display: flex; gap: 0.75rem;">
                <button type="submit" class="btn btn-primary" style="flex: 2; padding: 0.8rem; border-radius: 12px; font-weight: 700;">حفظ التغييرات</button>
                <button type="button" class="btn btn-secondary" @click="showEditModal = false" style="flex: 1; padding: 0.8rem; border-radius: 12px; font-weight: 600;">إلغاء</button>
            </div>
        </form>
    </x-edit-modal>

</div>

@endsection
