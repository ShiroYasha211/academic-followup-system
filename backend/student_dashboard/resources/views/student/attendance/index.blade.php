@extends('layouts.student')

@section('title', 'سجل الحضور')

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
        grid-template-columns: repeat(4, 1fr);
        gap: 1.5rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: white;
        border-radius: 20px;
        padding: 1.5rem;
        display: flex;
        align-items: center;
        gap: 1.25rem;
        border: 1px solid #e2e8f0;
        transition: all 0.3s ease;
    }

    .stat-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 12px 24px -8px rgba(0, 0, 0, 0.1);
    }

    .stat-icon {
        width: 56px;
        height: 56px;
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .stat-value {
        font-size: 1.75rem;
        font-weight: 800;
        line-height: 1;
        margin-bottom: 0.25rem;
    }

    .stat-label {
        color: var(--text-secondary);
        font-size: 0.9rem;
    }

    /* Content Card */
    .content-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
    }

    .content-header {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid #f1f5f9;
        font-weight: 700;
        display: flex;
        align-items: center;
        gap: 0.75rem;
        font-size: 1.1rem;
    }

    /* Accordion */
    .subject-accordion {
        border-bottom: 1px solid #f1f5f9;
    }

    .subject-accordion:last-child {
        border-bottom: none;
    }

    .accordion-header {
        width: 100%;
        padding: 1.25rem 1.5rem;
        background: none;
        border: none;
        display: flex;
        justify-content: space-between;
        align-items: center;
        cursor: pointer;
        transition: background 0.2s;
    }

    .accordion-header:hover {
        background: #f8fafc;
    }

    .accordion-title {
        font-weight: 700;
        color: var(--text-primary);
        font-size: 1rem;
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .accordion-meta {
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .percentage-badge {
        padding: 0.4rem 0.75rem;
        border-radius: 8px;
        font-weight: 700;
        font-size: 0.85rem;
    }

    .percentage-badge.good {
        background: #dcfce7;
        color: #16a34a;
    }

    .percentage-badge.warning {
        background: #fef3c7;
        color: #d97706;
    }

    .percentage-badge.danger {
        background: #fee2e2;
        color: #dc2626;
    }

    .accordion-icon {
        width: 24px;
        height: 24px;
        color: var(--text-secondary);
        transition: transform 0.3s;
    }

    .accordion-icon.open {
        transform: rotate(180deg);
    }

    .accordion-body {
        padding: 0 1.5rem 1.5rem;
        display: none;
    }

    .accordion-body.open {
        display: block;
    }

    /* Table */
    .attendance-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        overflow: hidden;
    }

    .attendance-table thead th {
        background: #f8fafc;
        padding: 0.75rem 1rem;
        text-align: right;
        font-weight: 700;
        color: var(--text-secondary);
        font-size: 0.85rem;
        border-bottom: 1px solid #e2e8f0;
    }

    .attendance-table tbody td {
        padding: 0.75rem 1rem;
        border-bottom: 1px solid #f1f5f9;
    }

    .attendance-table tbody tr:last-child td {
        border-bottom: none;
    }

    .attendance-table tbody tr:hover {
        background: #f8fafc;
    }

    .status-badge {
        display: inline-block;
        padding: 0.3rem 0.6rem;
        border-radius: 6px;
        font-weight: 600;
        font-size: 0.8rem;
    }

    .status-badge.present {
        background: #dcfce7;
        color: #16a34a;
    }

    .status-badge.absent {
        background: #fee2e2;
        color: #dc2626;
    }

    .status-badge.late {
        background: #fef3c7;
        color: #d97706;
    }

    .status-badge.excused {
        background: #dbeafe;
        color: #2563eb;
    }

    /* Excuse Status */
    .excuse-status {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        font-size: 0.8rem;
        margin-top: 0.5rem;
    }

    .excuse-btn {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        padding: 0.35rem 0.75rem;
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        color: white;
        border: none;
        border-radius: 8px;
        font-size: 0.8rem;
        font-weight: 600;
        cursor: pointer;
        margin-top: 0.5rem;
        transition: all 0.2s;
    }

    .excuse-btn:hover {
        transform: scale(1.02);
        box-shadow: 0 4px 12px -2px rgba(79, 70, 229, 0.4);
    }

    /* Modal */
    .modal-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
        padding: 1rem;
    }

    .modal-container {
        background: white;
        border-radius: 20px;
        width: 100%;
        max-width: 500px;
        padding: 2rem;
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
    }

    .modal-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.5rem;
    }

    .modal-title {
        font-size: 1.25rem;
        font-weight: 700;
    }

    .modal-close {
        width: 36px;
        height: 36px;
        background: #f1f5f9;
        border: none;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all 0.2s;
    }

    .modal-close:hover {
        background: #e2e8f0;
    }

    .form-group {
        margin-bottom: 1.25rem;
    }

    .form-label {
        display: block;
        font-weight: 600;
        margin-bottom: 0.5rem;
    }

    .form-control {
        width: 100%;
        padding: 0.75rem;
        border: 2px solid #e2e8f0;
        border-radius: 10px;
        font-size: 1rem;
        transition: all 0.2s;
    }

    .form-control:focus {
        outline: none;
        border-color: var(--primary-color);
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
    }

    .form-hint {
        font-size: 0.8rem;
        color: var(--text-secondary);
        margin-top: 0.35rem;
    }

    .modal-actions {
        display: flex;
        justify-content: flex-end;
        gap: 0.75rem;
        margin-top: 1.5rem;
    }

    .btn-cancel {
        padding: 0.75rem 1.25rem;
        background: #f1f5f9;
        border: none;
        border-radius: 10px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.2s;
    }

    .btn-cancel:hover {
        background: #e2e8f0;
    }

    .btn-submit {
        padding: 0.75rem 1.5rem;
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        color: white;
        border: none;
        border-radius: 10px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.2s;
    }

    .btn-submit:hover {
        box-shadow: 0 8px 20px -6px rgba(79, 70, 229, 0.5);
    }

    /* Empty State */
    .empty-state {
        text-align: center;
        padding: 4rem 2rem;
        color: var(--text-secondary);
    }

    @media (max-width: 1100px) {
        .stats-grid {
            grid-template-columns: repeat(2, 1fr);
        }
    }

    @media (max-width: 600px) {
        .stats-grid {

    .attendance-table tbody tr:hover {
        background: #f8fafc;
    }

    .status-badge {
        display: inline-block;
        padding: 0.3rem 0.6rem;
        border-radius: 6px;
        font-weight: 600;
        font-size: 0.8rem;
    }

    .status-badge.present {
        background: #dcfce7;
        color: #16a34a;
    }

    .status-badge.absent {
        background: #fee2e2;
        color: #dc2626;
    }

    .status-badge.late {
        background: #fef3c7;
        color: #d97706;
    }

    .status-badge.excused {
        background: #dbeafe;
        color: #2563eb;
    }

    /* Excuse Status */
    .excuse-status {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        font-size: 0.8rem;
        margin-top: 0.5rem;
    }

    .excuse-btn {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        padding: 0.35rem 0.75rem;
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        color: white;
        border: none;
        border-radius: 8px;
        font-size: 0.8rem;
        font-weight: 600;
        cursor: pointer;
        margin-top: 0.5rem;
        transition: all 0.2s;
    }

    .excuse-btn:hover {
        transform: scale(1.02);
        box-shadow: 0 4px 12px -2px rgba(79, 70, 229, 0.4);
    }

    /* Modal */
    .modal-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
        padding: 1rem;
    }

    .modal-container {
        background: white;
        border-radius: 20px;
        width: 100%;
        max-width: 500px;
        padding: 2rem;
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
    }

    .modal-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.5rem;
    }

    .modal-title {
        font-size: 1.25rem;
        font-weight: 700;
    }

    .modal-close {
        width: 36px;
        height: 36px;
        background: #f1f5f9;
        border: none;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all 0.2s;
    }

    .modal-close:hover {
        background: #e2e8f0;
    }

    .form-group {
        margin-bottom: 1.25rem;
    }

    .form-label {
        display: block;
        font-weight: 600;
        margin-bottom: 0.5rem;
    }

    .form-control {
        width: 100%;
        padding: 0.75rem;
        border: 2px solid #e2e8f0;
        border-radius: 10px;
        font-size: 1rem;
        transition: all 0.2s;
    }

    .form-control:focus {
        outline: none;
        border-color: var(--primary-color);
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
    }

    .form-hint {
        font-size: 0.8rem;
        color: var(--text-secondary);
        margin-top: 0.35rem;
    }

    .modal-actions {
        display: flex;
        justify-content: flex-end;
        gap: 0.75rem;
        margin-top: 1.5rem;
    }

    .btn-cancel {
        padding: 0.75rem 1.25rem;
        background: #f1f5f9;
        border: none;
        border-radius: 10px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.2s;
    }

    .btn-cancel:hover {
        background: #e2e8f0;
    }

    .btn-submit {
        padding: 0.75rem 1.5rem;
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        color: white;
        border: none;
        border-radius: 10px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.2s;
    }

    .btn-submit:hover {
        box-shadow: 0 8px 20px -6px rgba(79, 70, 229, 0.5);
    }

    /* Empty State */
    .empty-state {
        text-align: center;
        padding: 4rem 2rem;
        color: var(--text-secondary);
    }

    @media (max-width: 1100px) {
        .stats-grid {
            grid-template-columns: repeat(2, 1fr);
        }
    }

    @media (max-width: 600px) {
        .stats-grid {
            grid-template-columns: 1fr;
        }
    }
</style>

<div x-data="{
    openSubject: null,
    showExcuseModal: false,
    showDetailsModal: false,
    attendanceId: null,
    lectureDate: '',
    excuseDetails: {
        reason: '',
        attachments: [],
        status: '',
        doctorComment: '',
        resolutionLabel: ''
    },
    toggleSubject(id) {
        this.openSubject = this.openSubject === id ? null : id;
    },
    openModal(id, date) {
        this.attendanceId = id;
        this.lectureDate = date;
        this.showExcuseModal = true;
    },
    openDetails(reason, attachments, status, comment, resolutionLabel) {
        this.excuseDetails = {
            reason: reason,
            attachments: attachments,
            status: status,
            doctorComment: comment,
            resolutionLabel: resolutionLabel
        };
        this.showDetailsModal = true;
    }
}">

    <!-- Header -->
    <div class="page-header">
        <h1 class="page-title">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
            سجل الحضور والغياب
        </h1>
        <p class="page-subtitle">تقرير شامل عن حضورك في جميع المقررات الدراسية</p>
    </div>

    <!-- Stats Grid -->
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon" style="background: linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%); color: #16a34a;">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                    <polyline points="22 4 12 14.01 9 11.01"></polyline>
                </svg>
            </div>
            <div>
                <div class="stat-value" style="color: #16a34a;">{{ $presencePercentage }}%</div>
                <div class="stat-label">نسبة الحضور</div>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-icon" style="background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%); color: #4f46e5;">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                </svg>
            </div>
            <div>
                <div class="stat-value">{{ $totalLectures }}</div>
                <div class="stat-label">إجمالي المحاضرات</div>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-icon" style="background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%); color: #2563eb;">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
            </div>
            <div>
                <div class="stat-value">{{ $presentCount + $lateCount }}</div>
                <div class="stat-label">مرات الحضور</div>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-icon" style="background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%); color: #dc2626;">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="15" y1="9" x2="9" y2="15"></line>
                    <line x1="9" y1="9" x2="15" y2="15"></line>
                </svg>
            </div>
            <div>
                <div class="stat-value">{{ $absentCount }}</div>
                <div class="stat-label">مرات الغياب</div>
            </div>
        </div>
    </div>

    <!-- Detailed Report -->
    <div class="content-card">
        <div class="content-header">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
                <line x1="16" y1="13" x2="8" y2="13"></line>
                <line x1="16" y1="17" x2="8" y2="17"></line>
            </svg>
            تفاصيل الحضور حسب المقرر
        </div>

        @if($attendanceBySubject->count() > 0)
        @foreach($attendanceBySubject as $subjectId => $records)
        @php
        $subjectName = $records->first()->subject->name ?? 'مادة غير معروفة';
        $subPresent = $records->whereIn('status', ['present', 'late'])->count();
        $subTotal = $records->count();
        $subPercentage = $subTotal > 0 ? round(($subPresent / $subTotal) * 100) : 0;
        $badgeClass = $subPercentage >= 75 ? 'good' : ($subPercentage >= 50 ? 'warning' : 'danger');
        @endphp
        <div class="subject-accordion">
            <button class="accordion-header" @click="toggleSubject({{ $subjectId }})">
                <span class="accordion-title">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                    </svg>
                    {{ $subjectName }}
                </span>
                <div class="accordion-meta">
                    <span class="percentage-badge {{ $badgeClass }}">نسبة الحضور: {{ $subPercentage }}%</span>
                    <svg class="accordion-icon" :class="{ 'open': openSubject === {{ $subjectId }} }" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <polyline points="6 9 12 15 18 9"></polyline>
                    </svg>
                </div>
            </button>
            <div class="accordion-body" :class="{ 'open': openSubject === {{ $subjectId }} }">
                @if(isset($subjectWarnings[$subjectId]) && $subjectWarnings[$subjectId]['warning_level'])
                @php $sw = $subjectWarnings[$subjectId]; @endphp
                <div style="padding: 0.75rem 1.25rem; margin: 0 1rem 0.75rem 1rem; border-radius: 12px;
                        {{ $sw['warning_level'] === 'danger' ? 'background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%); border: 1px solid #fecaca; color: #991b1b;' : 'background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%); border: 1px solid #fde68a; color: #92400e;' }}
                        display: flex; align-items: center; gap: 0.75rem; font-size: 0.9rem; font-weight: 600;">
                    <span style="font-size: 1.25rem;">{{ $sw['warning_level'] === 'danger' ? '🚫' : '⚠️' }}</span>
                    <div>
                        @if($sw['warning_level'] === 'danger')
                        <strong>تحذير حرمان!</strong> عدد الغيابات ({{ $sw['absent_count'] }}) تجاوز الحد المسموح ({{ $sw['max_absences'] }}) أو نسبة الغياب ({{ $sw['absence_percent'] }}%) تجاوزت حد الحرمان ({{ $sw['threshold'] }}%)
                        @else
                        <strong>تنبيه:</strong> أنت على بعد غياب واحد من الحد الأقصى المسموح ({{ $sw['max_absences'] }} غيابات)
                        @endif
                    </div>
                </div>
                @endif
                <div class="table-responsive">
<table class="attendance-table">
                    <thead>
                        <tr>
                            <th>التاريخ</th>
                            <th style="text-align: center;">الحالة</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($records as $record)
                        <tr>
                            <td style="font-weight: 600;">{{ \Carbon\Carbon::parse($record->date)->format('Y-m-d') }}</td>
                            <td style="text-align: center;">
                                @if($record->status == 'present')
                                <span class="status-badge present">حاضر</span>
                                @elseif($record->status == 'absent')
                                <span class="status-badge absent">غائب</span>

                                @php
                                $canExcuse = false;
                                $excuseDeadlineDays = (int) (auth()->user()->major?->college?->excuses_deadline_days ?? \App\Models\Setting::get('excuse_deadline_days', 7));
                                $deadline = \Carbon\Carbon::parse($record->date)->addDays($excuseDeadlineDays);
                                if(now()->lte($deadline) && !$record->excuse) {
                                $canExcuse = true;
                                }
                                @endphp

                                @if($record->excuse)
                                <div class="excuse-status" style="display: flex; flex-direction: column; align-items: center; gap: 0.35rem; margin-top: 0.5rem;">
                                    @if($record->excuse->status == 'pending')
                                    <span style="color: #d97706; font-size: 0.8rem; font-weight: 600;">⏳ العذر قيد المراجعة</span>
                                    @elseif($record->excuse->status == 'accepted')
                                    <span style="color: #16a34a; font-size: 0.8rem; font-weight: 600;">✅ تم قبول العذر</span>
                                    @elseif($record->excuse->status == 'rejected')
                                    <span style="color: #dc2626; font-size: 0.8rem; font-weight: 600;">❌ تم رفض العذر</span>
                                    @endif

                                    <button type="button" 
                                            @click='openDetails(@js($record->excuse->reason), @js($record->excuse->allAttachments()->map(fn ($file) => ["name" => $file->file_name, "url" => $file->file_url])->values()), @js($record->excuse->status), @js($record->excuse->doctor_comment ?? ""), @js(\App\Support\ExcuseWorkflow::resolutionLabel($record->excuse->resolution) ?? ""))'
                                            style="background: #f1f5f9; color: #475569; border: 1px solid #cbd5e1; border-radius: 6px; padding: 0.2rem 0.5rem; font-size: 0.75rem; font-weight: 600; cursor: pointer; transition: all 0.2s;">
                                        عرض التفاصيل
                                    </button>
                                </div>
                                @elseif($canExcuse)
                                <div style="display: flex; flex-direction: column; align-items: center; gap: 0.25rem;">
                                    <button class="excuse-btn" @click="openModal({{ $record->id }}, '{{ $record->date->format('Y-m-d') }}')">
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                                            <polyline points="14 2 14 8 20 8"></polyline>
                                            <line x1="12" y1="18" x2="12" y2="12"></line>
                                            <line x1="9" y1="15" x2="15" y2="15"></line>
                                        </svg>
                                        تقديم عذر
                                    </button>
                                    @php
                                    $daysLeft = (int) ceil(now()->floatDiffInDays($deadline, false));
                                    @endphp
                                    @if($daysLeft <= 2)
                                        <span style="font-size: 0.75rem; color: #dc2626; font-weight: 700;">
                                        ⚠️ باقي {{ $daysLeft < 1 ? 'أقل من يوم' : $daysLeft . ' يوم' }}
                                        </span>
                                        @else
                                        <span style="font-size: 0.75rem; color: #64748b;">
                                            آخر موعد: {{ $deadline->format('Y-m-d') }}
                                        </span>
                                        @endif
                                </div>
                                @endif

                                @elseif($record->status == 'late')
                                <span class="status-badge late">تأخر</span>
                                @elseif(in_array($record->status, ['excused', 'permitted', 'exempted']))
                                <span class="status-badge excused">معذور</span>
                                @endif
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
</div>
            </div>
        </div>
        @endforeach
        @else
        <div class="empty-state">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom: 1rem;">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
            <p>لا توجد سجلات حضور مسجلة حتى الآن</p>
        </div>
        @endif
    </div>

    <!-- Excuse Modal -->
    <div x-show="showExcuseModal" class="modal-overlay" style="display: none;" x-transition.opacity>
        <div class="modal-container" @click.away="showExcuseModal = false">
            <div class="modal-header">
                <h3 class="modal-title">تقديم عذر غياب</h3>
                <button class="modal-close" @click="showExcuseModal = false">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </button>
            </div>

            <form action="{{ route('student.excuse.store') }}" method="POST" enctype="multipart/form-data">
                @csrf
                <input type="hidden" name="attendance_id" :value="attendanceId">

                <div class="form-group">
                    <label class="form-label">تاريخ المحاضرة</label>
                    <input type="text" class="form-control" :value="lectureDate" disabled style="background: #f8fafc;">
                </div>

                <div class="form-group">
                    <label class="form-label">سبب الغياب <span style="color: #ef4444;">*</span></label>
                    <textarea name="reason" rows="3" required placeholder="اشرح سبب الغياب بالتفصيل..." class="form-control"></textarea>
                </div>

                <div class="form-group">
                    <label class="form-label">مرفق (اختياري)</label>
                    <input type="file" name="attachments[]" accept=".pdf,.jpg,.png,.jpeg" class="form-control" multiple>
                    <div class="form-hint">صورة أو ملف PDF يثبت العذر (الحد الأقصى 2 ميجابايت)</div>
                </div>

                <div class="modal-actions">
                    <button type="button" class="btn-cancel" @click="showExcuseModal = false">إلغاء</button>
                    <button type="submit" class="btn-submit">إرسال العذر</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Excuse Details Modal -->
    <div x-show="showDetailsModal" class="modal-overlay" style="display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 1000; align-items: center; justify-content: center;" x-transition style="display: flex;">
        <div class="modal-container" @click.away="showDetailsModal = false" style="background: white; border-radius: 20px; width: 100%; max-width: 500px; padding: 2rem; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); margin: 1rem;">
            <div class="modal-header" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem;">
                <h3 class="modal-title" style="font-size: 1.25rem; font-weight: 700; margin: 0;">تفاصيل العذر</h3>
                <button @click="showDetailsModal = false" style="width: 36px; height: 36px; background: #f1f5f9; border: none; border-radius: 10px; display: flex; align-items: center; justify-content: center; cursor: pointer;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                </button>
            </div>

            <div style="background: #f8fafc; padding: 1rem; border-radius: 12px; margin-bottom: 1rem; border: 1px solid #e2e8f0;">
                <h4 style="font-size: 0.9rem; color: var(--text-secondary); margin: 0 0 0.5rem 0; font-weight: 600;">سبب الغياب المرسل:</h4>
                <p style="margin: 0; color: var(--text-primary); line-height: 1.5;" x-text="excuseDetails.reason"></p>
                
                <template x-if="excuseDetails.attachments.length">
                    <div style="margin-top: 1rem; padding-top: 1rem; border-top: 1px dashed #cbd5e1;">
                        <template x-for="file in excuseDetails.attachments" :key="file.url">
                        <a :href="file.url" target="_blank" style="display: inline-flex; align-items: center; gap: 0.5rem; color: #4f46e5; text-decoration: none; font-weight: 600; font-size: 0.9rem;">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"></path></svg>
                            عرض المرفق المرسل
                        </a>
                        </template>
                    </div>
                </template>
            </div>

            <template x-if="excuseDetails.doctorComment">
                <div style="background: #fffbeb; padding: 1rem; border-radius: 12px; border: 1px solid #fde68a; margin-bottom: 1rem;">
                    <h4 style="font-size: 0.9rem; color: #92400e; margin: 0 0 0.5rem 0; font-weight: 600; display: flex; align-items: center; gap: 0.35rem;">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg>
                        ملاحظة الدكتور:
                    </h4>
                    <p style="margin: 0; color: #b45309; line-height: 1.5;" x-text="excuseDetails.doctorComment"></p>
                </div>
            </template>

            <template x-if="excuseDetails.resolutionLabel">
                <div style="background: #eff6ff; padding: 1rem; border-radius: 12px; border: 1px solid #bfdbfe; margin-bottom: 1rem;">
                    <h4 style="font-size: 0.9rem; color: #1d4ed8; margin: 0 0 0.5rem 0; font-weight: 600;">الإجراء النهائي</h4>
                    <p style="margin: 0; color: #1e40af; line-height: 1.5;" x-text="excuseDetails.resolutionLabel"></p>
                </div>
            </template>

            <div style="display: flex; justify-content: flex-end; margin-top: 1.5rem;">
                <button type="button" @click="showDetailsModal = false" style="padding: 0.75rem 1.5rem; background: #e2e8f0; color: #475569; border: none; border-radius: 10px; font-weight: 600; cursor: pointer;">أغلق التقرير</button>
            </div>
        </div>
    </div>

</div>

@endsection
