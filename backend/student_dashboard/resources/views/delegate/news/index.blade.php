@extends('layouts.delegate')

@section('title', 'المركز الإخباري')

@section('content')
<style>
    :root {
        --news-primary: #4f46e5;
        --news-secondary: #7c3aed;
        --news-accent: #10b981;
        --news-warning: #f59e0b;
        --news-danger: #ef4444;
        --card-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
        --card-hover-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
    }

    /* Header Section */
    .news-header {
        background: linear-gradient(135deg, var(--news-primary) 0%, var(--news-secondary) 100%);
        border-radius: 24px;
        padding: 3rem 2rem;
        color: white;
        margin-bottom: 2.5rem;
        position: relative;
        overflow: hidden;
        box-shadow: var(--card-shadow);
    }

    .news-header::before {
        content: '';
        position: absolute;
        top: -50%;
        right: -10%;
        width: 400px;
        height: 400px;
        background: rgba(255, 255, 255, 0.1);
        border-radius: 50%;
    }

    .news-header-content {
        position: relative;
        z-index: 1;
    }

    .news-title {
        font-size: 2.5rem;
        font-weight: 800;
        margin-bottom: 0.5rem;
    }

    .news-subtitle {
        font-size: 1.1rem;
        opacity: 0.9;
        max-width: 600px;
    }

    /* Grid Layout */
    .news-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
        gap: 2rem;
    }

    /* News Card */
    .news-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        display: flex;
        flex-direction: column;
        height: 100%;
        position: relative;
    }

    .news-card:hover {
        transform: translateY(-8px);
        box-shadow: var(--card-hover-shadow);
    }

    .news-card.unread {
        border-right: 6px solid var(--news-primary);
    }

    .unread-dot {
        position: absolute;
        top: 1.5rem;
        left: 1.5rem;
        width: 12px;
        height: 12px;
        background-color: var(--news-danger);
        border-radius: 50%;
        box-shadow: 0 0 0 4px rgba(239, 68, 68, 0.2);
    }

    .card-banner {
        height: 8px;
        width: 100%;
    }

    .type-announcement .card-banner { background: var(--news-primary); }
    .type-exam .card-banner { background: var(--news-danger); }
    .type-poll .card-banner { background: var(--news-accent); }
    .type-assignment .card-banner { background: var(--news-warning); }

    .card-content {
        padding: 2rem;
        flex: 1;
        display: flex;
        flex-direction: column;
    }

    .card-meta {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        margin-bottom: 1rem;
    }

    .type-badge {
        padding: 0.35rem 0.75rem;
        border-radius: 99px;
        font-size: 0.75rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.025em;
    }

    .type-announcement .type-badge { background: #e0e7ff; color: #4338ca; }
    .type-exam .type-badge { background: #fee2e2; color: #b91c1c; }
    .type-poll .type-badge { background: #d1fae5; color: #065f46; }
    .type-assignment .type-badge { background: #fef3c7; color: #92400e; }

    .card-date {
        font-size: 0.85rem;
        color: #64748b;
        font-weight: 500;
    }

    .card-title {
        font-size: 1.25rem;
        font-weight: 800;
        color: #1e293b;
        margin-bottom: 1rem;
        line-height: 1.4;
    }

    .card-excerpt {
        color: #475569;
        font-size: 0.95rem;
        line-height: 1.6;
        margin-bottom: 1.5rem;
        flex: 1;
    }

    .card-footer {
        padding: 1.5rem 2rem;
        border-top: 1px solid #f1f5f9;
        background: #f8fafc;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .view-link {
        font-weight: 700;
        color: var(--news-primary);
        text-decoration: none;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        transition: gap 0.2s;
    }

    .view-link:hover {
        gap: 0.75rem;
    }

    .attachments-badge {
        display: flex;
        align-items: center;
        gap: 0.25rem;
        font-size: 0.8rem;
        color: #64748b;
        background: white;
        padding: 0.25rem 0.6rem;
        border-radius: 8px;
        border: 1px solid #e2e8f0;
    }

    /* Empty State */
    .empty-state {
        text-align: center;
        padding: 5rem 2rem;
        background: white;
        border-radius: 24px;
        border: 2px dashed #e2e8f0;
    }

    .empty-icon {
        font-size: 4rem;
        color: #cbd5e1;
        margin-bottom: 1.5rem;
    }

    .empty-title {
        font-size: 1.5rem;
        font-weight: 700;
        color: #475569;
        margin-bottom: 0.5rem;
    }

    @media (max-width: 768px) {
        .news-header {
            padding: 2rem 1.5rem;
        }
        .news-title {
            font-size: 1.8rem;
        }
        .news-grid {
            grid-template-columns: 1fr;
        }
    }
</style>

<div class="news-header">
    <div class="news-header-content">
        <h1 class="news-title">المركز الإخباري الرقمي</h1>
        <p class="news-subtitle">مرحباً بك في وجهتك الرسمية لكافة أخبار الكلية، الاستطلاعات، والقرارات الإدارية الهامة. ابقَ على اطلاع دائم بكل ما يخص مسيرتك الأكاديمية.</p>
    </div>
</div>

<div class="container-fluid">
    @if($news->count() > 0)
    <div class="news-grid">
        @foreach($news as $item)
        <div class="news-card {{ $item->read_at ? '' : 'unread' }} type-{{ $item->type }}">
            @if(!$item->read_at)
            <div class="unread-dot" title="خبر غير مقروء"></div>
            @endif
            
            <div class="card-banner"></div>
            
            <div class="card-content">
                <div class="card-meta">
                    <span class="type-badge">
                        @switch($item->type)
                            @case('announcement') إعلان إداري @break
                            @case('exam') تنبيه اختبار @break
                            @case('poll') استطلاع رأي @break
                            @case('assignment') تكليف جديد @break
                            @default تنبيه @break
                        @endswitch
                    </span>
                    <span class="card-date">{{ $item->created_at->diffForHumans() }}</span>
                </div>
                
                <h3 class="card-title">{{ $item->title }}</h3>
                <p class="card-excerpt">{{ Str::limit($item->message, 150) }}</p>
                
                <div class="card-actions">
                    <a href="{{ $item->batch_id ? route('delegate.news.show', $item->batch_id) : '#' }}" class="view-link" @if(!$item->batch_id) style="opacity: 0.5; pointer-events: none;" @endif>
                        <span>اقرأ التفاصيل</span>
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"></path><path d="m12 5 7 7-7 7"></path></svg>
                    </a>
                </div>
            </div>
            
            <div class="card-footer">
                <div style="display: flex; gap: 0.5rem;">
                    @if($item->attachment_path)
                    <div class="attachments-badge" title="يوجد مرفقات">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="m21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l8.57-8.57A4 4 0 1 1 18 8.84l-8.59 8.57a2 2 0 0 1-2.83-2.83l8.49-8.48"></path></svg>
                        <span>مرفق</span>
                    </div>
                    @endif
                    
                    @if($item->type === 'poll')
                    <div class="attachments-badge" style="border-color: var(--news-accent); color: var(--news-accent);">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M12 20h9"></path><path d="m16.5 3.5 3 3L7 19l-4 1 1-4Z"></path></svg>
                        <span>تصويت</span>
                    </div>
                    @endif
                </div>
                
                <div style="font-size: 0.8rem; color: #94a3b8;">
                    #{{ $item->id }}
                </div>
            </div>
        </div>
        @endforeach
    </div>

    <div class="mt-5 d-flex justify-content-center">
        {{ $news->links() }}
    </div>
    @else
    <div class="empty-state">
        <div class="empty-icon">
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg>
        </div>
        <h2 class="empty-title">لا توجد أخبار حالياً</h2>
        <p class="text-secondary">سيظهر هنا كافة الإعلانات والأخبار الرسمية عند نشرها.</p>
    </div>
    @endif
</div>
@endsection
