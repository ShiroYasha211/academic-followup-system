@extends('layouts.delegate')

@section('title', 'عرض الرسالة')

@section('content')

<style>
    .page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 2rem;
    }

    .back-btn {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        color: var(--text-secondary);
        text-decoration: none;
        font-weight: 600;
        transition: color 0.2s;
    }

    .back-btn:hover {
        color: var(--primary-color);
    }

    .message-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        margin-bottom: 2rem;
    }

    .message-header {
        padding: 1.5rem;
        border-bottom: 1px solid #f1f5f9;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .sender-info {
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .sender-avatar {
        width: 48px;
        height: 48px;
        border-radius: 12px;
        background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        color: #4f46e5;
    }

    .sender-name {
        font-weight: 700;
        color: var(--text-primary);
    }

    .sender-role {
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    .message-time {
        font-size: 0.85rem;
        color: #94a3b8;
    }

    .message-subject {
        padding: 1.5rem;
        border-bottom: 1px solid #f1f5f9;
    }

    .message-subject h2 {
        font-size: 1.25rem;
        font-weight: 700;
        color: var(--text-primary);
        margin: 0;
    }

    .message-body {
        padding: 1.5rem;
        line-height: 1.8;
        color: var(--text-primary);
        white-space: pre-wrap;
    }

    .reply-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
    }

    .reply-title {
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 1rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .reply-textarea {
        width: 100%;
        min-height: 120px;
        padding: 1rem;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        font-family: inherit;
        font-size: 1rem;
        resize: vertical;
        margin-bottom: 1rem;
    }

    .reply-textarea:focus {
        outline: none;
        background: white;
        border-color: var(--primary-color);
    }

    .btn-primary {
        padding: 0.75rem 1.5rem;
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

    .quick-reply-btn {
        padding: 0.5rem 1rem;
        background: white;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
        font-weight: 600;
        color: var(--text-secondary);
        cursor: pointer;
        margin-left: 0.5rem;
        transition: all 0.2s;
        text-decoration: none;
    }

    .quick-reply-btn:hover {
        background: var(--primary-color);
        color: white;
        border-color: var(--primary-color);
    }
</style>

<div class="page-header">
    <a href="{{ route('delegate.messages.index') }}" class="back-btn">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="15 18 9 12 15 6"></polyline>
        </svg>
        العودة للرسائل
    </a>
    @if($message->sender_id != auth()->id())
    <a href="{{ route('delegate.messages.create', ['to' => $message->sender_id]) }}" class="quick-reply-btn">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display: inline; vertical-align: middle; margin-left: 0.25rem;">
            <polyline points="9 14 4 9 9 4"></polyline>
            <path d="M20 20v-7a4 4 0 0 0-4-4H4"></path>
        </svg>
        رد سريع
    </a>
    @endif
</div>

<div class="message-card">
    <div class="message-header">
        <div class="sender-info">
            <div class="sender-avatar">{{ mb_substr($message->sender->name ?? '?', 0, 1) }}</div>
            <div>
                <div class="sender-name">{{ $message->sender->name ?? 'غير معروف' }}</div>
                <div class="sender-role">
                    @if($message->sender_id == auth()->id())
                    أنت
                    @else
                    طالب
                    @endif
                    → {{ $message->receiver->name ?? 'غير معروف' }}
                </div>
            </div>
        </div>
        <div class="message-time">
            {{ $message->created_at->format('Y/m/d h:i A') }}
        </div>
    </div>

    <div class="message-subject">
        <h2>{{ $message->subject }}</h2>
    </div>

    <div class="message-body">
        {{ $message->body }}
    </div>
</div>

@if($message->sender_id != auth()->id())
<div class="reply-card">
    <div class="reply-title">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="9 14 4 9 9 4"></polyline>
            <path d="M20 20v-7a4 4 0 0 0-4-4H4"></path>
        </svg>
        الرد على الرسالة
    </div>
    <form action="{{ route('delegate.messages.reply', $message->id) }}" method="POST">
        @csrf
        <textarea name="body" class="reply-textarea" placeholder="اكتب ردك هنا..." required></textarea>
        <button type="submit" class="btn-primary">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="22" y1="2" x2="11" y2="13"></line>
                <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
            </svg>
            إرسال الرد
        </button>
    </form>
</div>
@endif

@endsection