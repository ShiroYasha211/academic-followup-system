@extends('layouts.student')

@section('title', 'رسالة جديدة')

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

    .form-group {
        margin-bottom: 1.5rem;
    }

    .form-label {
        display: block;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.5rem;
    }

    .form-input {
        width: 100%;
        padding: 0.875rem 1rem;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        font-size: 1rem;
        font-family: inherit;
        transition: all 0.2s;
    }

    .form-input:focus {
        outline: none;
        background: white;
        border-color: var(--primary-color);
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
    }

    .form-textarea {
        min-height: 200px;
        resize: vertical;
    }

    .receiver-card {
        display: flex;
        align-items: center;
        gap: 1rem;
        padding: 1rem;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
    }

    .receiver-avatar {
        width: 48px;
        height: 48px;
        border-radius: 12px;
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        font-weight: 700;
    }

    .btn-row {
        display: flex;
        gap: 1rem;
        margin-top: 2rem;
    }

    .btn-primary {
        padding: 0.875rem 2rem;
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        color: white;
        border: none;
        border-radius: 12px;
        font-weight: 700;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        transition: all 0.2s;
    }

    .btn-primary:hover {
        box-shadow: 0 4px 12px -2px rgba(79, 70, 229, 0.4);
    }

    .btn-secondary {
        padding: 0.875rem 2rem;
        background: #f1f5f9;
        color: var(--text-secondary);
        border: none;
        border-radius: 12px;
        font-weight: 700;
        text-decoration: none;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        transition: all 0.2s;
    }

    .btn-secondary:hover {
        background: #e2e8f0;
    }
</style>

<div class="page-header">
    <h1 class="page-title">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
            <line x1="22" y1="2" x2="11" y2="13"></line>
            <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
        </svg>
        إرسال رسالة جديدة
    </h1>
</div>

<div class="form-card">
    <form action="{{ route('student.messages.store') }}" method="POST">
        @csrf

        <div class="form-group">
            <label class="form-label">إرسال إلى</label>
            @if($delegate)
            <div class="receiver-card">
                <div class="receiver-avatar">{{ mb_substr($delegate->name, 0, 1) }}</div>
                <div>
                    <div style="font-weight: 700; color: var(--text-primary);">{{ $delegate->name }}</div>
                    <div style="font-size: 0.85rem; color: var(--text-secondary);">مندوب الشعبة</div>
                </div>
            </div>
            <input type="hidden" name="receiver_id" value="{{ $delegate->id }}">
            @else
            <div style="padding: 1rem; background: #fef3c7; border-radius: 12px; color: #92400e;">
                لا يوجد مندوب مسجل لشعبتك حالياً
            </div>
            @endif
        </div>

        <div class="form-group">
            <label class="form-label" for="subject">عنوان الرسالة</label>
            <input type="text" id="subject" name="subject" class="form-input" placeholder="أدخل عنوان الرسالة..." value="{{ old('subject') }}" required>
            @error('subject')
            <span style="color: #ef4444; font-size: 0.85rem;">{{ $message }}</span>
            @enderror
        </div>

        <div class="form-group">
            <label class="form-label" for="body">نص الرسالة</label>
            <textarea id="body" name="body" class="form-input form-textarea" placeholder="اكتب رسالتك هنا..." required>{{ old('body') }}</textarea>
            @error('body')
            <span style="color: #ef4444; font-size: 0.85rem;">{{ $message }}</span>
            @enderror
        </div>

        <div class="btn-row">
            @if($delegate)
            <button type="submit" class="btn-primary">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="22" y1="2" x2="11" y2="13"></line>
                    <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                </svg>
                إرسال الرسالة
            </button>
            @endif
            <a href="{{ route('student.messages.index') }}" class="btn-secondary">إلغاء</a>
        </div>
    </form>
</div>

@endsection