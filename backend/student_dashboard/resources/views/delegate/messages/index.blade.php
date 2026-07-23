@extends('layouts.delegate')

@section('title', 'رسائل الطلاب')

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

    @media (max-width: 768px) {
        .chat-container {
            grid-template-columns: 1fr;
            height: calc(100vh - 140px);
        }

        .conversations-list {
            display: {{ isset($conversation) ? 'none' : 'block' }} !important;
        }

        .chat-area {
            display: {{ isset($conversation) ? 'flex' : 'none' }} !important;
        }
    }

    .conversations-list {
        border-left: 1px solid #f1f5f9;
        overflow-y: auto;
        background: #ffffff;
        /* Cleaner white background */
    }

    .conversations-header {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid #f1f5f9;
        background: white;
        position: sticky;
        top: 0;
        z-index: 10;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .conversations-header h3 {
        font-size: 1.1rem;
        font-weight: 700;
        color: var(--text-primary);
        margin: 0;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .new-chat-btn {
        width: 36px;
        height: 36px;
        background: #f1f5f9;
        color: var(--primary-color);
        border: none;
        border-radius: 12px;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        text-decoration: none;
        transition: all 0.2s;
    }

    .new-chat-btn:hover {
        background: var(--primary-color);
        color: white;
        transform: translateY(-2px);
    }

    .conversation-item {
        padding: 1.25rem 1.5rem;
        display: flex;
        gap: 1rem;
        cursor: pointer;
        transition: all 0.2s;
        border-bottom: 1px solid #f8fafc;
        text-decoration: none;
        color: inherit;
    }

    .conversation-item:hover {
        background: #f8fafc;
    }

    .conversation-item.active {
        background: #f8fafc;
        border-right: 4px solid var(--primary-color);
    }

    .conv-avatar {
        width: 44px;
        height: 44px;
        border-radius: 12px;
        background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        color: #4f46e5;
        flex-shrink: 0;
    }

    .conv-info {
        flex: 1;
        min-width: 0;
    }

    .conv-name {
        font-weight: 600;
        color: var(--text-primary);
        margin-bottom: 0.15rem;
    }

    .conv-preview {
        font-size: 0.85rem;
        color: var(--text-secondary);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .conv-meta {
        text-align: left;
        flex-shrink: 0;
    }

    .conv-time {
        font-size: 0.75rem;
        color: #94a3b8;
    }

    .conv-unread {
        background: var(--primary-color);
        color: white;
        font-size: 0.7rem;
        font-weight: 700;
        padding: 0.15rem 0.5rem;
        border-radius: 10px;
        margin-top: 0.25rem;
        display: inline-block;
    }

    .chat-area {
        display: flex;
        flex-direction: column;
        background: white;
        min-height: 0;
        overflow: hidden;
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

    .chat-header-avatar {
        width: 40px;
        height: 40px;
        border-radius: 10px;
        background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        color: #4f46e5;
    }

    .chat-header-info h4 {
        font-weight: 700;
        color: var(--text-primary);
        margin: 0;
    }

    .chat-header-info span {
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    .messages-area {
        flex: 1;
        min-height: 0;
        overflow-y: auto;
        -webkit-overflow-scrolling: touch;
        overscroll-behavior: contain;
        padding: 1.5rem;
        display: flex;
        flex-direction: column;
        gap: 1rem;
        background: #f8fafc;
    }

    .message-bubble {
        max-width: 75%;
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

    .message-bubble.sent .message-time {
        color: rgba(255, 255, 255, 0.8);
    }

    .message-bubble.received .message-time {
        color: #94a3b8;
    }

    .chat-input-area {
        padding: 1.25rem 1.5rem;
        background: white;
        border-top: 1px solid #f1f5f9;
    }

    .chat-input-form {
        display: flex;
        gap: 0.75rem;
    }

    .chat-input {
        flex: 1;
        padding: 0.875rem 1.25rem;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        font-family: inherit;
        font-size: 1rem;
        resize: none;
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
        background: #f8fafc;
    }

    .empty-chat svg {
        width: 64px;
        height: 64px;
        color: #cbd5e1;
        margin-bottom: 1rem;
    }

    .no-conversations {
        padding: 3rem 1.5rem;
        text-align: center;
        color: var(--text-secondary);
    }
</style>

<div class="chat-container">
    <!-- Conversations List -->
    <div class="conversations-list">
        <div class="conversations-header">
            <h3>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
                </svg>
                رسائل الطلاب
            </h3>
            <a href="{{ route('delegate.messages.create') }}" class="new-chat-btn" title="محادثة جديدة">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="12" y1="5" x2="12" y2="19"></line>
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
            </a>
        </div>

        @if($conversations->count() > 0)
        @foreach($conversations as $conv)
        @php
        $unread = $conv->unreadCountFor(auth()->id());
        $lastMsg = $conv->lastMessage;
        @endphp
        <a href="{{ route('delegate.messages.show', $conv->id) }}"
            class="conversation-item {{ isset($conversation) && $conversation->id == $conv->id ? 'active' : '' }}">
            <div class="conv-avatar">{{ mb_substr($conv->student->name ?? '?', 0, 1) }}</div>
            <div class="conv-info">
                <div class="conv-name">{{ $conv->student->name ?? 'طالب' }}</div>
                <div class="conv-preview">{{ $lastMsg ? Str::limit($lastMsg->body, 30) : 'ابدأ المحادثة...' }}</div>
            </div>
            <div class="conv-meta">
                @if($lastMsg)
                <div class="conv-time">{{ $lastMsg->created_at->diffForHumans(null, true, true) }}</div>
                @endif
                @if($unread > 0)
                <span class="conv-unread">{{ $unread }}</span>
                @endif
            </div>
        </a>
        @endforeach
        @else
        <div class="no-conversations">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color: #cbd5e1; margin-bottom: 1rem;">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
            </svg>
            <p>لا توجد محادثات بعد</p>
            <p style="font-size: 0.85rem;">ستظهر هنا رسائل الطلاب</p>
        </div>
        @endif
    </div>

    <!-- Chat Area -->
    <div class="chat-area">
        @if(isset($conversation))
        <div class="chat-header">
            <a href="{{ route('delegate.messages.index') }}" class="d-md-none" style="color: var(--text-secondary);">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="15 18 9 12 15 6"></polyline>
                </svg>
            </a>
            <div class="chat-header-avatar">{{ mb_substr($conversation->student->name ?? '?', 0, 1) }}</div>
            <div class="chat-header-info">
                <h4>{{ $conversation->student->name ?? 'طالب' }}</h4>
                <span>{{ $conversation->student->student_number ?? 'طالب' }}</span>
            </div>
        </div>

        <div class="messages-area" id="messagesArea">
            @foreach($messages as $msg)
            <div class="message-bubble {{ $msg->sender_id == auth()->id() ? 'sent' : 'received' }}">
                {{ $msg->body }}
                <div class="message-time">{{ $msg->created_at->format('h:i A') }}</div>
            </div>
            @endforeach
        </div>

        <div class="chat-input-area">
            <form action="{{ route('delegate.messages.send', $conversation->id) }}" method="POST" class="chat-input-form">
                @csrf
                <textarea name="body" class="chat-input" placeholder="اكتب رسالتك..." rows="1" required></textarea>
                <button type="submit" class="send-btn">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="22" y1="2" x2="11" y2="13"></line>
                        <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                    </svg>
                </button>
            </form>
        </div>

        <script>
            document.addEventListener('DOMContentLoaded', function() {
                var area = document.getElementById('messagesArea');
                if (area) {
                    area.scrollTop = area.scrollHeight;
                }
            });
        </script>
        @else
        <div class="empty-chat">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
            </svg>
            <p>اختر محادثة للبدء</p>
        </div>
        @endif
    </div>
</div>

@endsection