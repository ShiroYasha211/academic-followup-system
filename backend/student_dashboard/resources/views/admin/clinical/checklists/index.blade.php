@extends('layouts.admin')
@section('title', 'قوائم التقييم (عام)')
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
    }

    .section-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.25rem;
        padding-bottom: 0.75rem;
        border-bottom: 1px solid #f1f5f9;
        flex-wrap: wrap;
        gap: 1rem;
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
        grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
        gap: 1.25rem;
    }

    .checklist-card {
        background: #fafbfe;
        border: 2px solid #e0e7ff; /* Highlighted border for standard items */
        border-radius: 14px;
        padding: 1.25rem;
        transition: all 0.2s;
        position: relative;
    }

    .standard-badge {
        position: absolute;
        top: -12px;
        right: 15px;
        background: linear-gradient(135deg, #f59e0b, #d97706);
        color: white;
        font-size: 0.7rem;
        font-weight: bold;
        padding: 3px 10px;
        border-radius: 20px;
        box-shadow: 0 2px 5px rgba(245, 158, 11, 0.3);
    }

    .checklist-card h4 {
        font-size: 1.1rem;
        font-weight: 700;
        margin: 0.5rem 0 0.5rem 0;
        color: var(--text-primary);
    }

    .checklist-meta {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
        margin-bottom: 0.75rem;
    }

    .meta-badge {
        padding: 0.2rem 0.6rem;
        border-radius: 6px;
        font-size: 0.75rem;
        font-weight: 600;
    }

    .meta-badge.skill { background: #e0e7ff; color: #4338ca; }
    .meta-badge.time { background: #fef3c7; color: #92400e; }
    .meta-badge.marks { background: #d1fae5; color: #065f46; }

    .checklist-actions {
        display: flex;
        gap: 0.5rem;
        margin-top: 1rem;
        padding-top: 1rem;
        border-top: 1px solid #e2e8f0;
    }

    .action-btn {
        padding: 0.4rem 0.8rem;
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

    .action-btn.edit { background: #eff6ff; color: #3b82f6; }
    .action-btn.edit:hover { background: #dbeafe; color: #2563eb; text-decoration: none;}
    
    .action-btn.delete { background: #fef2f2; color: #ef4444; }
    .action-btn.delete:hover { background: #fee2e2; }

    .alert-banner {
        padding: 0.85rem 1.25rem;
        border-radius: 12px;
        margin-bottom: 1.5rem;
        font-weight: 600;
        font-size: 0.9rem;
    }
    .alert-banner.success { background: #d1fae5; color: #065f46; border: 1px solid #6ee7b7; }
</style>

<div class="clinical-page-header">
    <div class="right-side">
        <h1>الثوابت: قوائم التقييم السريري 📋</h1>
        <p>إنشاء وإدارة قوائم الفحص السريرية الأساسية المتاحة لجميع الدكاترة والطلاب</p>
    </div>
    <div class="left-side">
        <a href="{{ route('admin.clinical.checklists.create') }}" class="btn-primary-action">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            إنشاء قائمة أساسية جديدة
        </a>
        <a href="{{ route('admin.dashboard') }}" class="btn-back">لوحة الإدارة</a>
    </div>
</div>

@if(session('success'))<div class="alert-banner success">✅ {{ session('success') }}</div>@endif
@if(session('error'))<div class="alert-banner" style="background:#fef2f2; color:#ef4444; border:1px solid #fca5a5;">❌ {{ session('error') }}</div>@endif

<div class="card-section">
    <div class="section-header">
        <h3 class="section-title">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
                <line x1="16" y1="13" x2="8" y2="13"></line>
                <line x1="16" y1="17" x2="8" y2="17"></line>
                <polyline points="10 9 9 9 8 9"></polyline>
            </svg>
            القوائم الأساسية
        </h3>
        
        <form action="{{ route('admin.clinical.checklists.index') }}" method="GET" style="display: flex; gap: 0.5rem;">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="بحث بالاسم..." class="form-control" style="border-radius:8px; padding:0.4rem 0.75rem; border:1px solid #cbd5e1; outline:none;" />
            <select name="skill_type" class="form-control" style="border-radius:8px; padding:0.4rem 0.75rem; border:1px solid #cbd5e1; outline:none;">
                <option value="">جميع الأنواع</option>
                <option value="history_taking" {{ request('skill_type') == 'history_taking' ? 'selected' : '' }}>أخذ قصة</option>
                <option value="clinical_examination" {{ request('skill_type') == 'clinical_examination' ? 'selected' : '' }}>فحص سريري</option>
                <option value="procedure" {{ request('skill_type') == 'procedure' ? 'selected' : '' }}>إجراء طبي</option>
                <option value="communication" {{ request('skill_type') == 'communication' ? 'selected' : '' }}>مهارات تواصل</option>
            </select>
            <button type="submit" class="btn-primary-action" style="padding: 0.4rem 0.8rem;">بحث</button>
            @if(request()->has('search') || request()->has('skill_type'))
                <a href="{{ route('admin.clinical.checklists.index') }}" class="btn-back" style="padding: 0.4rem 0.8rem;">إلغاء</a>
            @endif
        </form>
    </div>

    <div class="checklist-grid">
        @forelse($checklists as $cl)
        <div class="checklist-card">
            <div class="standard-badge">👑 أساسي (Standard)</div>
            <h4>{{ $cl->title }}</h4>
            <div class="checklist-meta">
                <span class="meta-badge skill">{{ $cl->skill_label }}</span>
                <span class="meta-badge time">⏱ {{ $cl->time_limit_minutes ?? 'مفتوح' }} {{ $cl->time_limit_minutes ? 'دقيقة' : '' }}</span>
                <span class="meta-badge marks">🏆 {{ $cl->total_marks }} درجة</span>
            </div>
            @if($cl->description)<p style="font-size:0.85rem; color:var(--text-secondary); margin:0; line-height: 1.5;">{{ Str::limit($cl->description, 90) }}</p>@endif
            
            <div class="checklist-actions">
                <a href="{{ route('admin.clinical.checklists.show', $cl->id) }}" class="action-btn edit" style="background:#f3f4f6; color:#4b5563;">👁 معاينة</a>
                <a href="{{ route('admin.clinical.checklists.edit', $cl->id) }}" class="action-btn edit">✏️ تعديل</a>
                <form action="{{ route('admin.clinical.checklists.destroy', $cl->id) }}" method="POST" style="display:inline;" onsubmit="return confirm('تنبيه: حذف هذه القائمة سيحذفها من النظام بالكامل، وقد يعطل التقييمات المرتبطة بها. هل أنت متأكد؟')">
                    @csrf @method('DELETE')
                    <button type="submit" class="action-btn delete">🗑 حذف</button>
                </form>
            </div>
        </div>
        @empty
        <div style="grid-column: 1 / -1; text-align:center; color:var(--text-secondary); padding:4rem;">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="2" style="margin-bottom: 1rem;">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
            </svg>
            <p>لا توجد قوائم تقييم أساسية حالياً.</p>
        </div>
        @endforelse
    </div>

    @if($checklists->hasPages())
    <div style="margin-top: 2rem; display:flex; justify-content:center;">
        {{ $checklists->links() }}
    </div>
    @endif
</div>
@endsection
