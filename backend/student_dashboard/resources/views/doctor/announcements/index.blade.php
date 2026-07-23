@extends('layouts.doctor')

@section('title', 'إعلانات الدكتور')

@section('content')
<style>
    :root {
        --ann-primary: #4f46e5;
        --ann-warning: #ef4444;
        --ann-quiz: #f59e0b;
        --card-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
        --card-hover-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
    }

    .ann-header {
        background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
        border-radius: 24px;
        padding: 2.5rem 2rem;
        color: white;
        margin-bottom: 2rem;
        position: relative;
        overflow: hidden;
        box-shadow: var(--card-shadow);
    }

    .ann-header::before {
        content: '';
        position: absolute;
        top: -50%;
        right: -10%;
        width: 350px;
        height: 350px;
        background: rgba(255, 255, 255, 0.08);
        border-radius: 50%;
    }

    .ann-header-content {
        position: relative;
        z-index: 1;
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 1rem;
    }

    .ann-title {
        font-size: 2rem;
        font-weight: 800;
        margin-bottom: 0.25rem;
    }

    .ann-subtitle {
        opacity: 0.85;
        font-size: 1rem;
    }

    .btn-create {
        background: rgba(255,255,255,0.2);
        backdrop-filter: blur(10px);
        border: 1px solid rgba(255,255,255,0.3);
        color: white;
        padding: 0.75rem 1.5rem;
        border-radius: 14px;
        font-weight: 700;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        transition: all 0.2s;
    }

    .btn-create:hover {
        background: rgba(255,255,255,0.35);
        color: white;
        transform: translateY(-2px);
    }

    /* Filters */
    .filter-pills {
        display: flex;
        gap: 0.5rem;
        margin-bottom: 2rem;
        flex-wrap: wrap;
    }

    .filter-pill {
        padding: 0.5rem 1.25rem;
        border-radius: 99px;
        font-weight: 600;
        font-size: 0.85rem;
        text-decoration: none;
        border: 2px solid #e2e8f0;
        color: #64748b;
        transition: all 0.2s;
        background: white;
    }

    .filter-pill:hover { border-color: #4f46e5; color: #4f46e5; }
    .filter-pill.active { background: #4f46e5; color: white; border-color: #4f46e5; }
    .filter-pill.active-warning { background: #ef4444; color: white; border-color: #ef4444; }
    .filter-pill.active-quiz { background: #f59e0b; color: white; border-color: #f59e0b; }

    /* Cards Grid */
    .ann-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
        gap: 1.5rem;
    }

    .ann-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        display: flex;
        flex-direction: column;
    }

    .ann-card:hover {
        transform: translateY(-6px);
        box-shadow: var(--card-hover-shadow);
    }

    .ann-card-banner {
        height: 6px;
        width: 100%;
    }

    .ann-card-banner.type-announcement { background: #4f46e5; }
    .ann-card-banner.type-warning { background: #ef4444; }
    .ann-card-banner.type-quiz_alert { background: #f59e0b; }

    .ann-card-body {
        padding: 1.75rem;
        flex: 1;
        display: flex;
        flex-direction: column;
    }

    .ann-card-meta {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        margin-bottom: 1rem;
        flex-wrap: wrap;
    }

    .ann-type-badge {
        padding: 0.3rem 0.75rem;
        border-radius: 99px;
        font-size: 0.75rem;
        font-weight: 700;
    }

    .badge-announcement { background: #e0e7ff; color: #4338ca; }
    .badge-warning { background: #fee2e2; color: #b91c1c; }
    .badge-quiz_alert { background: #fef3c7; color: #92400e; }

    .ann-card-subject {
        font-size: 0.8rem;
        color: #64748b;
        background: #f1f5f9;
        padding: 0.25rem 0.6rem;
        border-radius: 8px;
        font-weight: 600;
    }

    .ann-card-date {
        font-size: 0.8rem;
        color: #94a3b8;
        margin-right: auto;
    }

    .ann-card-title {
        font-size: 1.15rem;
        font-weight: 800;
        color: #1e293b;
        margin-bottom: 0.75rem;
        line-height: 1.5;
    }

    .ann-card-content {
        color: #475569;
        font-size: 0.9rem;
        line-height: 1.7;
        flex: 1;
        margin-bottom: 1rem;
    }

    .ann-card-footer {
        padding: 1.25rem 1.75rem;
        border-top: 1px solid #f1f5f9;
        background: #f8fafc;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .ann-action-btn {
        background: none;
        border: none;
        padding: 0.4rem;
        border-radius: 8px;
        cursor: pointer;
        color: #64748b;
        transition: all 0.2s;
    }

    .ann-action-btn:hover { background: #e2e8f0; }
    .ann-action-btn.danger:hover { background: #fee2e2; color: #ef4444; }

    /* Scheduled Badge */
    .scheduled-badge {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        font-size: 0.75rem;
        color: #f59e0b;
        background: #fffbeb;
        padding: 0.25rem 0.6rem;
        border-radius: 8px;
        border: 1px solid #fde68a;
        font-weight: 600;
    }

    /* Empty State */
    .empty-state {
        text-align: center;
        padding: 5rem 2rem;
        background: white;
        border-radius: 24px;
        border: 2px dashed #e2e8f0;
    }

    .empty-icon { font-size: 4rem; color: #cbd5e1; margin-bottom: 1.5rem; }
    .empty-title { font-size: 1.5rem; font-weight: 700; color: #475569; margin-bottom: 0.5rem; }

    @media (max-width: 768px) {
        .ann-header { padding: 1.5rem; }
        .ann-title { font-size: 1.5rem; }
        .ann-grid { grid-template-columns: 1fr; }
        .ann-header-content { flex-direction: column; align-items: flex-start; }
    }
</style>

<!-- Header -->
<div class="ann-header">
    <div class="ann-header-content">
        <div>
            <h1 class="ann-title"><i class="fa-solid fa-bullhorn me-2"></i>إعلاناتي</h1>
            <p class="ann-subtitle">إدارة الإعلانات والإنذارات وتنبيهات الكويزات لطلابك</p>
        </div>
        <a href="{{ route('doctor.announcements.create') }}" class="btn-create">
            <i class="fa-solid fa-plus"></i>
            إعلان جديد
        </a>
    </div>
</div>

<!-- Filters -->
<div class="filter-pills">
    <a href="{{ route('doctor.announcements.index') }}" class="filter-pill {{ $type === 'all' ? 'active' : '' }}">
        <i class="fa-solid fa-layer-group me-1"></i> الكل
    </a>
    <a href="{{ route('doctor.announcements.index', ['type' => 'announcement']) }}" class="filter-pill {{ $type === 'announcement' ? 'active' : '' }}">
        <i class="fa-solid fa-bullhorn me-1"></i> إعلانات
    </a>
    <a href="{{ route('doctor.announcements.index', ['type' => 'warning']) }}" class="filter-pill {{ $type === 'warning' ? 'active-warning' : '' }}">
        <i class="fa-solid fa-triangle-exclamation me-1"></i> إنذارات
    </a>
    <a href="{{ route('doctor.announcements.index', ['type' => 'quiz_alert']) }}" class="filter-pill {{ $type === 'quiz_alert' ? 'active-quiz' : '' }}">
        <i class="fa-solid fa-clipboard-question me-1"></i> تنبيهات الكويزات
    </a>
</div>

<!-- Grid -->
@if($announcements->count() > 0)
<div class="ann-grid">
    @foreach($announcements as $ann)
    <div class="ann-card">
        <div class="ann-card-banner type-{{ $ann->type }}"></div>
        <div class="ann-card-body">
            <div class="ann-card-meta">
                <span class="ann-type-badge badge-{{ $ann->type }}">
                    <i class="fa-solid {{ $ann->type_icon }} me-1"></i>{{ $ann->type_label }}
                </span>
                <span class="ann-card-subject">{{ $ann->subject->name ?? '—' }}</span>
                <span class="ann-card-date">{{ $ann->created_at->diffForHumans() }}</span>
            </div>

            <h3 class="ann-card-title">{{ $ann->title }}</h3>
            <p class="ann-card-content">{{ Str::limit($ann->content, 120) }}</p>

            @if(!$ann->is_published)
            <div class="scheduled-badge">
                <i class="fa-regular fa-clock"></i>
                مجدول: {{ $ann->published_at?->format('Y-m-d H:i') }}
            </div>
            @endif
        </div>

        <div class="ann-card-footer">
            <div style="display: flex; gap: 0.5rem;">
                @if($ann->attachment_path)
                <a href="{{ $ann->attachment_url }}" target="_blank" class="ann-action-btn" title="عرض المرفق">
                    <i class="fa-solid fa-paperclip"></i>
                </a>
                @endif
            </div>

            <div style="display: flex; gap: 0.35rem;">
                <a href="{{ route('doctor.announcements.edit', $ann) }}" class="ann-action-btn" title="تعديل">
                    <i class="fa-solid fa-pen-to-square"></i>
                </a>
                <form action="{{ route('doctor.announcements.destroy', $ann) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف هذا الإعلان؟')">
                    @csrf
                    @method('DELETE')
                    <button type="submit" class="ann-action-btn danger" title="حذف">
                        <i class="fa-solid fa-trash-can"></i>
                    </button>
                </form>
            </div>
        </div>
    </div>
    @endforeach
</div>

<div class="mt-4 d-flex justify-content-center">
    {{ $announcements->appends(['type' => $type])->links() }}
</div>
@else
<div class="empty-state">
    <div class="empty-icon">
        <i class="fa-solid fa-bullhorn"></i>
    </div>
    <h2 class="empty-title">لا توجد إعلانات حالياً</h2>
    <p class="text-secondary mb-3">قم بإنشاء أول إعلان لطلابك الآن</p>
    <a href="{{ route('doctor.announcements.create') }}" class="btn btn-primary" style="border-radius: 12px; padding: 0.6rem 1.5rem;">
        <i class="fa-solid fa-plus me-1"></i> إعلان جديد
    </a>
</div>
@endif
@endsection
