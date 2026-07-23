@extends('layouts.delegate')

@section('title', 'محادثات الدكاترة')

@section('content')

<style>
    .chat-container {
        display: grid;
        grid-template-columns: 320px 1fr;
        gap: 0;
        height: calc(100vh - 180px);
        background: white;
        border-radius: 20px;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
        /* Soft shadow instead of border */
        overflow: hidden;
    }

    .conversations-panel {
        background: #ffffff;
        border-right: 1px solid #f1f5f9;
        display: flex;
        flex-direction: column;
        overflow: hidden;
        border-radius: 0;
        border: none;
    }

    .conversations-header {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid #f1f5f9;
        display: flex;
        justify-content: space-between;
        align-items: center;
        background: white;
    }

    .conversations-title {
        font-weight: 700;
        font-size: 1.1rem;
    }

    .new-chat-btn {
        width: 36px;
        height: 36px;
        border-radius: 12px;
        background: #f1f5f9;
        color: var(--primary-color);
        border: none;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all 0.2s;
    }

    .new-chat-btn:hover {
        background: var(--primary-color);
        color: white;
        transform: translateY(-2px);
    }

    .conversations-list {
        flex: 1;
        overflow-y: auto;
    }

    .conversation-item {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid #f8fafc;
        cursor: pointer;
        transition: all 0.2s;
        text-decoration: none;
        color: inherit;
        display: block;
    }

    .conversation-item:hover {
        background: #f8fafc;
    }

    .conversation-item.active {
        background: #f8fafc;
        border-left: 4px solid var(--primary-color);
        /* Note: in LTR it's left, but in RTL it should be right. Let's make it border-right */
        border-left: none;
        border-right: 4px solid var(--primary-color);
    }

    .conversation-avatar {
        width: 42px;
        height: 42px;
        border-radius: 12px;
        background: linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        color: #166534;
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
        border-left: 1px solid #f1f5f9;
        display: flex;
        flex-direction: column;
        min-height: 0;
        overflow: hidden;
        border-radius: 0;
    }

    .chat-header {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid #f1f5f9;
        display: flex;
        align-items: center;
        gap: 1rem;
        background: rgba(255, 255, 255, 0.9);
        backdrop-filter: blur(10px);
        position: sticky;
        top: 0;
        z-index: 10;
    }

    .messages-container {
        flex: 1;
        min-height: 0;
        overflow-y: auto;
        -webkit-overflow-scrolling: touch;
        overscroll-behavior: contain;
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
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        color: white;
        align-self: flex-start;
        border-bottom-right-radius: 4px;
        box-shadow: 0 4px 15px rgba(16, 185, 129, 0.2);
    }

    .message-bubble.received {
        background: white;
        color: var(--text-primary);
        align-self: flex-end;
        border-bottom-left-radius: 4px;
        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.03);
        border: 1px solid #f1f5f9;
    }

    .message-time {
        font-size: 0.7rem;
        opacity: 0.7;
        margin-top: 0.35rem;
    }

    .chat-input-area {
        padding: 1.25rem 1.5rem;
        border-top: 1px solid #f1f5f9;
        background: white;
    }

    .chat-input-form {
        display: flex;
        gap: 0.75rem;
    }

    .chat-input {
        flex: 1;
        padding: 0.875rem 1.25rem;
        background: #f8fafc;
        border: 1px solid #f1f5f9;
        border-radius: 14px;
        resize: none;
        font-family: inherit;
        font-size: 1rem;
        max-height: 120px;
    }

    .chat-input:focus {
        outline: none;
        background: white;
        border-color: var(--primary-color);
    }

    .send-btn {
        padding: 0.875rem;
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        color: white;
        border: none;
        border-radius: 14px;
        font-weight: 600;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.2s;
    }

    .send-btn:hover {
        box-shadow: 0 4px 12px -2px rgba(16, 185, 129, 0.4);
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
            <span class="conversations-title">محادثات الدكاترة</span>
            <a href="{{ route('delegate.doctor-chat.create') }}" class="new-chat-btn" title="محادثة جديدة">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="12" y1="5" x2="12" y2="19"></line>
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
            </a>
        </div>
        <div class="conversations-list">
            @forelse($conversations as $conv)
            <a href="{{ route('delegate.doctor-chat.show', $conv->id) }}"
                class="conversation-item {{ isset($conversation) && $conversation->id == $conv->id ? 'active' : '' }}">
                <div class="conversation-info">
                    <div class="conversation-avatar">{{ mb_substr($conv->doctor->name ?? '?', 0, 1) }}</div>
                    <div>
                        <div class="conversation-name">د. {{ $conv->doctor->name ?? 'دكتور' }}</div>
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
            <div class="conversation-avatar">{{ mb_substr($conversation->doctor->name ?? '?', 0, 1) }}</div>
            <div>
                <div style="font-weight: 700;">د. {{ $conversation->doctor->name ?? 'دكتور' }}</div>
                <div style="font-size: 0.8rem; color: var(--text-secondary);">دكتور</div>
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
            <form action="{{ route('delegate.doctor-chat.send', $conversation->id) }}" method="POST" class="chat-input-form">
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
            <p>أو ابدأ محادثة جديدة مع دكتور</p>
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