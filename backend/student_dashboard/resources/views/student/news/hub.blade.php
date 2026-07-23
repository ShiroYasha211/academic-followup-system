@extends('layouts.student')

@section('title', 'الأخبار والإعلانات')

@section('content')
<style>
    .news-hero {
        background: linear-gradient(135deg, #0f172a 0%, #1e293b 55%, #334155 100%);
        border-radius: 24px;
        padding: 2rem;
        color: #fff;
        position: relative;
        overflow: hidden;
        margin-bottom: 1.5rem;
    }

    .news-hero::after {
        content: '';
        position: absolute;
        inset: auto -8% -35% auto;
        width: 280px;
        height: 280px;
        background: radial-gradient(circle, rgba(96, 165, 250, 0.35) 0%, rgba(96, 165, 250, 0) 70%);
    }

    .news-summary-card {
        border: 1px solid #e2e8f0;
        border-radius: 20px;
        transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
        text-decoration: none;
        color: inherit;
    }

    .news-summary-card:hover {
        transform: translateY(-3px);
        box-shadow: 0 18px 30px -24px rgba(15, 23, 42, 0.45);
    }

    .news-summary-card.active {
        border-color: #0d6efd;
        box-shadow: 0 20px 35px -26px rgba(13, 110, 253, 0.55);
    }

    .news-feed-card {
        border: 1px solid #e2e8f0;
        border-radius: 22px;
        overflow: hidden;
    }

    .news-feed-card.unread {
        border-color: #93c5fd;
        box-shadow: 0 18px 35px -28px rgba(59, 130, 246, 0.6);
    }

    .source-chip {
        font-size: 0.78rem;
        font-weight: 700;
        padding: 0.45rem 0.75rem;
        border-radius: 999px;
    }

    .meta-text {
        color: #64748b;
        font-size: 0.92rem;
    }

    .body-preview {
        color: #334155;
        line-height: 1.8;
        white-space: pre-line;
    }

    .empty-state {
        border: 1px dashed #cbd5e1;
        border-radius: 24px;
        background: #f8fafc;
    }
</style>

@php
    $sourceMeta = collect($sources)->keyBy('key');
    $activeSource = $sourceMeta->get($source);
    $allCount = $stats['all'] ?? 0;
@endphp

<div class="news-hero shadow-sm">
    <div class="position-relative" style="z-index: 1;">
        <div class="d-flex flex-column flex-lg-row align-items-lg-end justify-content-between gap-3">
            <div>
                <span class="badge text-bg-light text-dark mb-3 px-3 py-2 rounded-pill">مركز موحد للأخبار والإعلانات</span>
                <h1 class="h2 fw-bold mb-2">كل تحديثات الطالب من مكان واحد</h1>
                <p class="mb-0 text-white-50">
                    يعرض هذا القسم أخبار المركز الإخباري والإعلانات الإدارية وإعلانات الدكتور وإعلانات المندوب مع إمكانية التصفية السريعة حسب المصدر.
                </p>
            </div>

            <div class="text-lg-end">
                <div class="small text-white-50 mb-1">إجمالي العناصر الحالية</div>
                <div class="display-6 fw-bold mb-0">{{ $allCount }}</div>
            </div>
        </div>
    </div>
</div>

<div class="row g-3 mb-4">
    <div class="col-12 col-md-6 col-xl-3">
        <a href="{{ route('student.news.index', ['source' => 'all']) }}" class="card h-100 news-summary-card {{ $source === 'all' ? 'active' : '' }}">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-start mb-3">
                    <span class="source-chip bg-primary-subtle text-primary">الكل</span>
                    <i class="fa-solid fa-layer-group text-primary fs-4"></i>
                </div>
                <div class="display-6 fw-bold mb-1">{{ $stats['all'] }}</div>
                <div class="fw-semibold mb-2">جميع المصادر</div>
                <div class="meta-text">عرض كامل للأخبار والإعلانات مهما كان مصدرها.</div>
            </div>
        </a>
    </div>

    @foreach ($sources as $entry)
        <div class="col-12 col-md-6 col-xl-3">
            <a href="{{ route('student.news.index', ['source' => $entry['key']]) }}" class="card h-100 news-summary-card {{ $source === $entry['key'] ? 'active' : '' }}">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start mb-3">
                        <span class="source-chip bg-light text-dark">{{ $entry['label'] }}</span>
                        <i class="fa-solid {{ $entry['key'] === 'administration' ? 'fa-building-shield text-primary' : ($entry['key'] === 'doctor' ? 'fa-user-doctor text-success' : 'fa-users text-warning') }} fs-4"></i>
                    </div>
                    <div class="display-6 fw-bold mb-1">{{ $stats[$entry['key']] ?? 0 }}</div>
                    <div class="fw-semibold mb-2">{{ $entry['label'] }}</div>
                    <div class="meta-text">{{ $entry['description'] }}</div>
                </div>
            </a>
        </div>
    @endforeach
</div>

<div class="card border-0 shadow-sm mb-4">
    <div class="card-body">
        <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-center gap-3">
            <div>
                <div class="small text-secondary mb-1">الفئة الحالية</div>
                <div class="h5 mb-1 fw-bold">{{ $source === 'all' ? 'جميع الأخبار والإعلانات' : $activeSource['label'] }}</div>
                <div class="text-secondary">{{ $source === 'all' ? 'استخدم التبويبات أو البطاقات بالأعلى للتنقل السريع بين المصادر.' : $activeSource['description'] }}</div>
            </div>

            <ul class="nav nav-pills gap-2">
                <li class="nav-item">
                    <a class="nav-link {{ $source === 'all' ? 'active' : '' }}" href="{{ route('student.news.index', ['source' => 'all']) }}">الكل</a>
                </li>
                @foreach ($sources as $entry)
                    <li class="nav-item">
                        <a class="nav-link {{ $source === $entry['key'] ? 'active' : '' }}" href="{{ route('student.news.index', ['source' => $entry['key']]) }}">{{ $entry['label'] }}</a>
                    </li>
                @endforeach
            </ul>
        </div>
    </div>
</div>

@if ($items->count())
    <div class="d-flex flex-column gap-4">
        @foreach ($items as $item)
            @php
                $modalId = 'newsItemModal' . preg_replace('/[^A-Za-z0-9]/', '', $item['id']);
                $badgeClass = match ($item['badge_class']) {
                    'badge-danger' => 'text-bg-danger',
                    'badge-warning' => 'text-bg-warning',
                    'badge-success' => 'text-bg-success',
                    'badge-info' => 'text-bg-info',
                    'badge-admin' => 'text-bg-primary',
                    default => 'text-bg-secondary',
                };
            @endphp
            <div class="card news-feed-card {{ $item['is_unread'] ? 'unread' : '' }}">
                <div class="card-body p-4">
                    <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
                        <div class="d-flex align-items-start gap-3">
                            <div class="rounded-circle d-flex align-items-center justify-content-center flex-shrink-0" style="width: 52px; height: 52px; background: #eff6ff; color: #2563eb;">
                                <i class="fa-solid {{ $item['icon'] }}"></i>
                            </div>
                            <div>
                                <div class="d-flex flex-wrap align-items-center gap-2 mb-2">
                                    <span class="badge rounded-pill text-bg-light">{{ $item['source_label'] }}</span>
                                    <span class="badge rounded-pill {{ $badgeClass }}">{{ $item['badge'] }}</span>
                                    @if ($item['is_unread'])
                                        <span class="badge rounded-pill text-bg-primary">غير مقروء</span>
                                    @endif
                                </div>
                                <h2 class="h4 fw-bold mb-2">{{ $item['title'] }}</h2>
                                <div class="d-flex flex-wrap gap-3 meta-text">
                                    <span><i class="fa-regular fa-clock me-1"></i>{{ $item['created_at_human'] }}</span>
                                    <span><i class="fa-regular fa-user me-1"></i>{{ $item['author_name'] }}</span>
                                    @if ($item['subject_name'])
                                        <span><i class="fa-solid fa-book-open me-1"></i>{{ $item['subject_name'] }}</span>
                                    @endif
                                    <span><i class="fa-regular fa-folder-open me-1"></i>{{ $item['channel_label'] }}</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <p class="body-preview mb-3">{{ $item['excerpt'] }}</p>

                    <div class="d-flex flex-wrap gap-2">
                        @if ($item['open_mode'] === 'link' && $item['detail_url'])
                            <a href="{{ $item['detail_url'] }}" class="btn btn-primary">
                                <i class="fa-solid fa-arrow-up-right-from-square me-1"></i>
                                فتح التفاصيل
                            </a>
                        @else
                            <button type="button" class="btn btn-outline-primary" data-bs-toggle="modal" data-bs-target="#{{ $modalId }}">
                                <i class="fa-regular fa-eye me-1"></i>
                                عرض الإعلان
                            </button>
                        @endif

                        @if ($item['attachment_url'])
                            <a href="{{ $item['attachment_url'] }}" target="_blank" class="btn btn-outline-secondary">
                                <i class="fa-solid fa-paperclip me-1"></i>
                                المرفق
                            </a>
                        @endif

                        @if ($item['can_vote'] && $item['detail_url'])
                            <a href="{{ $item['detail_url'] }}" class="btn btn-outline-success">
                                <i class="fa-solid fa-square-poll-vertical me-1"></i>
                                التصويت
                            </a>
                        @endif
                    </div>
                </div>
            </div>

            @if ($item['open_mode'] !== 'link')
                <div class="modal fade" id="{{ $modalId }}" tabindex="-1" aria-hidden="true">
                    <div class="modal-dialog modal-lg modal-dialog-scrollable">
                        <div class="modal-content border-0 shadow">
                            <div class="modal-header">
                                <div>
                                    <div class="small text-secondary mb-1">{{ $item['source_label'] }} / {{ $item['channel_label'] }}</div>
                                    <h3 class="modal-title fs-4 mb-0">{{ $item['title'] }}</h3>
                                </div>
                                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                            </div>
                            <div class="modal-body">
                                <div class="d-flex flex-wrap gap-3 meta-text mb-3">
                                    <span><i class="fa-regular fa-clock me-1"></i>{{ $item['created_at_human'] }}</span>
                                    <span><i class="fa-regular fa-user me-1"></i>{{ $item['author_name'] }}</span>
                                    @if ($item['subject_name'])
                                        <span><i class="fa-solid fa-book-open me-1"></i>{{ $item['subject_name'] }}</span>
                                    @endif
                                </div>
                                <div class="body-preview">{{ $item['body'] }}</div>
                            </div>
                            <div class="modal-footer justify-content-between">
                                @if ($item['attachment_url'])
                                    <a href="{{ $item['attachment_url'] }}" target="_blank" class="btn btn-outline-secondary">
                                        <i class="fa-solid fa-paperclip me-1"></i>
                                        فتح المرفق
                                    </a>
                                @else
                                    <span class="text-secondary small">لا يوجد مرفق لهذا العنصر.</span>
                                @endif
                                <button type="button" class="btn btn-primary" data-bs-dismiss="modal">إغلاق</button>
                            </div>
                        </div>
                    </div>
                </div>
            @endif
        @endforeach
    </div>

    <div class="mt-4">
        {{ $items->links() }}
    </div>
@else
    <div class="empty-state text-center p-5">
        <div class="mb-3">
            <i class="fa-regular fa-newspaper fs-1 text-secondary"></i>
        </div>
        <h2 class="h4 fw-bold mb-2">لا توجد عناصر حالية في هذا القسم</h2>
        <p class="text-secondary mb-0">جرّب تغيير المصدر من الأعلى أو انتظر حتى يتم نشر إعلان جديد.</p>
    </div>
@endif
@endsection
