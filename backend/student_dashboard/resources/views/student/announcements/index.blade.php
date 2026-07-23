@extends('layouts.student')

@section('title', 'الأخبار والإعلانات')

@section('content')

<style>
    .page-header {
        margin-bottom: 2rem;
    }

    .page-title {
        font-size: 1.75rem;
        font-weight: 800;
        color: var(--text-primary);
        margin-bottom: 0.5rem;
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .page-subtitle {
        color: var(--text-secondary);
    }

    /* Stats Grid */
    .stats-grid {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: white;
        border-radius: 16px;
        padding: 1.25rem;
        display: flex;
        align-items: center;
        gap: 1rem;
        border: 1px solid #e2e8f0;
        transition: all 0.3s ease;
        cursor: pointer;
        text-decoration: none;
    }

    .stat-card:hover {
        transform: translateY(-3px);
        box-shadow: 0 10px 20px -8px rgba(0, 0, 0, 0.1);
    }

    .stat-card.active {
        border-color: var(--primary-color);
        background: linear-gradient(135deg, #f0f0ff 0%, #e8e8ff 100%);
    }

    .stat-icon {
        width: 48px;
        height: 48px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .stat-value {
        font-size: 1.5rem;
        font-weight: 800;
        line-height: 1;
        margin-bottom: 0.25rem;
    }

    .stat-label {
        color: var(--text-secondary);
        font-size: 0.85rem;
    }

    /* Pinned Section */
    .pinned-section {
        background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
        border-radius: 20px;
        padding: 1.5rem;
        margin-bottom: 2rem;
    }

    .pinned-header {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        font-weight: 700;
        color: #92400e;
        margin-bottom: 1rem;
    }

    .pinned-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
        gap: 1rem;
    }

    .pinned-card {
        background: white;
        border-radius: 16px;
        padding: 1.25rem;
        border-right: 4px solid #f59e0b;
        transition: all 0.2s;
        cursor: pointer;
    }

    .pinned-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.1);
    }

    /* Announcement Card */
    .announcement-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        margin-bottom: 1rem;
        transition: all 0.3s ease;
        cursor: pointer;
    }

    .announcement-card:hover {
        transform: translateY(-3px);
        box-shadow: 0 12px 24px -8px rgba(0, 0, 0, 0.1);
    }

    .card-stripe {
        height: 4px;
    }

    .card-stripe.urgent {
        background: linear-gradient(90deg, #ef4444 0%, #f87171 100%);
    }

    .card-stripe.academic {
        background: linear-gradient(90deg, #3b82f6 0%, #60a5fa 100%);
    }

    .card-stripe.general {
        background: linear-gradient(90deg, #6b7280 0%, #9ca3af 100%);
    }

    .card-body {
        padding: 1.5rem;
    }

    .card-meta {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        margin-bottom: 0.75rem;
    }

    .category-badge {
        padding: 0.3rem 0.75rem;
        border-radius: 8px;
        font-weight: 600;
        font-size: 0.8rem;
    }

    .category-badge.urgent {
        background: #fee2e2;
        color: #dc2626;
    }

    .category-badge.academic {
        background: #dbeafe;
        color: #2563eb;
    }

    .category-badge.general {
        background: #f1f5f9;
        color: #64748b;
    }

    .card-title {
        font-size: 1.15rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.5rem;
    }

    .card-content {
        color: var(--text-secondary);
        line-height: 1.7;
        margin-bottom: 1rem;
    }

    .card-footer {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding-top: 1rem;
        border-top: 1px solid #f1f5f9;
    }

    .author-info {
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .author-avatar {
        width: 36px;
        height: 36px;
        background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: #4f46e5;
        font-weight: 700;
        font-size: 0.9rem;
    }

    .author-name {
        font-weight: 600;
        color: var(--text-primary);
        font-size: 0.9rem;
    }

    .author-role {
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    .attachment-badge {
        display: flex;
        align-items: center;
        gap: 0.35rem;
        padding: 0.4rem 0.75rem;
        background: #f1f5f9;
        border-radius: 8px;
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    /* Modal */
    .modal-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
        padding: 1rem;
    }

    .modal-container {
        background: white;
        border-radius: 24px;
        width: 100%;
        max-width: 700px;
        max-height: 90vh;
        overflow-y: auto;
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
    }

    .modal-header {
        padding: 1.5rem;
        border-bottom: 1px solid #f1f5f9;
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
    }

    .modal-close {
        width: 36px;
        height: 36px;
        background: #f1f5f9;
        border: none;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all 0.2s;
    }

    .modal-close:hover {
        background: #e2e8f0;
    }

    .modal-body {
        padding: 1.5rem;
    }

    .modal-content {
        line-height: 1.8;
        color: var(--text-primary);
        font-size: 1rem;
    }

    .modal-attachment {
        margin-top: 1.5rem;
        padding: 1rem;
        background: #f8fafc;
        border-radius: 12px;
    }

    .modal-attachment img {
        max-width: 100%;
        border-radius: 8px;
    }

    /* Empty State */
    .empty-state {
        text-align: center;
        padding: 4rem 2rem;
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
    }

    .empty-icon {
        width: 80px;
        height: 80px;
        background: #f1f5f9;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 1.5rem;
        color: var(--text-secondary);
    }

    @media (max-width: 900px) {
        .stats-grid {
            grid-template-columns: repeat(2, 1fr);
        }
    }

    @media (max-width: 600px) {
        .stats-grid {
            grid-template-columns: 1fr;
        }
    }
</style>

<div x-data="{
    showModal: false,
    modalData: { title: '', content: '', category: '', date: '', author: '', attachment: null, attachmentType: '' },
    openModal(title, content, category, date, author, attachment) {
        this.modalData.title = title;
        this.modalData.content = content;
        this.modalData.category = category;
        this.modalData.date = date;
        this.modalData.author = author;
        this.modalData.attachment = attachment;
        // Determine attachment type
        if (attachment) {
            const ext = attachment.split('.').pop().toLowerCase();
            this.modalData.attachmentType = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].includes(ext) ? 'image' : 'document';
        } else {
            this.modalData.attachmentType = '';
        }
        this.showModal = true;
    }
}">

    <!-- Header -->
    <div class="page-header">
        <h1 class="page-title">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
            </svg>
            الأخبار والإعلانات
        </h1>
        <p class="page-subtitle">آخر المستجدات الأكاديمية والإعلانات الهامة</p>
    </div>

    <!-- Stats Grid -->
    <div class="stats-grid">
        <a href="{{ route('student.announcements.index') }}" class="stat-card {{ is_null($category) ? 'active' : '' }}">
            <div class="stat-icon" style="background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%); color: #4f46e5;">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
                </svg>
            </div>
            <div>
                <div class="stat-value">{{ $stats['total'] }}</div>
                <div class="stat-label">جميع الإعلانات</div>
            </div>
        </a>

        <a href="{{ route('student.announcements.index', ['category' => 'academic']) }}" class="stat-card {{ $category == 'academic' ? 'active' : '' }}">
            <div class="stat-icon" style="background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%); color: #2563eb;">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                </svg>
            </div>
            <div>
                <div class="stat-value">{{ $stats['academic'] }}</div>
                <div class="stat-label">أكاديمي</div>
            </div>
        </a>

        <a href="{{ route('student.announcements.index', ['category' => 'general']) }}" class="stat-card {{ $category == 'general' ? 'active' : '' }}">
            <div class="stat-icon" style="background: linear-gradient(135deg, #f1f5f9 0%, #e2e8f0 100%); color: #64748b;">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="12" y1="16" x2="12" y2="12"></line>
                    <line x1="12" y1="8" x2="12.01" y2="8"></line>
                </svg>
            </div>
            <div>
                <div class="stat-value">{{ $stats['general'] }}</div>
                <div class="stat-label">عام</div>
            </div>
        </a>

        <a href="{{ route('student.announcements.index', ['category' => 'urgent']) }}" class="stat-card {{ $category == 'urgent' ? 'active' : '' }}">
            <div class="stat-icon" style="background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%); color: #dc2626;">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                    <line x1="12" y1="9" x2="12" y2="13"></line>
                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                </svg>
            </div>
            <div>
                <div class="stat-value">{{ $stats['urgent'] }}</div>
                <div class="stat-label">عاجل</div>
            </div>
        </a>
    </div>

    <!-- Pinned Announcements -->
    @if($pinnedAnnouncements->count() > 0)
    <div class="pinned-section">
        <div class="pinned-header">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"></path>
            </svg>
            إعلانات مثبتة
        </div>
        <div class="pinned-grid">
            @foreach($pinnedAnnouncements as $pinned)
            <div class="pinned-card" @click="openModal('{{ addslashes($pinned->title) }}', `{!! addslashes(nl2br(e($pinned->content))) !!}`, '{{ $pinned->category }}', '{{ $pinned->created_at->format('Y-m-d') }}', '{{ $pinned->creator->name }}', '{{ $pinned->attachment_url ?? '' }}')">
                <div style="font-weight: 700; margin-bottom: 0.5rem;">{{ $pinned->title }}</div>
                <div style="font-size: 0.85rem; color: var(--text-secondary);">{{ Str::limit($pinned->content, 80) }}</div>
            </div>
            @endforeach
        </div>
    </div>
    @endif

    <!-- Announcements List -->
    @if($announcements->count() > 0)
    <div>
        @foreach($announcements as $post)
        <div class="announcement-card" @click="openModal('{{ addslashes($post->title) }}', `{!! addslashes(nl2br(e($post->content))) !!}`, '{{ $post->category }}', '{{ $post->created_at->format('Y-m-d') }}', '{{ $post->creator->name }}', '{{ $post->attachment_url ?? '' }}')">
            <div class="card-stripe {{ $post->category }}"></div>
            <div class="card-body">
                <div class="card-meta">
                    <span class="category-badge {{ $post->category }}">
                        {{ $post->category == 'urgent' ? 'عاجل' : ($post->category == 'academic' ? 'أكاديمي' : 'عام') }}
                    </span>
                    <span style="font-size: 0.85rem; color: var(--text-secondary);">{{ $post->created_at->diffForHumans() }}</span>
                </div>

                <h3 class="card-title">{{ $post->title }}</h3>
                <p class="card-content">{{ Str::limit($post->content, 200) }}</p>

                <div class="card-footer">
                    <div class="author-info">
                        <div class="author-avatar">{{ mb_substr($post->creator->name, 0, 1) }}</div>
                        <div>
                            <div class="author-name">{{ $post->creator->name }}</div>
                            <div class="author-role">الناشر</div>
                        </div>
                    </div>
                    @if($post->attachment_path)
                    <div class="attachment-badge">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"></path>
                        </svg>
                        مرفق
                    </div>
                    @endif
                </div>
            </div>
        </div>
        @endforeach

        <!-- Pagination -->
        <div style="margin-top: 2rem;">
            {{ $announcements->withQueryString()->links() }}
        </div>
    </div>
    @else
    <div class="empty-state">
        <div class="empty-icon">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
            </svg>
        </div>
        <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem;">لا توجد إعلانات</h3>
        <p style="color: var(--text-secondary);">لا توجد أخبار في هذا التصنيف حالياً</p>
    </div>
    @endif

    <!-- Modal -->
    <div x-show="showModal" class="modal-overlay" style="display: none;" x-transition.opacity @click.self="showModal = false">
        <div class="modal-container" @click.stop>
            <div class="modal-header">
                <div>
                    <span class="category-badge" :class="modalData.category" x-text="modalData.category == 'urgent' ? 'عاجل' : (modalData.category == 'academic' ? 'أكاديمي' : 'عام')"></span>
                    <h2 style="font-size: 1.25rem; font-weight: 700; margin-top: 0.75rem;" x-text="modalData.title"></h2>
                    <div style="font-size: 0.85rem; color: var(--text-secondary); margin-top: 0.5rem;">
                        <span x-text="modalData.date"></span> • بواسطة: <span x-text="modalData.author"></span>
                    </div>
                </div>
                <button class="modal-close" @click="showModal = false">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </button>
            </div>
            <div class="modal-body">
                <div class="modal-content" x-html="modalData.content"></div>
                <template x-if="modalData.attachment">
                    <div class="modal-attachment">
                        <div style="font-weight: 600; margin-bottom: 0.75rem; display: flex; align-items: center; gap: 0.5rem;">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"></path>
                            </svg>
                            مرفق
                        </div>
                        <!-- Check if it's an image -->
                        <template x-if="modalData.attachmentType === 'image'">
                            <img :src="modalData.attachment" alt="مرفق" style="max-width: 100%; border-radius: 8px;">
                        </template>
                        <!-- For PDF and other documents -->
                        <template x-if="modalData.attachmentType !== 'image'">
                            <a :href="modalData.attachment" target="_blank" download style="display: flex; align-items: center; gap: 1rem; padding: 1rem; background: white; border: 2px solid #e2e8f0; border-radius: 12px; text-decoration: none; transition: all 0.2s;">
                                <div style="width: 48px; height: 48px; background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%); border-radius: 12px; display: flex; align-items: center; justify-content: center; color: #dc2626;">
                                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                                        <polyline points="14 2 14 8 20 8"></polyline>
                                        <line x1="16" y1="13" x2="8" y2="13"></line>
                                        <line x1="16" y1="17" x2="8" y2="17"></line>
                                    </svg>
                                </div>
                                <div style="flex: 1;">
                                    <div style="font-weight: 700; color: var(--text-primary); margin-bottom: 0.25rem;">ملف مرفق</div>
                                    <div style="font-size: 0.85rem; color: var(--text-secondary);">اضغط لفتح أو تنزيل الملف</div>
                                </div>
                                <div style="color: var(--primary-color);">
                                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                                        <polyline points="7 10 12 15 17 10"></polyline>
                                        <line x1="12" y1="15" x2="12" y2="3"></line>
                                    </svg>
                                </div>
                            </a>
                        </template>
                    </div>
                </template>
            </div>
        </div>
    </div>

</div>

@endsection