@extends('layouts.admin')
@section('title', 'معاينة قائمة التقييم')
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

    .card-section {
        background: white;
        border-radius: 18px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
        margin-bottom: 1.5rem;
    }

    .meta-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 1.5rem;
        margin-bottom: 1rem;
    }

    .meta-item {
        background: #f8fafc;
        padding: 1rem;
        border-radius: 12px;
        border: 1px solid #e2e8f0;
    }

    .meta-item .label {
        font-size: 0.85rem;
        color: var(--text-secondary);
        font-weight: 600;
        margin-bottom: 0.4rem;
    }

    .meta-item .value {
        font-size: 1.1rem;
        font-weight: 700;
        color: var(--text-primary);
    }

    .item-block {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        padding: 1rem;
        margin-bottom: 1rem;
    }

    .item-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        background: white;
        padding: 0.75rem 1rem;
        border-radius: 8px;
        border: 1px solid #e2e8f0;
        font-weight: 700;
        color: var(--text-primary);
    }

    .item-marks {
        background: #dbeafe;
        color: #1e40af;
        padding: 0.25rem 0.6rem;
        border-radius: 6px;
        font-size: 0.85rem;
    }

    .sub-items-list {
        margin-top: 0.75rem;
        padding-right: 1.5rem;
        border-right: 2px dashed #cbd5e1;
    }

    .sub-item-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        background: white;
        padding: 0.6rem 1rem;
        border-radius: 8px;
        border: 1px solid #e2e8f0;
        margin-bottom: 0.5rem;
        font-size: 0.9rem;
        color: var(--text-secondary);
    }

    .sub-item-marks {
        background: #f1f5f9;
        color: #475569;
        padding: 0.2rem 0.5rem;
        border-radius: 5px;
        font-weight: 600;
        font-size: 0.8rem;
    }
</style>

<div class="clinical-page-header">
    <div class="right-side">
        <h1>معاينة القائمة: {{ $checklist->title }} 👁️</h1>
        <p>عرض تفاصيل وعناصر القائمة الأساسية.</p>
    </div>
    <div class="left-side">
        <a href="{{ route('admin.clinical.checklists.edit', $checklist->id) }}" class="btn-primary-action">
            ✏️ تعديل
        </a>
        <a href="{{ route('admin.clinical.checklists.index') }}" class="btn-back">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg>
            الرجوع
        </a>
    </div>
</div>

<div class="card-section" style="border: 2px solid #e0e7ff; background: #fafbfe;">
    <div class="meta-grid">
        <div class="meta-item">
            <div class="label">نوع المهارة</div>
            <div class="value">{{ $checklist->skill_label }}</div>
        </div>
        <div class="meta-item">
            <div class="label">إعدادات الوقت</div>
            <div class="value">
                @if($checklist->time_limit_minutes)
                    ⏱ {{ $checklist->time_limit_minutes }} دقيقة (OSCE)
                @else
                    مفتوح (مراقب)
                @endif
            </div>
        </div>
        <div class="meta-item">
            <div class="label">إجمالي الدرجات</div>
            <div class="value" style="color: #059669;">🏆 {{ $checklist->total_marks }} درجة</div>
        </div>
        <div class="meta-item">
            <div class="label">التدرب الذاتي للطلاب</div>
            <div class="value">
                @if($checklist->is_practice_allowed)
                    <span style="color:#059669;">✅ مسموح</span>
                @else
                    <span style="color:#dc2626;">❌ غير مسموح</span>
                @endif
            </div>
        </div>
    </div>
    @if($checklist->description)
        <div style="margin-top: 1rem; padding-top: 1rem; border-top: 1px solid #e2e8f0;">
            <div style="font-size:0.85rem; color:var(--text-secondary); font-weight:600; margin-bottom:0.3rem;">الوصف:</div>
            <p style="margin:0; color:var(--text-primary); line-height:1.5;">{{ $checklist->description }}</p>
        </div>
    @endif
</div>

<div class="card-section">
    <h3 style="font-weight:700; margin-bottom:1.25rem; display:flex; align-items:center; gap:0.5rem; color: var(--text-primary);">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color:var(--primary-color);">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
            <polyline points="14 2 14 8 20 8"></polyline>
            <line x1="16" y1="13" x2="8" y2="13"></line>
            <line x1="16" y1="17" x2="8" y2="17"></line>
            <polyline points="10 9 9 9 8 9"></polyline>
        </svg>
        عناصر التقييم القياسية
    </h3>

    @foreach($checklist->items->whereNull('parent_id') as $index => $mainItem)
        <div class="item-block">
            <div class="item-header">
                <div style="display:flex; align-items:center; gap:0.75rem;">
                    <span style="background:#f1f5f9; color:#64748b; padding:0.2rem 0.6rem; border-radius:6px; font-size:0.85rem;">{{ $index + 1 }}</span>
                    <span>{{ $mainItem->description }}</span>
                </div>
                <div class="item-marks">{{ $mainItem->marks }} درجة</div>
            </div>

            @if($mainItem->subItems->count() > 0)
                <div class="sub-items-list">
                    @foreach($mainItem->subItems as $subItem)
                        <div class="sub-item-row">
                            <div><span style="color:#94a3b8; margin-left:0.5rem;">↳</span> {{ $subItem->description }}</div>
                            <div class="sub-item-marks">{{ $subItem->marks }} درجة</div>
                        </div>
                    @endforeach
                </div>
            @endif
        </div>
    @endforeach
</div>
@endsection
