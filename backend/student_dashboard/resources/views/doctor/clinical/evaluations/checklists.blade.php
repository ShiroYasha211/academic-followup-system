@extends('layouts.doctor')
@section('title', 'قوائم التقييم')
@section('content')
<style>
    .clinical-page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.75rem;
        flex-wrap: wrap;
        gap: 1rem;
    }

    .clinical-page-header .right-side h1 {
        font-size: 1.6rem;
        font-weight: 800;
        color: var(--text-primary);
        margin: 0 0 0.15rem 0;
    }

    .clinical-page-header .right-side p {
        color: var(--text-secondary);
        font-size: 0.9rem;
        margin: 0;
    }

    .clinical-page-header .left-side {
        display: flex;
        gap: 0.75rem;
        align-items: center;
    }

    .btn-back {
        background: white;
        color: var(--text-secondary);
        border: 1.5px solid #e2e8f0;
        padding: 0.55rem 1.1rem;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.88rem;
        transition: all 0.2s;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
    }

    .btn-back:hover {
        border-color: #cbd5e1;
        background: #f8fafc;
        color: var(--text-primary);
        text-decoration: none;
    }

    .btn-primary-action {
        background: linear-gradient(135deg, #4f46e5, #6366f1);
        color: white;
        border: none;
        padding: 0.6rem 1.3rem;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.88rem;
        transition: all 0.25s;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
        box-shadow: 0 2px 8px rgba(79, 70, 229, 0.25);
    }

    .btn-primary-action:hover {
        transform: translateY(-1px);
        box-shadow: 0 4px 14px rgba(79, 70, 229, 0.35);
        color: white;
        text-decoration: none;
    }

    .card-section {
        background: white;
        border-radius: 18px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
    }

    .section-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.25rem;
        padding-bottom: 0.75rem;
        border-bottom: 1px solid #f1f5f9;
    }

    .section-title {
        font-size: 1rem;
        font-weight: 700;
        color: var(--text-primary);
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .checklist-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
        gap: 1rem;
    }

    .checklist-card {
        background: #fafbfe;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        padding: 1.25rem;
        transition: all 0.2s;
    }

    .checklist-card:hover {
        border-color: #c7d2fe;
        box-shadow: 0 2px 12px rgba(79, 70, 229, 0.06);
    }

    .checklist-card h4 {
        font-size: 1rem;
        font-weight: 700;
        margin: 0 0 0.5rem 0;
        color: var(--text-primary);
    }

    .checklist-meta {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
        margin-bottom: 0.75rem;
    }

    .meta-badge {
        padding: 0.2rem 0.5rem;
        border-radius: 5px;
        font-size: 0.78rem;
        font-weight: 600;
    }

    .meta-badge.skill {
        background: #e0e7ff;
        color: #4338ca;
    }

    .meta-badge.time {
        background: #fef3c7;
        color: #92400e;
    }

    .meta-badge.items {
        background: #d1fae5;
        color: #065f46;
    }

    .checklist-actions {
        display: flex;
        gap: 0.5rem;
        margin-top: 0.75rem;
    }

    .action-btn {
        padding: 0.4rem 0.75rem;
        border-radius: 8px;
        font-size: 0.82rem;
        font-weight: 600;
        border: none;
        cursor: pointer;
        transition: all 0.2s;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.3rem;
    }

    .action-btn.edit {
        background: #eff6ff;
        color: #3b82f6;
    }

    .action-btn.edit:hover {
        background: #dbeafe;
        text-decoration: none;
        color: #2563eb;
    }

    .action-btn.delete {
        background: #fef2f2;
        color: #ef4444;
    }

    .action-btn.delete:hover {
        background: #fee2e2;
    }

    .alert-banner {
        padding: 0.85rem 1.25rem;
        border-radius: 12px;
        margin-bottom: 1.5rem;
        font-weight: 600;
        font-size: 0.9rem;
    }

    .alert-banner.success {
        background: #d1fae5;
        color: #065f46;
        border: 1px solid #6ee7b7;
    }
</style>

<div class="clinical-page-header">
    <div class="right-side">
        <h1>قوائم التقييم 📋</h1>
        <p>إنشاء وإدارة قوائم الفحص المعيارية للتقييم السريري المباشر</p>
    </div>
    <div class="left-side">
        <form action="{{ route('doctor.clinical.evaluations.checklists.restore') }}" method="POST" style="display: inline;" onsubmit="return confirm('هل أنت متأكد من رغبتك في استرداد القوائم الأساسية المخفية؟');">
            @csrf
            <button type="submit" class="btn-primary-action" style="background: linear-gradient(135deg, #10b981, #059669);">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"></path>
                    <polyline points="3 3 3 8 8 8"></polyline>
                </svg>
                استرداد الثوابت
            </button>
        </form>
        <a href="{{ route('doctor.clinical.evaluations.checklists.create') }}" class="btn-primary-action">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            إنشاء قائمة جديدة
        </a>
        <a href="{{ route('doctor.clinical.evaluations.start') }}" class="btn-primary-action" style="background: linear-gradient(135deg, #059669, #10b981); box-shadow: 0 2px 8px rgba(5,150,105,0.25);">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polygon points="5 3 19 12 5 21 5 3"></polygon>
            </svg>
            بدء تقييم مباشر
        </a>
        <a href="{{ route('doctor.clinical.index') }}" class="btn-back">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg>
            القسم العملي
        </a>
    </div>
</div>

@if(session('success'))<div class="alert-banner success">✅ {{ session('success') }}</div>@endif

<div class="card-section">
    <div class="section-header">
        <h3 class="section-title">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                <path d="M9 11l3 3L22 4"></path>
                <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path>
            </svg>
            القوائم المتاحة
        </h3>
    </div>

    <div class="checklist-grid">
        @forelse($checklists as $cl)
        <div class="checklist-card">
            <h4 style="display: flex; align-items: center; justify-content: space-between;">
                {{ $cl->title }}
                @if(is_null($cl->doctor_id))
                    <span style="background: #e0e7ff; color: #4338ca; padding: 0.2rem 0.5rem; border-radius: 6px; font-size: 0.75rem; font-weight: 700;">أساسي</span>
                @endif
            </h4>
            <div class="checklist-meta">
                <span class="meta-badge skill">{{ $cl->skill_label }}</span>
                <span class="meta-badge time">⏱ {{ $cl->time_limit_minutes }} دقيقة</span>
                <span class="meta-badge items">{{ $cl->items_count }} عنصر</span>
            </div>
            <div style="font-size:0.78rem; color:#7c3aed; font-weight:700; margin-top:0.2rem; margin-bottom:0.35rem;">
                المنشئ: {{ $cl->creator?->name ?? $cl->doctor?->name ?? 'غير محدد' }}
            </div>
            @if($cl->description)<p style="font-size:0.82rem; color:var(--text-secondary); margin:0;">{{ Str::limit($cl->description, 80) }}</p>@endif
            <div class="checklist-actions">
                <a href="{{ route('doctor.clinical.evaluations.checklists.edit', $cl->id) }}" class="action-btn edit">✏️ تعديل</a>
                <form action="{{ route('doctor.clinical.evaluations.checklists.destroy', $cl->id) }}" method="POST" style="display:inline;" onsubmit="return confirm('هل أنت متأكد؟')">
                    @csrf @method('DELETE')
                    <button type="submit" class="action-btn delete">🗑 حذف</button>
                </form>
            </div>
        </div>
        @empty
        <div style="grid-column: 1 / -1; text-align:center; color:var(--text-secondary); padding:3rem;">
            <p>لم تقم بإنشاء أي قائمة تقييم بعد.</p>
        </div>
        @endforelse
    </div>
</div>
@endsection
