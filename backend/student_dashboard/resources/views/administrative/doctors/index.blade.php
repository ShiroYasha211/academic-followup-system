@extends('layouts.administrative')

@section('title', 'إدارة الدكاترة - ' . $college->name)

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
        background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
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

    .form-card {
        background: white;
        border-radius: 24px;
        border: 1px solid var(--border-color);
        padding: 2rem;
        box-shadow: var(--shadow-sm);
    }

    .form-card-header {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin-bottom: 2rem;
        padding-bottom: 1.25rem;
        border-bottom: 1px solid var(--border-color);
    }

    .form-card-header .icon {
        width: 44px;
        height: 44px;
        background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
    }

    .form-card-header h3 {
        font-size: 1.25rem;
        font-weight: 700;
        margin: 0;
    }

    .input-with-icon {
        position: relative;
    }

    .input-with-icon .icon {
        position: absolute;
        right: 14px;
        top: 50%;
        transform: translateY(-50%);
        color: var(--text-light);
        display: flex;
        align-items: center;
    }

    .input-with-icon input {
        padding-right: 2.75rem;
        border-radius: 12px;
        border: 2px solid #f1f5f9;
        transition: all 0.3s;
    }

    .input-with-icon input:focus {
        border-color: #3b82f6;
        box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.1);
    }

    .table-card {
        background: white;
        border-radius: 24px;
        border: 1px solid var(--border-color);
        padding: 2rem;
        box-shadow: var(--shadow-sm);
    }

    .table-card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 2rem;
    }

    .table-card-header h3 {
        font-size: 1.25rem;
        font-weight: 700;
        display: flex;
        align-items: center;
        gap: 0.75rem;
        margin: 0;
    }

    .count-badge {
        background: #eff6ff;
        color: #1e40af;
        padding: 0.5rem 1rem;
        border-radius: 12px;
        font-size: 0.9rem;
        font-weight: 700;
        border: 1px solid #dbeafe;
    }

    .modern-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
    }

    .modern-table thead th {
        background: #f8fafc;
        padding: 1.25rem 1rem;
        text-align: right;
        font-weight: 700;
        color: var(--text-secondary);
        font-size: 0.85rem;
        text-transform: uppercase;
        letter-spacing: 0.025em;
        border-bottom: 2px solid #f1f5f9;
    }

    .modern-table tbody td {
        padding: 1.25rem 1rem;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
    }

    .doctor-avatar {
        width: 48px;
        height: 48px;
        background: linear-gradient(135deg, #dbeafe, #bfdbfe);
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.1rem;
        font-weight: 800;
        color: #2563eb;
    }

    .btn-submit {
        width: 100%;
        padding: 1rem;
        background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
        color: white;
        border: none;
        border-radius: 14px;
        font-size: 1.1rem;
        font-weight: 700;
        cursor: pointer;
        transition: all 0.3s;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.75rem;
        box-shadow: 0 10px 15px -3px rgba(59, 130, 246, 0.2);
    }

    .btn-submit:hover {
        transform: translateY(-2px);
        box-shadow: 0 20px 25px -5px rgba(59, 130, 246, 0.3);
    }

    .action-btn {
        width: 36px;
        height: 36px;
        border-radius: 10px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        border: none;
        cursor: pointer;
        transition: all 0.2s;
        color: white;
    }

    .action-btn.edit { background: #3b82f6; }
    .action-btn.stars { background: #d97706; }
    .action-btn.delete { background: #ef4444; }
    .action-btn:hover { transform: translateY(-2px); filter: brightness(1.1); }
</style>

<div x-data="{ 
    showDeleteModal: false, 
    showEditModal: false,
    showStarsModal: false,
    deleteUrl: '', 
    modalTitle: '', 
    modalMessage: '',
    
    editUrl: '',
    editName: '',
    editEmail: '',
    starsUrl: '',
    starsDoctorName: '',
    starsBalance: 0
}">

    <!-- Page Header -->
    <div class="page-header">
        <div class="page-header-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                <circle cx="12" cy="7" r="4"></circle>
            </svg>
        </div>
        <div class="page-header-text">
            <h1>إدارة الدكاترة</h1>
            <p>إدارة أعضاء هيئة التدريس في كلية {{ $college->name }}</p>
        </div>
    </div>

    <div style="display: grid; grid-template-columns: 1fr 2.5fr; gap: 2rem; align-items: start;">

        <!-- Create Form -->
        <div class="form-card">
            <div class="form-card-header">
                <div class="icon">
                    <i class="fas fa-user-plus"></i>
                </div>
                <h3>إضافة دكتور جديد</h3>
            </div>

            <form action="{{ route('administrative.doctors.store') }}" method="POST">
                @csrf
                <div class="form-group mb-4">
                    <label class="form-label font-weight-bold mb-2">اسم الدكتور</label>
                    <div class="input-with-icon">
                        <span class="icon"><i class="fas fa-user-tie"></i></span>
                        <input type="text" name="name" class="form-control" placeholder="الاسم الكامل للدكتور..." required>
                    </div>
                </div>

                <div class="form-group mb-4">
                    <label class="form-label font-weight-bold mb-2">البريد الإلكتروني</label>
                    <div class="input-with-icon">
                        <span class="icon"><i class="fas fa-envelope"></i></span>
                        <input type="email" name="email" class="form-control" placeholder="doctor@college.edu" required>
                    </div>
                </div>

                <div class="form-group mb-5">
                    <label class="form-label font-weight-bold mb-2">كلمة المرور</label>
                    <div class="input-with-icon">
                        <span class="icon"><i class="fas fa-lock"></i></span>
                        <input type="password" name="password" class="form-control" placeholder="8 أحرف على الأقل..." required>
                    </div>
                </div>

                <button type="submit" class="btn-submit">
                    <i class="fas fa-save"></i>
                    <span>حفظ البيانات</span>
                </button>
            </form>
        </div>

        <!-- Table Card -->
        <div class="table-card">
            <div class="table-card-header">
                <h3>
                    <i class="fas fa-users" style="color: #3b82f6;"></i>
                    الدكاترة الحاليين
                </h3>
                <span class="count-badge">{{ $doctors->total() }} دكتور مسجل</span>
            </div>

            <div class="table-responsive">
                <table class="modern-table">
                    <thead>
                        <tr>
                            <th>الدكتور</th>
                            <th>المواد المسؤولة</th>
                            <th>رصيد المنح</th>
                            <th style="width: 160px;">الإجراءات</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($doctors as $doctor)
                        <tr>
                            <td>
                                <div style="display: flex; align-items: center; gap: 1rem;">
                                    <div class="doctor-avatar">{{ mb_substr($doctor->name, 0, 1) }}</div>
                                    <div>
                                        <div style="font-weight: 700; color: #1e293b;">{{ $doctor->name }}</div>
                                        <div style="font-size: 0.8rem; color: #64748b;">{{ $doctor->email }}</div>
                                    </div>
                                </div>
                            </td>
                            <td>
                                @if($doctor->subjects->count() > 0)
                                    <div style="display: flex; flex-wrap: wrap; gap: 0.4rem;">
                                        @foreach($doctor->subjects->take(3) as $subject)
                                            <span style="background: #f1f5f9; padding: 0.2rem 0.6rem; border-radius: 6px; font-size: 0.75rem; color: #475569; border: 1px solid #e2e8f0;">
                                                {{ $subject->name }}
                                            </span>
                                        @endforeach
                                        @if($doctor->subjects->count() > 3)
                                            <span style="font-size: 0.75rem; color: #64748b; font-weight: 600;">+ {{ $doctor->subjects->count() - 3 }} أخرى</span>
                                        @endif
                                    </div>
                                @else
                                    <span style="color: #94a3b8; font-size: 0.85rem; font-style: italic;">لا توجد مواد حالياً</span>
                                @endif
                            </td>
                            <td>
                                <div style="display:inline-flex;align-items:center;gap:.45rem;background:#fffbeb;color:#92400e;border:1px solid #fde68a;padding:.45rem .7rem;border-radius:10px;font-weight:800;">
                                    <i class="fas fa-star"></i>
                                    {{ $doctor->doctorStarWallet?->balance ?? 0 }}
                                </div>
                            </td>
                            <td>
                                <div style="display: flex; gap: 0.5rem;">
                                    <button @click="
                                        showStarsModal = true;
                                        starsUrl = '{{ route('administrative.doctors.star-wallet.top-up', $doctor) }}';
                                        starsDoctorName = @js($doctor->name);
                                        starsBalance = {{ $doctor->doctorStarWallet?->balance ?? 0 }};
                                    " class="action-btn stars" title="إضافة رصيد نجوم">
                                        <i class="fas fa-star"></i>
                                    </button>
                                    <button @click="
                                        showEditModal = true;
                                        modalTitle = 'تعديل بيانات: {{ $doctor->name }}';
                                        editUrl = '{{ route('administrative.doctors.update', $doctor) }}';
                                        editName = '{{ $doctor->name }}';
                                        editEmail = '{{ $doctor->email }}';
                                    " class="action-btn edit" title="تعديل">
                                        <i class="fas fa-edit"></i>
                                    </button>

                                    <button @click="
                                        showDeleteModal = true;
                                        deleteUrl = '{{ route('administrative.doctors.destroy', $doctor) }}';
                                        modalTitle = 'حذف الدكتور: {{ $doctor->name }}';
                                        modalMessage = 'سيتم حذف حساب الدكتور وجميع صلاحياته. لن يتمكن من الوصول للمواد. هل أنت متأكد؟';
                                    " class="action-btn delete" title="حذف">
                                        <i class="fas fa-trash-alt"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="4" style="text-align: center; padding: 4rem;">
                                <div style="color: #94a3b8; font-weight: 600;">لا يوجد دكاترة مسجلين في الكلية حالياً</div>
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <div style="margin-top: 2rem;">
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

            <div class="form-group mb-4">
                <label class="form-label font-weight-bold">الاسم الكامل</label>
                <div class="input-with-icon">
                    <span class="icon"><i class="fas fa-user-tie"></i></span>
                    <input type="text" name="name" class="form-control" x-model="editName" required>
                </div>
            </div>

            <div class="form-group mb-4">
                <label class="form-label font-weight-bold">البريد الإلكتروني</label>
                <div class="input-with-icon">
                    <span class="icon"><i class="fas fa-envelope"></i></span>
                    <input type="email" name="email" class="form-control" x-model="editEmail" required>
                </div>
            </div>

            <div class="form-group mb-5" style="background: #f8fafc; padding: 1.25rem; border-radius: 16px; border: 1px dashed #ced4da;">
                <label class="form-label" style="color: #64748b;">كلمة المرور الجديدة (اختياري)</label>
                <div class="input-with-icon">
                    <span class="icon"><i class="fas fa-lock"></i></span>
                    <input type="password" name="password" class="form-control" placeholder="اتركه فارغاً للحفاظ على الحالية">
                </div>
            </div>

            <div class="modal-actions" style="display: flex; gap: 0.75rem;">
                <button type="submit" class="btn btn-primary" style="flex: 2; padding: 1rem; border-radius: 14px; font-weight: 700;">تحديث البيانات</button>
                <button type="button" class="btn btn-secondary" @click="showEditModal = false" style="flex: 1; padding: 1rem; border-radius: 14px; font-weight: 600;">إلغاء</button>
            </div>
        </form>
    </x-edit-modal>

    <div x-show="showStarsModal" x-cloak
         style="position:fixed;inset:0;background:rgba(15,23,42,.55);z-index:1050;display:flex;align-items:center;justify-content:center;padding:1rem;"
         @keydown.escape.window="showStarsModal = false">
        <div @click.outside="showStarsModal = false"
             style="width:min(480px,100%);background:white;border-radius:22px;padding:1.5rem;box-shadow:0 24px 70px rgba(15,23,42,.25);">
            <div class="d-flex align-items-center justify-content-between mb-4">
                <div>
                    <h3 class="h5 fw-bold mb-1">إضافة رصيد منح النجوم</h3>
                    <div class="text-muted small" x-text="starsDoctorName"></div>
                </div>
                <div style="background:#fffbeb;color:#92400e;border-radius:12px;padding:.55rem .8rem;font-weight:800;">
                    <i class="fas fa-star me-1"></i>
                    <span x-text="starsBalance"></span>
                </div>
            </div>
            <form :action="starsUrl" method="POST">
                @csrf
                <div class="mb-3">
                    <label class="form-label fw-bold">عدد النجوم المضافة</label>
                    <input type="number" name="amount" class="form-control" min="1" max="1000000" required>
                </div>
                <div class="mb-4">
                    <label class="form-label fw-bold">سبب الإضافة</label>
                    <textarea name="reason" class="form-control" rows="3" maxlength="255" required
                              placeholder="مثال: تعزيز رصيد المنح للفصل الحالي"></textarea>
                </div>
                <div class="d-flex gap-2">
                    <button type="submit" class="btn btn-warning flex-grow-1 fw-bold">تأكيد إضافة الرصيد</button>
                    <button type="button" class="btn btn-light" @click="showStarsModal = false">إلغاء</button>
                </div>
            </form>
        </div>
    </div>

</div>

@endsection
