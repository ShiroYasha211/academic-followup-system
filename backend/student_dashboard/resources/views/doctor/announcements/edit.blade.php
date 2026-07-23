@extends('layouts.doctor')

@section('title', 'تعديل الإعلان')

@section('content')
<style>
    .form-container {
        max-width: 800px;
        margin: 0 auto;
    }

    .form-header {
        background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
        border-radius: 24px;
        padding: 2.5rem 2rem;
        color: white;
        margin-bottom: 2rem;
        position: relative;
        overflow: hidden;
    }

    .form-header::before {
        content: '';
        position: absolute;
        top: -50%;
        right: -10%;
        width: 300px;
        height: 300px;
        background: rgba(255,255,255,0.08);
        border-radius: 50%;
    }

    .form-header-content { position: relative; z-index: 1; }
    .form-title { font-size: 2rem; font-weight: 800; margin-bottom: 0.25rem; }
    .form-subtitle { opacity: 0.85; }

    .form-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        padding: 2rem;
        box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
    }

    .form-label-custom {
        font-weight: 700;
        color: #334155;
        margin-bottom: 0.5rem;
        font-size: 0.95rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .form-control-custom, .form-select-custom {
        border: 2px solid #e2e8f0;
        border-radius: 14px;
        padding: 0.75rem 1rem;
        font-size: 0.95rem;
        transition: border-color 0.2s;
    }

    .form-control-custom:focus, .form-select-custom:focus {
        border-color: #4f46e5;
        box-shadow: 0 0 0 4px rgba(79,70,229,0.1);
    }

    textarea.form-control-custom { min-height: 150px; resize: vertical; }

    .type-selector { display: flex; gap: 0.75rem; flex-wrap: wrap; }

    .type-option { flex: 1; min-width: 150px; }
    .type-option input[type="radio"] { display: none; }

    .type-option label {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.5rem;
        padding: 1.25rem 1rem;
        border: 2px solid #e2e8f0;
        border-radius: 16px;
        cursor: pointer;
        transition: all 0.2s;
        text-align: center;
        font-weight: 700;
        font-size: 0.9rem;
        color: #64748b;
    }

    .type-option label:hover { border-color: #a5b4fc; }

    .type-option input:checked + label.type-announcement-label { border-color: #4f46e5; background: #eef2ff; color: #4338ca; }
    .type-option input:checked + label.type-warning-label { border-color: #ef4444; background: #fef2f2; color: #b91c1c; }
    .type-option input:checked + label.type-quiz-label { border-color: #f59e0b; background: #fffbeb; color: #92400e; }

    .type-icon { font-size: 1.5rem; }

    .btn-submit {
        background: linear-gradient(135deg, #4f46e5, #7c3aed);
        color: white;
        border: none;
        padding: 0.85rem 2rem;
        border-radius: 14px;
        font-weight: 700;
        font-size: 1rem;
        transition: all 0.2s;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
    }

    .btn-submit:hover { transform: translateY(-2px); box-shadow: 0 10px 25px rgba(79,70,229,0.3); color: white; }

    .btn-back {
        background: #f1f5f9;
        color: #475569;
        border: none;
        padding: 0.85rem 1.5rem;
        border-radius: 14px;
        font-weight: 600;
        text-decoration: none;
        transition: all 0.2s;
    }

    .btn-back:hover { background: #e2e8f0; color: #334155; }

    .current-file {
        background: #f0fdf4;
        border: 1px solid #bbf7d0;
        border-radius: 10px;
        padding: 0.5rem 0.75rem;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.85rem;
        color: #166534;
        font-weight: 600;
        margin-top: 0.5rem;
    }
</style>

<div class="form-container">
    <div class="form-header">
        <div class="form-header-content">
            <h1 class="form-title"><i class="fa-solid fa-pen-to-square me-2"></i>تعديل الإعلان</h1>
            <p class="form-subtitle">تعديل "{{ $announcement->title }}"</p>
        </div>
    </div>

    <div class="form-card">
        <form action="{{ route('doctor.announcements.update', $announcement) }}" method="POST" enctype="multipart/form-data">
            @csrf
            @method('PUT')

            <!-- Type -->
            <div class="mb-4">
                <label class="form-label-custom"><i class="fa-solid fa-tag"></i> نوع الإعلان</label>
                <div class="type-selector">
                    <div class="type-option">
                        <input type="radio" name="type" id="type_announcement" value="announcement" {{ old('type', $announcement->type) === 'announcement' ? 'checked' : '' }}>
                        <label for="type_announcement" class="type-announcement-label">
                            <i class="fa-solid fa-bullhorn type-icon"></i> إعلان
                        </label>
                    </div>
                    <div class="type-option">
                        <input type="radio" name="type" id="type_warning" value="warning" {{ old('type', $announcement->type) === 'warning' ? 'checked' : '' }}>
                        <label for="type_warning" class="type-warning-label">
                            <i class="fa-solid fa-triangle-exclamation type-icon"></i> إنذار
                        </label>
                    </div>
                    <div class="type-option">
                        <input type="radio" name="type" id="type_quiz" value="quiz_alert" {{ old('type', $announcement->type) === 'quiz_alert' ? 'checked' : '' }}>
                        <label for="type_quiz" class="type-quiz-label">
                            <i class="fa-solid fa-clipboard-question type-icon"></i> تنبيه كويز
                        </label>
                    </div>
                </div>
                @error('type') <div class="text-danger mt-1 small">{{ $message }}</div> @enderror
            </div>

            <!-- Subject -->
            <div class="mb-4">
                <label class="form-label-custom" for="subject_id">
                    <i class="fa-solid fa-book"></i> المادة
                </label>
                <select name="subject_id" id="subject_id" class="form-select form-select-custom" required>
                    @foreach($subjects as $subject)
                    <option value="{{ $subject->id }}" {{ old('subject_id', $announcement->subject_id) == $subject->id ? 'selected' : '' }}>
                        {{ $subject->name }} — {{ $subject->level->name ?? '' }}
                    </option>
                    @endforeach
                </select>
                @error('subject_id') <div class="text-danger mt-1 small">{{ $message }}</div> @enderror
            </div>

            <!-- Title -->
            <div class="mb-4">
                <label class="form-label-custom" for="title"><i class="fa-solid fa-heading"></i> العنوان</label>
                <input type="text" name="title" id="title" class="form-control form-control-custom" value="{{ old('title', $announcement->title) }}" required>
                @error('title') <div class="text-danger mt-1 small">{{ $message }}</div> @enderror
            </div>

            <!-- Content -->
            <div class="mb-4">
                <label class="form-label-custom" for="content"><i class="fa-solid fa-align-right"></i> المحتوى</label>
                <textarea name="content" id="content" class="form-control form-control-custom" required>{{ old('content', $announcement->content) }}</textarea>
                @error('content') <div class="text-danger mt-1 small">{{ $message }}</div> @enderror
            </div>

            <!-- Attachment -->
            <div class="mb-4">
                <label class="form-label-custom" for="attachment"><i class="fa-solid fa-paperclip"></i> مرفق جديد (اختياري)</label>
                <input type="file" name="attachment" id="attachment" class="form-control form-control-custom">
                @if($announcement->attachment_path)
                <div class="current-file">
                    <i class="fa-solid fa-file-lines"></i>
                    {{ $announcement->attachment_name ?? 'مرفق حالي' }}
                </div>
                @endif
                @error('attachment') <div class="text-danger mt-1 small">{{ $message }}</div> @enderror
            </div>

            <!-- Schedule -->
            <div class="mb-4">
                <label class="form-label-custom" for="published_at"><i class="fa-regular fa-clock"></i> جدولة النشر</label>
                <input type="datetime-local" name="published_at" id="published_at" class="form-control form-control-custom" value="{{ old('published_at', $announcement->published_at?->format('Y-m-d\TH:i')) }}">
                @error('published_at') <div class="text-danger mt-1 small">{{ $message }}</div> @enderror
            </div>

            <!-- Actions -->
            <div class="d-flex justify-content-between align-items-center mt-4 pt-3" style="border-top: 1px solid #f1f5f9;">
                <a href="{{ route('doctor.announcements.index') }}" class="btn-back">
                    <i class="fa-solid fa-arrow-right me-1"></i> رجوع
                </a>
                <button type="submit" class="btn-submit">
                    <i class="fa-solid fa-check"></i> حفظ التعديلات
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
