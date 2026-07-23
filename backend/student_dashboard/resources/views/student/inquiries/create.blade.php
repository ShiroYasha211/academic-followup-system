@extends('layouts.student')

@section('title', 'استفسار جديد')

@section('content')

<style>
    .page-header {
        margin-bottom: 2rem;
    }

    .page-title {
        font-size: 1.75rem;
        font-weight: 800;
        color: var(--text-primary);
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .form-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        padding: 2rem;
    }

    .info-box {
        padding: 1rem 1.25rem;
        background: #eff6ff;
        border-radius: 14px;
        margin-bottom: 1.5rem;
        display: flex;
        align-items: flex-start;
        gap: 0.75rem;
    }

    .field {
        margin-bottom: 1.5rem;
    }

    .label {
        display: block;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.5rem;
    }

    .input,
    .select,
    .textarea {
        width: 100%;
        padding: 0.875rem 1rem;
        border-radius: 12px;
        border: 1px solid #dbe3ee;
        background: #f8fafc;
        font-family: inherit;
        font-size: 1rem;
        transition: all 0.2s ease;
    }

    .input:focus,
    .select:focus,
    .textarea:focus {
        outline: none;
        background: #fff;
        border-color: var(--primary-color);
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
    }

    .textarea {
        min-height: 180px;
        resize: vertical;
    }

    .hint {
        margin-top: 0.5rem;
        font-size: 0.88rem;
        color: #64748b;
        line-height: 1.6;
    }

    .status-panel {
        display: none;
        margin-top: 1rem;
        padding: 1rem 1.25rem;
        border-radius: 14px;
        border: 1px solid transparent;
    }

    .status-panel.open {
        display: block;
        background: #ecfdf5;
        border-color: #a7f3d0;
        color: #065f46;
    }

    .status-panel.closed {
        display: block;
        background: #fff7ed;
        border-color: #fdba74;
        color: #9a3412;
    }

    .btn-row {
        display: flex;
        gap: 1rem;
        margin-top: 2rem;
        flex-wrap: wrap;
    }

    .btn-primary {
        padding: 0.875rem 2rem;
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        color: white;
        border: none;
        border-radius: 12px;
        font-weight: 700;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        transition: all 0.2s;
    }

    .btn-primary:hover:not(:disabled) {
        box-shadow: 0 4px 12px -2px rgba(79, 70, 229, 0.4);
        transform: translateY(-1px);
    }

    .btn-primary:disabled {
        opacity: 0.55;
        cursor: not-allowed;
        box-shadow: none;
    }

    .btn-secondary {
        padding: 0.875rem 2rem;
        background: #f1f5f9;
        color: var(--text-secondary);
        border: none;
        border-radius: 12px;
        font-weight: 700;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
    }

    .btn-secondary:hover {
        background: #e2e8f0;
    }
</style>

<div class="page-header">
    <h1 class="page-title">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
            <circle cx="12" cy="12" r="10"></circle>
            <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
            <line x1="12" y1="17" x2="12.01" y2="17"></line>
        </svg>
        استفسار جديد للدكتور
    </h1>
</div>

<div class="form-card">
    <div class="info-box">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="12" y1="16" x2="12" y2="12"></line>
            <line x1="12" y1="8" x2="12.01" y2="8"></line>
        </svg>
        <div style="color: #1e40af; font-size: 0.95rem; line-height: 1.8;">
            اختر المادة المرتبطة بالدكتور الذي تريد مراسلته. ستظهر لك حالة الاستفسارات مباشرة:
            <strong>مفتوحة</strong> أو <strong>مغلقة</strong>.
            إذا كانت المادة مغلقة فلن يمكنك إرسال الاستفسار حتى يفتحها الدكتور.
        </div>
    </div>

    <form action="{{ route('student.inquiries.store') }}" method="POST" id="inquiryForm">
        @csrf

        <div class="field">
            <label class="label" for="subject_id">الدكتور والمادة</label>
            <select id="subject_id" name="subject_id" class="select" required>
                <option value="">اختر الدكتور والمادة...</option>
                @foreach($subjects as $subject)
                    @php
                        $doctorName = $subject->doctor?->name ?? 'دكتور غير محدد';
                        $canReceive = (bool) ($subject->doctor_id && $subject->inquiries_enabled);
                        $statusLabel = $canReceive ? 'مفتوحة' : 'مغلقة';
                        $statusMessage = $canReceive
                            ? 'الاستفسارات متاحة لهذه المادة.'
                            : ($subject->inquiries_closed_reason ?: 'الاستفسارات مغلقة حالياً لهذه المادة.');
                    @endphp
                    <option
                        value="{{ $subject->id }}"
                        data-doctor-name="{{ e($doctorName) }}"
                        data-subject-name="{{ e($subject->name) }}"
                        data-status-label="{{ e($statusLabel) }}"
                        data-status-message="{{ e($statusMessage) }}"
                        data-can-receive="{{ $canReceive ? '1' : '0' }}"
                        {{ old('subject_id') == $subject->id ? 'selected' : '' }}
                    >
                        {{ $doctorName }} - {{ $subject->name }} ({{ $statusLabel }})
                    </option>
                @endforeach
            </select>
            <div class="hint">
                اختر المادة المناسبة، وسيظهر لك مباشرة هل الاستفسارات مفتوحة أم مغلقة.
            </div>
            @error('subject_id')
                <span style="color: #ef4444; font-size: 0.85rem;">{{ $message }}</span>
            @enderror

            <div id="statusPanel" class="status-panel" aria-live="polite"></div>
        </div>

        <div class="field">
            <label class="label" for="title">عنوان الاستفسار</label>
            <input type="text" id="title" name="title" class="input" placeholder="مثال: استفسار عن موعد تسليم المشروع..." value="{{ old('title') }}" required>
            @error('title')
                <span style="color: #ef4444; font-size: 0.85rem;">{{ $message }}</span>
            @enderror
        </div>

        <div class="field">
            <label class="label" for="question">سؤالك للدكتور</label>
            <textarea id="question" name="question" class="textarea" placeholder="اكتب سؤالك أو استفسارك بالتفصيل..." required>{{ old('question') }}</textarea>
            @error('question')
                <span style="color: #ef4444; font-size: 0.85rem;">{{ $message }}</span>
            @enderror
        </div>

        <div class="btn-row">
            <button type="submit" class="btn-primary" id="submitBtn">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="22" y1="2" x2="11" y2="13"></line>
                    <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                </svg>
                إرسال الاستفسار
            </button>
            <a href="{{ route('student.inquiries.index') }}" class="btn-secondary">إلغاء</a>
        </div>
    </form>
</div>

<script>
(() => {
    const select = document.getElementById('subject_id');
    const statusPanel = document.getElementById('statusPanel');
    const submitBtn = document.getElementById('submitBtn');

    const renderStatus = () => {
        const option = select.options[select.selectedIndex];

        if (!option || !option.value) {
            statusPanel.className = 'status-panel';
            statusPanel.innerHTML = '';
            submitBtn.disabled = false;
            return;
        }

        const canReceive = option.dataset.canReceive === '1';
        const doctorName = option.dataset.doctorName || '';
        const subjectName = option.dataset.subjectName || '';
        const statusLabel = option.dataset.statusLabel || '';
        const statusMessage = option.dataset.statusMessage || '';

        statusPanel.className = 'status-panel ' + (canReceive ? 'open' : 'closed');
        statusPanel.innerHTML = `
            <div style="font-weight: 800; margin-bottom: 0.25rem;">${doctorName} - ${subjectName}</div>
            <div>${statusMessage}</div>
            <div style="margin-top: 0.35rem; font-weight: 700;">الحالة: ${statusLabel}</div>
        `;
        submitBtn.disabled = !canReceive;
    };

    select.addEventListener('change', renderStatus);
    renderStatus();
})();
</script>

@endsection
