@extends('layouts.student')

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
</style>

<div class="page-header">
    <a href="{{ route('student.messages.index') }}" class="back-btn">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="15 18 9 12 15 6"></polyline>
        </svg>
        العودة للرسائل
    </a>
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
                    {{ $message->sender->role == 'delegate' ? 'مندوب الشعبة' : 'طالب' }}
                    @endif
                    ← {{ $message->receiver->name ?? 'غير معروف' }}
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

@endsection