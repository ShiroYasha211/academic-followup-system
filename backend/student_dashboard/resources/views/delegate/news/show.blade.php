@extends('layouts.delegate')

@section('title', $item->title)

@section('content')
<style>
    .news-detail-container {
        max-width: 900px;
        margin: 0 auto;
    }

    .news-main-card {
        background: white;
        border-radius: 24px;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
        overflow: hidden;
        border: 1px solid #f1f5f9;
    }

    .news-detail-header {
        padding: 3rem;
        background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
        border-bottom: 1px solid #e2e8f0;
        position: relative;
    }

    .type-ribbon {
        position: absolute;
        top: 2rem;
        left: 2rem;
        padding: 0.5rem 1.25rem;
        border-radius: 99px;
        font-size: 0.85rem;
        font-weight: 800;
        text-transform: uppercase;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    }

    .type-announcement .type-ribbon { background: #4f46e5; color: white; }
    .type-exam .type-ribbon { background: #ef4444; color: white; }
    .type-poll .type-ribbon { background: #10b981; color: white; }
    .type-assignment .type-ribbon { background: #f59e0b; color: white; }

    .news-detail-title {
        font-size: 2.25rem;
        font-weight: 900;
        color: #0f172a;
        margin-bottom: 1.5rem;
        line-height: 1.3;
        margin-top: 1rem;
    }

    .news-meta-row {
        display: flex;
        flex-wrap: wrap;
        gap: 2rem;
        color: #64748b;
        font-size: 0.95rem;
        font-weight: 500;
    }

    .meta-item {
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .news-content-body {
        padding: 3rem;
        font-size: 1.15rem;
        line-height: 1.8;
        color: #334155;
        white-space: pre-line;
    }

    /* Poll Section */
    .poll-section {
        margin: 0 3rem 3rem;
        padding: 2.5rem;
        background: #f8fafc;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
    }

    .poll-title {
        font-size: 1.25rem;
        font-weight: 800;
        color: #1e293b;
        margin-bottom: 2rem;
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .poll-options {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    .poll-option-card {
        background: white;
        border: 2px solid #e2e8f0;
        border-radius: 16px;
        padding: 1.25rem 1.5rem;
        cursor: pointer;
        transition: all 0.2s;
        display: flex;
        align-items: center;
        justify-content: space-between;
        position: relative;
        overflow: hidden;
    }

    .poll-option-card:hover:not(.disabled) {
        border-color: #4f46e5;
        background: #f5f3ff;
    }

    .poll-option-card.selected {
        border-color: #4f46e5;
        background: #eef2ff;
    }

    .poll-option-card input {
        position: absolute;
        opacity: 0;
    }

    .option-text {
        font-weight: 700;
        color: #1e293b;
        z-index: 1;
    }

    .poll-progress {
        position: absolute;
        top: 0;
        right: 0;
        height: 100%;
        background: rgba(79, 70, 229, 0.1);
        transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
        z-index: 0;
    }

    /* Attachment Section */
    .attachment-section {
        margin: 0 3rem 3rem;
        padding: 2rem;
        background: #ffffff;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        display: flex;
        align-items: center;
        justify-content: space-between;
    }

    .attachment-info {
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .back-nav {
        margin-bottom: 2rem;
    }

    .btn-back {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        color: #64748b;
        text-decoration: none;
        font-weight: 600;
        transition: color 0.2s;
    }

    .btn-back:hover {
        color: #0f172a;
    }

    @media (max-width: 768px) {
        .news-detail-header, .news-content-body, .poll-section, .attachment-section {
            padding: 1.5rem;
        }
        .poll-section, .attachment-section {
            margin-left: 1rem;
            margin-right: 1rem;
        }
    }
</style>

<div class="news-detail-container">
    <div class="back-nav">
        <a href="{{ route('delegate.news.index') }}" class="btn-back">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"></path></svg>
            العودة للمركز الإخباري
        </a>
    </div>

    <article class="news-main-card type-{{ $item->type }}">
        <header class="news-detail-header">
            <div class="type-ribbon">
                @switch($item->type)
                    @case('announcement') إعلان رسمي @break
                    @case('exam') اختبار @break
                    @case('poll') استطلاع @break
                    @case('assignment') تكليف @break
                    @default تنبيه @break
                @endswitch
            </div>
            
            <h1 class="news-detail-title">{{ $item->title }}</h1>
            
            <div class="news-meta-row">
                <div class="meta-item">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                    <span>{{ $item->created_at->format('d M Y') }}</span>
                </div>
                <div class="meta-item">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
                    <span>المرسل: الإدارة الأكاديمية</span>
                </div>
                <div class="meta-item" style="color: #10b981;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
                    <span>تمت الرؤية</span>
                </div>
            </div>
        </header>

        <div class="news-content-body">
            {{ $item->message }}
        </div>

        @if($item->type === 'poll')
        <section class="poll-section">
            <h2 class="poll-title">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 20h9"></path><path d="m16.5 3.5 3 3L7 19l-4 1 1-4Z"></path></svg>
                شاركنا برأيك
            </h2>

            @if($hasVoted)
                <div class="alert alert-info mb-4" style="border-radius: 12px; font-weight: 600;">
                    لقد قمت بالتصويت مسبقاً على هذا الاستطلاع. شكراً لمشاركتك!
                </div>
            @endif

            <form action="{{ route('delegate.news.vote', $item->batch_id) }}" method="POST" class="poll-options">
                @csrf
                @foreach($pollOptions as $option)
                    @php
                        $totalVotes = $pollOptions->sum('votes_count');
                        $percentage = $totalVotes > 0 ? round(($option->votes_count / $totalVotes) * 100) : 0;
                    @endphp
                    <label class="poll-option-card {{ $hasVoted && $userVote->poll_option_id == $option->id ? 'selected' : '' }} {{ $hasVoted ? 'disabled' : '' }}">
                        <input type="radio" name="option_id" value="{{ $option->id }}" {{ $hasVoted ? 'disabled' : '' }} required>
                        <span class="option-text">{{ $option->option_text }}</span>
                        
                        @if($hasVoted)
                            <div class="poll-progress" style="width: {{ $percentage }}%"></div>
                            <span class="badge bg-light text-dark z-1">{{ $percentage }}%</span>
                        @endif
                    </label>
                @endforeach

                @if(!$hasVoted)
                <button type="submit" class="btn btn-primary w-100 mt-4 py-3 shadow-sm" style="border-radius: 16px; font-weight: 800; font-size: 1.1rem; background: linear-gradient(135deg, #4f46e5 0%, #3730a3 100%);">
                    تسجيل صوتي
                </button>
                @endif
            </form>
        </section>
        @endif

        @if($item->attachment_path)
        <section class="attachment-section">
            <div class="attachment-info">
                <div style="width: 48px; height: 48px; background: #eff6ff; color: #3b82f6; border-radius: 12px; display: flex; align-items: center; justify-content: center;">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l8.57-8.57A4 4 0 1 1 18 8.84l-8.59 8.57a2 2 0 0 1-2.83-2.83l8.49-8.48"></path></svg>
                </div>
                <div>
                    <div style="font-weight: 700; color: #1e293b;">مرفق رسمي مصاحب</div>
                    <div style="font-size: 0.85rem; color: #64748b;">انقر للتحميل والمعاينة</div>
                </div>
            </div>
            <a href="{{ $item->attachment_url }}" target="_blank" class="btn btn-outline-primary" style="border-radius: 10px; font-weight: 700;">
                تحميل الملف
            </a>
        </section>
        @endif
    </article>
    
    <div style="text-align: center; margin-top: 3rem; color: #94a3b8; font-size: 0.9rem;">
        تم إصدار هذا الخبر من الهيكل الإداري الرسمي للنظام الأكاديمي.
    </div>
</div>
@endsection
