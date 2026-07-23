@extends('layouts.student')
@section('title', 'الاختبارات السريرية التجريبية')
@section('content')
<style>
    .mock-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 2rem;
        flex-wrap: wrap;
        gap: 1rem;
    }

    .mock-header .right-side h1 {
        font-size: 1.6rem;
        font-weight: 800;
        color: var(--text-primary);
        margin: 0 0 0.25rem 0;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .mock-header .right-side p {
        color: #64748b;
        font-size: 0.95rem;
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
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
        transition: all 0.2s;
    }

    .btn-back:hover {
        border-color: #cbd5e1;
        background: #f8fafc;
        color: var(--text-primary);
        text-decoration: none;
    }

    /* Checklists Grid */
    .checklist-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
        gap: 1.5rem;
        margin-bottom: 3rem;
    }

    .opt-card {
        background: white;
        border-radius: 16px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        display: flex;
        flex-direction: column;
        justify-content: space-between;
    }

    .opt-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 12px 24px rgba(0, 0, 0, 0.04);
        border-color: #c7d2fe;
    }

    .opt-icon {
        width: 48px;
        height: 48px;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: #eef2ff;
        color: #4f46e5;
        margin-bottom: 1rem;
    }

    .opt-title {
        font-size: 1.15rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.5rem;
        line-height: 1.4;
    }

    .opt-desc {
        color: #64748b;
        font-size: 0.9rem;
        margin-bottom: 1.5rem;
        line-height: 1.5;
    }

    .btn-start {
        width: 100%;
        padding: 0.75rem;
        background: #4f46e5;
        color: white;
        border: none;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.95rem;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        text-decoration: none;
        transition: background 0.2s;
    }

    .btn-start:hover {
        background: #4338ca;
        color: white;
    }

    /* History Section */
    .history-section {
        background: white;
        border-radius: 18px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
    }

    .history-header {
        font-size: 1.2rem;
        font-weight: 800;
        color: var(--text-primary);
        margin-bottom: 1.5rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .history-list {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    .history-card {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        padding: 1.25rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 1rem;
        transition: border-color 0.2s;
    }

    .history-card:hover {
        border-color: #cbd5e1;
    }

    .h-info {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
    }

    .h-title {
        font-weight: 700;
        color: var(--text-primary);
    }

    .h-meta {
        font-size: 0.85rem;
        color: #64748b;
        display: flex;
        gap: 1rem;
        align-items: center;
    }

    .h-meta span {
        display: flex;
        align-items: center;
        gap: 0.35rem;
    }

    .h-grade {
        padding: 0.4rem 0.8rem;
        border-radius: 8px;
        font-weight: 700;
        font-size: 0.9rem;
        color: white;
        display: inline-block;
    }

    .h-link {
        font-weight: 600;
        font-size: 0.9rem;
        color: #4f46e5;
        text-decoration: none;
    }

    .h-link:hover {
        text-decoration: underline;
    }
</style>

<div class="mock-header">
    <div class="right-side">
        <h1>
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <path d="M12 16v-4"></path>
                <path d="M12 8h.01"></path>
            </svg>
            الاختبارات السريرية التجريبية (Mock OSCE)
        </h1>
        <p>درب نفسك على نماذج التقييم السريري الرسمية قبل دخول الامتحان الحقيقي مع الدكتور.</p>
    </div>
    <div class="left-side" style="display: flex; gap: 0.75rem;">
        <a href="{{ route('student.clinical.mock.create_custom') }}" class="btn-back" style="background: #4f46e5; color: white; border-color: #4f46e5;">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            إنشاء نموذج مخصص
        </a>
        <a href="{{ route('student.clinical.index') }}" class="btn-back">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg>
            رجوع
        </a>
    </div>
</div>

@if(session('success'))
<div style="background: #dcfce7; border: 1px solid #bbf7d0; color: #16a34a; padding: 1rem; border-radius: 12px; margin-bottom: 1.5rem; font-weight: 600;">
    {{ session('success') }}
</div>
@endif

@if(session('error'))
<div style="background: #fee2e2; border: 1px solid #fca5a5; color: #b91c1c; padding: 1rem; border-radius: 12px; margin-bottom: 1.5rem; font-weight: 600;">
    {{ session('error') }}
</div>
@endif

<h2 style="font-size: 1.15rem; font-weight: 800; color: #334155; margin-bottom: 1.25rem;">النماذج المتاحة للتدريب:</h2>

<div class="checklist-grid">
    @forelse($checklists as $chk)
    <div class="opt-card" style="position: relative; {{ $chk->creator_id ? 'border: 2px dashed #a5b4fc;' : '' }}">

        @if($chk->creator_id == Auth::id())
        <div style="position: absolute; top: 1rem; left: 1rem; display: flex; gap: 0.5rem;">
            <span style="background: #fef08a; color: #854d0e; padding: 0.2rem 0.6rem; border-radius: 6px; font-size: 0.75rem; font-weight: 700;">محفوظاتك</span>
            <form action="{{ route('student.clinical.mock.destroy_custom', $chk->id) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف هذا النموذج المرتبط بمحاولاتك التجريبية؟');">
                @csrf
                @method('DELETE')
                <button type="submit" style="background: #fee2e2; color: #dc2626; border: none; border-radius: 6px; padding: 0.2rem 0.5rem; cursor: pointer;" title="حذف النموذج">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <polyline points="3 6 5 6 21 6"></polyline>
                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                    </svg>
                </button>
            </form>
        </div>
        @endif

        <div>
            <div class="opt-icon" style="{{ $chk->creator_id ? 'background: #fdf4ff; color: #c026d3;' : '' }}">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                    <polyline points="14 2 14 8 20 8"></polyline>
                    <line x1="16" y1="13" x2="8" y2="13"></line>
                    <line x1="16" y1="17" x2="8" y2="17"></line>
                    <polyline points="10 9 9 9 8 9"></polyline>
                </svg>
            </div>
            <div class="opt-title" style="padding-left: {{ $chk->creator_id ? '4rem' : '0' }}; display: flex; align-items: center;">
                {{ $chk->title }}
                @if(is_null($chk->doctor_id) && is_null($chk->creator_id))
                    <span style="background: #e0e7ff; color: #4338ca; padding: 0.2rem 0.5rem; border-radius: 6px; font-size: 0.75rem; margin-right: 0.5rem; font-weight: 700;">أساسي</span>
                @elseif($chk->doctor_id && $chk->creator_id !== Auth::id())
                    <span style="background: #fce7f3; color: #be185d; padding: 0.2rem 0.5rem; border-radius: 6px; font-size: 0.75rem; margin-right: 0.5rem; font-weight: 700;">من الدكتور</span>
                @endif
            </div>
            <div style="font-size: 0.8rem; color: #64748b; margin-bottom: 0.65rem;">
                المنشئ: {{ $chk->creator?->name ?? $chk->doctor?->name ?? 'غير محدد' }}
            </div>
            <div class="opt-desc">{{ $chk->description ?? 'نموذج تقييم سريري شامل لتدريب المهارات الأساسية والمتقدمة.' }}</div>
        </div>
        <a href="{{ route('student.clinical.mock.take', $chk->id) }}" class="btn-start" style="{{ $chk->creator_id ? 'background: #c026d3;' : '' }}">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polygon points="5 3 19 12 5 21 5 3"></polygon>
            </svg>
            بدء الاختبار الآن
        </a>
    </div>
    @empty
    <div style="grid-column: 1 / -1; text-align: center; color: #64748b; padding: 3rem; background: #f8fafc; border-radius: 16px; border: 1px dashed #cbd5e1;">
        <p>لا يوجد نماذج تقييم متاحة حالياً.</p>
    </div>
    @endforelse
</div>

<div class="history-section">
    <div class="history-header">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"></circle>
            <polyline points="12 6 12 12 16 14"></polyline>
        </svg>
        سجل المحاولات السابقة
    </div>

    <div class="history-list">
        @forelse($previousMocks as $mock)
        <div class="history-card">
            <div class="h-info">
                <div class="h-title">{{ $mock->checklist->title ?? 'نموذج غير معروف' }}</div>
                <div class="h-meta">
                    <span>📅 {{ $mock->created_at->format('Y-m-d H:i') }}</span>
                    <span>⏱ {{ $mock->formatted_time }} دقيقة</span>
                </div>
            </div>
            <div style="display: flex; align-items: center; gap: 1.5rem;">
                <div class="h-grade" style="background: {{ $mock->grade_color }}">
                    {{ $mock->grade_label }} — {{ $mock->percentage }}%
                </div>
                <a href="{{ route('student.clinical.mock.show', $mock->id) }}" class="h-link">عرض التفاصيل ←</a>
            </div>
        </div>
        @empty
        <div style="text-align: center; color: #64748b; padding: 2rem;">
            لم تقم بأي محاولات تجريبية بعد. ابدأ محاولتك الأولى بالأعلى!
        </div>
        @endforelse
    </div>
</div>

@endsection
