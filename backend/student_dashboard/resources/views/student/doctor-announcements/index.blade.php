@extends('layouts.student')

@section('title', 'إعلانات الدكاترة')

@section('content')
<style>
    :root {
        --post-bg: #ffffff;
        --post-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
        --post-radius: 20px;
        --author-size: 48px;
        --accent-blue: #3b82f6;
        --accent-purple: #8b5cf6;
        --accent-orange: #f59e0b;
        --accent-red: #ef4444;
    }

    body { background-color: #f8fafc; }

    /* Modern Feed Header */
    .feed-header {
        background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
        border-radius: 24px;
        padding: 2.5rem 2rem;
        color: white;
        margin-bottom: 2rem;
        position: relative;
        overflow: hidden;
        box-shadow: 0 10px 25px -5px rgba(0,0,0,0.1);
    }

    .feed-header::after {
        content: '';
        position: absolute;
        top: -10%;
        right: -5%;
        width: 300px;
        height: 300px;
        background: linear-gradient(135deg, rgba(59, 130, 246, 0.15), rgba(139, 92, 246, 0.1));
        border-radius: 50%;
        filter: blur(40px);
    }

    .feed-header-content { position: relative; z-index: 1; }
    .feed-title { font-size: 2.2rem; font-weight: 900; margin-bottom: 0.5rem; letter-spacing: -0.5px; }
    .feed-subtitle { opacity: 0.8; font-size: 1.05rem; font-weight: 500; }

    /* Enhanced Feed Filter Tabs */
    .feed-tabs {
        display: flex;
        gap: 0.75rem;
        margin-bottom: 2.5rem;
        background: #f1f5f9;
        padding: 0.5rem;
        border-radius: 16px;
        width: fit-content;
        border: 1px solid #e2e8f0;
    }

    .feed-tab {
        padding: 0.6rem 1.5rem;
        border-radius: 12px;
        font-weight: 700;
        font-size: 0.9rem;
        text-decoration: none;
        color: #64748b;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .feed-tab:hover:not(.active) { background: #e2e8f0; color: #334155; }
    
    .feed-tab.active { background: white; color: #1e293b; box-shadow: 0 4px 10px rgba(0,0,0,0.05); }
    .feed-tab.active.tab-announcement { color: var(--accent-blue); }
    .feed-tab.active.tab-warning { color: var(--accent-red); }
    .feed-tab.active.tab-quiz { color: var(--accent-orange); }

    /* The Feed Container */
    .feed-container {
        display: flex;
        flex-direction: column;
        gap: 1.5rem;
        max-width: 800px;
        margin: 0 auto;
    }

    /* Professional Post Card */
    .post-card {
        background: var(--post-bg);
        border-radius: var(--post-radius);
        box-shadow: var(--post-shadow);
        border: 1px solid #f1f5f9;
        transition: transform 0.2s ease;
        overflow: hidden;
    }

    .post-card:hover { transform: translateY(-2px); }

    .post-header {
        padding: 1.25rem 1.5rem;
        display: flex;
        align-items: center;
        gap: 1rem;
        border-bottom: 1px solid #f8fafc;
    }

    .author-avatar {
        width: var(--author-size);
        height: var(--author-size);
        border-radius: 14px;
        background: linear-gradient(135deg, #3b82f6, #8b5cf6);
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 800;
        font-size: 1.2rem;
        flex-shrink: 0;
        box-shadow: 0 4px 12px rgba(59, 130, 246, 0.2);
        letter-spacing: 1px;
    }

    .author-meta { flex: 1; min-width: 0; }
    .author-name {
        font-size: 1.1rem;
        font-weight: 800;
        color: #1e293b;
        margin: 0;
        display: flex;
        align-items: center;
        gap: 0.35rem;
    }

    .author-badge { font-size: 0.85rem; color: #3b82f6; } /* Verified-like icon color */

    .post-time {
        font-size: 0.8rem;
        color: #94a3b8;
        display: flex;
        align-items: center;
        gap: 0.35rem;
    }

    .post-type { margin-left: auto; }

    /* Post Content */
    .post-body {
        padding: 1.5rem;
    }

    .post-title {
        font-size: 1.25rem;
        font-weight: 900;
        color: #0f172a;
        margin-bottom: 0.85rem;
        line-height: 1.4;
    }

    .post-content {
        font-size: 0.95rem;
        color: #334155;
        line-height: 1.8;
        white-space: pre-wrap;
    }

    .post-subject-tag {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        background: #f1f5f9;
        color: #475569;
        padding: 0.4rem 0.85rem;
        border-radius: 10px;
        font-size: 0.8rem;
        font-weight: 700;
        margin-top: 1.25rem;
    }

    /* Post Footer/Actions */
    .post-footer {
        padding: 1rem 1.5rem;
        background: #fcfdfe;
        border-top: 1px solid #f1f5f9;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 1rem;
    }

    .post-attachments {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
    }

    .attachment-card {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        background: white;
        padding: 0.5rem 1rem;
        border-radius: 12px;
        border: 1.5px solid #e2e8f0;
        text-decoration: none;
        color: #475569;
        font-size: 0.85rem;
        font-weight: 700;
        transition: all 0.2s ease;
    }

    .attachment-card:hover { border-color: #3b82f6; color: #3b82f6; background: #eff6ff; }
    .attachment-card i { font-size: 1rem; color: #94a3b8; }

    .interaction-group {
        display: flex;
        gap: 0.5rem;
    }

    .interaction-btn {
        background: white;
        border: 1px solid #e2e8f0;
        width: 38px;
        height: 38px;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: #64748b;
        cursor: pointer;
        transition: all 0.2s;
    }

    .interaction-btn:hover { background: #f1f5f9; color: #1e293b; border-color: #cbd5e1; }
    .interaction-btn.active { color: #f59e0b; background: #fffbeb; border-color: #fde68a; }

    /* Status Badges */
    .status-badge {
        padding: 0.4rem 0.85rem;
        border-radius: 10px;
        font-size: 0.75rem;
        font-weight: 800;
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
    }

    .badge-announcement { background: #dbeafe; color: #1e40af; }
    .badge-warning { background: #fee2e2; color: #991b1b; }
    .badge-quiz_alert { background: #fef3c7; color: #92400e; }

    /* Empty Feed */
    .empty-feed {
        text-align: center;
        padding: 5rem 2rem;
        background: white;
        border-radius: 24px;
        border: 2px dashed #e2e8f0;
    }

    .empty-feed-icon { font-size: 4rem; color: #cbd5e1; margin-bottom: 2rem; }

    @media (max-width: 768px) {
        .feed-header { padding: 2rem 1.5rem; }
        .feed-title { font-size: 1.75rem; }
        .feed-tabs { width: 100%; overflow-x: auto; flex-wrap: nowrap; }
        .feed-tab { white-space: nowrap; flex: 1; justify-content: center; }
        .post-card { border-radius: 0; margin-left: -1rem; margin-right: -1rem; border-left: none; border-right: none; }
    }
</style>

<!-- Top Premium Header -->
<div class="feed-header">
    <div class="feed-header-content text-center text-md-start">
        <h1 class="feed-title"><i class="fa-solid fa-chalkboard-user me-2"></i>منصة إعلانات الدكاترة</h1>
        <p class="feed-subtitle">آخر التحديثات، التنبيهات، والمواعيد الدراسية من أعضاء هيئة التدريس</p>
    </div>
</div>

<!-- Social-Style Tabs -->
<div class="d-flex justify-content-center">
    <div class="feed-tabs">
        <a href="{{ route('student.doctor-announcements.index') }}" class="feed-tab {{ $type === 'all' ? 'active' : '' }}">
            <i class="fa-solid fa-layer-group"></i> الجميع
        </a>
        <a href="{{ route('student.doctor-announcements.index', ['type' => 'announcement']) }}" class="feed-tab tab-announcement {{ $type === 'announcement' ? 'active' : '' }}">
            <i class="fa-solid fa-bullhorn"></i> إعلانات
        </a>
        <a href="{{ route('student.doctor-announcements.index', ['type' => 'warning']) }}" class="feed-tab tab-warning {{ $type === 'warning' ? 'active' : '' }}">
            <i class="fa-solid fa-circle-exclamation"></i> تحذيرات
        </a>
        <a href="{{ route('student.doctor-announcements.index', ['type' => 'quiz_alert']) }}" class="feed-tab tab-quiz {{ $type === 'quiz_alert' ? 'active' : '' }}">
            <i class="fa-solid fa-clipboard-question"></i> كويزات
        </a>
    </div>
</div>

<!-- Main Feed -->
<div class="feed-container">
    @if($announcements->count() > 0)
        @foreach($announcements as $ann)
        @php $doctor = $ann->doctor; @endphp
        <div class="post-card">
            <!-- Post Header -->
            <div class="post-header">
                <div class="author-avatar">
                    {{ mb_substr($doctor->name ?? 'د', 0, 1) }}
                </div>
                <div class="author-meta">
                    <h3 class="author-name">
                        {{ $doctor->name ?? 'عضو هيئة تدريس' }}
                        <span class="author-badge" title="موثوق"><i class="fa-solid fa-circle-check"></i></span>
                    </h3>
                    <div class="post-time">
                        <span class="me-2 fw-bold text-primary"><i class="fa-solid fa-book-open me-1"></i> {{ $ann->subject->name ?? 'مادة عامة' }}</span>
                        <span><i class="fa-regular fa-clock me-1"></i> {{ $ann->published_at?->diffForHumans() ?? $ann->created_at->diffForHumans() }}</span>
                    </div>
                </div>
                <div class="post-type">
                    <span class="status-badge badge-{{ $ann->type }}">
                        <i class="fa-solid {{ $ann->type_icon }}"></i>
                        {{ $ann->type_label }}
                    </span>
                </div>
            </div>

            <!-- Post Body -->
            <div class="post-body">
                <h2 class="post-title">{{ $ann->title }}</h2>
                <div class="post-content mb-3">{{ $ann->content }}</div>

                {{-- Visual Attachment (Image) --}}
                @if($ann->attachment_path && in_array(strtolower(pathinfo($ann->attachment_path, PATHINFO_EXTENSION)), ['jpg', 'jpeg', 'png', 'gif', 'webp']))
                    <div class="post-image-container mb-3">
                        <a href="{{ $ann->attachment_url }}" target="_blank">
                            <img src="{{ $ann->attachment_url }}" class="img-fluid rounded-4 shadow-sm border" style="max-height: 500px; width: 100%; object-fit: cover;" alt="{{ $ann->title }}">
                        </a>
                    </div>
                @endif
            </div>

            <!-- Post Footer (Non-Image Attachments) -->
            @if($ann->attachment_path && !in_array(strtolower(pathinfo($ann->attachment_path, PATHINFO_EXTENSION)), ['jpg', 'jpeg', 'png', 'gif', 'webp']))
            <div class="post-footer">
                <div class="post-attachments w-100">
                    <a href="{{ $ann->attachment_url }}" target="_blank" class="attachment-card w-100">
                        <div class="d-flex align-items-center gap-3">
                            <i class="fa-solid fa-file-pdf" style="font-size: 1.5rem; color: #ef4444;"></i>
                            <div class="flex-grow-1">
                                <div class="fw-bold mb-0 text-dark">تحميل المرفق</div>
                                <div class="text-secondary small">{{ $ann->attachment_name ?? 'اضغط هنا للتحميل' }}</div>
                            </div>
                            <i class="fa-solid fa-download" style="color: #3b82f6;"></i>
                        </div>
                    </a>
                </div>
            </div>
            @endif
        </div>
        @endforeach

        <!-- Pagination -->
        <div class="mt-4 d-flex justify-content-center">
            {{ $announcements->appends(['type' => $type])->links() }}
        </div>
    @else
        <!-- Empty Feed State -->
        <div class="empty-feed">
            <div class="empty-feed-icon">
                <i class="fa-solid fa-hashtag"></i>
            </div>
            <h2 class="fw-bold text-dark">خلاصة فارغة</h2>
            <p class="text-secondary">لا توجد إعلانات نشطة حالياً ضمن هذا التصنيف.</p>
        </div>
    @endif
</div>
@endsection
