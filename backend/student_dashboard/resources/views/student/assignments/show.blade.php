@extends('layouts.student')

@section('title', $assignment->title)

@section('content')

<style>
    .back-link {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        color: var(--text-secondary);
        text-decoration: none;
        font-weight: 600;
        margin-bottom: 1.5rem;
    }

    .back-link:hover {
        color: var(--primary-color);
    }

    .assignment-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
    }

    .assignment-header {
        padding: 1.5rem;
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        color: white;
    }

    .assignment-title {
        font-size: 1.5rem;
        font-weight: 700;
        margin-bottom: 0.5rem;
    }

    .assignment-meta {
        display: flex;
        gap: 1.5rem;
        font-size: 0.9rem;
        opacity: 0.9;
    }

    .assignment-body {
        padding: 1.5rem;
    }

    .section-title {
        font-size: 1.1rem;
        font-weight: 700;
        margin-bottom: 1rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .due-badge {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        padding: 0.4rem 0.8rem;
        border-radius: 8px;
        font-weight: 600;
        font-size: 0.85rem;
    }

    .due-upcoming {
        background: #d1fae5;
        color: #065f46;
    }

    .due-overdue {
        background: #fee2e2;
        color: #991b1b;
    }

    .submission-card {
        background: #f8fafc;
        border-radius: 12px;
        padding: 1.25rem;
        margin-bottom: 1.5rem;
    }

    .submission-status {
        display: inline-block;
        padding: 0.3rem 0.6rem;
        border-radius: 6px;
        font-weight: 600;
        font-size: 0.8rem;
    }

    .status-pending {
        background: #fef3c7;
        color: #92400e;
    }

    .status-accepted {
        background: #d1fae5;
        color: #065f46;
    }

    .status-rejected {
        background: #fee2e2;
        color: #991b1b;
    }

    .upload-area {
        border: 2px dashed #e2e8f0;
        border-radius: 12px;
        padding: 2rem;
        text-align: center;
        transition: all 0.2s;
        cursor: pointer;
    }

    .upload-area:hover {
        border-color: var(--primary-color);
        background: #f8fafc;
    }

    .upload-area.dragover {
        border-color: var(--primary-color);
        background: #eff6ff;
    }

    .file-input {
        display: none;
    }

    .selected-file {
        background: #eff6ff;
        border: 1px solid #e0e7ff;
        border-radius: 10px;
        padding: 0.75rem 1rem;
        display: flex;
        align-items: center;
        gap: 0.75rem;
        margin-top: 1rem;
    }

    .btn-submit {
        padding: 0.875rem 2rem;
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        color: white;
        border: none;
        border-radius: 12px;
        font-weight: 700;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        margin-top: 1rem;
    }

    .btn-submit:hover {
        box-shadow: 0 4px 12px -2px rgba(16, 185, 129, 0.4);
    }

    .btn-submit:disabled {
        opacity: 0.5;
        cursor: not-allowed;
    }

    .notes-input {
        width: 100%;
        padding: 0.75rem;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
        margin-top: 1rem;
        resize: vertical;
    }

    .feedback-card {
        background: #fef3c7;
        border: 1px solid #fcd34d;
        border-radius: 10px;
        padding: 1rem;
        margin-top: 1rem;
    }
</style>

<a href="{{ route('student.assignments.index') }}" class="back-link">
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="15 18 9 12 15 6"></polyline>
    </svg>
    العودة للتكاليف
</a>

<div class="assignment-card">
    <div class="assignment-header">
        <h1 class="assignment-title">{{ $assignment->title }}</h1>
        <div class="assignment-meta">
            <span>📚 {{ $assignment->subject->name ?? 'المقرر' }}</span>
            <span>📅 الموعد: {{ $assignment->due_date->format('Y-m-d') }}</span>
            @if($assignment->isOverdue())
            <span class="due-badge due-overdue">منتهي</span>
            @else
            <span class="due-badge due-upcoming">قيد التسليم</span>
            @endif
        </div>
    </div>

    <div class="assignment-body">
        <!-- Description -->
        <div style="margin-bottom: 2rem;">
            <h3 class="section-title">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                    <polyline points="14 2 14 8 20 8"></polyline>
                </svg>
                تفاصيل التكليف
            </h3>
            <p style="color: var(--text-secondary); line-height: 1.8;">{{ $assignment->description }}</p>
        </div>

        @if(session('success'))
        <div class="alert alert-success mb-4">{{ session('success') }}</div>
        @endif

        @if($errors->any())
        <div class="alert alert-danger mb-4">
            <ul class="mb-0">
                @foreach($errors->all() as $error)
                <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
        @endif

        <!-- Existing Submission -->
        @if($submission)
        <div class="submission-card">
            <h3 class="section-title" style="margin-bottom: 0.75rem;">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: #10b981;">
                    <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
                تسليمك السابق
            </h3>
            <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem;">
                <div>
                    @if($submission->file_name)
                        <strong>{{ $submission->file_name }}</strong>
                        <span style="color: var(--text-secondary); font-size: 0.85rem;">({{ $submission->formatted_file_size }})</span>
                    @else
                        <strong style="color: #10b981;">✅ تم الإنجاز (بدون مرفق)</strong>
                    @endif
                    <div style="font-size: 0.85rem; color: var(--text-secondary);">
                        تم التسليم: {{ $submission->submitted_at->format('Y-m-d H:i') }}
                        @if($submission->isLate())
                        <span style="background: #fee2e2; color: #991b1b; padding: 0.15rem 0.4rem; border-radius: 4px; font-size: 0.75rem; margin-right: 0.5rem;">متأخر</span>
                        @endif
                    </div>
                </div>
                <span class="submission-status status-{{ $submission->status }}">
                    @switch($submission->status)
                    @case('pending') قيد المراجعة @break
                    @case('accepted') مقبول @break
                    @case('rejected') مرفوض @break
                    @endswitch
                </span>
            </div>

            @if($submission->grade)
            <div style="margin-top: 1rem; padding: 0.75rem; background: white; border-radius: 8px;">
                <strong>الدرجة:</strong>
                <span style="font-size: 1.25rem; font-weight: 700; color: {{ $submission->grade >= 60 ? '#10b981' : '#ef4444' }};">
                    {{ $submission->grade }}/100
                </span>
            </div>
            @endif

            @if($submission->feedback)
            <div class="feedback-card">
                <strong>ملاحظات الدكتور:</strong>
                <p style="margin: 0.5rem 0 0;">{{ $submission->feedback }}</p>
            </div>
            @endif
        </div>
        @endif

        <!-- Upload Form (only if not overdue or re-submitting) -->
        @if(!$assignment->isOverdue() || !$submission)
        <div>
            <h3 class="section-title">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: #8b5cf6;">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                    <polyline points="17 8 12 3 7 8"></polyline>
                    <line x1="12" y1="3" x2="12" y2="15"></line>
                </svg>
                {{ $submission ? 'تحديث التسليم' : 'تسليم التكليف' }}
            </h3>

            <form action="{{ route('student.assignments.submit', $assignment->id) }}" method="POST" enctype="multipart/form-data" id="submitForm">
                @csrf

                @if($assignment->requires_submission)
                    <div class="upload-area" id="uploadArea" onclick="document.getElementById('fileInput').click();">
                        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color: #cbd5e1; margin-bottom: 1rem;">
                            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                            <polyline points="17 8 12 3 7 8"></polyline>
                            <line x1="12" y1="3" x2="12" y2="15"></line>
                        </svg>
                        <p style="font-weight: 600; color: var(--text-primary); margin-bottom: 0.5rem;">اضغط لاختيار ملف أو اسحب الملف هنا</p>
                        <p style="font-size: 0.85rem; color: var(--text-secondary);">PDF أو ZIP • الحد الأقصى 10MB</p>
                    </div>

                    <input type="file" name="file" id="fileInput" class="file-input" accept=".pdf,.zip,.rar" required>

                    <div id="selectedFile" class="selected-file" style="display: none;">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                            <polyline points="14 2 14 8 20 8"></polyline>
                        </svg>
                        <div>
                            <div id="fileName" style="font-weight: 600;"></div>
                            <div id="fileSize" style="font-size: 0.8rem; color: var(--text-secondary);"></div>
                        </div>
                    </div>
                @else
                    <div style="background: #f0fdf4; border: 1px dashed #22c55e; border-radius: 12px; padding: 1.5rem; text-align: center; margin-bottom: 1rem;">
                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: #22c55e; margin-bottom: 0.5rem;">
                            <polyline points="20 6 9 17 4 12"></polyline>
                        </svg>
                        <p style="font-weight: 600; color: #166534;">هذا التكليف لا يتطلب ملفاً. يمكنك فقط الضغط على "تحديد كمكتمل".</p>
                    </div>
                @endif

                <textarea name="notes" class="notes-input" rows="2" placeholder="ملاحظات إضافية (اختياري)..."></textarea>

                <button type="submit" class="btn-submit" id="submitBtn" {{ $assignment->requires_submission ? 'disabled' : '' }}>
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                    {{ $submission ? 'تحديث التسليم' : ($assignment->requires_submission ? 'تسليم التكليف' : 'تحديد كمكتمل') }}
                </button>
            </form>
        </div>
        @endif
    </div>
</div>

<script>
    const fileInput = document.getElementById('fileInput');
    const uploadArea = document.getElementById('uploadArea');
    const selectedFile = document.getElementById('selectedFile');
    const fileName = document.getElementById('fileName');
    const fileSize = document.getElementById('fileSize');
    const submitBtn = document.getElementById('submitBtn');

    if (fileInput && uploadArea && selectedFile && fileName && fileSize && submitBtn) {
        fileInput.addEventListener('change', function() {
            if (this.files.length > 0) {
                const file = this.files[0];
                fileName.textContent = file.name;
                fileSize.textContent = formatFileSize(file.size);
                selectedFile.style.display = 'flex';
                submitBtn.disabled = false;
            }
        });

        // Drag and drop
        uploadArea.addEventListener('dragover', function(e) {
            e.preventDefault();
            this.classList.add('dragover');
        });

        uploadArea.addEventListener('dragleave', function(e) {
            e.preventDefault();
            this.classList.remove('dragover');
        });

        uploadArea.addEventListener('drop', function(e) {
            e.preventDefault();
            this.classList.remove('dragover');
            const files = e.dataTransfer.files;
            if (files.length > 0) {
                fileInput.files = files;
                fileInput.dispatchEvent(new Event('change'));
            }
        });
    }

    function formatFileSize(bytes) {
        if (bytes >= 1048576) return (bytes / 1048576).toFixed(2) + ' MB';
        if (bytes >= 1024) return (bytes / 1024).toFixed(2) + ' KB';
        return bytes + ' bytes';
    }
</script>

@endsection
