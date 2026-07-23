@extends('layouts.delegate')

@section('title', 'أخبار الدفعة')

@section('content')

<style>
    /* Premium Feed Styles */
    .feed-container {
        max-width: 680px;
        /* narrowed for a better feed feel */
        margin: 0 auto;
    }

    .news-card {
        background: white;
        border-radius: 16px;
        border: 1px solid #e2e8f0;
        padding: 0;
        margin-bottom: 1.5rem;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
        /* Softer shadow */
        position: relative;
    }

    .news-card.pinned {
        border-color: #fbd38d;
        background: #fffdf5;
    }

    /* Remove the colored side strip, we'll use a badge instead to look cleaner */
    .news-card::before {
        display: none;
    }

    .card-body {
        padding: 1.25rem 1.5rem;
        /* Adjusted padding */
    }

    .news-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        flex-wrap: wrap;
        /* Prevents overlap on small screens */
        gap: 1rem;
        margin-bottom: 1rem;
    }

    .author-info {
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .author-avatar {
        width: 42px;
        height: 42px;
        background: linear-gradient(135deg, #f1f5f9 0%, #e2e8f0 100%);
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--text-secondary);
        font-weight: 700;
        font-size: 1rem;
    }

    .author-details {
        display: flex;
        flex-direction: column;
        line-height: 1.3;
        gap: 0.1rem;
    }

    .author-name {
        font-weight: 700;
        color: var(--text-primary);
        font-size: 0.95rem;
    }

    .post-date {
        font-size: 0.75rem;
        color: var(--text-light);
    }

    .news-title {
        font-size: 1.15rem;
        font-weight: 800;
        color: var(--text-primary);
        margin: 0.5rem 0;
        line-height: 1.4;
    }

    .news-content {
        color: var(--text-secondary);
        font-size: 0.95rem;
        line-height: 1.8;
        white-space: pre-wrap;
        margin-bottom: 1rem;
    }

    .news-footer {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 1rem 1.5rem;
        border-top: 1px solid #f1f5f9;
        background: #f8fafc;
        border-bottom-left-radius: 16px;
        border-bottom-right-radius: 16px;
    }

    .category-badge {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        padding: 0.4rem 0.8rem;
        border-radius: 8px;
        font-size: 0.75rem;
        font-weight: 700;
        background: #f8fafc;
        color: var(--text-secondary);
    }

    .type-academic .category-badge {
        color: var(--info-color);
        background: rgba(59, 130, 246, 0.08);
    }

    .type-urgent .category-badge {
        color: var(--danger-color);
        background: rgba(244, 63, 94, 0.08);
    }

    .action-btn {
        width: 32px;
        height: 32px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 8px;
        color: var(--text-light);
        transition: all 0.2s;
        border: none;
        background: transparent;
        cursor: pointer;
    }

    .action-btn:hover {
        background: #f1f5f9;
        color: var(--primary-color);
    }

    .action-btn.pin-active {
        color: #f59e0b;
        background: #fffbeb;
    }

    /* Stats Banner */
    .stats-banner {
        display: grid;
        grid-template-columns: repeat(5, 1fr);
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: white;
        border-radius: 16px;
        padding: 1.25rem;
        text-align: center;
        border: 1px solid #e2e8f0;
        transition: all 0.3s;
    }

    .stat-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 20px rgba(0, 0, 0, 0.05);
    }

    .stat-card .stat-icon {
        font-size: 1.5rem;
        margin-bottom: 0.5rem;
    }

    .stat-card .stat-value {
        font-size: 1.5rem;
        font-weight: 800;
        color: var(--text-primary);
    }

    .stat-card .stat-label {
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    /* Filter Buttons */
    .filter-tabs {
        display: flex;
        gap: 0.75rem;
        margin-bottom: 2rem;
        flex-wrap: wrap;
    }

    .filter-tab {
        padding: 0.6rem 1.25rem;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.9rem;
        text-decoration: none;
        transition: all 0.2s;
        border: 2px solid #e2e8f0;
        background: white;
        color: var(--text-secondary);
        display: flex;
        align-items: center;
        gap: 0.4rem;
    }

    .filter-tab:hover {
        border-color: var(--primary-color);
        color: var(--primary-color);
    }

    .filter-tab.active {
        background: var(--primary-color);
        color: white;
        border-color: var(--primary-color);
    }

    /* Attachment Preview */
    .attachment-preview {
        border-top: 1px solid #e2e8f0;
        border-bottom: 1px solid #e2e8f0;
        background: #f8fafc;
        display: flex;
        justify-content: center;
        overflow: hidden;
    }

    .attachment-preview img {
        width: 100%;
        max-height: 400px;
        object-fit: contain;
        display: block;
    }

    .attachment-document {
        display: flex;
        align-items: center;
        width: 100%;
        gap: 0.75rem;
        padding: 1rem 1.5rem;
        background: #f8fafc;
        color: var(--text-primary);
        text-decoration: none;
        transition: background 0.2s;
    }

    .attachment-document:hover {
        background: #f1f5f9;
    }

    /* Pin Badge */
    .pin-badge {
        position: absolute;
        top: 1rem;
        left: 1rem;
        background: #f59e0b;
        color: white;
        padding: 0.25rem 0.75rem;
        border-radius: 8px;
        font-size: 0.75rem;
        font-weight: 700;
        display: flex;
        align-items: center;
        gap: 0.3rem;
    }

    /* Modal Styles */
    .modal-overlay {
        display: flex;
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(15, 23, 42, 0.6);
        z-index: 1000;
        align-items: center;
        justify-content: center;
        backdrop-filter: blur(8px);
    }

    .modal-container {
        background: white;
        width: 90%;
        max-width: 650px;
        border-radius: 24px;
        padding: 2.5rem;
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
        animation: modalSlideUp 0.3s ease-out;
        max-height: 90vh;
        overflow-y: auto;
    }

    @keyframes modalSlideUp {
        from {
            opacity: 0;
            transform: translateY(20px);
        }

        to {
            opacity: 1;
            transform: translateY(0);
        }
    }

    /* Upload Zone */
    .upload-zone {
        border: 2px dashed #e2e8f0;
        border-radius: 16px;
        padding: 2rem;
        text-align: center;
        transition: all 0.3s;
        cursor: pointer;
    }

    .upload-zone:hover,
    .upload-zone.dragover {
        border-color: var(--primary-color);
        background: #f8fafc;
    }

    .upload-zone.has-file {
        border-color: #10b981;
        background: #ecfdf5;
    }

    @media (max-width: 768px) {
        .stats-banner {
            grid-template-columns: repeat(2, 1fr);
        }

        .filter-tabs {
            justify-content: center;
        }
    }
</style>

<div class="container" x-data="newsManager()">

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
        <div>
            <h1 style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary); letter-spacing: -0.5px;">أخبار الدفعة</h1>
            <p style="color: var(--text-secondary); font-size: 1rem;">آخر التحديثات والإعلانات الرسمية للطلاب</p>
        </div>
        <button @click="openCreateModal()" class="btn btn-primary" style="padding: 0.8rem 1.5rem; box-shadow: 0 4px 12px rgba(67, 56, 202, 0.2); border-radius: 12px; display: flex; align-items: center; gap: 0.5rem; font-weight: 700;">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            خبر جديد
        </button>
    </div>

    <!-- Stats Banner -->
    <div class="stats-banner">
        <div class="stat-card">
            <div class="stat-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="18" y1="20" x2="18" y2="10"></line>
                    <line x1="12" y1="20" x2="12" y2="4"></line>
                    <line x1="6" y1="20" x2="6" y2="14"></line>
                </svg>
            </div>
            <div class="stat-value">{{ $stats['total'] }}</div>
            <div class="stat-label">إجمالي الأخبار</div>
        </div>
        <div class="stat-card" style="border-color: #fecaca;">
            <div class="stat-icon" style="color: #ef4444;">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                    <line x1="12" y1="9" x2="12" y2="13"></line>
                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                </svg>
            </div>
            <div class="stat-value" style="color: #ef4444;">{{ $stats['urgent'] }}</div>
            <div class="stat-label">عاجل</div>
        </div>
        <div class="stat-card" style="border-color: #bfdbfe;">
            <div class="stat-icon" style="color: #3b82f6;">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                </svg>
            </div>
            <div class="stat-value" style="color: #3b82f6;">{{ $stats['academic'] }}</div>
            <div class="stat-label">أكاديمي</div>
        </div>
        <div class="stat-card" style="border-color: #d1d5db;">
            <div class="stat-icon" style="color: #6b7280;">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path>
                </svg>
            </div>
            <div class="stat-value" style="color: #6b7280;">{{ $stats['general'] }}</div>
            <div class="stat-label">عام</div>
        </div>
        <div class="stat-card" style="border-color: #fde68a;">
            <div class="stat-icon" style="color: #f59e0b;">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="12" y1="17" x2="12" y2="22"></line>
                    <path d="M5 17h14v-1.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V6h1a2 2 0 0 0 0-4H8a2 2 0 0 0 0 4h1v4.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24Z"></path>
                </svg>
            </div>
            <div class="stat-value" style="color: #f59e0b;">{{ $stats['pinned'] }}</div>
            <div class="stat-label">مثبت</div>
        </div>
    </div>

    <!-- Filter Tabs -->
    <div class="filter-tabs">
        <a href="{{ route('delegate.announcements.index') }}" class="filter-tab {{ $category == 'all' ? 'active' : '' }}">
            الكل
        </a>
        <a href="{{ route('delegate.announcements.index', ['category' => 'urgent']) }}" class="filter-tab {{ $category == 'urgent' ? 'active' : '' }}" @if($category !='urgent' ) style="border-color: #fecaca; color: #ef4444;" @endif>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                <line x1="12" y1="9" x2="12" y2="13"></line>
                <line x1="12" y1="17" x2="12.01" y2="17"></line>
            </svg>
            عاجل
        </a>
        <a href="{{ route('delegate.announcements.index', ['category' => 'academic']) }}" class="filter-tab {{ $category == 'academic' ? 'active' : '' }}" @if($category !='academic' ) style="border-color: #bfdbfe; color: #3b82f6;" @endif>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
            </svg>
            أكاديمي
        </a>
        <a href="{{ route('delegate.announcements.index', ['category' => 'general']) }}" class="filter-tab {{ $category == 'general' ? 'active' : '' }}" @if($category !='general' ) style="border-color: #d1d5db; color: #6b7280;" @endif>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path>
            </svg>
            عام
        </a>
    </div>

    @if(session('success'))
    <div class="alert alert-success d-flex align-items-center gap-2 mb-4" style="border-radius: 12px;">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
        {{ session('success') }}
    </div>
    @endif

    <div class="feed-container">
        @forelse($announcements as $post)
        <div class="news-card type-{{ $post->category }} {{ $post->is_pinned ? 'pinned' : '' }}">
            @if($post->is_pinned)
            <div class="pin-badge">
                📌 مثبت
            </div>
            @endif

            <div class="card-body">
                <div class="news-header">
                    <div class="author-info">
                        <div class="author-avatar">
                            {{ mb_substr($post->creator->name, 0, 1) }}
                        </div>
                        <div class="author-details">
                            <span class="author-name">{{ $post->creator->name }}</span>
                            <span class="post-date" title="{{ $post->created_at }}">{{ $post->created_at->diffForHumans() }}</span>
                        </div>
                    </div>

                    @if($post->created_by == auth()->id())
                    <div style="display: flex; gap: 0.5rem; flex-shrink: 0; align-items: center; background: #f8fafc; padding: 0.25rem; border-radius: 10px;">
                        <!-- Pin Button -->
                        <form action="{{ route('delegate.announcements.togglePin', $post->id) }}" method="POST" style="margin: 0;">
                            @csrf
                            <button type="submit" class="action-btn {{ $post->is_pinned ? 'pin-active' : '' }}" title="{{ $post->is_pinned ? 'إلغاء التثبيت' : 'تثبيت' }}">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="{{ $post->is_pinned ? '#f59e0b' : 'none' }}" stroke="currentColor" stroke-width="2">
                                    <path d="M12 2v8m0 0l-3-3m3 3l3-3M5 10h14l-1.5 9.5a2 2 0 01-2 1.5h-7a2 2 0 01-2-1.5L5 10z" />
                                </svg>
                            </button>
                        </form>

                        <!-- Edit Button -->
                        <button class="action-btn" @click="openEditModal({{ json_encode($post) }})" title="تعديل">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                            </svg>
                        </button>

                        <!-- Delete Button -->
                        <form action="{{ route('delegate.announcements.destroy', $post->id) }}" method="POST" onsubmit="return confirm('حذف هذا الخبر؟')" style="margin: 0;">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="action-btn" title="حذف" style="color: var(--danger-color);">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <polyline points="3 6 5 6 21 6"></polyline>
                                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                                </svg>
                            </button>
                        </form>
                    </div>
                    @endif
                </div>

                <h3 class="news-title">{{ $post->title }}</h3>
                <div class="news-content">{{ $post->content }}</div>
            </div> <!-- End Card Body -->

            <!-- Attachment Display (Bleeds to edges) -->
            @if($post->attachment_path)
            <div class="attachment-preview">
                @if($post->attachment_type == 'image')
                <img src="{{ $post->attachment_url }}" alt="صورة مرفقة">
                @else
                <a href="{{ $post->attachment_url }}" target="_blank" class="attachment-document">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#4f46e5" stroke-width="2">
                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                        <polyline points="14 2 14 8 20 8"></polyline>
                    </svg>
                    <span style="font-weight: 600;">عرض المرفق</span>
                </a>
                @endif
            </div>
            @endif

            <div class="news-footer">
                <div class="category-badge">
                    @if($post->category == 'urgent')
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                        <line x1="12" y1="9" x2="12" y2="13"></line>
                        <line x1="12" y1="17" x2="12.01" y2="17"></line>
                    </svg>
                    عاجل
                    @elseif($post->category == 'academic')
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                    </svg>
                    أكاديمي
                    @else
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path>
                    </svg>
                    عام
                    @endif
                </div>
            </div>
        </div>
        @empty
        <div class="text-center py-5" style="background: white; border-radius: 20px; border: 2px dashed var(--border-color);">
            <div style="width: 80px; height: 80px; background: #f8fafc; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.5rem; color: #94a3b8;">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M4 22h16a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2H8a2 2 0 0 0-2 2v16a2 2 0 0 1-2 2Zm0 0a2 2 0 0 1-2-2v-9c0-1.1.9-2 2-2h2"></path>
                    <path d="M18 14h-8"></path>
                    <path d="M15 18h-5"></path>
                    <path d="M10 6h8v4h-8V6Z"></path>
                </svg>
            </div>
            <h3 class="font-weight-bold" style="color: var(--text-primary); margin-bottom: 0.5rem;">لا توجد أخبار حالياً</h3>
            <p style="color: var(--text-secondary);">يمكنك نشر إعلانات وتعاميم للطلاب وستظهر هنا.</p>
        </div>
        @endforelse
    </div>

    @if($announcements->hasPages())
    <div class="mt-4">
        {{ $announcements->appends(['category' => $category])->links() }}
    </div>
    @endif


    <!-- Create/Edit Modal -->
    <div x-show="showModal" class="modal-overlay" style="display: none;" x-transition.opacity>
        <div class="modal-container" @click.away="showModal = false" x-transition.scale>
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
                <h3 style="margin: 0; font-size: 1.5rem; font-weight: 800;" x-text="modalTitle"></h3>
                <button type="button" @click="showModal = false" style="background: #f1f5f9; border: none; width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; cursor: pointer; color: var(--text-secondary);">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </button>
            </div>

            <form :action="formAction" method="POST" enctype="multipart/form-data">
                @csrf
                <input type="hidden" name="_method" :value="formMethod">

                <div style="display: flex; flex-direction: column; gap: 1.5rem;">

                    <!-- Category Selection -->
                    <div>
                        <label style="font-size: 0.9rem; color: var(--text-secondary); display: block; margin-bottom: 0.75rem;">نوع الخبر</label>
                        <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem;">
                            <label style="cursor: pointer;">
                                <input type="radio" name="category" value="general" x-model="formData.category" style="display: none;">
                                <div style="display: flex; flex-direction: column; align-items: center; gap: 0.5rem; padding: 1rem; text-align: center; border: 2px solid; border-radius: 12px; transition: all 0.2s; font-weight: 700;"
                                    :style="formData.category === 'general' ? 'border-color: var(--primary-color); background: #eff6ff; color: var(--primary-color);' : 'border-color: #e2e8f0; color: var(--text-secondary);'">
                                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path>
                                    </svg>
                                    عام
                                </div>
                            </label>
                            <label style="cursor: pointer;">
                                <input type="radio" name="category" value="academic" x-model="formData.category" style="display: none;">
                                <div style="display: flex; flex-direction: column; align-items: center; gap: 0.5rem; padding: 1rem; text-align: center; border: 2px solid; border-radius: 12px; transition: all 0.2s; font-weight: 700;"
                                    :style="formData.category === 'academic' ? 'border-color: #3b82f6; background: #eff6ff; color: #3b82f6;' : 'border-color: #e2e8f0; color: var(--text-secondary);'">
                                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                                        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                                    </svg>
                                    أكاديمي
                                </div>
                            </label>
                            <label style="cursor: pointer;">
                                <input type="radio" name="category" value="urgent" x-model="formData.category" style="display: none;">
                                <div style="display: flex; flex-direction: column; align-items: center; gap: 0.5rem; padding: 1rem; text-align: center; border: 2px solid; border-radius: 12px; transition: all 0.2s; font-weight: 700;"
                                    :style="formData.category === 'urgent' ? 'border-color: #ef4444; background: #fef2f2; color: #ef4444;' : 'border-color: #e2e8f0; color: var(--text-secondary);'">
                                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                                        <line x1="12" y1="9" x2="12" y2="13"></line>
                                        <line x1="12" y1="17" x2="12.01" y2="17"></line>
                                    </svg>
                                    عاجل
                                </div>
                            </label>
                        </div>
                    </div>

                    <!-- Title -->
                    <div>
                        <label style="font-size: 0.9rem; color: var(--text-secondary); display: block; margin-bottom: 0.5rem;">عنوان الخبر</label>
                        <input type="text" name="title" x-model="formData.title" class="form-control form-control-lg" required placeholder="مثال: تغيير موعد محاضرة البرمجة" style="font-weight: 600; border-radius: 12px;">
                    </div>

                    <!-- Content -->
                    <div>
                        <label style="font-size: 0.9rem; color: var(--text-secondary); display: block; margin-bottom: 0.5rem;">التفاصيل</label>
                        <textarea name="content" x-model="formData.content" class="form-control" rows="4" required placeholder="اكتب تفاصيل الخبر هنا..." style="resize: none; border-radius: 12px;"></textarea>
                    </div>

                    <!-- Attachment Upload -->
                    <div>
                        <label style="font-size: 0.9rem; color: var(--text-secondary); display: block; margin-bottom: 0.5rem;">مرفق (اختياري)</label>
                        <div class="upload-zone"
                            :class="{'has-file': attachmentName}"
                            @click="$refs.fileInput.click()"
                            @dragover.prevent="$el.classList.add('dragover')"
                            @dragleave.prevent="$el.classList.remove('dragover')"
                            @drop.prevent="handleDrop($event)">
                            <input type="file" name="attachment" x-ref="fileInput" @change="handleFileSelect($event)" accept="image/*,.pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx" style="display: none;">

                            <div x-show="!attachmentName" style="color: var(--text-secondary);">
                                <div style="margin-bottom: 0.5rem; display: flex; justify-content: center;">
                                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"></path>
                                    </svg>
                                </div>
                                <div style="font-weight: 600;">اسحب الملف هنا أو اضغط للاختيار</div>
                                <div style="font-size: 0.8rem; margin-top: 0.25rem;">صور، PDF، Word، Excel، PowerPoint</div>
                            </div>

                            <div x-show="attachmentName" style="color: #10b981;">
                                <div style="margin-bottom: 0.5rem; display: flex; justify-content: center;">
                                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                                        <polyline points="22 4 12 14.01 9 11.01"></polyline>
                                    </svg>
                                </div>
                                <div style="font-weight: 600;" x-text="attachmentName"></div>
                                <button type="button" @click.stop="clearAttachment()" style="margin-top: 0.5rem; background: #fef2f2; color: #ef4444; border: none; padding: 0.25rem 0.75rem; border-radius: 6px; font-size: 0.8rem; cursor: pointer;">إزالة</button>
                            </div>
                        </div>

                        <!-- Show existing attachment in edit mode -->
                        <div x-show="editingId && existingAttachment && !attachmentName" style="margin-top: 0.5rem; padding: 0.75rem; background: #f8fafc; border-radius: 8px; display: flex; align-items: center; justify-content: space-between;">
                            <span style="font-size: 0.9rem; color: var(--text-secondary);">📎 مرفق موجود</span>
                            <label style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer; font-size: 0.8rem; color: #ef4444;">
                                <input type="checkbox" name="remove_attachment" value="1"> إزالة المرفق
                            </label>
                        </div>
                    </div>
                </div>

                <div style="display: flex; gap: 1rem; justify-content: flex-end; margin-top: 2rem; padding-top: 1.5rem; border-top: 1px dashed var(--border-color);">
                    <button type="button" class="btn" @click="showModal = false" style="background: white; border: 1px solid var(--border-color); padding: 0.75rem 1.5rem; border-radius: 10px;">إلغاء</button>
                    <button type="submit" class="btn btn-primary" style="padding: 0.75rem 2rem; border-radius: 10px; font-weight: 700;">نشر الخبر</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
    function newsManager() {
        return {
            showModal: false,
            modalTitle: 'نشر خبر جديد',
            formAction: "{{ route('delegate.announcements.store') }}",
            formMethod: 'POST',
            editingId: null,
            existingAttachment: false,
            attachmentName: '',
            formData: {
                category: 'general',
                title: '',
                content: ''
            },
            openCreateModal() {
                this.modalTitle = 'نشر خبر جديد';
                this.formAction = "{{ route('delegate.announcements.store') }}";
                this.formMethod = 'POST';
                this.editingId = null;
                this.existingAttachment = false;
                this.attachmentName = '';
                this.formData = {
                    category: 'general',
                    title: '',
                    content: ''
                };
                this.showModal = true;
            },
            openEditModal(post) {
                this.modalTitle = 'تعديل الخبر';
                this.formAction = `/delegate/announcements/${post.id}`;
                this.formMethod = 'PUT';
                this.editingId = post.id;
                this.existingAttachment = !!post.attachment_path;
                this.attachmentName = '';
                this.formData = {
                    category: post.category,
                    title: post.title,
                    content: post.content
                };
                this.showModal = true;
            },
            handleFileSelect(event) {
                const file = event.target.files[0];
                if (file) {
                    this.attachmentName = file.name;
                }
            },
            handleDrop(event) {
                event.target.classList.remove('dragover');
                const file = event.dataTransfer.files[0];
                if (file) {
                    this.$refs.fileInput.files = event.dataTransfer.files;
                    this.attachmentName = file.name;
                }
            },
            clearAttachment() {
                this.$refs.fileInput.value = '';
                this.attachmentName = '';
            }
        }
    }
</script>

@endsection