@extends('layouts.delegate')

@section('title', 'تنبيهات الغياب')

@section('content')

<style>
    /* Stats Banner */
    .stats-banner {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: white;
        border-radius: 16px;
        padding: 1.25rem;
        text-align: center;
        border: 1px solid #e2e8f0;
        transition: all 0.3s;
    }

    .stat-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 20px rgba(0, 0, 0, 0.05);
    }

    .stat-card .stat-icon {
        margin-bottom: 0.5rem;
    }

    .stat-card .stat-value {
        font-size: 1.75rem;
        font-weight: 800;
        color: var(--text-primary);
    }

    .stat-card .stat-label {
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    /* Filter Buttons */
    .filter-tabs {
        display: flex;
        gap: 0.75rem;
        margin-bottom: 2rem;
        flex-wrap: wrap;
    }

    .filter-tab {
        padding: 0.6rem 1.25rem;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.9rem;
        text-decoration: none;
        transition: all 0.2s;
        border: 2px solid #e2e8f0;
        background: white;
        color: var(--text-secondary);
        display: flex;
        align-items: center;
        gap: 0.4rem;
    }

    .filter-tab:hover {
        border-color: var(--primary-color);
        color: var(--primary-color);
    }

    .filter-tab.active {
        background: var(--primary-color);
        color: white;
        border-color: var(--primary-color);
    }

    /* Table Styling */
    .alerts-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
    }

    .alerts-table thead th {
        background: #f8fafc;
        padding: 1rem;
        text-align: right;
        font-weight: 700;
        color: var(--text-secondary);
        font-size: 0.85rem;
        border-bottom: 2px solid #e2e8f0;
    }

    .alerts-table tbody tr {
        transition: all 0.2s;
    }

    .alerts-table tbody tr:hover {
        background: #f8fafc;
    }

    .alerts-table tbody td {
        padding: 1rem;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
    }

    .student-info {
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .student-avatar {
        width: 40px;
        height: 40px;
        background: linear-gradient(135deg, #f1f5f9 0%, #e2e8f0 100%);
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        color: var(--text-secondary);
    }

    .status-badge {
        display: inline-flex;
        align-items: center;
        gap: 0.3rem;
        padding: 0.35rem 0.75rem;
        border-radius: 8px;
        font-size: 0.8rem;
        font-weight: 700;
    }

    .status-badge.danger {
        background: #fef2f2;
        color: #ef4444;
    }

    .status-badge.warning {
        background: #fffbeb;
        color: #f59e0b;
    }

    .status-badge.normal {
        background: #ecfdf5;
        color: #10b981;
    }

    .send-btn {
        padding: 0.5rem 1rem;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.85rem;
        border: 2px solid #ef4444;
        background: white;
        color: #ef4444;
        cursor: pointer;
        transition: all 0.2s;
        display: flex;
        align-items: center;
        gap: 0.4rem;
    }

    .send-btn:hover {
        background: #ef4444;
        color: white;
    }

    /* Modal Styles */
    .modal-overlay {
        display: flex;
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(15, 23, 42, 0.6);
        z-index: 1000;
        align-items: center;
        justify-content: center;
        backdrop-filter: blur(8px);
    }

    .modal-container {
        background: white;
        width: 90%;
        max-width: 550px;
        border-radius: 24px;
        padding: 0;
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
        animation: modalSlideUp 0.3s ease-out;
        overflow: hidden;
    }

    @keyframes modalSlideUp {
        from {
            opacity: 0;
            transform: translateY(20px);
        }

        to {
            opacity: 1;
            transform: translateY(0);
        }
    }

    .modal-header-danger {
        background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
        color: white;
        padding: 1.5rem 2rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .modal-body {
        padding: 2rem;
    }

    /* History Tab */
    .tabs-container {
        display: flex;
        gap: 0.5rem;
        margin-bottom: 1.5rem;
        border-bottom: 2px solid #e2e8f0;
        padding-bottom: 0;
    }

    .tab-btn {
        padding: 0.75rem 1.5rem;
        background: none;
        border: none;
        font-weight: 700;
        color: var(--text-secondary);
        cursor: pointer;
        position: relative;
        transition: all 0.2s;
    }

    .tab-btn.active {
        color: var(--primary-color);
    }

    .tab-btn.active::after {
        content: '';
        position: absolute;
        bottom: -2px;
        left: 0;
        right: 0;
        height: 3px;
        background: var(--primary-color);
        border-radius: 3px 3px 0 0;
    }

    .history-card {
        background: #f8fafc;
        border-radius: 12px;
        padding: 1rem;
        margin-bottom: 0.75rem;
        border-right: 4px solid #ef4444;
    }

    .history-card .title {
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.25rem;
    }

    .history-card .meta {
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    @media (max-width: 768px) {
        .stats-banner {
            grid-template-columns: repeat(2, 1fr);
        }
    }
</style>

<div class="container" x-data="alertsManager()">

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
        <div>
            <h1 style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary);">تنبيهات الغياب</h1>
            <p style="color: var(--text-secondary);">متابعة غيابات الطلاب وإرسال تنبيهات الحرمان والإنذارات.</p>
        </div>
    </div>

    <!-- Stats Banner -->
    <div class="stats-banner">
        <div class="stat-card">
            <div class="stat-icon">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#6b7280" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                    <circle cx="9" cy="7" r="4"></circle>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                </svg>
            </div>
            <div class="stat-value">{{ $stats['total'] }}</div>
            <div class="stat-label">إجمالي الحالات</div>
        </div>
        <div class="stat-card" style="border-color: #fecaca;">
            <div class="stat-icon">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                    <line x1="12" y1="9" x2="12" y2="13"></line>
                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                </svg>
            </div>
            <div class="stat-value" style="color: #ef4444;">{{ $stats['danger'] }}</div>
            <div class="stat-label">مهدد بالحرمان</div>
        </div>
        <div class="stat-card" style="border-color: #fde68a;">
            <div class="stat-icon">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="12" y1="8" x2="12" y2="12"></line>
                    <line x1="12" y1="16" x2="12.01" y2="16"></line>
                </svg>
            </div>
            <div class="stat-value" style="color: #f59e0b;">{{ $stats['warning'] }}</div>
            <div class="stat-label">إنذار أول</div>
        </div>
        <div class="stat-card" style="border-color: #bbf7d0;">
            <div class="stat-icon">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                    <polyline points="22 4 12 14.01 9 11.01"></polyline>
                </svg>
            </div>
            <div class="stat-value" style="color: #10b981;">{{ $stats['normal'] }}</div>
            <div class="stat-label">طبيعي</div>
        </div>
    </div>

    <!-- Tabs -->
    <div class="tabs-container">
        <button class="tab-btn" :class="{ 'active': activeTab === 'current' }" @click="activeTab = 'current'">
            الحالات الحالية
        </button>
        <button class="tab-btn" :class="{ 'active': activeTab === 'history' }" @click="activeTab = 'history'">
            سجل التنبيهات المُرسلة
        </button>
    </div>

    <!-- Current Cases Tab -->
    <div x-show="activeTab === 'current'">
        <!-- Filter Buttons -->
        <div class="filter-tabs">
            <a href="{{ route('delegate.notifications.index') }}" class="filter-tab {{ $filter == 'all' ? 'active' : '' }}">
                الكل
            </a>
            <a href="{{ route('delegate.notifications.index', ['filter' => 'danger']) }}" class="filter-tab {{ $filter == 'danger' ? 'active' : '' }}" style="{{ $filter == 'danger' ? '' : 'border-color: #fecaca; color: #ef4444;' }}">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                </svg>
                مهدد بالحرمان
            </a>
            <a href="{{ route('delegate.notifications.index', ['filter' => 'warning']) }}" class="filter-tab {{ $filter == 'warning' ? 'active' : '' }}" style="{{ $filter == 'warning' ? '' : 'border-color: #fde68a; color: #f59e0b;' }}">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="12" y1="8" x2="12" y2="12"></line>
                </svg>
                إنذار أول
            </a>
            <a href="{{ route('delegate.notifications.index', ['filter' => 'normal']) }}" class="filter-tab {{ $filter == 'normal' ? 'active' : '' }}" style="{{ $filter == 'normal' ? '' : 'border-color: #bbf7d0; color: #10b981;' }}">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                    <polyline points="22 4 12 14.01 9 11.01"></polyline>
                </svg>
                طبيعي
            </a>
        </div>

        @if(session('success'))
        <div class="alert alert-success d-flex align-items-center gap-2 mb-4" style="border-radius: 12px;">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="20 6 9 17 4 12"></polyline>
            </svg>
            {{ session('success') }}
        </div>
        @endif

        <div class="card" style="border-radius: 20px; overflow: hidden;">
            @if(count($report) == 0)
            <div style="text-align: center; padding: 4rem 2rem;">
                <div style="width: 80px; height: 80px; background: #f8fafc; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.5rem; color: #94a3b8;">
                    <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
                        <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
                    </svg>
                </div>
                <h3 style="font-size: 1.1rem; font-weight: 700; color: var(--text-primary);">لا توجد حالات غياب</h3>
                <p style="color: var(--text-secondary);">جميع الطلاب في حالة التزام جيد.</p>
            </div>
            @else
            <div class="table-container">
                <div class="table-responsive">
<table class="alerts-table">
                    <thead>
                        <tr>
                            <th>الطالب</th>
                            <th>المادة</th>
                            <th style="text-align: center;">الغيابات</th>
                            <th>الوضع</th>
                            <th style="text-align: center;">الإجراء</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($report as $item)
                        <tr>
                            <td>
                                <div class="student-info">
                                    <div class="student-avatar">
                                        {{ mb_substr($item['student']->name, 0, 1) }}
                                    </div>
                                    <div>
                                        <div style="font-weight: 700; color: var(--text-primary);">{{ $item['student']->name }}</div>
                                        <div style="font-size: 0.8rem; color: var(--text-secondary); font-family: monospace;">{{ $item['student']->student_number }}</div>
                                    </div>
                                </div>
                            </td>
                            <td>{{ $item['subject']->name }}</td>
                            <td style="text-align: center;">
                                <span style="font-weight: 800; font-size: 1.1rem; color: {{ $item['absences'] >= 5 ? '#ef4444' : ($item['absences'] >= 3 ? '#f59e0b' : '#10b981') }};">
                                    {{ $item['absences'] }}
                                </span>
                            </td>
                            <td>
                                @if($item['absences'] >= 5)
                                <span class="status-badge danger">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                                    </svg>
                                    مهدد بالحرمان
                                </span>
                                @elseif($item['absences'] >= 3)
                                <span class="status-badge warning">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <circle cx="12" cy="12" r="10"></circle>
                                        <line x1="12" y1="8" x2="12" y2="12"></line>
                                    </svg>
                                    إنذار أول
                                </span>
                                @else
                                <span class="status-badge normal">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                                        <polyline points="22 4 12 14.01 9 11.01"></polyline>
                                    </svg>
                                    طبيعي
                                </span>
                                @endif
                            </td>
                            <td style="text-align: center;">
                                <button type="button" class="send-btn"
                                    @click="openModal('{{ $item['student']->id }}', '{{ $item['student']->name }}', '{{ $item['subject']->id }}', '{{ $item['subject']->name }}', {{ $item['absences'] }})">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <line x1="22" y1="2" x2="11" y2="13"></line>
                                        <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                                    </svg>
                                    إرسال تنبيه
                                </button>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
</div>
            </div>
            @endif
        </div>
    </div>

    <!-- History Tab -->
    <div x-show="activeTab === 'history'" style="display: none;">
        <div class="card" style="border-radius: 20px; padding: 1.5rem;">
            @if(count($sentAlerts) == 0)
            <div style="text-align: center; padding: 3rem;">
                <div style="color: #94a3b8; margin-bottom: 1rem;">
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                        <path d="M22 12h-4l-3 9L9 3l-3 9H2"></path>
                    </svg>
                </div>
                <p style="color: var(--text-secondary);">لا توجد تنبيهات مُرسلة بعد.</p>
            </div>
            @else
            @foreach($sentAlerts as $alert)
            <div class="history-card">
                <div class="title">{{ $alert['title'] }}</div>
                <div class="meta">
                    <strong>{{ $alert['student_name'] }}</strong> •
                    {{ \Carbon\Carbon::parse($alert['created_at'])->diffForHumans() }}
                </div>
            </div>
            @endforeach
            @endif
        </div>
    </div>

    <!-- Send Alert Modal (Alpine.js) -->
    <div x-show="showModal" class="modal-overlay" style="display: none;" x-transition.opacity>
        <div class="modal-container" @click.away="showModal = false" x-transition.scale>
            <div class="modal-header-danger">
                <h4 style="margin: 0; font-weight: 800;">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display: inline; vertical-align: middle; margin-left: 0.5rem;">
                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                        <line x1="12" y1="9" x2="12" y2="13"></line>
                        <line x1="12" y1="17" x2="12.01" y2="17"></line>
                    </svg>
                    إرسال تنبيه غياب
                </h4>
                <button type="button" @click="showModal = false" style="background: rgba(255,255,255,0.2); border: none; width: 32px; height: 32px; border-radius: 50%; color: white; cursor: pointer;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </button>
            </div>
            <div class="modal-body">
                <form :action="'{{ route('delegate.notifications.store') }}'" method="POST">
                    @csrf
                    <input type="hidden" name="student_id" :value="formData.studentId">
                    <input type="hidden" name="subject_id" :value="formData.subjectId">

                    <div style="background: #fef2f2; border-radius: 12px; padding: 1rem; margin-bottom: 1.5rem; display: flex; align-items: center; gap: 1rem;">
                        <div style="width: 48px; height: 48px; background: #fee2e2; border-radius: 12px; display: flex; align-items: center; justify-content: center; color: #ef4444;">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                                <circle cx="12" cy="7" r="4"></circle>
                            </svg>
                        </div>
                        <div>
                            <div style="font-size: 0.85rem; color: var(--text-secondary);">سيتم إرسال التنبيه للطالب:</div>
                            <div style="font-weight: 800; font-size: 1.1rem; color: var(--text-primary);" x-text="formData.studentName"></div>
                        </div>
                    </div>

                    <div style="margin-bottom: 1.5rem;">
                        <label style="display: block; font-weight: 700; margin-bottom: 0.5rem; color: var(--text-primary);">نص الرسالة</label>
                        <textarea name="message" x-model="formData.message" class="form-control" rows="5" required style="border-radius: 12px; resize: none;"></textarea>
                        <div style="font-size: 0.8rem; color: var(--text-secondary); margin-top: 0.5rem;">يمكنك تعديل الرسالة المقترحة أعلاه.</div>
                    </div>

                    <div style="display: flex; gap: 1rem; justify-content: flex-end;">
                        <button type="button" @click="showModal = false" style="padding: 0.75rem 1.5rem; border-radius: 10px; border: 1px solid #e2e8f0; background: white; cursor: pointer;">إلغاء</button>
                        <button type="submit" style="padding: 0.75rem 1.5rem; border-radius: 10px; border: none; background: #ef4444; color: white; font-weight: 700; cursor: pointer; display: flex; align-items: center; gap: 0.5rem;">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <line x1="22" y1="2" x2="11" y2="13"></line>
                                <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                            </svg>
                            تأكيد الإرسال
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<script>
    function alertsManager() {
        return {
            activeTab: 'current',
            showModal: false,
            formData: {
                studentId: '',
                studentName: '',
                subjectId: '',
                subjectName: '',
                absences: 0,
                message: ''
            },
            openModal(studentId, studentName, subjectId, subjectName, absences) {
                this.formData.studentId = studentId;
                this.formData.studentName = studentName;
                this.formData.subjectId = subjectId;
                this.formData.subjectName = subjectName;
                this.formData.absences = absences;
                this.formData.message = `عزيزي الطالب ${studentName}،\nنود تنبيهك بأن عدد مرات غيابك في مادة (${subjectName}) قد وصل إلى ${absences} محاضرات.\nيرجى مراجعة المرشد الأكاديمي أو أستاذ المقرر لتجنب الحرمان من دخول الاختبار النهائي.`;
                this.showModal = true;
            }
        }
    }
</script>

@endsection