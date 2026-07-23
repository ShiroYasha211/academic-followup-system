@extends('layouts.admin')

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
        background: rgba(139, 92, 246, 0.1);
        color: #8b5cf6;
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
    }

    .btn-submit:hover {
        box-shadow: 0 4px 15px -3px rgba(16, 185, 129, 0.4);
        transform: translateY(-1px);
    }

    .student-avatar {
        width: 40px;
        height: 40px;
        background: linear-gradient(135deg, #d1fae5, #a7f3d0);
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 0.9rem;
        font-weight: 700;
        color: #059669;
    }

    .student-number {
        font-family: monospace;
        background: #f0fdf4;
        color: #166534;
        padding: 0.25rem 0.5rem;
        border-radius: 6px;
        font-size: 0.8rem;
        font-weight: 600;
    }

    .device-card {
        border: 1px solid #e5e7eb;
        border-radius: 12px;
        padding: 0.85rem;
        background: #ffffff;
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        transition: all 0.22s cubic-bezier(0.4, 0, 0.2, 1);
    }
    .device-card:hover {
        border-color: #cbd5e1;
        box-shadow: 0 5px 15px -3px rgba(0, 0, 0, 0.05), 0 4px 6px -2px rgba(0, 0, 0, 0.03);
        transform: translateY(-2px);
    }
    @keyframes spin {
        from { transform: rotate(0deg); }
        to { transform: rotate(360deg); }
    }

    .device-icon {
        width: 38px;
        height: 38px;
        border-radius: 11px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: #eff6ff;
        color: #2563eb;
        flex: 0 0 auto;
    }

    .device-meta {
        display: flex;
        flex-wrap: wrap;
        gap: 0.4rem;
        margin-top: 0.45rem;
    }

    .device-badge {
        display: inline-flex;
        align-items: center;
        border-radius: 999px;
        padding: 0.2rem 0.55rem;
        font-size: 0.72rem;
        font-weight: 700;
        background: #f1f5f9;
        color: #475569;
    }

    .device-badge.primary {
        background: #dcfce7;
        color: #166534;
    }

    .device-badge.secondary {
        background: #fef3c7;
        color: #92400e;
    }

    .device-badge.active {
        background: #dbeafe;
        color: #1d4ed8;
    }

    .device-badge.inactive {
        background: #fee2e2;
        color: #991b1b;
    }

    .active-tab {
        color: #2563eb !important;
        border-bottom: 2px solid #2563eb !important;
    }
    .inactive-tab {
        color: #64748b !important;
        border-bottom: 2px solid transparent !important;
    }
    .inactive-tab:hover {
        color: #334155 !important;
        border-bottom-color: #cbd5e1 !important;
    }
</style>

<div x-data="{ 
    showDeleteModal: false, 
    showEditModal: false,
    showDetailsModal: false,
    deleteUrl: '', 
    modalTitle: '', 
    
    // Device Requests modal state
    showDeviceRequestsModal: false,
    deviceRequestsList: [],
    isLoadingDeviceRequests: false,
    rejectingRequest: null,
    adminRejectNote: '',
    adminApproveNote: '',
    modalMessage: '',
    
    editUrl: '',
    editName: '',
    editEmail: '',
    editStudentNumber: '',
    editLevelId: '',
    editGender: 'male',
    
    viewStudent: {},
    viewSubjects: [],
    viewDelegate: null,
    viewDevices: [],
    showPermissionsModal: false,
    permStudent: { name: '', permissions: [] },
    permsUrl: '',
    selectedStudents: [],

    // AJAX Device Management and Toast states
    toastShow: false,
    toastMessage: '',
    toastType: 'success',
    isLoadingDevices: false,
    showToast(message, type = 'success') {
        this.toastMessage = message;
        this.toastType = type;
        this.toastShow = true;
        setTimeout(() => { this.toastShow = false; }, 4000);
    },
    async openDeviceSlotAJAX() {
        if (this.isLoadingDevices) return;
        this.isLoadingDevices = true;
        try {
            const response = await fetch('{{ url('admin/students') }}/' + this.viewStudent.id + '/open-slot', {
                method: 'POST',
                headers: {
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                }
            });
            const data = await response.json();
            if (data.success) {
                this.viewStudent.allowed_secondary_devices = data.allowed_secondary_devices;
                this.viewStudent.secondary_devices_count = data.secondary_devices_count;
                this.viewDevices = data.devices;
                this.showToast(data.message, 'success');
            } else {
                this.showToast(data.message || 'حدث خطأ ما', 'error');
            }
        } catch (err) {
            this.showToast('حدث خطأ في الاتصال بالخادم', 'error');
        } finally {
            this.isLoadingDevices = false;
        }
    },
    async closeDeviceSlotAJAX() {
        if (this.isLoadingDevices) return;
        this.isLoadingDevices = true;
        try {
            const response = await fetch('{{ url('admin/students') }}/' + this.viewStudent.id + '/close-slot', {
                method: 'POST',
                headers: {
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                }
            });
            const data = await response.json();
            if (data.success) {
                this.viewStudent.allowed_secondary_devices = data.allowed_secondary_devices;
                this.viewStudent.secondary_devices_count = data.secondary_devices_count;
                this.viewDevices = data.devices;
                this.showToast(data.message, 'success');
            } else {
                this.showToast(data.message || 'حدث خطأ ما', 'error');
            }
        } catch (err) {
            this.showToast('حدث خطأ في الاتصال بالخادم', 'error');
        } finally {
            this.isLoadingDevices = false;
        }
    },
    async resetDevicesAJAX() {
        if (!confirm('هل أنت متأكد من إعادة تعيين جميع الأجهزة المرتبطة بهذا الحساب؟ سيتعين على الطالب تسجيل الدخول مجدداً من جهازه الجديد وسيتم ربطه تلقائياً.')) return;
        if (this.isLoadingDevices) return;
        this.isLoadingDevices = true;
        try {
            const response = await fetch('{{ url('admin/students') }}/' + this.viewStudent.id + '/reset-devices', {
                method: 'POST',
                headers: {
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                }
            });
            const data = await response.json();
            if (data.success) {
                this.viewStudent.allowed_secondary_devices = data.allowed_secondary_devices;
                this.viewStudent.secondary_devices_count = data.secondary_devices_count;
                this.viewDevices = data.devices;
                this.showToast(data.message, 'success');
            } else {
                this.showToast(data.message || 'حدث خطأ ما', 'error');
            }
        } catch (err) {
            this.showToast('حدث خطأ في الاتصال بالخادم', 'error');
        } finally {
            this.isLoadingDevices = false;
        }
    },
    async updateDeviceAJAX(deviceId, payload) {
        if (this.isLoadingDevices) return;
        this.isLoadingDevices = true;
        try {
            const response = await fetch('{{ url('admin/students/devices') }}/' + deviceId, {
                method: 'POST',
                body: JSON.stringify(payload),
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'X-HTTP-Method-Override': 'PATCH',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                }
            });
            const data = await response.json();
            if (data.success) {
                this.viewStudent.allowed_secondary_devices = data.allowed_secondary_devices;
                this.viewStudent.secondary_devices_count = data.secondary_devices_count;
                this.viewDevices = data.devices;
                this.showToast(data.message, 'success');
            } else {
                this.showToast(data.message || 'حدث خطأ ما', 'error');
            }
        } catch (err) {
            this.showToast('حدث خطأ في الاتصال بالخادم', 'error');
        } finally {
            this.isLoadingDevices = false;
        }
    },
    async destroyDeviceAJAX(deviceId) {
        if (!confirm('هل أنت متأكد من إلغاء ربط وحذف هذا الجهاز؟')) return;
        if (this.isLoadingDevices) return;
        this.isLoadingDevices = true;
        try {
            const response = await fetch('{{ url('admin/students/devices') }}/' + deviceId, {
                method: 'POST',
                headers: {
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'X-HTTP-Method-Override': 'DELETE',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                }
            });
            const data = await response.json();
            if (data.success) {
                this.viewStudent.allowed_secondary_devices = data.allowed_secondary_devices;
                this.viewStudent.secondary_devices_count = data.secondary_devices_count;
                this.viewDevices = data.devices;
                this.showToast(data.message, 'success');
            } else {
                this.showToast(data.message || 'حدث خطأ ما', 'error');
            }
        } catch (err) {
            this.showToast('حدث خطأ في الاتصال بالخادم', 'error');
        } finally {
            this.isLoadingDevices = false;
        }
    },
    async fetchAndShowDeviceRequests() {
        this.isLoadingDeviceRequests = true;
        this.showDeviceRequestsModal = true;
        this.deviceRequestsList = [];
        this.rejectingRequest = null;
        this.adminRejectNote = '';
        try {
            const response = await fetch('{{ route('admin.students.device-requests.pending') }}', {
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                }
            });
            const data = await response.json();
            if (data.success) {
                this.deviceRequestsList = data.requests;
            } else {
                this.showToast('حدث خطأ أثناء جلب طلبات الأجهزة', 'error');
            }
        } catch (err) {
            this.showToast('حدث خطأ في الاتصال بالخادم', 'error');
        } finally {
            this.isLoadingDeviceRequests = false;
        }
    },
    async approveRequestAJAX(requestId, note = '') {
        if (this.isLoadingDeviceRequests) return;
        this.isLoadingDeviceRequests = true;
        try {
            const response = await fetch('{{ url('admin/student-device-requests') }}/' + requestId + '/approve', {
                method: 'POST',
                body: JSON.stringify({ admin_note: note }),
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                }
            });
            const data = await response.json();
            if (data.success) {
                this.showToast(data.message, 'success');
                this.deviceRequestsList = this.deviceRequestsList.filter(r => r.id !== requestId);
                if (this.deviceRequestsList.length === 0) {
                    this.showDeviceRequestsModal = false;
                    window.location.reload();
                }
            } else {
                this.showToast(data.message || 'حدث خطأ ما', 'error');
            }
        } catch (err) {
            this.showToast('حدث خطأ في الاتصال بالخادم', 'error');
        } finally {
            this.isLoadingDeviceRequests = false;
        }
    },
    async rejectRequestAJAX(requestId, note) {
        if (!note || note.trim() === '') {
            this.showToast('يرجى تحديد سبب الرفض', 'error');
            return;
        }
        if (this.isLoadingDeviceRequests) return;
        this.isLoadingDeviceRequests = true;
        try {
            const response = await fetch('{{ url('admin/student-device-requests') }}/' + requestId + '/reject', {
                method: 'POST',
                body: JSON.stringify({ admin_note: note }),
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                }
            });
            const data = await response.json();
            if (data.success) {
                this.showToast(data.message, 'success');
                this.rejectingRequest = null;
                this.adminRejectNote = '';
                this.deviceRequestsList = this.deviceRequestsList.filter(r => r.id !== requestId);
                if (this.deviceRequestsList.length === 0) {
                    this.showDeviceRequestsModal = false;
                    window.location.reload();
                }
            } else {
                this.showToast(data.message || 'حدث خطأ ما', 'error');
            }
        } catch (err) {
            this.showToast('حدث خطأ في الاتصال بالخادم', 'error');
        } finally {
            this.isLoadingDeviceRequests = false;
        }
    },
    toggleAllStudents(checked) {
        const pageIds = Array.from(document.querySelectorAll('[data-student-checkbox]')).map((checkbox) => checkbox.value);
        if (checked) {
            this.selectedStudents = Array.from(new Set([...this.selectedStudents, ...pageIds]));
        } else {
            this.selectedStudents = this.selectedStudents.filter((id) => !pageIds.includes(id));
        }
    },
    isPageFullySelected() {
        const pageIds = Array.from(document.querySelectorAll('[data-student-checkbox]')).map((checkbox) => checkbox.value);
        return pageIds.length > 0 && pageIds.every((id) => this.selectedStudents.includes(id));
    },
    async bulkResetSelectedDevices() {
        if (this.selectedStudents.length === 0) {
            this.showToast('حدد طالباً واحداً على الأقل أولاً.', 'error');
            return;
        }
        if (!confirm('سيتم حذف جميع الأجهزة المرتبطة للطلاب المحددين، وسيتمكنون من ربط جهاز جديد عند تسجيل الدخول. هل تريد المتابعة؟')) return;

        try {
            const response = await fetch('{{ route('admin.students.bulk-reset-devices') }}', {
                method: 'POST',
                body: JSON.stringify({ student_ids: this.selectedStudents }),
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                }
            });
            const data = await response.json();
            if (data.success) {
                this.showToast(data.message, 'success');
                setTimeout(() => window.location.reload(), 900);
            } else {
                this.showToast(data.message || 'تعذر تنفيذ العملية الجماعية.', 'error');
            }
        } catch (err) {
            this.showToast('حدث خطأ في الاتصال بالخادم', 'error');
        }
    }
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
            <h1>إدارة الطلاب</h1>
            <p>تسجيل وإدارة بيانات الطلاب المسجلين في النظام</p>
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
            <div class="stat-icon green">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                    <circle cx="9" cy="7" r="4"></circle>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                </svg>
            </div>
            <div class="stat-info">
                <h3>{{ $students->total() }}</h3>
                <p>إجمالي الطلاب</p>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon blue">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
                    <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
                </svg>
            </div>
            <div class="stat-info">
                <h3>{{ \App\Models\Academic\Major::count() }}</h3>
                <p>التخصصات</p>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon purple">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="3" width="7" height="7"></rect>
                    <rect x="14" y="3" width="7" height="7"></rect>
                    <rect x="14" y="14" width="7" height="7"></rect>
                    <rect x="3" y="14" width="7" height="7"></rect>
                </svg>
            </div>
            <div class="stat-info">
                <h3>{{ \App\Models\Academic\Level::count() }}</h3>
                <p>المستويات</p>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon amber">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                    <circle cx="8.5" cy="7" r="4"></circle>
                    <polyline points="17 11 19 13 23 9"></polyline>
                </svg>
            </div>
            <div class="stat-info">
                <h3>{{ \App\Models\User::where('role', 'delegate')->count() }}</h3>
                <p>المندوبين</p>
            </div>
        </div>
    </div>

    <!-- Pending Requests Banner/Action Box -->
    @php
        $pendingRequests = \App\Models\StudentDeviceRequest::pending()->count();
    @endphp
    @if($pendingRequests > 0)
    <div style="background: linear-gradient(135deg, #fef3c7, #fffbef); border: 1px solid #fde68a; border-radius: 16px; padding: 1.25rem 1.5rem; margin-bottom: 2rem; display: flex; align-items: center; justify-content: space-between; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);">
        <div style="display: flex; align-items: center; gap: 1rem;">
            <div style="width: 48px; height: 48px; background: #f59e0b; border-radius: 12px; display: flex; align-items: center; justify-content: center; color: white;">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="5" y="2" width="14" height="20" rx="2" ry="2"></rect>
                    <line x1="12" y1="18" x2="12.01" y2="18"></line>
                </svg>
            </div>
            <div>
                <h4 style="font-size: 1.05rem; font-weight: 800; color: #92400e; margin-bottom: 0.15rem; margin-top: 0;">طلبات تفعيل الأجهزة الفرعية</h4>
                <p style="font-size: 0.85rem; color: #b45309; font-weight: 600; margin: 0;">يوجد حالياً <span style="font-weight: 900; font-size: 1rem; color: #b45309;">{{ $pendingRequests }}</span> طلبات معلقة بانتظار المراجعة واتخاذ قرار بالقبول أو الرفض.</p>
            </div>
        </div>
        <button type="button" @click="fetchAndShowDeviceRequests()" class="action-btn" style="background: #f59e0b; color: white; padding: 0.6rem 1.25rem; font-size: 0.85rem; font-weight: 700; border-radius: 10px; box-shadow: 0 4px 10px -2px rgba(245, 158, 11, 0.4); display: flex; align-items: center; gap: 0.35rem; border: none; cursor: pointer;">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="12" y1="8" x2="12" y2="16"></line>
                <line x1="8" y1="12" x2="16" y2="12"></line>
            </svg>
            مراجعة الطلبات المعلقة
        </button>
    </div>
    @endif

    <!-- Main Grid -->
    <div style="display: grid; grid-template-columns: 320px 1fr; gap: 1.5rem; align-items: start;">

        <!-- Create Form -->
        <div class="form-card">
            <div class="form-card-header">
                <div class="icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="12" y1="5" x2="12" y2="19"></line>
                        <line x1="5" y1="12" x2="19" y2="12"></line>
                    </svg>
                </div>
                <h3>تسجيل طالب جديد</h3>
            </div>

            <form action="{{ route('admin.students.store') }}" method="POST">
                @csrf

                <div class="form-group">
                    <label for="level_id" class="form-label">المرحلة الدراسية</label>
                    <div class="input-with-icon">
                        <span class="icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="3" y="3" width="7" height="7"></rect>
                                <rect x="14" y="3" width="7" height="7"></rect>
                                <rect x="14" y="14" width="7" height="7"></rect>
                                <rect x="3" y="14" width="7" height="7"></rect>
                            </svg>
                        </span>
                        <select name="level_id" id="level_id" class="form-control" required style="font-size: 0.9rem;">
                            <option value="">اختر المرحلة...</option>
                            @foreach($universities as $university)
                            <optgroup label="{{ $university->name }}">
                                @foreach($university->colleges as $college)
                                @foreach($college->majors as $major)
                                @foreach($major->levels as $level)
                                <option value="{{ $level->id }}">
                                    {{ $level->name }} - {{ $major->name }} ({{ $college->name }})
                                </option>
                                @endforeach
                                @endforeach
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
                        <input type="text" name="name" id="name" class="form-control" placeholder="اسم الطالب..." required>
                    </div>
                </div>

                <div class="form-group">
                    <label for="student_number" class="form-label">الرقم الجامعي</label>
                    <div class="input-with-icon">
                        <span class="icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="3" y="4" width="18" height="16" rx="2" ry="2"></rect>
                                <line x1="3" y1="10" x2="21" y2="10"></line>
                            </svg>
                        </span>
                        <input type="text" name="student_number" id="student_number" class="form-control" placeholder="12345678" required>
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
                        <input type="email" name="email" id="email" class="form-control" placeholder="student@example.com" required>
                    </div>
                </div>

                <div class="form-group">
                    <label for="gender" class="form-label">الجنس</label>
                    <select name="gender" id="gender" class="form-control" required>
                        <option value="male">ذكر</option>
                        <option value="female">أنثى</option>
                    </select>
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

                <button type="submit" class="btn-submit">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                        <polyline points="17 21 17 13 7 13 7 21"></polyline>
                    </svg>
                    تسجيل الطالب
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
                    قائمة الطلاب
                </h3>
                <span class="count-badge">{{ $students->total() }} طالب</span>
            </div>

            <!-- Search and Filters -->
            <div style="margin-bottom: 1.25rem;">
                <form action="{{ route('admin.students.index') }}" method="GET" style="display: grid; grid-template-columns: minmax(220px, 1fr) 210px auto auto; gap: 0.5rem; margin: 0; align-items: center;">
                    <div style="position: relative; flex: 1;">
                        <span style="position: absolute; right: 12px; top: 50%; transform: translateY(-50%); color: var(--text-secondary); pointer-events: none; display: flex; align-items: center;">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <circle cx="11" cy="11" r="8"></circle>
                                <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                            </svg>
                        </span>
                        <input type="text" name="search" value="{{ request('search') }}" placeholder="ابحث باسم الطالب، البريد الإلكتروني، أو الرقم الجامعي..." style="width: 100%; padding: 0.65rem 2.5rem 0.65rem 1rem; border: 1px solid var(--border-color); border-radius: 10px; font-size: 0.85rem; background: #fafafa; transition: all 0.2s;" onfocus="this.style.borderColor='var(--primary-color)'; this.style.background='white';" onblur="this.style.borderColor='var(--border-color)'; this.style.background='#fafafa';">
                    </div>
                    <select name="device_status" style="width: 100%; padding: 0.65rem 0.8rem; border: 1px solid var(--border-color); border-radius: 10px; font-size: 0.85rem; background: #fafafa; color: var(--text-primary);">
                        <option value="">كل حالات الأجهزة</option>
                        <option value="has_devices" @selected(request('device_status') === 'has_devices')>لديهم أجهزة مرتبطة</option>
                        <option value="no_devices" @selected(request('device_status') === 'no_devices')>بدون أجهزة مرتبطة</option>
                    </select>
                    <button type="submit" style="padding: 0.65rem 1.25rem; font-size: 0.85rem; background: #2563eb; color: white; border-radius: 10px; height: 38px; display: inline-flex; align-items: center; justify-content: center; border: none; cursor: pointer; font-weight: 600;">
                        بحث
                    </button>
                    @if(request('search') || request('device_status'))
                    <a href="{{ route('admin.students.index') }}" style="padding: 0.65rem 1.25rem; font-size: 0.85rem; border-radius: 10px; display: inline-flex; align-items: center; justify-content: center; text-decoration: none; height: 38px; border: 1px solid var(--border-color); background: #f3f4f6; color: #4b5563; font-weight: 600;">
                        إلغاء
                    </a>
                    @endif
                </form>
            </div>

            <div x-show="selectedStudents.length > 0" x-transition.opacity style="margin-bottom: 1rem; background: #eff6ff; border: 1px solid #bfdbfe; color: #1d4ed8; padding: 0.8rem 1rem; border-radius: 12px; display: flex; align-items: center; justify-content: space-between; gap: 1rem;">
                <div style="font-size: 0.85rem; font-weight: 800;">
                    تم تحديد <span x-text="selectedStudents.length"></span> حساب
                </div>
                <div style="display: flex; gap: 0.5rem; align-items: center;">
                    <button type="button" @click="bulkResetSelectedDevices()" class="action-btn delete" style="background: #fee2e2; color: #b91c1c; padding: 0.5rem 0.85rem;">
                        إلغاء ربط أجهزة المحددين
                    </button>
                    <button type="button" @click="selectedStudents = []" class="action-btn view" style="padding: 0.5rem 0.85rem;">
                        إلغاء التحديد
                    </button>
                </div>
            </div>

            <div class="table-responsive">
<table class="modern-table">
                <thead>
                    <tr>
                        <th style="width: 42px; text-align: center;">
                            <input type="checkbox" @change="toggleAllStudents($event.target.checked)" :checked="isPageFullySelected()" style="width: 16px; height: 16px; cursor: pointer;">
                        </th>
                        <th>#</th>
                        <th>الطالب</th>
                        <th>الرقم الجامعي</th>
                        <th>الجنس</th>
                        <th>الانتساب الأكاديمي</th>
                        <th>الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($students as $student)
                    <tr>
                        <td style="text-align: center;">
                            <input type="checkbox" data-student-checkbox value="{{ $student->id }}" x-model="selectedStudents" style="width: 16px; height: 16px; cursor: pointer;">
                        </td>
                        <td style="font-weight: 600; color: var(--text-secondary);">{{ $loop->iteration }}</td>
                        <td>
                            <div style="display: flex; align-items: center; gap: 0.75rem;">
                                <div class="student-avatar">{{ mb_substr($student->name, 0, 1) }}</div>
                                <div>
                                    <div style="display: flex; align-items: center; gap: 0.35rem; flex-wrap: wrap;">
                                        <span style="font-weight: 600;">{{ $student->name }}</span>
                                        @if($student->role === \App\Enums\UserRole::DELEGATE)
                                            <span style="font-size: 0.7rem; background: #e0f2fe; color: #0369a1; padding: 0.1rem 0.4rem; border-radius: 6px; font-weight: 700; display: inline-flex; align-items: center;">مندوب دفعة</span>
                                        @elseif($student->role === \App\Enums\UserRole::PRACTICAL_DELEGATE)
                                            <span style="font-size: 0.7rem; background: #fef3c7; color: #b45309; padding: 0.1rem 0.4rem; border-radius: 6px; font-weight: 700; display: inline-flex; align-items: center;">مندوب عملي</span>
                                        @endif
                                    </div>
                                    <div style="font-size: 0.8rem; color: var(--text-secondary);">{{ $student->email }}</div>
                                </div>
                            </div>
                        </td>
                        <td>
                            <span class="student-number">{{ $student->student_number }}</span>
                        </td>
                        <td>
                            <span style="display: inline-flex; align-items: center; gap: 0.35rem; padding: 0.35rem 0.75rem; border-radius: 999px; background: {{ $student->gender === 'female' ? '#fdf2f8' : '#eff6ff' }}; color: {{ $student->gender === 'female' ? '#db2777' : '#2563eb' }}; font-size: 0.8rem; font-weight: 700;">
                                {{ $student->gender === 'female' ? 'أنثى' : 'ذكر' }}
                            </span>
                        </td>
                        <td>
                            <div style="font-weight: 600;">{{ $student->level->name ?? '-' }}</div>
                            <div style="font-size: 0.8rem; color: var(--text-secondary);">
                                {{ $student->major->name ?? '' }} ({{ $student->college->name ?? '' }})
                            </div>
                        </td>
                        <td>
                            <div style="display: flex; gap: 0.5rem;">
                                <button type="button" class="action-btn view" title="عرض التفاصيل"
                                    @click="
                                        showDetailsModal = true;
                                        viewStudent = {
                                            id: '{{ $student->id }}',
                                            name: '{{ $student->name }}',
                                            email: '{{ $student->email }}',
                                            student_number: '{{ $student->student_number }}',
                                            gender: '{{ $student->gender }}',
                                            level: '{{ $student->level->name ?? '-' }}',
                                            major: '{{ $student->major->name ?? '-' }}',
                                            college: '{{ $student->college->name ?? '-' }}',
                                            university: '{{ $student->university->name ?? '-' }}',
                                            role_label: '{{ $student->role === \App\Enums\UserRole::DELEGATE ? "مندوب دفعة" : ($student->role === \App\Enums\UserRole::PRACTICAL_DELEGATE ? "مندوب عملي" : "طالب") }}',
                                            allowed_secondary_devices: {{ $student->allowed_secondary_devices ?? 0 }},
                                            secondary_devices_count: {{ $student->studentDevices->where('device_type', \App\Models\StudentDevice::TYPE_SECONDARY)->count() }}
                                        };
                                        viewDevices = {{ json_encode($student->studentDevices->map(function($device) {
                                            return [
                                                'id' => $device->id,
                                                'device_id' => $device->device_id,
                                                'device_name' => $device->device_name ?: 'جهاز غير مسمى',
                                                'platform' => $device->platform ?: '-',
                                                'app_version' => $device->app_version ?: '-',
                                                'device_type' => $device->device_type,
                                                'device_type_label' => $device->is_primary ? 'أساسي' : 'فرعي',
                                                'is_primary' => (bool) $device->is_primary,
                                                'is_active' => (bool) $device->is_active,
                                                'is_temporary' => (bool) $device->is_temporary,
                                                'expires_at' => $device->expires_at ? $device->expires_at->format('Y-m-d\TH:i') : null,
                                                'expires_at_label' => $device->expires_at ? $device->expires_at->format('Y-m-d H:i') : null,
                                                'status_label' => $device->is_active ? ($device->isExpired() ? 'منتهي الصلاحية' : 'مفعل') : 'غير مفعل',
                                                'is_expired' => $device->isExpired(),
                                                'approved_at' => $device->approved_at ? $device->approved_at->format('Y-m-d H:i') : null,
                                                'last_login_at' => $device->last_login_at ? $device->last_login_at->format('Y-m-d H:i') : null,
                                                'created_at' => $device->created_at ? $device->created_at->format('Y-m-d H:i') : null,
                                            ];
                                        })->values()) }};
                                        viewSubjects = {{ json_encode($student->level ? $student->level->terms->flatMap->subjects->map(function($s) {
                                            return [
                                                'name' => $s->name,
                                                'code' => $s->code,
                                                'doctor' => $s->doctor ? $s->doctor->name : 'غير محدد',
                                                'term' => $s->term->name
                                            ];
                                        }) : []) }};
                                        viewDelegate = {{ json_encode(isset($delegates[$student->level_id]) ? [
                                            'name' => $delegates[$student->level_id]->name,
                                            'email' => $delegates[$student->level_id]->email
                                        ] : null) }};
                                    ">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                                        <circle cx="12" cy="12" r="3"></circle>
                                    </svg>
                                </button>
                                <button type="button" class="action-btn edit" title="تعديل الطالب" style="padding: 0.5rem;"
                                    @click="
                                        showEditModal = true;
                                        modalTitle = 'تعديل: {{ $student->name }}';
                                        editUrl = '{{ route('admin.students.update', $student) }}';
                                        editName = '{{ $student->name }}';
                                        editEmail = '{{ $student->email }}';
                                        editStudentNumber = '{{ $student->student_number }}';
                                        editLevelId = '{{ $student->level_id }}';
                                        editGender = '{{ $student->gender ?? 'male' }}';
                                    ">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                                    </svg>
                                </button>
                                <button type="button" class="action-btn" title="الصلاحيات" style="background: #f0f9ff; color: #0369a1; padding: 0.5rem;"
                                    @click="
                                        showPermissionsModal = true;
                                        permStudent.name = '{{ $student->name }}';
                                        permStudent.permissions = {{ json_encode($student->permissions->pluck('slug')) }};
                                        permsUrl = '{{ route('admin.students.permissions', $student) }}';
                                    ">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
                                    </svg>
                                </button>
                                <button type="button" class="action-btn delete" title="حذف الطالب" style="padding: 0.5rem;"
                                    @click="
                                        showDeleteModal = true;
                                        deleteUrl = '{{ route('admin.students.destroy', $student) }}';
                                        modalTitle = 'حذف {{ $student->name }}';
                                        modalMessage = 'حذف الطالب سيؤدي إلى حذف جميع سجلات حضوره.';
                                    ">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <polyline points="3 6 5 6 21 6"></polyline>
                                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                                    </svg>
                                </button>

                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" style="text-align: center; padding: 3rem; color: var(--text-secondary);">
                            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5" style="margin-bottom: 1rem;">
                                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                                <circle cx="9" cy="7" r="4"></circle>
                            </svg>
                            <div>لا يوجد طلاب مسجلين</div>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
</div>

            <div style="margin-top: 1.5rem;">
                {{ $students->links() }}
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
                <label for="edit_level_id" class="form-label">المرحلة الدراسية</label>
                <select name="level_id" id="edit_level_id" class="form-control" x-model="editLevelId" required style="font-size: 0.9rem;">
                    <option value="">اختر المرحلة...</option>
                    @foreach($universities as $university)
                    <optgroup label="{{ $university->name }}">
                        @foreach($university->colleges as $college)
                        @foreach($college->majors as $major)
                        @foreach($major->levels as $level)
                        <option value="{{ $level->id }}">
                            {{ $level->name }} - {{ $major->name }} ({{ $college->name }})
                        </option>
                        @endforeach
                        @endforeach
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
                <label for="edit_student_number" class="form-label">الرقم الجامعي</label>
                <input type="text" name="student_number" id="edit_student_number" class="form-control" x-model="editStudentNumber" required>
            </div>

            <div class="form-group">
                <label for="edit_email" class="form-label">البريد الإلكتروني</label>
                <input type="email" name="email" id="edit_email" class="form-control" x-model="editEmail" required>
            </div>

            <div class="form-group">
                <label for="edit_gender" class="form-label">الجنس</label>
                <select name="gender" id="edit_gender" class="form-control" x-model="editGender" required style="font-size: 0.9rem;">
                    <option value="male">ذكر</option>
                    <option value="female">أنثى</option>
                </select>
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

    <!-- Details Modal -->
    <div x-show="showDetailsModal" class="modal-overlay" style="display: none;"
        x-transition:enter="transition ease-out duration-300"
        x-transition:enter-start="opacity-0"
        x-transition:enter-end="opacity-100"
        x-transition:leave="transition ease-in duration-200"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0">
        <div class="modal-container" style="text-align: right; max-width: 650px; max-height: 90vh; display: flex; flex-direction: column; overflow: hidden;" @click.away="showDetailsModal = false" x-data="{ activeTab: 'academic' }">
            
            <!-- Modal Header (Fixed) -->
            <div style="display: flex; justify-content: space-between; align-items: center; padding: 1.25rem 1.5rem; border-bottom: 1px solid var(--border-color); background: white;">
                <h3 class="modal-title" style="margin: 0; font-size: 1.15rem; font-weight: 800;">تفاصيل الطالب الأكاديمية</h3>
                <button @click="showDetailsModal = false" style="background: none; border: none; cursor: pointer; font-size: 1.5rem; color: var(--text-secondary); line-height: 1;">&times;</button>
            </div>

            <!-- Modal Content (Scrollable) -->
            <div style="flex: 1; overflow-y: auto; padding: 1.5rem;">
                
                <!-- Student Header Banner -->
                <div style="background: linear-gradient(135deg, #10b981, #059669); color: white; padding: 1.5rem; border-radius: 12px; margin-bottom: 1.5rem;">
                    <div style="display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 0.25rem;">
                        <h4 x-text="viewStudent.name" style="margin: 0; font-size: 1.25rem; font-weight: 800;"></h4>
                        <span x-show="viewStudent.role_label && viewStudent.role_label !== 'طالب'" x-text="viewStudent.role_label" style="font-size: 0.72rem; background: rgba(255, 255, 255, 0.22); color: white; padding: 0.15rem 0.45rem; border-radius: 6px; font-weight: 700;"></span>
                    </div>
                    <div style="opacity: 0.9; margin-top: 0.5rem; display: flex; gap: 1rem; font-size: 0.9rem; align-items: center;">
                        <div style="display: flex; align-items: center; gap: 0.25rem;">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="3" y="4" width="18" height="16" rx="2" ry="2"></rect>
                                <line x1="3" y1="10" x2="21" y2="10"></line>
                            </svg>
                            <span x-text="viewStudent.student_number"></span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 0.25rem;">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M12 2a5 5 0 0 1 5 5c0 2-1 3-2 4l-1 1v2"></path>
                                <path d="M9 21h6"></path>
                                <path d="M12 14v7"></path>
                            </svg>
                            <span x-text="viewStudent.gender === 'female' ? 'أنثى' : 'ذكر'"></span>
                        </div>
                    </div>
                </div>

                <!-- Tab Navigation Bar -->
                <div style="display: flex; border-bottom: 1px solid var(--border-color); margin-bottom: 1.5rem; gap: 1rem;">
                    <button type="button" @click="activeTab = 'academic'" :class="activeTab === 'academic' ? 'active-tab' : 'inactive-tab'" style="padding: 0.75rem 0.5rem; font-weight: 700; font-size: 0.9rem; border: none; background: none; cursor: pointer; transition: all 0.2s;">
                        البيانات الأكاديمية
                    </button>
                    <button type="button" @click="activeTab = 'devices'" :class="activeTab === 'devices' ? 'active-tab' : 'inactive-tab'" style="padding: 0.75rem 0.5rem; font-weight: 700; font-size: 0.9rem; border: none; background: none; cursor: pointer; transition: all 0.2s; display: flex; align-items: center; gap: 0.35rem;">
                        الأجهزة المرتبطة
                        <span style="font-size: 0.75rem; background: #e2e8f0; color: #475569; padding: 0.15rem 0.4rem; border-radius: 99px;" x-text="viewDevices.length"></span>
                    </button>
                    <button type="button" @click="activeTab = 'subjects'" :class="activeTab === 'subjects' ? 'active-tab' : 'inactive-tab'" style="padding: 0.75rem 0.5rem; font-weight: 700; font-size: 0.9rem; border: none; background: none; cursor: pointer; transition: all 0.2s; display: flex; align-items: center; gap: 0.35rem;">
                        المواد والمدرسين
                        <span style="font-size: 0.75rem; background: #e2e8f0; color: #475569; padding: 0.15rem 0.4rem; border-radius: 99px;" x-text="viewSubjects.length"></span>
                    </button>
                </div>

                <!-- Tab 1: Academic Data -->
                <div x-show="activeTab === 'academic'" x-transition.opacity>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1.5rem;">
                        <div style="background: #fafafa; padding: 0.85rem 1rem; border-radius: 10px; border: 1px solid var(--border-color);">
                            <div style="font-size: 0.75rem; color: var(--text-secondary); margin-bottom: 0.25rem;">الجامعة</div>
                            <div style="font-weight: 700; color: var(--text-primary);" x-text="viewStudent.university || '-'"></div>
                        </div>
                        <div style="background: #fafafa; padding: 0.85rem 1rem; border-radius: 10px; border: 1px solid var(--border-color);">
                            <div style="font-size: 0.75rem; color: var(--text-secondary); margin-bottom: 0.25rem;">الكلية</div>
                            <div style="font-weight: 700; color: var(--text-primary);" x-text="viewStudent.college || '-'"></div>
                        </div>
                        <div style="background: #fafafa; padding: 0.85rem 1rem; border-radius: 10px; border: 1px solid var(--border-color);">
                            <div style="font-size: 0.75rem; color: var(--text-secondary); margin-bottom: 0.25rem;">التخصص</div>
                            <div style="font-weight: 700; color: var(--text-primary);" x-text="viewStudent.major || '-'"></div>
                        </div>
                        <div style="background: #fafafa; padding: 0.85rem 1rem; border-radius: 10px; border: 1px solid var(--border-color);">
                            <div style="font-size: 0.75rem; color: var(--text-secondary); margin-bottom: 0.25rem;">المرحلة / المستوى</div>
                            <div style="font-weight: 700; color: var(--text-primary);" x-text="viewStudent.level || '-'"></div>
                        </div>
                        <div style="background: #fafafa; padding: 0.85rem 1rem; border-radius: 10px; border: 1px solid var(--border-color); grid-column: span 2;">
                            <div style="font-size: 0.75rem; color: var(--text-secondary); margin-bottom: 0.25rem;">البريد الإلكتروني</div>
                            <div style="font-weight: 700; color: var(--text-primary);" x-text="viewStudent.email || '-'"></div>
                        </div>
                    </div>

                    <!-- Delegate Box -->
                    <div style="background: linear-gradient(135deg, #f0fdf4, #dcfce7); padding: 1.25rem; border-radius: 12px; border: 1px solid #bbf7d0;">
                        <h5 style="margin-top: 0; margin-bottom: 1rem; font-size: 0.9rem; font-weight: 800; color: #166534; display: flex; align-items: center; gap: 0.35rem;">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                                <circle cx="12" cy="7" r="4"></circle>
                            </svg>
                            مندوب الدفعة
                        </h5>

                        <template x-if="viewDelegate">
                            <div style="display: flex; align-items: center; gap: 0.75rem;">
                                <div style="width: 40px; height: 40px; background: linear-gradient(135deg, #10b981, #059669); color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 1rem; font-weight: bold;">
                                    <span x-text="viewDelegate.name.charAt(0)"></span>
                                </div>
                                <div>
                                    <div style="font-weight: 700; font-size: 0.9rem; color: #166534;" x-text="viewDelegate.name"></div>
                                    <div style="font-size: 0.75rem; color: #15803d;" x-text="viewDelegate.email"></div>
                                </div>
                            </div>
                        </template>

                        <template x-if="!viewDelegate">
                            <div style="color: #16a34a; font-size: 0.8rem; font-weight: 600;">
                                لم يتم تعيين مندوب لهذه الدفعة بعد.
                            </div>
                        </template>
                    </div>
                </div>

                <!-- Tab 2: Devices -->
                <div x-show="activeTab === 'devices'" x-transition.opacity style="position: relative;">
                    <!-- Loading overlay for the tab -->
                    <div x-show="isLoadingDevices" 
                         x-transition.opacity 
                         style="position: absolute; inset: 0; background: rgba(255, 255, 255, 0.72); z-index: 10; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(1px); border-radius: 12px;">
                        <div style="display: flex; flex-direction: column; align-items: center; gap: 0.5rem; color: #2563eb; font-weight: 700; font-size: 0.85rem;">
                            <span style="width: 28px; height: 28px; border: 3px solid #2563eb; border-top-color: transparent; border-radius: 50%; display: inline-block; animation: spin 0.6s linear infinite;"></span>
                            جاري معالجة الطلب...
                        </div>
                    </div>

                    <!-- Slot Manager Controls -->
                    <div style="background: #f8fafc; border: 1px solid var(--border-color); border-radius: 12px; padding: 1rem; margin-bottom: 1.5rem; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem;">
                        <div>
                            <div style="font-weight: 800; font-size: 0.9rem; color: var(--text-primary); margin-bottom: 0.15rem;">
                                المساحات الفرعية المفتوحة: <span x-text="viewStudent.allowed_secondary_devices" style="color: #2563eb; font-weight: 900;"></span>
                            </div>
                            <div style="font-size: 0.75rem; color: var(--text-secondary);">
                                الأجهزة الفرعية المسجلة حالياً: <span x-text="viewStudent.secondary_devices_count" style="font-weight: 700;"></span> 
                                | المساحات الشاغرة: <span x-text="Math.max(0, viewStudent.allowed_secondary_devices - viewStudent.secondary_devices_count)" style="color: #059669; font-weight: 700;"></span>
                            </div>
                        </div>
                        <div style="display: flex; gap: 0.5rem;">
                            <!-- Open Slot Button -->
                            <button type="button" @click="openDeviceSlotAJAX()" class="action-btn view" style="padding: 0.45rem 0.85rem; font-size: 0.8rem; font-weight: 700; border-radius: 8px; display: flex; align-items: center; gap: 0.25rem;">
                                + فتح مساحة جديدة
                            </button>
                            <!-- Close Slot Button -->
                            <button type="button" @click="closeDeviceSlotAJAX()" class="action-btn delete" style="padding: 0.45rem 0.85rem; font-size: 0.8rem; font-weight: 700; border-radius: 8px; background: #fee2e2; color: #b91c1c; display: flex; align-items: center; gap: 0.25rem;" x-show="viewStudent.allowed_secondary_devices > viewStudent.secondary_devices_count">
                                إلغاء مساحة شاغرة
                            </button>
                        </div>
                    </div>

                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                        <h5 style="margin: 0; font-size: 0.95rem; font-weight: 800; color: var(--text-primary);">الأجهزة المسجلة لحساب الطالب</h5>
                        <!-- Reset Devices Button -->
                        <button type="button" @click="resetDevicesAJAX()" class="action-btn delete" style="padding: 0.35rem 0.75rem; font-size: 0.78rem; display: flex; align-items: center; gap: 0.3rem;" x-show="viewDevices.length > 0">
                            <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M23 4v6h-6"></path>
                                <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path>
                            </svg>
                            إعادة تعيين الأجهزة
                        </button>
                    </div>

                    <div style="display: flex; flex-direction: column; gap: 0.75rem;">
                        <template x-for="device in viewDevices" :key="device.device_id">
                            <div class="device-card" x-data="{ 
                                editing: false,
                                is_active: device.is_active ? '1' : '0',
                                device_type: device.device_type,
                                is_temporary: device.is_temporary ? '1' : '0',
                                expires_at: device.expires_at ? device.expires_at.substring(0, 16) : ''
                            }">
                                <!-- View Mode -->
                                <div x-show="!editing" style="width: 100%; display: flex; gap: 0.75rem; align-items: flex-start;">
                                    <div class="device-icon" style="display: flex; align-items: center; justify-content: center;">
                                        <svg xmlns="http://www.w3.org/2000/svg" width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                            <rect x="7" y="2" width="10" height="20" rx="2" ry="2"></rect>
                                            <line x1="12" y1="18" x2="12.01" y2="18"></line>
                                        </svg>
                                    </div>
                                    <div style="flex: 1; min-width: 0;">
                                        <div style="display: flex; justify-content: space-between; gap: 0.75rem; align-items: flex-start;">
                                            <div>
                                                <div style="font-weight: 800; color: var(--text-primary);" x-text="device.device_name"></div>
                                                <div style="font-size: 0.75rem; color: var(--text-secondary); word-break: break-all;" x-text="device.device_id"></div>
                                            </div>
                                            <span class="device-badge" :class="device.is_primary ? 'primary' : 'secondary'" x-text="device.device_type_label"></span>
                                        </div>
                                        <div class="device-meta" style="margin-top: 0.4rem;">
                                            <!-- Status Badge -->
                                            <span class="device-badge" :class="device.is_expired ? 'inactive' : (device.is_active ? 'active' : 'inactive')" x-text="device.status_label"></span>
                                            <span class="device-badge" x-text="'النظام: ' + device.platform"></span>
                                            <span class="device-badge" x-show="device.app_version && device.app_version !== '-'" x-text="'الإصدار: ' + device.app_version"></span>
                                            
                                            <!-- Expiration Badge -->
                                            <span class="device-badge" :class="device.is_temporary ? 'secondary' : 'primary'" style="background: #f1f5f9; color: #475569;" x-text="device.is_temporary ? ('مؤقت (ينتهي: ' + (device.expires_at_label || '-') + ')') : 'صلاحية دائمة'"></span>
                                        </div>
                                        <div style="font-size: 0.76rem; color: var(--text-secondary); margin-top: 0.55rem; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 0.5rem;">
                                            <div>
                                                آخر دخول: <strong x-text="device.last_login_at || 'لم يسجل بعد'"></strong>
                                                <span style="margin: 0 0.25rem;">•</span>
                                                تاريخ الربط: <strong x-text="device.created_at || '-'"></strong>
                                            </div>
                                            <div style="display: flex; gap: 0.35rem;">
                                                <button type="button" @click="editing = true" class="action-btn view" style="padding: 0.2rem 0.5rem; font-size: 0.72rem; border-radius: 6px;">
                                                    تعديل الصلاحية
                                                </button>
                                                
                                                <button type="button" @click="destroyDeviceAJAX(device.id)" class="action-btn delete" style="padding: 0.2rem 0.5rem; font-size: 0.72rem; border-radius: 6px;">
                                                    حذف
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Edit Mode -->
                                <div x-show="editing" style="width: 100%;" x-transition.opacity>
                                    <form @submit.prevent="updateDeviceAJAX(device.id, { is_active: is_active, device_type: device_type, is_temporary: is_temporary, expires_at: expires_at }); editing = false;" style="margin: 0;">
                                        <div style="font-weight: 800; font-size: 0.85rem; color: #2563eb; margin-bottom: 0.75rem; border-bottom: 1px dashed var(--border-color); padding-bottom: 0.25rem;">
                                            تعديل صلاحية الجهاز: <span x-text="device.device_name"></span>
                                        </div>
                                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem; margin-bottom: 0.75rem;">
                                            <div>
                                                <label style="font-size: 0.72rem; color: var(--text-secondary); display: block; margin-bottom: 0.25rem;">نوع الجهاز</label>
                                                <select name="device_type" x-model="device_type" style="width: 100%; padding: 0.35rem; font-size: 0.78rem; border: 1px solid var(--border-color); border-radius: 6px; background: white;">
                                                    <option value="primary">أساسي (Primary)</option>
                                                    <option value="secondary">فرعي (Secondary)</option>
                                                </select>
                                            </div>
                                            <div>
                                                <label style="font-size: 0.72rem; color: var(--text-secondary); display: block; margin-bottom: 0.25rem;">حالة التنشيط</label>
                                                <select name="is_active" x-model="is_active" style="width: 100%; padding: 0.35rem; font-size: 0.78rem; border: 1px solid var(--border-color); border-radius: 6px; background: white;">
                                                    <option value="1">نشط ومفعل</option>
                                                    <option value="0">غير نشط</option>
                                                </select>
                                            </div>
                                            <div>
                                                <label style="font-size: 0.72rem; color: var(--text-secondary); display: block; margin-bottom: 0.25rem;">صلاحية الجهاز</label>
                                                <select name="is_temporary" x-model="is_temporary" style="width: 100%; padding: 0.35rem; font-size: 0.78rem; border: 1px solid var(--border-color); border-radius: 6px; background: white;">
                                                    <option value="0">دائمة (Permanent)</option>
                                                    <option value="1">مؤقتة (Temporary)</option>
                                                </select>
                                            </div>
                                            <div x-show="is_temporary === '1'">
                                                <label style="font-size: 0.72rem; color: var(--text-secondary); display: block; margin-bottom: 0.25rem;">تاريخ انتهاء الصلاحية</label>
                                                <input type="datetime-local" name="expires_at" x-model="expires_at" style="width: 100%; padding: 0.3rem; font-size: 0.75rem; border: 1px solid var(--border-color); border-radius: 6px; background: white;" :required="is_temporary === '1'">
                                            </div>
                                        </div>
                                        <div style="display: flex; gap: 0.35rem; justify-content: flex-end; margin-top: 0.5rem;">
                                            <button type="button" @click="editing = false" class="action-btn view" style="padding: 0.3rem 0.75rem; font-size: 0.75rem; border-radius: 6px; background: #f3f4f6; color: #4b5563;">
                                                إلغاء
                                            </button>
                                            <button type="submit" class="action-btn view" style="padding: 0.3rem 0.75rem; font-size: 0.75rem; border-radius: 6px; background: #059669; color: white;">
                                                حفظ التغييرات
                                            </button>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </template>

                        <div x-show="viewDevices.length === 0" style="text-align: center; padding: 1.5rem; color: var(--text-secondary); background: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 12px;">
                            لم يتم تسجيل أي جهاز لهذا الطالب حتى الآن.
                        </div>
                    </div>
                </div>

                <!-- Tab 3: Subjects -->
                <div x-show="activeTab === 'subjects'" x-transition.opacity>
                    <h5 style="margin-top: 0; margin-bottom: 1rem; font-size: 0.95rem; font-weight: 800; color: var(--text-primary);">المواد الدراسية ومدرسيها</h5>
                    
                    <div style="display: flex; flex-direction: column; gap: 0.75rem;">
                        <template x-for="subject in viewSubjects">
                            <div style="background: white; border: 1px solid var(--border-color); padding: 0.75rem; border-radius: 8px; display: flex; justify-content: space-between; align-items: center;">
                                <div>
                                    <div style="font-weight: 600; font-size: 0.95rem;" x-text="subject.name"></div>
                                    <div style="font-size: 0.75rem; color: var(--text-secondary);">
                                        كود: <span x-text="subject.code || '-'"></span> | <span x-text="subject.term"></span>
                                    </div>
                                </div>
                                <div style="text-align: left;">
                                    <div style="font-size: 0.75rem; color: var(--text-secondary);">المدرس</div>
                                    <div style="font-weight: 600; font-size: 0.85rem; color: #059669;" x-text="subject.doctor"></div>
                                </div>
                            </div>
                        </template>

                        <div x-show="viewSubjects.length === 0" style="text-align: center; padding: 1.5rem; color: var(--text-secondary); background: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 12px;">
                            لم يتم تسجيل أي مواد دراسية لهذا الطالب.
                        </div>
                    </div>
                </div>

            </div>

            <div class="modal-actions" style="margin-top: 2rem; border-top: 1px solid var(--border-color); padding-top: 1rem;">
                <button type="button" class="btn btn-secondary" @click="showDetailsModal = false">إغلاق</button>
            </div>
        </div>
    </div>



    <!-- Device Requests Modal -->
    <div x-show="showDeviceRequestsModal" class="modal-overlay" style="display: none;"
        x-transition:enter="transition ease-out duration-300"
        x-transition:enter-start="opacity-0"
        x-transition:enter-end="opacity-100"
        x-transition:leave="transition ease-in duration-200"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0">
        <div class="modal-container" style="text-align: right; max-width: 750px; max-height: 90vh; display: flex; flex-direction: column; overflow: hidden;" @click.away="showDeviceRequestsModal = false">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; border-bottom: 1px solid var(--border-color); padding-bottom: 1rem;">
                <div style="display: flex; align-items: center; gap: 0.75rem;">
                    <div style="width: 40px; height: 40px; background: rgba(245, 158, 11, 0.1); color: #f59e0b; border-radius: 10px; display: flex; align-items: center; justify-content: center;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <rect x="5" y="2" width="14" height="20" rx="2" ry="2"></rect>
                            <line x1="12" y1="18" x2="12.01" y2="18"></line>
                        </svg>
                    </div>
                    <h3 class="modal-title" style="margin: 0; font-size: 1.25rem;">طلبات الأجهزة الفرعية المعلقة</h3>
                </div>
                <button @click="showDeviceRequestsModal = false" style="background: none; border: none; cursor: pointer; font-size: 1.5rem; color: var(--text-secondary);">&times;</button>
            </div>

            <!-- Modal Content with scroll -->
            <div style="flex: 1; overflow-y: auto; padding-right: 0.25rem; display: flex; flex-direction: column; gap: 1.25rem;">
                <!-- Loading State -->
                <div x-show="isLoadingDeviceRequests && deviceRequestsList.length === 0" style="display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 3rem 1rem; gap: 1rem;">
                    <div class="loading-spinner" style="width: 40px; height: 40px; border: 4px solid rgba(0, 0, 0, 0.1); border-top-color: #f59e0b; border-radius: 50%; animation: spin 1s linear infinite;"></div>
                    <p style="color: var(--text-secondary); font-weight: 600;">جاري تحميل طلبات الأجهزة المعلقة...</p>
                </div>

                <!-- Empty State -->
                <div x-show="!isLoadingDeviceRequests && deviceRequestsList.length === 0" style="text-align: center; padding: 4rem 1rem; color: var(--text-secondary); display: flex; flex-direction: column; align-items: center; gap: 1rem;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="2">
                        <circle cx="12" cy="12" r="10"></circle>
                        <polyline points="12 6 12 12 16 14"></polyline>
                    </svg>
                    <p style="font-size: 1rem; font-weight: 600; color: var(--text-secondary);">لا توجد طلبات أجهزة معلقة حالياً.</p>
                </div>

                <!-- Requests List -->
                <template x-for="req in deviceRequestsList" :key="req.id">
                    <div class="device-request-card" style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 16px; padding: 1.25rem; display: flex; flex-direction: column; gap: 1rem; transition: all 0.3s; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.02);" onmouseover="this.style.borderColor='#f59e0b'" onmouseout="this.style.borderColor='#e2e8f0'">
                        <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 1rem; border-bottom: 1px dashed #e2e8f0; padding-bottom: 0.75rem;">
                            <div>
                                <h4 style="margin: 0 0 0.25rem 0; font-size: 1.05rem; font-weight: 800; color: var(--text-primary);" x-text="req.student_name"></h4>
                                <span style="font-size: 0.8rem; color: var(--text-secondary); font-weight: 600;" x-text="'الرقم الجامعي: ' + req.student_number"></span>
                                <span style="margin: 0 0.5rem; color: #cbd5e1;">|</span>
                                <span style="font-size: 0.8rem; color: var(--text-secondary); font-weight: 600;" x-text="req.college_name + ' - ' + req.major_name + ' (' + req.level_name + ')'"></span>
                            </div>
                            <span style="font-size: 0.75rem; color: var(--text-secondary); font-weight: 500; background: #e2e8f0; padding: 0.25rem 0.50rem; border-radius: 6px;" x-text="req.created_at"></span>
                        </div>

                        <!-- Requested Device & Platform Details -->
                        <div style="display: flex; flex-wrap: wrap; gap: 0.75rem; align-items: center;">
                            <div style="display: inline-flex; align-items: center; gap: 0.35rem; padding: 0.35rem 0.75rem; border-radius: 10px; background: rgba(59, 130, 246, 0.08); border: 1px solid rgba(59, 130, 246, 0.15); color: #2563eb; font-size: 0.85rem; font-weight: 700;">
                                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                    <rect x="5" y="2" width="14" height="20" rx="2" ry="2"></rect>
                                    <line x1="12" y1="18" x2="12.01" y2="18"></line>
                                </svg>
                                <span x-text="req.requested_device_name"></span>
                            </div>
                            <template x-if="req.platform">
                                <span style="font-size: 0.75rem; font-weight: 700; padding: 0.3rem 0.6rem; border-radius: 8px; text-transform: uppercase;"
                                    :style="req.platform.toLowerCase().includes('ios') || req.platform.toLowerCase().includes('iphone') ? 'background: #f3f4f6; color: #1f2937;' : 'background: #e0f2fe; color: #0369a1;'"
                                    x-text="req.platform">
                                </span>
                            </template>
                        </div>

                        <!-- Reason -->
                        <div style="background: white; border: 1px solid #f1f5f9; border-right: 3px solid #f59e0b; border-radius: 10px; padding: 0.75rem 1rem;">
                            <div style="font-size: 0.75rem; color: var(--text-secondary); font-weight: 700; margin-bottom: 0.25rem;">سبب تقديم الطلب:</div>
                            <p style="margin: 0; font-size: 0.85rem; line-height: 1.5; color: var(--text-primary); font-weight: 600;" x-text="req.reason"></p>
                        </div>

                        <!-- Notes / Actions Section -->
                        <div style="display: flex; flex-direction: column; gap: 0.75rem; border-top: 1px solid #f1f5f9; padding-top: 0.75rem;">
                            <!-- Note input for approval -->
                            <div style="display: flex; gap: 0.5rem; align-items: center;" x-show="rejectingRequest !== req.id">
                                <input type="text" placeholder="ملاحظة للموافقة (اختياري)..." x-model="adminApproveNote" style="flex: 1; padding: 0.5rem 0.75rem; border: 1px solid #cbd5e1; border-radius: 10px; font-size: 0.85rem;" />
                                <button type="button" @click="approveRequestAJAX(req.id, adminApproveNote); adminApproveNote = ''" class="action-btn" style="background: #10b981; color: white; padding: 0.5rem 1rem; border: none; border-radius: 10px; font-size: 0.85rem; font-weight: 700; cursor: pointer; display: flex; align-items: center; gap: 0.25rem;">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                        <polyline points="20 6 9 17 4 12"></polyline>
                                    </svg>
                                    موافقة وتفعيل
                                </button>
                                <button type="button" @click="rejectingRequest = req.id; adminRejectNote = ''" class="action-btn" style="background: #ef4444; color: white; padding: 0.5rem 1rem; border: none; border-radius: 10px; font-size: 0.85rem; font-weight: 700; cursor: pointer;">
                                    رفض
                                </button>
                            </div>

                            <!-- Reject note input -->
                            <div style="display: flex; flex-direction: column; gap: 0.5rem; background: #fff5f5; border: 1px solid #fed7d7; border-radius: 12px; padding: 1rem;" x-show="rejectingRequest === req.id">
                                <label style="font-size: 0.8rem; font-weight: 700; color: #991b1b; display: block;">يرجى تحديد سبب الرفض لإرساله للطالب في إشعار:</label>
                                <textarea placeholder="اكتب سبب رفض الطلب هنا (مطلوب)..." x-model="adminRejectNote" rows="2" style="width: 100%; padding: 0.5rem 0.75rem; border: 1px solid #fecaca; border-radius: 8px; font-size: 0.85rem; font-weight: 600; resize: none; direction: rtl; box-sizing: border-box;"></textarea>
                                <div style="display: flex; justify-content: flex-end; gap: 0.5rem; margin-top: 0.25rem;">
                                    <button type="button" @click="rejectingRequest = null" class="action-btn view" style="padding: 0.4rem 0.85rem; font-size: 0.8rem; font-weight: 700; border-radius: 8px;">إلغاء</button>
                                    <button type="button" @click="rejectRequestAJAX(req.id, adminRejectNote)" class="action-btn" style="background: #ef4444; color: white; padding: 0.4rem 0.85rem; border: none; border-radius: 8px; font-size: 0.8rem; font-weight: 700; cursor: pointer;">تأكيد الرفض</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </template>
            </div>

            <!-- Modal footer -->
            <div class="modal-actions" style="margin-top: 1.5rem; border-top: 1px solid var(--border-color); padding-top: 1rem; display: flex; justify-content: flex-end;">
                <button type="button" class="btn btn-secondary" @click="showDeviceRequestsModal = false">إغلاق</button>
            </div>
        </div>
    </div>



    <!-- Permissions Modal -->
    <div x-show="showPermissionsModal" class="modal-overlay" style="display: none;"
        x-transition:enter="transition ease-out duration-300"
        x-transition:enter-start="opacity-0"
        x-transition:enter-end="opacity-100"
        x-transition:leave="transition ease-in duration-200"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0">
        <div class="modal-container" style="text-align: right; max-width: 500px;" @click.away="showPermissionsModal = false">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; border-bottom: 1px solid var(--border-color); padding-bottom: 1rem;">
                <div style="display: flex; align-items: center; gap: 0.75rem;">
                    <div style="width: 40px; height: 40px; background: rgba(59, 130, 246, 0.1); color: #3b82f6; border-radius: 10px; display: flex; align-items: center; justify-content: center;">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
                        </svg>
                    </div>
                    <h3 class="modal-title" style="margin: 0; font-size: 1.25rem;">إدارة الصلاحيات</h3>
                </div>
                <button @click="showPermissionsModal = false" style="background: none; border: none; cursor: pointer; font-size: 1.5rem; color: var(--text-secondary);">&times;</button>
            </div>

            <p style="color: var(--text-secondary); margin-bottom: 1.5rem;">
                الطالب: <strong style="color: var(--text-primary);" x-text="permStudent.name"></strong>
            </p>

            <form :action="permsUrl" method="POST">
                @csrf
                <div style="display: flex; flex-direction: column; gap: 1rem; margin-bottom: 2rem;">
                    @foreach(\App\Models\Permission::all() as $perm)
                    <label style="display: flex; align-items: center; justify-content: space-between; padding: 1rem; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; cursor: pointer; transition: all 0.2s;" class="permission-item" onmouseover="this.style.borderColor='var(--primary-color)'" onmouseout="this.style.borderColor='#e2e8f0'">
                        <div style="display: flex; flex-direction: column; gap: 0.25rem;">
                            <span style="font-weight: 700; color: var(--text-primary);">{{ $perm->name }}</span>
                            <span style="font-size: 0.8rem; color: var(--text-secondary);">{{ $perm->description }}</span>
                        </div>
                        <div class="custom-toggle">
                            <input type="checkbox" name="permissions[]" value="{{ $perm->slug }}" style="width: 20px; height: 20px; cursor: pointer;"
                                :checked="permStudent.permissions.includes('{{ $perm->slug }}')">
                        </div>
                    </label>
                    @endforeach
                </div>

                <div class="modal-actions" style="margin-top: 2rem; border-top: 1px solid var(--border-color); padding-top: 1rem; display: flex; gap: 1rem; justify-content: flex-end;">
                    <button type="button" class="action-btn view" @click="showPermissionsModal = false" style="padding: 0.75rem 1.5rem;">إلغاء</button>
                    <button type="submit" class="action-btn edit" style="padding: 0.75rem 1.5rem; background: #10b981; color: white;">حفظ الصلاحيات</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Beautiful premium toast notification container -->
    <div x-show="toastShow" 
         x-transition:enter="transition ease-out duration-300"
         x-transition:enter-start="opacity-0 translate-y-2 scale-95"
         x-transition:enter-end="opacity-100 translate-y-0 scale-100"
         x-transition:leave="transition ease-in duration-200"
         x-transition:leave-start="opacity-100 translate-y-0 scale-100"
         x-transition:leave-end="opacity-0 translate-y-2 scale-95"
         style="position: fixed; bottom: 2rem; left: 2rem; z-index: 99999; display: flex; align-items: center; gap: 0.75rem; padding: 0.85rem 1.5rem; border-radius: 14px; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.15), 0 8px 10px -6px rgba(0, 0, 0, 0.15); color: white; direction: rtl; transition: all 0.3s; pointer-events: none;"
         :style="toastType === 'success' ? 'background: linear-gradient(135deg, #059669 0%, #10b981 100%); border: 1px solid #34d399;' : 'background: linear-gradient(135deg, #b91c1c 0%, #ef4444 100%); border: 1px solid #fca5a5;'">
         
         <!-- Success Icon -->
         <template x-if="toastType === 'success'">
             <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                 <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                 <polyline points="22 4 12 14.01 9 11.01"></polyline>
             </svg>
         </template>
         
         <!-- Error Icon -->
         <template x-if="toastType === 'error'">
             <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                 <circle cx="12" cy="12" r="10"></circle>
                 <line x1="12" y1="8" x2="12" y2="12"></line>
                 <line x1="12" y1="16" x2="12.01" y2="16"></line>
             </svg>
         </template>
         
         <span style="font-weight: 700; font-size: 0.9rem;" x-text="toastMessage"></span>
    </div>

</div>

@endsection
