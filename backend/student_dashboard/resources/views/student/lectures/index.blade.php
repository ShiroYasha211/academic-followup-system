@extends('layouts.student')

@section('title', 'محاضرات ' . $subject->name)

@section('content')
<!-- Flatpickr CSS -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
<!-- Flatpickr JS -->
<script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>

<div class="container" style="max-width: 100%;">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
        <div>
            <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">
                محاضرات: {{ $subject->name }}
            </h1>
            <p style="color: var(--text-secondary);">
                تتبع محاضراتك وتقدمك الدراسي
            </p>
        </div>
        <div style="display: flex; align-items: center; gap: 1rem; background: white; padding: 1rem 1.5rem; border-radius: 16px; border: 1px solid #e2e8f0; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
            <div>
                <div style="font-size: 0.85rem; color: var(--text-secondary); margin-bottom: 0.25rem;">معدل الإنجاز</div>
                <div style="font-size: 0.85rem; color: var(--text-secondary);" id="stat-count">
                    تمت مذاكرة <span style="font-weight: 700; color: var(--text-primary);">{{ $studiedLectures }}</span> من {{ $totalLectures }}
                </div>
            </div>
            <div class="progress-ring-mini">
                <svg viewBox="0 0 36 36">
                    <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke="#f1f5f9" stroke-width="3" />
                    <path id="progress-ring-path" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke="var(--primary-color)" stroke-width="3" stroke-dasharray="{{ $progressPercentage }}, 100" stroke-linecap="round" style="transition: stroke-dasharray 1s ease-out;" />
                </svg>
                <div class="progress-value-mini" id="stat-percentage">
                    {{ $progressPercentage }}%
                </div>
            </div>
        </div>
    </div>

    <!-- Filters -->
    <div class="filters-container" style="margin-bottom: 2rem; display: flex; gap: 0.5rem; overflow-x: auto; padding-bottom: 0.5rem;">
        <button onclick="filterLectures('all')" class="btn filter-btn active" data-filter="all" style="border-radius: 20px; transition: all 0.2s;">
            الكل
        </button>
        <button onclick="filterLectures('studied')" class="btn filter-btn" data-filter="studied" style="border-radius: 20px; transition: all 0.2s;">
            تمت المذاكرة
        </button>
        <button onclick="filterLectures('not-studied')" class="btn filter-btn" data-filter="not-studied" style="border-radius: 20px; transition: all 0.2s;">
            غير مذاكرة
        </button>
        <button onclick="filterLectures('scheduled')" class="btn filter-btn" data-filter="scheduled" style="border-radius: 20px; transition: all 0.2s;">
            مجدولة
        </button>
    </div>

    @if($lectures->isEmpty())
    <div class="card" style="text-align: center; padding: 4rem 2rem;">
        <div style="color: var(--text-secondary); margin-bottom: 1rem;">
            <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" stroke-linecap="round" stroke-linejoin="round">
                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
            </svg>
        </div>
        <h3 style="font-size: 1.1rem; font-weight: 700; color: var(--text-primary);">لا توجد محاضرات مسجلة</h3>
        <p style="color: var(--text-secondary);">لم يتم تسجيل أي محاضرات لهذه المادة بعد.</p>
    </div>
    @else
    <div class="timeline">
        @foreach($lectures as $lecture)
        @php
        $isStudied = $lecture->statuses->isNotEmpty() && $lecture->statuses->first()->is_studied;
        $attendance = $attendances[$lecture->date->format('Y-m-d')] ?? null;
        $isScheduled = $scheduledLectures->has($lecture->id);
        $scheduleItem = $isScheduled ? $scheduledLectures->get($lecture->id) : null;
        @endphp
        <div class="timeline-item {{ $isStudied ? 'studied' : '' }} {{ $isScheduled ? 'scheduled' : '' }}" id="lecture-{{ $lecture->id }}">
            <div class="timeline-marker"></div>
            <div class="timeline-content card">
                <div style="display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: 1rem;">
                    <div>
                        <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem; flex-wrap: wrap;">
                            <span style="font-size: 0.85rem; color: var(--text-secondary); background: #f1f5f9; padding: 2px 8px; border-radius: 4px;">{{ $lecture->date->format('Y-m-d') }}</span>
                            @if($lecture->lecture_number)
                            <span style="font-size: 0.85rem; color: var(--primary-color); background: rgba(37, 99, 235, 0.1); padding: 2px 8px; border-radius: 4px; font-weight: 600;">#{{ $lecture->lecture_number }}</span>
                            @endif

                            <!-- Scheduled Badge -->
                            @if($isScheduled)
                            <span class="badge-scheduled">
                                <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                                    <line x1="16" y1="2" x2="16" y2="6"></line>
                                    <line x1="8" y1="2" x2="8" y2="6"></line>
                                    <line x1="3" y1="10" x2="21" y2="10"></line>
                                </svg>
                                في الجدول
                            </span>
                            @endif

                            <!-- Attendance Status -->
                            @if($attendance)
                            @if($attendance->status == 'present')
                            <span style="background-color: #dcfce7; color: #166534; padding: 2px 8px; border-radius: 4px; font-size: 0.8rem; display: flex; align-items: center; gap: 4px;">
                                <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <polyline points="20 6 9 17 4 12"></polyline>
                                </svg>
                                حاضر
                            </span>
                            @elseif($attendance->status == 'absent')
                            <span style="background-color: #fee2e2; color: #991b1b; padding: 2px 8px; border-radius: 4px; font-size: 0.8rem; display: flex; align-items: center; gap: 4px;">
                                <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <circle cx="12" cy="12" r="10"></circle>
                                    <line x1="15" y1="9" x2="9" y2="15"></line>
                                    <line x1="9" y1="9" x2="15" y2="15"></line>
                                </svg>
                                غائب
                            </span>
                            @elseif($attendance->status == 'late')
                            <span style="background-color: #fef9c3; color: #854d0e; padding: 2px 8px; border-radius: 4px; font-size: 0.8rem; display: flex; align-items: center; gap: 4px;">
                                <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <circle cx="12" cy="12" r="10"></circle>
                                    <polyline points="12 6 12 12 16 14"></polyline>
                                </svg>
                                متأخر
                            </span>
                            @endif
                            @else
                            <span style="background-color: #f3f4f6; color: #6b7280; padding: 2px 8px; border-radius: 4px; font-size: 0.8rem;">
                                لم يرصد
                            </span>
                            @endif
                        </div>
                        <h3 style="font-size: 1.1rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">
                            {{ $lecture->title }}
                        </h3>
                        @if($lecture->description)
                        <p style="color: var(--text-secondary); font-size: 0.95rem; line-height: 1.5;">
                            {{ $lecture->description }}
                        </p>
                        @endif
                    </div>

                    <div class="actions" style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
                        <button type="button"
                            @if($isScheduled)
                            onclick='openEditModal(@json($scheduleItem))'
                            @else
                            onclick="openAddModal({{ $lecture->id }}, '{{ addslashes($lecture->title) }}')"
                            @endif
                            class="btn {{ $isScheduled ? 'btn-primary' : 'btn-outline-primary' }}"
                            style="display: flex; align-items: center; justify-content: center; gap: 0.5rem;"
                            title="{{ $isScheduled ? 'تعديل الجدولة' : 'إضافة لجدولي' }}">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                                <line x1="16" y1="2" x2="16" y2="6"></line>
                                <line x1="8" y1="2" x2="8" y2="6"></line>
                                <line x1="3" y1="10" x2="21" y2="10"></line>
                                <line x1="12" y1="15" x2="12" y2="15"></line>
                            </svg>
                            <span class="d-none d-md-inline">{{ $isScheduled ? 'مجدول' : 'جدولي' }}</span>
                        </button>

                        <button type="button"
                            onclick="toggleStatus({{ $lecture->id }}, this)"
                            class="btn btn-status {{ $isStudied ? 'btn-success' : 'btn-outline-secondary' }}"
                            style="min-width: 140px; display: flex; align-items: center; justify-content: center; gap: 0.5rem;">
                            @if($isStudied)
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <polyline points="20 6 9 17 4 12"></polyline>
                            </svg>
                            <span>تمت المذاكرة</span>
                            @else
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="10"></circle>
                            </svg>
                            <span>غير مذاكرة</span>
                            @endif
                        </button>
                    </div>
                </div>
            </div>
        </div>
        @endforeach
    </div>
    @endif
</div>

<!-- ═══════════ Add/Edit Modal (Smart Study Hub Style) ═══════════ -->
<div id="taskModal" class="modal-overlay" style="display: none;">
    <div class="modal-container">
        <div class="modal-header">
            <h3 class="modal-title" id="modalTitle">إضافة محاضرة للجدول</h3>
            <button type="button" class="close-btn" onclick="closeModal()">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>
        </div>
        <div class="modal-body">
            <input type="hidden" id="modal_item_id">
            <input type="hidden" id="modal_ref_type" value="App\Models\Academic\Lecture">
            <input type="hidden" id="modal_ref_id">

            <!-- Title -->
            <div class="form-group">
                <label class="form-label">العنوان <span style="color: #ef4444;">*</span></label>
                <input type="text" id="modal_title" class="form-input" placeholder="اسم المحاضرة">
            </div>

            <!-- Type Selection -->
            <div class="form-group">
                <label class="form-label">النوع</label>
                <div style="display: flex; gap: 0.5rem;">
                    <label class="type-option active" data-type="study">
                        <input type="radio" name="modal_type" value="study" checked style="display: none;">
                        📅 مذاكرة
                    </label>
                    <label class="type-option" data-type="reminder">
                        <input type="radio" name="modal_type" value="reminder" style="display: none;">
                        🔔 تنبيه
                    </label>
                </div>
            </div>

            <!-- Priority -->
            <div class="form-group">
                <label class="form-label">الأولوية</label>
                <div style="display: flex; gap: 0.5rem;">
                    <label class="priority-option" data-priority="low" style="--priority-color: #10b981;">
                        <input type="radio" name="modal_priority" value="low" style="display: none;">
                        🟢 عادي
                    </label>
                    <label class="priority-option active" data-priority="medium" style="--priority-color: #f59e0b;">
                        <input type="radio" name="modal_priority" value="medium" checked style="display: none;">
                        🟡 مهم
                    </label>
                    <label class="priority-option" data-priority="high" style="--priority-color: #ef4444;">
                        <input type="radio" name="modal_priority" value="high" style="display: none;">
                        🔴 عاجل
                    </label>
                </div>
            </div>

            <!-- Date -->
            <div class="form-group">
                <label class="form-label">التاريخ (اختياري)</label>
                <input type="text" id="modal_date" class="form-input" placeholder="اختر التاريخ...">
            </div>

            <!-- Reminder Time (for reminders) -->
            <div class="form-group" id="reminder_section" style="display: none;">
                <label class="form-label">وقت التنبيه</label>
                <input type="text" id="modal_reminder_at" class="form-input" placeholder="اختر وقت التنبيه...">
            </div>

            <!-- Repeat -->
            <div class="form-group">
                <label class="form-label">التكرار</label>
                <select id="modal_repeat" class="form-input">
                    <option value="none" selected>بدون تكرار</option>
                    <option value="daily">يومي</option>
                    <option value="weekly">أسبوعي</option>
                </select>
            </div>

            <!-- Note -->
            <div class="form-group">
                <label class="form-label">ملاحظة (اختياري)</label>
                <textarea id="modal_note" class="form-input" rows="2" placeholder="أضف ملاحظة..."></textarea>
            </div>
        </div>
        <div class="modal-footer">
            <button type="button" class="btn-cancel" onclick="closeModal()">إلغاء</button>
            <button type="button" class="btn-submit" onclick="submitTask()">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
                حفظ
            </button>
        </div>
    </div>
</div>

<div id="lectures-data" data-total="{{ $totalLectures }}" data-studied="{{ $studiedLectures }}" style="display: none;"></div>

<style>
    /* ... existing styles ... */
    .progress-ring-mini {
        width: 60px;
        height: 60px;
        position: relative;
    }

    .progress-ring-mini svg {
        width: 100%;
        height: 100%;
        transform: rotate(-90deg);
    }

    .progress-value-mini {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        font-size: 0.9rem;
        font-weight: 800;
        color: var(--primary-color);
    }

    .timeline {
        position: relative;
        padding-left: 0;
        padding-right: 2rem;
    }

    .timeline::before {
        content: '';
        position: absolute;
        top: 0;
        right: 0;
        height: 100%;
        width: 2px;
        background: var(--border-color);
    }

    .timeline-item {
        position: relative;
        margin-bottom: 2rem;
        transition: all 0.3s ease;
    }

    .timeline-marker {
        position: absolute;
        top: 1.5rem;
        right: -2rem;
        transform: translateX(50%);
        width: 16px;
        height: 16px;
        border-radius: 50%;
        background: white;
        border: 3px solid var(--text-secondary);
        z-index: 1;
        transition: all 0.3s ease;
    }

    .timeline-item.studied .timeline-marker {
        border-color: var(--success-color);
        background: var(--success-color);
    }

    .timeline-item.scheduled .timeline-marker {
        border-color: var(--primary-color);
    }

    .timeline-content {
        transition: all 0.3s ease;
    }

    .timeline-item.studied .timeline-content {
        border-left: 4px solid var(--success-color);
    }

    .timeline-item.scheduled .timeline-content {
        border-right: 4px solid var(--primary-color);
    }

    .btn-status.btn-success {
        background-color: var(--success-color);
        color: white;
        border: none;
    }

    .btn-status.btn-outline-secondary {
        background-color: transparent;
        border: 1px solid var(--text-secondary);
        color: var(--text-secondary);
    }

    .btn-status.btn-outline-secondary:hover {
        background-color: #f1f5f9;
        color: var(--text-primary);
    }

    /* Filter styles */
    .filter-btn {
        background: white;
        border: 1px solid var(--border-color);
        color: var(--text-secondary);
        padding: 0.5rem 1.5rem;
    }

    .filter-btn.active {
        background: var(--primary-color);
        color: white;
        border-color: var(--primary-color);
    }

    .badge-scheduled {
        background-color: #dbeafe;
        color: #1e40af;
        padding: 2px 8px;
        border-radius: 4px;
        font-size: 0.8rem;
        display: flex;
        align-items: center;
        gap: 4px;
    }

    /* Modal Styles (Smart Hub) */
    .modal-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
        backdrop-filter: blur(4px);
    }

    .modal-container {
        background: white;
        border-radius: 16px;
        width: 100%;
        max-width: 500px;
        padding: 2rem;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
        margin: 1rem;
        max-height: 90vh;
        overflow-y: auto;
    }

    .modal-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 2rem;
    }

    .modal-title {
        font-size: 1.5rem;
        font-weight: 800;
        color: var(--text-primary);
        margin: 0;
    }

    .close-btn {
        background: none;
        border: none;
        color: var(--text-secondary);
        cursor: pointer;
        padding: 0;
    }

    .form-group {
        margin-bottom: 1.5rem;
    }

    .form-label {
        display: block;
        margin-bottom: 0.5rem;
        font-weight: 600;
        color: var(--text-primary);
    }

    .form-input {
        width: 100%;
        padding: 0.75rem 1rem;
        border: 2px solid #f1f5f9;
        border-radius: 10px;
        font-family: inherit;
        transition: all 0.2s;
    }

    .form-input:focus {
        border-color: var(--primary-color);
        outline: none;
        box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
    }

    .type-option,
    .priority-option {
        flex: 1;
        padding: 0.75rem;
        border: 2px solid #f1f5f9;
        border-radius: 10px;
        text-align: center;
        cursor: pointer;
        font-weight: 600;
        color: var(--text-secondary);
        transition: all 0.2s;
    }

    .type-option:hover,
    .priority-option:hover {
        background: #f8fafc;
    }

    .type-option.active {
        border-color: var(--primary-color);
        background: rgba(37, 99, 235, 0.05);
        color: var(--primary-color);
    }

    .priority-option.active {
        border-color: var(--priority-color);
        background: color-mix(in srgb, var(--priority-color) 10%, white);
        color: var(--priority-color);
    }

    .modal-footer {
        display: flex;
        gap: 1rem;
        margin-top: 2rem;
    }

    .btn-submit {
        flex: 1;
        background: linear-gradient(135deg, var(--primary-color), #7c3aed);
        color: white;
        border: none;
        padding: 0.75rem;
        border-radius: 12px;
        font-weight: 700;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        transition: all 0.3s;
    }

    .btn-submit:hover {
        opacity: 0.9;
        transform: translateY(-1px);
    }

    .btn-cancel {
        padding: 0.75rem 1.5rem;
        background: #f1f5f9;
        color: var(--text-secondary);
        border: none;
        border-radius: 12px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.2s;
    }

    .btn-cancel:hover {
        background: #e2e8f0;
        color: var(--text-primary);
    }
</style>

<script>
    // Initialize stats from data attributes
    const dataElement = document.getElementById('lectures-data');
    let totalLectures = parseInt(dataElement.getAttribute('data-total')) || 0;
    let studiedLectures = parseInt(dataElement.getAttribute('data-studied')) || 0;
    let datePicker = null;
    let reminderPicker = null;

    document.addEventListener('DOMContentLoaded', function() {
        // Init Date Picker
        datePicker = flatpickr("#modal_date", {
            dateFormat: "Y-m-d",
            minDate: "today",
            direction: "rtl",
            locale: {
                firstDayOfWeek: 6 // Saturday start
            }
        });

        // Init Time Picker for Reminder
        reminderPicker = flatpickr("#modal_reminder_at", {
            enableTime: true,
            dateFormat: "Y-m-d H:i",
            minDate: "today",
            time_24hr: false,
            direction: "rtl"
        });

        // Handle Type Selection
        document.querySelectorAll('.type-option').forEach(option => {
            option.addEventListener('click', function() {
                // Update active state
                document.querySelectorAll('.type-option').forEach(opt => opt.classList.remove('active'));
                this.classList.add('active');
                this.querySelector('input').checked = true;

                // Show/Hide fields based on type
                const type = this.dataset.type;
                const reminderSection = document.getElementById('reminder_section');
                if (type === 'reminder') {
                    reminderSection.style.display = 'block';
                } else {
                    reminderSection.style.display = 'none';
                    document.getElementById('modal_reminder_at').value = '';
                }
            });
        });

        // Handle Priority Selection
        document.querySelectorAll('.priority-option').forEach(option => {
            option.addEventListener('click', function() {
                document.querySelectorAll('.priority-option').forEach(opt => opt.classList.remove('active'));
                this.classList.add('active');
                this.querySelector('input').checked = true;
            });
        });
    });

    function updateStats() {
        const percentage = totalLectures > 0 ? Math.round((studiedLectures / totalLectures) * 100) : 0;
        const statPercentage = document.getElementById('stat-percentage');
        const statCount = document.getElementById('stat-count');
        const progressRingPath = document.getElementById('progress-ring-path');

        if (statPercentage) statPercentage.textContent = percentage + '%';
        if (statCount) statCount.innerHTML = `تمت مذاكرة <span style="font-weight: 700; color: var(--text-primary);">${studiedLectures}</span> من ${totalLectures}`;
        if (progressRingPath) progressRingPath.style.strokeDasharray = `${percentage}, 100`;
    }

    function filterLectures(filter) {
        const items = document.querySelectorAll('.timeline-item');
        items.forEach(item => {
            if (filter === 'all') {
                item.style.display = 'block';
            } else if (filter === 'studied') {
                item.style.display = item.classList.contains('studied') ? 'block' : 'none';
            } else if (filter === 'not-studied') {
                item.style.display = !item.classList.contains('studied') ? 'block' : 'none';
            } else if (filter === 'scheduled') {
                item.style.display = item.classList.contains('scheduled') ? 'block' : 'none';
            }
        });

        // Update active button
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.classList.toggle('active', btn.getAttribute('data-filter') === filter);
        });
    }

    function toggleStatus(lectureId, btn) {
        if (!confirm('هل تريد تغيير حالة مذاكرة هذه المحاضرة؟')) return;

        // Visual feedback
        const originalHtml = btn.innerHTML;
        const originalClass = btn.className;
        btn.disabled = true;
        btn.style.opacity = '0.7';

        fetch(`/student/lectures/toggle/${lectureId}`, {
                method: 'POST',
                headers: {
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    const timelineItem = document.getElementById(`lecture-${lectureId}`);

                    if (data.is_studied) {
                        // Changed to Studied
                        if (timelineItem) {
                            timelineItem.classList.add('studied');
                        }
                        btn.className = 'btn btn-status btn-success';
                        btn.innerHTML = `
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
                        <span>تمت المذاكرة</span>
                        `;
                        studiedLectures++;
                    } else {
                        // Changed to Not Studied
                        if (timelineItem) {
                            timelineItem.classList.remove('studied');
                        }
                        btn.className = 'btn btn-status btn-outline-secondary';
                        btn.innerHTML = `
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle></svg>
                        <span>غير مذاكرة</span>
                        `;
                        studiedLectures--;
                    }
                    updateStats();
                } else {
                    alert('حدث خطأ غير متوقع');
                    // Revert button state
                    btn.innerHTML = originalHtml;
                    btn.className = originalClass;
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('حدث خطأ أثناء الاتصال بالخادم');
                // Revert button state
                btn.innerHTML = originalHtml;
                btn.className = originalClass;
            })
            .finally(() => {
                btn.disabled = false;
                btn.style.opacity = '1';
            });
    }

    // Modal Functions
    function openAddModal(lectureId, title) {
        document.getElementById('modalTitle').textContent = 'إضافة محاضرة للجدول';
        document.getElementById('modal_item_id').value = ''; // Empty for new
        document.getElementById('modal_ref_id').value = lectureId;
        document.getElementById('modal_title').value = title;

        // Reset fields
        document.getElementById('modal_date').value = '';
        document.getElementById('modal_reminder_at').value = '';
        document.getElementById('modal_note').value = '';
        document.getElementById('modal_repeat').value = 'none';

        // Set default type to 'study'
        document.querySelector('.type-option[data-type="study"]').click();

        // Reset priority to medium
        document.querySelector('.priority-option[data-priority="medium"]').click();

        document.getElementById('taskModal').style.display = 'flex';
    }

    function openEditModal(item) {
        if (!item) return;

        document.getElementById('modalTitle').textContent = 'تعديل الجدولة';
        document.getElementById('modal_item_id').value = item.id;
        document.getElementById('modal_ref_id').value = item.referenceable_id; // Keep ref ID
        document.getElementById('modal_title').value = item.title || '';

        // Fill fields
        if (item.scheduled_date) {
            datePicker.setDate(item.scheduled_date);
        } else {
            datePicker.clear();
        }

        if (item.reminder_at) {
            reminderPicker.setDate(item.reminder_at);
        } else {
            reminderPicker.clear();
        }

        document.getElementById('modal_note').value = item.note || '';
        document.getElementById('modal_repeat').value = item.repeat_type || 'none';

        // Set type
        const type = item.item_type || 'study';
        const typeOption = document.querySelector(`.type-option[data-type="${type}"]`);
        if (typeOption) typeOption.click();

        // Set priority
        const priority = item.priority || 'medium';
        const priorityOption = document.querySelector(`.priority-option[data-priority="${priority}"]`);
        if (priorityOption) priorityOption.click();

        document.getElementById('taskModal').style.display = 'flex';
    }

    function closeModal() {
        document.getElementById('taskModal').style.display = 'none';
    }

    function submitTask() {
        const itemId = document.getElementById('modal_item_id').value;
        const refType = document.getElementById('modal_ref_type').value;
        const refId = document.getElementById('modal_ref_id').value;
        const title = document.getElementById('modal_title').value;

        if (!title) {
            alert('يرجى إدخال العنوان');
            return;
        }

        const body = {
            referenceable_type: refType,
            referenceable_id: refId,
            title: title,
            item_type: document.querySelector('input[name="modal_type"]:checked').value,
            priority: document.querySelector('input[name="modal_priority"]:checked').value,
            scheduled_date: document.getElementById('modal_date').value,
            reminder_at: document.getElementById('modal_reminder_at').value,
            repeat_type: document.getElementById('modal_repeat').value,
            note: document.getElementById('modal_note').value,
        };

        // If editing, use UPDATE method
        let url = '{{ route("student.schedule.store") }}';
        let method = 'POST';

        if (itemId) {
            url = `/student/schedule/${itemId}`;
            method = 'PUT';
            body.id = itemId; // Just in case
        } else {
            // New Custom Task (or linked lecture) - utilizing store method
            // The store method in controller should handle the fields
        }

        fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'Accept': 'application/json'
                },
                body: JSON.stringify(body)
            })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    alert(data.message);
                    closeModal();
                    // Reload to update status and button
                    location.reload();
                } else {
                    alert(data.message || 'حدث خطأ ما');
                }
            })
            .catch(err => {
                console.error(err);
                alert('حدث خطأ أثناء الاتصال بالخادم');
            });
    }
</script>
@endsection