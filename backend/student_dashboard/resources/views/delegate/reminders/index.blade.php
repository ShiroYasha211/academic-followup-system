@extends('layouts.delegate')

@section('title', 'جدولة التذكيرات')

@section('content')

<style>
    /* Styling for Reminders Page */
    .reminders-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
        gap: 1.5rem;
    }

    .reminder-card {
        background: white;
        border-radius: 20px;
        padding: 1.5rem;
        border: 1px solid var(--border-color);
        box-shadow: var(--shadow-sm);
        transition: transform 0.2s;
        position: relative;
        overflow: hidden;
    }

    .reminder-card:hover {
        transform: translateY(-4px);
        box-shadow: var(--shadow-md);
    }

    /* Status Indicator */
    .reminder-card::after {
        content: '';
        position: absolute;
        left: 0;
        top: 0;
        bottom: 0;
        width: 6px;
        background: var(--border-color);
    }

    .reminder-card.status-pending::after {
        background: var(--warning-color);
    }

    .reminder-card.status-scheduled::after {
        background: var(--info-color);
    }

    .reminder-card.status-sent::after {
        background: var(--success-color);
    }

    .reminder-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 1rem;
    }

    .time-badge {
        display: flex;
        flex-direction: column;
        align-items: center;
        background: #f8fafc;
        padding: 0.5rem 0.75rem;
        border-radius: 12px;
        border: 1px solid var(--border-color);
        min-width: 60px;
    }

    .time-badge .month {
        font-size: 0.75rem;
        text-transform: uppercase;
        color: var(--text-secondary);
        font-weight: 700;
    }

    .time-badge .day {
        font-size: 1.25rem;
        font-weight: 800;
        color: var(--text-primary);
        line-height: 1;
        margin: 0.2rem 0;
    }

    .reminder-title {
        font-size: 1.1rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.5rem;
    }

    .reminder-desc {
        font-size: 0.9rem;
        color: var(--text-secondary);
        line-height: 1.6;
        margin-bottom: 1.5rem;
    }

    .meta-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding-top: 1rem;
        border-top: 1px dashed var(--border-color);
        font-size: 0.85rem;
    }

    .notify-time {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        color: var(--info-color);
        font-weight: 600;
        background: rgba(59, 130, 246, 0.08);
        padding: 0.25rem 0.75rem;
        border-radius: 99px;
    }

    .action-btn {
        background: none;
        border: none;
        cursor: pointer;
        padding: 0.4rem;
        border-radius: 8px;
        color: var(--text-secondary);
        transition: all 0.2s;
    }

    .action-btn:hover {
        background: #f1f5f9;
        color: var(--primary-color);
    }

    .action-btn.delete:hover {
        background: #fef2f2;
        color: var(--danger-color);
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

    /* Stats Banner */
    .stats-banner {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
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
        box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
    }

    .stat-icon {
        width: 48px;
        height: 48px;
        border-radius: 50%;
        background: #f8fafc;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 1rem;
    }

    .stat-value {
        font-size: 1.75rem;
        font-weight: 800;
        margin-bottom: 0.25rem;
    }

    .stat-label {
        font-size: 0.9rem;
        color: var(--text-secondary);
        font-weight: 600;
    }

    /* Filter Tabs */
    .filter-tabs {
        display: flex;
        gap: 0.5rem;
        margin-bottom: 2rem;
        padding-bottom: 1rem;
        border-bottom: 1px solid #e2e8f0;
        overflow-x: auto;
    }

    .filter-tab {
        padding: 0.5rem 1.25rem;
        border-radius: 99px;
        font-size: 0.95rem;
        font-weight: 600;
        color: var(--text-secondary);
        background: white;
        border: 1px solid #e2e8f0;
        cursor: pointer;
        transition: all 0.2s;
        text-decoration: none;
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

    .modal-container {
        background: white;
        width: 90%;
        max-width: 550px;
        border-radius: 24px;
        padding: 2.5rem;
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
    }
</style>

<div class="container" x-data="reminderManager()">

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
        <div>
            <h1 style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary);">جدولة التذكيرات</h1>
            <p style="color: var(--text-secondary);">جدولة تنبيهات تلقائية للطلاب حول الأحداث الهامة.</p>
        </div>
        <button @click="openCreateModal()" class="btn btn-primary" style="padding: 0.8rem 1.5rem; border-radius: 12px; display: flex; align-items: center; gap: 0.5rem; font-weight: 700; box-shadow: 0 4px 12px rgba(67, 56, 202, 0.2);">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
            جدولة تنبيه
        </button>
    </div>

    <!-- Stats Banner -->
    <div class="stats-banner">
        <div class="stat-card">
            <div class="stat-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                    <line x1="16" y1="2" x2="16" y2="6"></line>
                    <line x1="8" y1="2" x2="8" y2="6"></line>
                    <line x1="3" y1="10" x2="21" y2="10"></line>
                </svg>
            </div>
            <div class="stat-value" style="color: var(--text-primary);">{{ $stats['total'] }}</div>
            <div class="stat-label">إجمالي التذكيرات</div>
        </div>
        <div class="stat-card" style="border-color: #bfdbfe;">
            <div class="stat-icon" style="color: #3b82f6;">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"></circle>
                    <polyline points="12 6 12 12 16 14"></polyline>
                </svg>
            </div>
            <div class="stat-value" style="color: #3b82f6;">{{ $stats['upcoming'] }}</div>
            <div class="stat-label">تذكيرات قادمة</div>
        </div>
        <div class="stat-card" style="border-color: #fde68a;">
            <div class="stat-icon" style="color: #f59e0b;">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                    <polyline points="22 4 12 14.01 9 11.01"></polyline>
                </svg>
            </div>
            <div class="stat-value" style="color: #f59e0b;">{{ $stats['past'] }}</div>
            <div class="stat-label">تذكيرات مرسلة</div>
        </div>
    </div>

    <!-- Filter Tabs -->
    <div class="filter-tabs">
        <a href="{{ route('delegate.reminders.index', ['filter' => 'upcoming']) }}" class="filter-tab {{ $filter == 'upcoming' ? 'active' : '' }}">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
            تذكيرات قادمة النشطة
        </a>
        <a href="{{ route('delegate.reminders.index', ['filter' => 'past']) }}" class="filter-tab {{ $filter == 'past' ? 'active' : '' }}">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
            التذكيرات السابقة (التي أرسلت)
        </a>
        <a href="{{ route('delegate.reminders.index', ['filter' => 'all']) }}" class="filter-tab {{ $filter == 'all' ? 'active' : '' }}">
            الكل
        </a>
    </div>

    @if(session('success'))
    <div class="alert alert-success d-flex align-items-center gap-2 mb-4" style="border-radius: 12px;">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
        {{ session('success') }}
    </div>
    @endif

    <div class="reminders-grid">
        @forelse($reminders as $reminder)
        @php
        $isSent = \Carbon\Carbon::parse($reminder->notify_at)->isPast();
        $statusClass = $isSent ? 'status-sent' : 'status-scheduled';
        @endphp
        <div class="reminder-card {{ $statusClass }}">
            <div class="reminder-header">
                <div>
                    <h3 class="reminder-title">{{ $reminder->title }}</h3>
                    <div style="font-size: 0.85rem; color: var(--text-light); display: flex; align-items: center; gap: 0.4rem;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                            <line x1="16" y1="2" x2="16" y2="6"></line>
                            <line x1="8" y1="2" x2="8" y2="6"></line>
                            <line x1="3" y1="10" x2="21" y2="10"></line>
                        </svg>
                        موعد الحدث: {{ $reminder->event_date->format('Y-m-d h:i A') }}
                    </div>
                </div>

                <div class="time-badge">
                    <span class="month">{{ $reminder->notify_at->format('M') }}</span>
                    <span class="day">{{ $reminder->notify_at->format('d') }}</span>
                </div>
            </div>

            <p class="reminder-desc">{{ $reminder->description }}</p>

            <div class="meta-row">
                <div class="notify-time" title="وقت الإرسال للطلاب">
                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
                        <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
                    </svg>
                    {{ $isSent ? 'تم الإرسال' : 'يُرسل: ' . $reminder->notify_at->diffForHumans() }}
                </div>

                <div style="display: flex; gap: 0.5rem;">
                    <button class="action-btn" @click="openEditModal({{ json_encode($reminder) }})" title="تعديل">
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                        </svg>
                    </button>

                    <form action="{{ route('delegate.reminders.destroy', $reminder->id) }}" method="POST" onsubmit="return confirm('حذف هذا التذكير؟')" style="margin: 0;">
                        @csrf
                        @method('DELETE')
                        <button type="submit" class="action-btn delete" title="حذف">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <polyline points="3 6 5 6 21 6"></polyline>
                                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                            </svg>
                        </button>
                    </form>
                </div>
            </div>
        </div>
        @empty
        <div class="col-12" style="grid-column: 1 / -1;">
            <div style="text-align: center; padding: 4rem; background: white; border-radius: 20px; border: 2px dashed var(--border-color);">
                <div style="width: 80px; height: 80px; background: #f8fafc; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.5rem; color: #cbd5e1;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"></circle>
                        <polyline points="12 6 12 12 16 14"></polyline>
                    </svg>
                </div>
                <h3 style="font-weight: 800; color: var(--text-primary); margin-bottom: 0.5rem;">لا توجد تذكيرات مجدولة</h3>
                <p style="color: var(--text-secondary);">قم بجدولة التنبيهات للاختبارات والمواعيد الهامة ليتم تذكير الطلاب بها تلقائياً.</p>
            </div>
        </div>
        @endforelse
    </div>

    @if($reminders->hasPages())
    <div class="mt-4">
        {{ $reminders->links() }}
    </div>
    @endif

    <!-- Create/Edit Modal -->
    <div x-show="showModal" class="modal-overlay" style="display: none;" x-transition.opacity>
        <div class="modal-container" @click.away="showModal = false" x-transition.scale>
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
                <h3 class="font-weight-800" style="margin: 0; font-size: 1.5rem;" x-text="modalTitle"></h3>
                <button type="button" @click="showModal = false" style="background: #f1f5f9; border: none; width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; cursor: pointer; color: var(--text-secondary);">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </button>
            </div>

            <form :action="formAction" method="POST">
                @csrf
                <input type="hidden" name="_method" :value="formMethod">

                <div class="row g-4" style="text-align: right;">
                    <div class="col-12">
                        <label class="form-label text-secondary small">عنوان التنبيه</label>
                        <input type="text" name="title" x-model="formData.title" class="form-control form-control-lg fw-bold" required placeholder="مثال: موعد اختبار الرياضيات النصفي">
                    </div>

                    <div class="col-md-6">
                        <label class="form-label text-secondary small">موعد الحدث (الاختبار/التكليف)</label>
                        <input type="datetime-local" name="event_date" x-model="formData.event_date" class="form-control" required style="direction: ltr;">
                    </div>

                    <div class="col-md-6">
                        <label class="form-label text-secondary small">وقت إرسال التنبيه للطلاب</label>
                        <input type="datetime-local" name="notify_at" x-model="formData.notify_at" class="form-control" required style="direction: ltr;">
                        <div class="form-text text-muted" style="font-size: 0.75rem;">متى تريد أن يظهر هذا التنبيه في جوالات الطلاب؟</div>
                    </div>

                    <div class="col-12">
                        <label class="form-label text-secondary small">تفاصيل إضافية (اختياري)</label>
                        <textarea name="description" x-model="formData.description" class="form-control" rows="3" placeholder="ملاحظات إضافية..."></textarea>
                    </div>
                </div>

                <div style="display: flex; gap: 1rem; justify-content: flex-end; margin-top: 2.5rem; padding-top: 1.5rem; border-top: 1px dashed var(--border-color);">
                    <button type="button" class="btn btn-secondary px-4" @click="showModal = false" style="background: white; border: 1px solid var(--border-color);">إلغاء</button>
                    <button type="submit" class="btn btn-primary px-5 py-2.5" style="border-radius: 10px; font-weight: 700;">جدولة التنبيه</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
    function reminderManager() {
        return {
            showModal: false,
            modalTitle: 'جدولة تنبيه جديد',
            formAction: "{{ route('delegate.reminders.store') }}",
            formMethod: 'POST',
            formData: {
                title: '',
                description: '',
                event_date: '',
                notify_at: ''
            },
            openCreateModal() {
                this.modalTitle = 'جدولة تنبيه جديد';
                this.formAction = "{{ route('delegate.reminders.store') }}";
                this.formMethod = 'POST';
                this.formData = {
                    title: '',
                    description: '',
                    event_date: '',
                    notify_at: ''
                };
                this.showModal = true;
            },
            openEditModal(reminder) {
                this.modalTitle = 'تعديل التنبيه';
                this.formAction = `/delegate/reminders/${reminder.id}`;
                this.formMethod = 'PUT';

                // Helper to format Date for input
                const formatDate = (dateString) => {
                    const date = new Date(dateString);
                    // Adjust to local ISO string roughly or use a library, here simple slicing for demo
                    // A robust solution usually involves dealing with timezones explicitly
                    // For now, let's assume server returns ISO8601
                    return date.toISOString().slice(0, 16);
                };

                this.formData = {
                    title: reminder.title,
                    description: reminder.description,
                    event_date: formatDate(reminder.event_date),
                    notify_at: formatDate(reminder.notify_at)
                };
                this.showModal = true;
            }
        }
    }
</script>

@endsection