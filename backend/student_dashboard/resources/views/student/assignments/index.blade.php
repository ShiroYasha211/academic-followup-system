@extends('layouts.student')

@section('title', 'التكاليف والواجبات')

@section('content')

<style>
    .page-header {
        margin-bottom: 2rem;
    }

    .page-title {
        font-size: 1.75rem;
        font-weight: 800;
        color: var(--text-primary);
        margin-bottom: 0.5rem;
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .page-subtitle {
        color: var(--text-secondary);
    }

    /* Stats Grid */
    .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 1.25rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: white;
        border-radius: 16px;
        padding: 1.25rem;
        border: 1px solid #e2e8f0;
        display: flex;
        align-items: center;
        gap: 1rem;
        transition: all 0.2s;
    }

    .stat-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.06);
    }

    .stat-icon {
        width: 52px;
        height: 52px;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .stat-value {
        font-size: 1.5rem;
        font-weight: 800;
        color: var(--text-primary);
    }

    .stat-label {
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    /* Tabs */
    .tabs-wrapper {
        background: white;
        border-radius: 16px;
        padding: 0.5rem;
        display: inline-flex;
        gap: 0.5rem;
        margin-bottom: 2rem;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
    }

    .tab-btn {
        background: transparent;
        border: none;
        padding: 0.85rem 1.5rem;
        font-family: inherit;
        font-weight: 700;
        color: var(--text-secondary);
        cursor: pointer;
        border-radius: 12px;
        transition: all 0.2s;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .tab-btn:hover {
        color: var(--primary-color);
        background: #f8fafc;
    }

    .tab-btn.active-tab {
        color: white;
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        box-shadow: 0 4px 12px -2px rgba(79, 70, 229, 0.35);
    }

    .tab-btn .badge {
        background: rgba(255, 255, 255, 0.25);
        padding: 0.2rem 0.5rem;
        border-radius: 6px;
        font-size: 0.75rem;
    }

    /* Assignment Cards */
    .assignments-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
        gap: 1.5rem;
    }

    .assignment-card {
        background: white;
        border-radius: 20px;
        border: 2px solid transparent;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
        overflow: hidden;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        display: flex;
        flex-direction: column;
        position: relative;
    }

    .assignment-card:hover {
        transform: translateY(-5px);
        border-color: #e2e8f0;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
    }

    .card-stripe {
        height: 5px;
        background: linear-gradient(90deg, #4f46e5 0%, #7c3aed 100%);
    }

    .card-stripe.urgent {
        background: linear-gradient(90deg, #dc2626 0%, #ef4444 100%);
    }

    .card-stripe.soon {
        background: linear-gradient(90deg, #f59e0b 0%, #fbbf24 100%);
    }

    .card-body {
        padding: 1.5rem;
        flex: 1;
        display: flex;
        flex-direction: column;
    }

    .card-header-row {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 1rem;
    }

    .subject-badge {
        background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
        color: #4f46e5;
        padding: 0.4rem 0.85rem;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.8rem;
    }

    .deadline-badge {
        display: flex;
        align-items: center;
        gap: 0.35rem;
        font-size: 0.8rem;
        font-weight: 700;
        padding: 0.4rem 0.75rem;
        border-radius: 999px;
    }

    .deadline-badge.urgent {
        background: #fef2f2;
        color: #dc2626;
        border: 1px solid #fecaca;
    }

    .deadline-badge.soon {
        background: #fffbeb;
        color: #d97706;
        border: 1px solid #fde68a;
    }

    .deadline-badge.normal {
        background: #f0fdf4;
        color: #16a34a;
        border: 1px solid #bbf7d0;
    }

    .assignment-title {
        font-size: 1.15rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.75rem;
        line-height: 1.4;
    }

    .assignment-desc {
        color: var(--text-secondary);
        font-size: 0.9rem;
        line-height: 1.6;
        flex: 1;
        margin-bottom: 1rem;
    }

    .card-footer {
        border-top: 1px solid #f1f5f9;
        padding-top: 1rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .due-date {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    .details-btn {
        padding: 0.65rem 1.4rem;
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        color: white;
        border-radius: 12px;
        text-decoration: none;
        font-weight: 700;
        font-size: 0.85rem;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        display: flex;
        align-items: center;
        gap: 0.5rem;
        border: none;
        cursor: pointer;
        box-shadow: 0 4px 6px -1px rgba(79, 70, 229, 0.2);
    }

    .details-btn:hover {
        transform: translateY(-2px);
        box-shadow: 0 10px 15px -3px rgba(79, 70, 229, 0.4);
        color: white;
        filter: brightness(1.1);
    }

    .modal-body-content {
        animation: fadeIn 0.4s ease-out;
    }

    @keyframes fadeIn {
        from { opacity: 0; transform: translateY(10px); }
        to { opacity: 1; transform: translateY(0); }
    }

    /* Past Assignments Table */
    .table-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
    }

    .modern-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
    }

    .modern-table thead th {
        background: #f8fafc;
        padding: 1rem 1.25rem;
        font-weight: 700;
        color: var(--text-secondary);
        font-size: 0.85rem;
        text-align: right;
        border-bottom: 2px solid #e2e8f0;
    }

    .modern-table tbody tr {
        transition: all 0.2s;
    }

    .modern-table tbody tr:hover {
        background: #fafbfc;
    }

    .modern-table tbody td {
        padding: 1rem 1.25rem;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
    }

    .past-badge {
        background: #f1f5f9;
        color: #64748b;
        padding: 0.35rem 0.75rem;
        border-radius: 8px;
        font-weight: 600;
        font-size: 0.8rem;
    }

    /* Empty State */
    .empty-state {
        text-align: center;
        padding: 4rem 2rem;
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
    }

    .empty-icon {
        width: 80px;
        height: 80px;
        background: linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%);
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 1.5rem;
        color: #16a34a;
    }
    /* Sorting Toggle */
    .sort-toggle {
        display: flex;
        background: #f1f5f9;
        padding: 0.35rem;
        border-radius: 12px;
        margin-bottom: 2rem;
        gap: 0.25rem;
        width: fit-content;
    }

    .sort-toggle button {
        border: none;
        background: transparent;
        padding: 0.5rem 1.5rem;
        border-radius: 9px;
        font-size: 0.85rem;
        font-weight: 700;
        color: #64748b;
        cursor: pointer;
        transition: all 0.2s;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .sort-toggle button.active {
        background: white;
        color: var(--primary-color);
        box-shadow: 0 2px 4px rgba(0,0,0,0.05);
    }

    /* Priority Controls */
    .priority-control {
        display: flex;
        gap: 0.15rem;
        margin-top: 0.25rem;
    }

    .priority-star {
        cursor: pointer;
        color: #e2e8f0;
        transition: all 0.2s;
    }

    .priority-star.active {
        color: #f59e0b;
        fill: #f59e0b;
    }

    .priority-star:hover {
        transform: scale(1.1);
    }

    /* Modal Styles */
    .modal-overlay {
        position: fixed;
        top: 0; left: 0; right: 0; bottom: 0;
        background: rgba(15, 23, 42, 0.7);
        backdrop-filter: blur(8px);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
        padding: 1.5rem;
    }

    .modal-content {
        background: white;
        border-radius: 24px;
        width: 100%;
        max-width: 650px;
        max-height: 90vh;
        overflow-y: auto;
        position: relative;
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
        border: 1px solid rgba(255, 255, 255, 0.2);
    }

    .modal-header-banner {
        padding: 2rem 1.5rem;
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        color: white;
        position: relative;
    }

    .modal-close {
        position: absolute;
        top: 1rem;
        left: 1rem;
        background: rgba(255, 255, 255, 0.2);
        color: white;
        border: none;
        width: 32px;
        height: 32px;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all 0.2s;
    }

    .modal-close:hover {
        background: rgba(255, 255, 255, 0.3);
        transform: rotate(90deg);
    }

    .modal-body {
        padding: 2rem;
    }

    .upload-area {
        border: 2px dashed #e2e8f0;
        border-radius: 16px;
        padding: 2rem;
        text-align: center;
        transition: all 0.2s;
        cursor: pointer;
        background: #f8fafc;
    }

    .upload-area:hover {
        border-color: var(--primary-color);
        background: #f1f5f9;
    }

    .upload-area.dragover {
        border-color: var(--primary-color);
        background: #eff6ff;
    }

    .selected-file {
        background: #eff6ff;
        border: 1px solid #e0e7ff;
        border-radius: 12px;
        padding: 1rem;
        display: flex;
        align-items: center;
        gap: 1rem;
        margin-top: 1rem;
    }

    .notes-input {
        width: 100%;
        padding: 1rem;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        margin-top: 1rem;
        resize: none;
        font-family: inherit;
    }

    .btn-submit-modal {
        width: 100%;
        padding: 1rem;
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        color: white;
        border: none;
        border-radius: 14px;
        font-weight: 700;
        font-size: 1rem;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        margin-top: 1.5rem;
        transition: all 0.2s;
    }

    .btn-submit-modal:hover {
        transform: translateY(-2px);
        box-shadow: 0 10px 15px -3px rgba(16, 185, 129, 0.4);
    }

    .btn-submit-modal:disabled {
        opacity: 0.6;
        cursor: not-allowed;
        transform: none;
    }

    [x-cloak] { display: none !important; }
</style>


<div class="page-header">
    <h1 class="page-title">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
            <polyline points="14 2 14 8 20 8"></polyline>
            <line x1="16" y1="13" x2="8" y2="13"></line>
            <line x1="16" y1="17" x2="8" y2="17"></line>
        </svg>
        التكاليف والواجبات
    </h1>
    <p class="page-subtitle">عرض التكاليف المطلوبة والواجبات المنزلية</p>
</div>

<!-- Stats Grid -->
<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-icon" style="background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%); color: #2563eb;">
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
        </div>
        <div>
            <div class="stat-value">{{ $activeAssignments->count() }}</div>
            <div class="stat-label">تكليف نشط</div>
        </div>
    </div>

    <div class="stat-card">
        <div class="stat-icon" style="background: linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%); color: #16a34a;">
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
        </div>
        <div>
            <div class="stat-value">{{ $pastAssignments->count() }}</div>
            <div class="stat-label">تكليف منتهي</div>
        </div>
    </div>

    @php
    $urgentCount = $activeAssignments->filter(function($a) {
    return (int) floor(\Carbon\Carbon::now()->startOfDay()->diffInDays(\Carbon\Carbon::parse($a->due_date)->startOfDay(), false)) <= 2;
        })->count();
        @endphp
        <div class="stat-card">
            <div class="stat-icon" style="background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%); color: #dc2626;">
                <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                    <line x1="12" y1="9" x2="12" y2="13"></line>
                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                </svg>
            </div>
            <div>
                <div class="stat-value">{{ $urgentCount }}</div>
                <div class="stat-label">تسليم قريب</div>
            </div>
        </div>
</div>

<script>
function assignmentData() {
    return {
        activeTab: 'active',
        sortBy: '{{ $sortBy }}',
        showModal: false,
        loading: false,
        assignment: null,
        submission: null,
        selectedFileName: '',
        selectedFileSize: '',
        notes: '',
        
        updateSort(mode) {
            this.sortBy = mode;
            fetch('{{ route("student.assignments.updatePreference") }}', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}'
                },
                body: JSON.stringify({ sort_by: mode })
            }).then(() => {
                window.location.reload();
            });
        },
        
        updatePriority(assignmentId, level) {
            fetch(`/student/assignments/${assignmentId}/priority`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}'
                },
                body: JSON.stringify({ priority: level })
            }).then(response => response.json())
            .then(data => {
                if(data.success && this.sortBy === 'priority') {
                    window.location.reload();
                }
            });
        },

        async openModal(id) {
            this.loading = true;
            this.showModal = true;
            this.assignment = null;
            this.submission = null;
            this.selectedFileName = '';
            this.notes = '';

            try {
                const response = await fetch(`/student/assignments/${id}/details`);
                const data = await response.json();
                
                // Set data ensuring reactivity
                this.assignment = data.assignment;
                this.submission = data.submission;
                this.notes = this.submission ? (this.submission.notes || '') : '';
                
                // Merge extra formatted fields into objects
                this.assignment.formatted_due_date = data.formatted_due_date;
                this.assignment.is_overdue = data.is_overdue;
                
                if (this.submission) {
                    this.submission.formatted_submitted_at = data.formatted_submitted_at;
                    this.submission.formatted_file_size = data.formatted_file_size;
                    this.submission.is_late = data.is_late;
                }
            } catch (error) {
                console.error('Error fetching assignment details:', error);
                alert('حدث خطأ أثناء تحميل البيانات. يرجى المحاولة مرة أخرى.');
                this.showModal = false;
            } finally {
                this.loading = false;
            }
        },

        handleFileChange(e) {
            const file = e.target.files[0];
            if (file) {
                this.selectedFileName = file.name;
                this.selectedFileSize = this.formatFileSize(file.size);
            }
        },

        formatFileSize(bytes) {
            if (bytes >= 1048576) return (bytes / 1048576).toFixed(2) + ' MB';
            if (bytes >= 1024) return (bytes / 1024).toFixed(2) + ' KB';
            return bytes + ' bytes';
        }
    }
}
</script>

<div x-data="assignmentData()" x-cloak>

    <!-- Modern Tabs -->
    <div style="display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: 1rem;">
        <div class="tabs-wrapper" style="margin-bottom: 0.5rem;">
            <button @click="activeTab = 'active'" :class="{ 'active-tab': activeTab === 'active' }" class="tab-btn">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <polyline points="12 6 12 12 16 14"></polyline>
                </svg>
                التكاليف الحالية
                @if($activeAssignments->count() > 0)
                <span class="badge">{{ $activeAssignments->count() }}</span>
                @endif
            </button>
            <button @click="activeTab = 'past'" :class="{ 'active-tab': activeTab === 'past' }" class="tab-btn">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                    <polyline points="22 4 12 14.01 9 11.01"></polyline>
                </svg>
                التكاليف المنتهية
            </button>
        </div>

        <div class="sort-toggle" x-show="activeTab === 'active'">
            <button @click="updateSort('due_date')" :class="{ 'active': sortBy === 'due_date' }">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <polyline points="12 6 12 12 16 14"></polyline>
                </svg>
                حسب الموعد
            </button>
            <button @click="updateSort('priority')" :class="{ 'active': sortBy === 'priority' }">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
                </svg>
                حسب أولويتي
            </button>
        </div>
    </div>

    <!-- Active Assignments -->
    <div x-show="activeTab === 'active'" x-transition:enter="transition ease-out duration-300" x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100">
        @if($activeAssignments->count() > 0)
        <div class="assignments-grid">
            @foreach($activeAssignments as $assignment)
            @php
            $daysLeft = (int) floor(\Carbon\Carbon::now()->startOfDay()->diffInDays(\Carbon\Carbon::parse($assignment->due_date)->startOfDay(), false));
            $urgencyClass = $daysLeft <= 1 ? 'urgent' : ($daysLeft <=3 ? 'soon' : 'normal' );
                $stripeClass=$daysLeft <=1 ? 'urgent' : ($daysLeft <=3 ? 'soon' : '' );
                @endphp
                <div class="assignment-card">
                <div class="card-stripe {{ $stripeClass }}"></div>
                <div class="card-body">
                    <div class="card-header-row">
                        <div style="display: flex; flex-direction: column; gap: 0.5rem;">
                            <span class="subject-badge">{{ $assignment->subject->name }}</span>
                            <!-- Priority Stars -->
                            <div class="priority-control" x-data="{ priority: {{ $assignment->my_priority }} }">
                                <template x-for="i in [1, 2]">
                                    <svg @click="updatePriority({{ $assignment->id }}, i); priority = i" 
                                         class="priority-star" :class="{ 'active': priority >= i }"
                                         width="18" height="18" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2">
                                        <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
                                    </svg>
                                </template>
                                <svg @click="updatePriority({{ $assignment->id }}, 0); priority = 0" 
                                     x-show="priority > 0"
                                     style="color: #ef4444; cursor: pointer; margin-right: 4px;"
                                     width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <line x1="18" y1="6" x2="6" y2="18"></line>
                                    <line x1="6" y1="6" x2="18" y2="18"></line>
                                </svg>
                            </div>
                        </div>
                        <span class="deadline-badge {{ $urgencyClass }}">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <circle cx="12" cy="12" r="10"></circle>
                                <polyline points="12 6 12 12 16 14"></polyline>
                            </svg>
                            @if($daysLeft <= 0)
                                اليوم!
                                @elseif($daysLeft==1)
                                غداً
                                @else
                                {{ $daysLeft }} أيام
                                @endif
                                </span>
                    </div>

                    <h3 class="assignment-title">{{ $assignment->title }}</h3>
                    <p class="assignment-desc">{{ \Illuminate\Support\Str::limit($assignment->description, 120) }}</p>

                    <div class="card-footer">
                        <div class="due-date">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                                <line x1="16" y1="2" x2="16" y2="6"></line>
                                <line x1="8" y1="2" x2="8" y2="6"></line>
                                <line x1="3" y1="10" x2="21" y2="10"></line>
                            </svg>
                            {{ \Carbon\Carbon::parse($assignment->due_date)->format('Y-m-d') }}
                        </div>
                        <button @click="openModal({{ $assignment->id }})" class="details-btn">
                            عرض التفاصيل
                        </button>
                    </div>
                </div>
        </div>
        @endforeach
    </div>
    @else
    <div class="empty-state">
        <div class="empty-icon">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
        </div>
        <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem;">🎉 لا توجد واجبات نشطة</h3>
        <p style="color: var(--text-secondary);">ممتاز! لقد أنجزت جميع واجباتك الحالية.</p>
    </div>
    @endif
</div>

<!-- Past Assignments -->
<div x-show="activeTab === 'past'" x-transition:enter="transition ease-out duration-300" x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100" style="display: none;">
    @if($pastAssignments->count() > 0)
    <div class="table-card">
        <div class="table-responsive">
            <table class="modern-table">
                <thead>
                    <tr>
                        <th>العنوان</th>
                        <th>المادة</th>
                        <th>تاريخ الاستحقاق</th>
                        <th>الحالة</th>
                        <th>الإجراء</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($pastAssignments as $assignment)
                    <tr>
                        <td style="font-weight: 700;">{{ $assignment->title }}</td>
                        <td>
                            <span style="background: #f1f5f9; padding: 0.35rem 0.75rem; border-radius: 8px; font-size: 0.85rem;">
                                {{ $assignment->subject->name }}
                            </span>
                        </td>
                        <td style="color: var(--text-secondary);">{{ \Carbon\Carbon::parse($assignment->due_date)->format('Y-m-d') }}</td>
                        <td>
                            <span class="past-badge">✓ منتهي</span>
                        </td>
                        <td>
                            <button @click="openModal({{ $assignment->id }})" style="color: var(--primary-color); background: none; border: none; font-weight: 700; cursor: pointer;">عرض</button>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
    @else
    <div class="empty-state">
        <div class="empty-icon" style="background: linear-gradient(135deg, #f1f5f9 0%, #e2e8f0 100%); color: #64748b;">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
            </svg>
        </div>
        <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem;">لا يوجد سجل</h3>
        <p style="color: var(--text-secondary);">لا يوجد سجل واجبات سابقة.</p>
    </div>
    @endif
</div>

<!-- Assignment Modal -->
<div x-show="showModal" 
     class="modal-overlay" 
     x-transition:enter="transition ease-out duration-300" 
     x-transition:enter-start="opacity-0" 
     x-transition:enter-end="opacity-100"
     @click.self="showModal = false">
    
    <div class="modal-content" 
         x-show="showModal"
         x-transition:enter="transition ease-out duration-300"
         x-transition:enter-start="opacity-0 scale-95 translateY(20px)"
         x-transition:enter-end="opacity-100 scale-100 translateY(0)">
        
        <!-- Loading State -->
        <div x-show="loading" class="modal-body" style="text-align: center; padding: 4rem;">
            <div class="spinner" style="border: 4px solid #f3f3f3; border-top: 4px solid #4f46e5; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto 1rem;"></div>
            <p style="color: var(--text-secondary); font-weight: 600;">جاري تحميل التفاصيل...</p>
        </div>

        <div x-show="!loading && assignment">
            <div class="modal-header-banner">
                <button @click="showModal = false" class="modal-close">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </button>
                <div style="font-size: 0.9rem; opacity: 0.9; margin-bottom: 0.5rem;" x-text="assignment.subject.name"></div>
                <h2 style="font-size: 1.5rem; font-weight: 800; margin: 0;" x-text="assignment.title"></h2>
            </div>

            <div class="modal-body">
                <!-- Status Bar -->
                <div style="display: flex; gap: 1rem; margin-bottom: 2rem; border-bottom: 1px solid #f1f5f9; padding-bottom: 1rem;">
                    <div style="flex: 1;">
                        <div style="font-size: 0.8rem; color: var(--text-secondary); margin-bottom: 0.25rem;">تاريخ الاستحقاق</div>
                        <div style="font-weight: 700; color: var(--text-primary);" x-text="assignment.formatted_due_date"></div>
                    </div>
                    <div style="flex: 1;">
                        <div style="font-size: 0.8rem; color: var(--text-secondary); margin-bottom: 0.25rem;">الحالة</div>
                        <template x-if="submission">
                            <div style="font-weight: 700; color: #10b981;">تم التسليم ✅</div>
                        </template>
                        <template x-if="!submission">
                            <div style="font-weight: 700;" :style="assignment.is_overdue ? 'color: #ef4444' : 'color: #f59e0b'" x-text="assignment.is_overdue ? 'منتهي' : 'قيد الانتظار'"></div>
                        </template>
                    </div>
                </div>

                <!-- Description -->
                <div style="margin-bottom: 2.5rem;">
                    <h4 style="font-weight: 800; color: var(--text-primary); margin-bottom: 0.75rem; display: flex; align-items: center; gap: 0.5rem;">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="color: var(--primary-color)">
                            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                            <polyline points="14 2 14 8 20 8"></polyline>
                        </svg>
                        وصف التكليف
                    </h4>
                    <p x-text="assignment.description" style="color: var(--text-secondary); line-height: 1.7; font-size: 0.95rem;"></p>
                </div>

                <!-- Previous Submission Feedback -->
                <template x-if="submission">
                    <div style="background: #f8fafc; border-radius: 16px; padding: 1.5rem; margin-bottom: 2.5rem; border: 1px solid #e2e8f0;">
                        <h4 style="font-weight: 800; color: #10b981; margin-bottom: 1rem; display: flex; align-items: center; gap: 0.5rem;">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                                <polyline points="22 4 12 14.01 9 11.01"></polyline>
                            </svg>
                            تفاصيل تسليمك
                        </h4>
                        
                        <div style="display: flex; flex-direction: column; gap: 0.75rem;">
                            <template x-if="submission.file_name">
                                <div style="display: flex; align-items: center; gap: 0.75rem; background: white; padding: 0.75rem; border-radius: 10px; border: 1px solid #f1f5f9;">
                                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                                    </svg>
                                    <div style="flex: 1;">
                                        <div style="font-weight: 700; font-size: 0.9rem;" x-text="submission.file_name"></div>
                                        <div style="font-size: 0.8rem; color: var(--text-secondary);" x-text="submission.formatted_file_size"></div>
                                    </div>
                                    <a :href="'/storage/' + submission.file_path" target="_blank" style="color: var(--primary-color);">
                                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                                            <polyline points="7 10 12 15 17 10"></polyline>
                                            <line x1="12" y1="15" x2="12" y2="3"></line>
                                        </svg>
                                    </a>
                                </div>
                            </template>
                            <template x-if="!submission.file_name">
                                <div style="color: #16a34a; font-weight: 700; font-size: 0.9rem;">✅ تم التأشير كمكتمل (بدون ملف)</div>
                            </template>
                            
                            <div style="font-size: 0.85rem; color: var(--text-secondary);">
                                تم التسليم في: <span x-text="submission.formatted_submitted_at"></span>
                                <template x-if="submission.is_late">
                                    <span style="background: #fee2e2; color: #991b1b; padding: 0.2rem 0.5rem; border-radius: 6px; font-weight: 700; font-size: 0.75rem; margin-right: 0.5rem;">متأخر</span>
                                </template>
                            </div>

                            <template x-if="submission.grade !== null">
                                <div style="margin-top: 0.5rem; padding: 1rem; background: white; border-radius: 12px; display: flex; align-items: center; justify-content: space-between;">
                                    <span style="font-weight: 700; color: var(--text-secondary);">الدرجة التقديرية</span>
                                    <span style="font-size: 1.5rem; font-weight: 800;" :style="submission.grade >= 60 ? 'color: #10b981' : 'color: #ef4444'" x-text="submission.grade + '/100'"></span>
                                </div>
                            </template>

                            <template x-if="submission.feedback">
                                <div style="margin-top: 0.5rem; padding: 1rem; background: #fffbeb; border: 1px solid #fef3c7; border-radius: 12px; color: #92400e;">
                                    <div style="font-weight: 800; margin-bottom: 0.25rem;">ملاحظات الدكتور:</div>
                                    <div style="line-height: 1.6;" x-text="submission.feedback"></div>
                                </div>
                            </template>
                        </div>
                    </div>
                </template>

                <!-- Submission Form -->
                <template x-if="!assignment.is_overdue || !submission">
                    <form :action="'/student/assignments/' + assignment.id + '/submit'" method="POST" enctype="multipart/form-data">
                        @csrf
                        <div x-show="assignment.requires_submission">
                            <h4 style="font-weight: 800; color: var(--text-primary); margin-bottom: 1rem; display: flex; align-items: center; gap: 0.5rem;">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="color: #8b5cf6">
                                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                                    <polyline points="17 8 12 3 7 8"></polyline>
                                </svg>
                                رفع ملف التكليف
                            </h4>
                            <div class="upload-area" @click="$refs.fileInput.click()" 
                                 @dragover.prevent="$el.classList.add('dragover')" 
                                 @dragleave.prevent="$el.classList.remove('dragover')"
                                 @drop.prevent="$el.classList.remove('dragover'); $refs.fileInput.files = $event.dataTransfer.files; handleFileChange({target: $refs.fileInput})">
                                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color: #cbd5e1; margin-bottom: 1rem;">
                                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                                    <polyline points="17 8 12 3 7 8"></polyline>
                                </svg>
                                <div style="font-weight: 700; color: var(--text-primary); font-size: 1rem;">اختر ملفاً للرفع</div>
                                <div style="color: var(--text-secondary); font-size: 0.85rem; margin-top: 0.25rem;">يمكنك سحب الملف وإفلاته هنا</div>
                            </div>
                            <input type="file" x-ref="fileInput" name="file" style="display: none;" @change="handleFileChange" accept=".pdf,.zip,.rar">
                            
                            <div class="selected-file" x-show="selectedFileName">
                                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                                </svg>
                                <div style="flex: 1;">
                                    <div style="font-weight: 700; font-size: 0.9rem;" x-text="selectedFileName"></div>
                                    <div style="font-size: 0.8rem; color: var(--text-secondary);" x-text="selectedFileSize"></div>
                                </div>
                            </div>
                        </div>

                        <template x-if="!assignment.requires_submission">
                            <div style="background: #f0fdf4; border: 1px dashed #22c55e; border-radius: 16px; padding: 1.5rem; text-align: center; margin-bottom: 1.5rem;">
                                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: #22c55e; margin-bottom: 0.5rem;">
                                    <polyline points="20 6 9 17 4 12"></polyline>
                                </svg>
                                <p style="font-weight: 700; color: #166534; font-size: 1rem; margin: 0;">هذا التكليف نظري ولا يتطلب ملفاً.</p>
                            </div>
                        </template>

                        <textarea name="notes" x-model="notes" class="notes-input" rows="3" placeholder="أضف ملاحظاتك هنا..."></textarea>

                        <button type="submit" class="btn-submit-modal" :disabled="assignment.requires_submission && !selectedFileName">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                                <polyline points="22 4 12 14.01 9 11.01"></polyline>
                            </svg>
                            <span x-text="submission ? 'تحديث التسليم' : (assignment.requires_submission ? 'رفع وتسليم التكليف' : 'تحديد كمكتمل')"></span>
                        </button>
                    </form>
                </template>
            </div>
        </div>
    </div>
</div>

<style>
@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
</style>

</div>


@endsection