@extends('layouts.doctor')

@section('title', 'الرسائل')

@section('content')

<style>
    .chat-container {
        display: grid;
        grid-template-columns: 300px 1fr;
        gap: 1.5rem;
        height: calc(100vh - 200px);
        min-height: 500px;
    }

    .conversations-panel {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        display: flex;
        flex-direction: column;
        overflow: hidden;
    }

    .conversations-header {
        padding: 1.25rem;
        border-bottom: 1px solid #e2e8f0;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .conversations-title {
        font-weight: 700;
        font-size: 1.1rem;
    }

    .new-chat-btn {
        width: 36px;
        height: 36px;
        border-radius: 10px;
        background: var(--primary-color);
        color: white;
        border: none;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
    }

    .conversations-list {
        flex: 1;
        overflow-y: auto;
    }

    .conversation-item {
        padding: 1rem 1.25rem;
        border-bottom: 1px solid #f1f5f9;
        cursor: pointer;
        transition: background 0.2s;
        text-decoration: none;
        color: inherit;
        display: block;
    }

    .conversation-item:hover,
    .conversation-item.active {
        background: #f8fafc;
    }

    .conversation-item.active {
        border-right: 3px solid var(--primary-color);
    }

    .conversation-avatar {
        width: 42px;
        height: 42px;
        border-radius: 12px;
        background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        color: #4f46e5;
    }

    .conversation-info {
        display: flex;
        gap: 0.75rem;
        align-items: center;
    }

    .conversation-name {
        font-weight: 600;
        color: var(--text-primary);
    }

    .conversation-preview {
        font-size: 0.8rem;
        color: var(--text-secondary);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        max-width: 180px;
    }

    .chat-panel {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        display: flex;
        flex-direction: column;
        overflow: hidden;
    }

    .chat-header {
        padding: 1.25rem;
        border-bottom: 1px solid #e2e8f0;
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .messages-container {
        flex: 1;
        overflow-y: auto;
        padding: 1.5rem;
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    .message-bubble {
        max-width: 70%;
        padding: 0.875rem 1.25rem;
        border-radius: 16px;
        line-height: 1.5;
    }

    .message-bubble.sent {
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        color: white;
        align-self: flex-start;
        border-bottom-right-radius: 4px;
    }

    .message-bubble.received {
        background: #f1f5f9;
        color: var(--text-primary);
        align-self: flex-end;
        border-bottom-left-radius: 4px;
    }

    .message-time {
        font-size: 0.7rem;
        opacity: 0.7;
        margin-top: 0.35rem;
    }

    .chat-input-area {
        padding: 1rem 1.25rem;
        border-top: 1px solid #e2e8f0;
    }

    .chat-input-form {
        display: flex;
        gap: 0.75rem;
    }

    .chat-input {
        flex: 1;
        padding: 0.875rem 1rem;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        resize: none;
    }

    .send-btn {
        padding: 0 1.25rem;
        background: var(--primary-color);
        color: white;
        border: none;
        border-radius: 12px;
        font-weight: 600;
        cursor: pointer;
    }

    .empty-chat {
        flex: 1;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        color: var(--text-secondary);
    }
</style>

<div class="chat-container">
    <!-- Conversations Panel -->
    <div class="conversations-panel">
        <div class="conversations-header">
            <span class="conversations-title">المحادثات</span>
            <a href="{{ route('doctor.messages.create') }}" class="new-chat-btn" title="محادثة جديدة">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="12" y1="5" x2="12" y2="19"></line>
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
            </a>
        </div>
        <div class="conversations-list">
            @forelse($conversations as $conv)
            <a href="{{ route('doctor.messages.show', $conv->id) }}"
                class="conversation-item {{ isset($conversation) && $conversation->id == $conv->id ? 'active' : '' }}">
                <div class="conversation-info">
                    <div class="conversation-avatar">{{ mb_substr($conv->delegate->name ?? '?', 0, 1) }}</div>
                    <div>
                        <div class="conversation-name">{{ $conv->delegate->name ?? 'مندوب' }}</div>
                        <div class="conversation-preview">
                            {{ $conv->lastMessage->body ?? 'ابدأ المحادثة...' }}
                        </div>
                    </div>
                </div>
            </a>
            @empty
            <div style="padding: 2rem; text-align: center; color: var(--text-secondary);">
                <p>لا توجد محادثات بعد</p>
            </div>
            @endforelse
        </div>
    </div>

    <!-- Chat Panel -->
    <div class="chat-panel">
        @if(isset($conversation))
        <div class="chat-header">
            <div class="conversation-avatar">{{ mb_substr($conversation->delegate->name ?? '?', 0, 1) }}</div>
            <div>
                <div style="font-weight: 700;">{{ $conversation->delegate->name ?? 'مندوب' }}</div>
                <div style="font-size: 0.8rem; color: var(--text-secondary);">مندوب</div>
            </div>
        </div>

        <div class="messages-container" id="messages">
            @foreach($messages as $message)
            <div class="message-bubble {{ $message->sender_id == Auth::id() ? 'sent' : 'received' }}">
                <div>{{ $message->body }}</div>
                <div class="message-time">{{ $message->created_at->format('H:i') }}</div>
            </div>
            @endforeach
        </div>

        <div class="chat-input-area">
            <form action="{{ route('doctor.messages.send', $conversation->id) }}" method="POST" class="chat-input-form">
                @csrf
                <textarea name="body" class="chat-input" placeholder="اكتب رسالتك..." rows="1" required></textarea>
                <button type="submit" class="send-btn">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="22" y1="2" x2="11" y2="13"></line>
                        <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                    </svg>
                </button>
            </form>
        </div>
        @else
        <div class="empty-chat">
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color: #cbd5e1; margin-bottom: 1rem;">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
            </svg>
            <h3 style="font-weight: 700; margin-bottom: 0.5rem;">اختر محادثة</h3>
            <p>أو ابدأ محادثة جديدة مع مندوب</p>
        </div>
        @endif
    </div>
</div>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        const messagesContainer = document.getElementById('messages');
        if (messagesContainer) {
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        }
    });
</script>

@endsection