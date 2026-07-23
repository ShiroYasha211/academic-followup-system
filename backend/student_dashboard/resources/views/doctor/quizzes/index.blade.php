@extends('layouts.doctor')

@section('title', 'الكويزات')

@section('content')
<style>
    .quiz-header {
        background: linear-gradient(135deg, #059669 0%, #10b981 50%, #34d399 100%);
        border-radius: 24px;
        padding: 2.5rem 2rem;
        color: white;
        margin-bottom: 2rem;
        position: relative;
        overflow: hidden;
        box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1);
    }

    .quiz-header::before {
        content: '';
        position: absolute;
        top: -50%;
        right: -10%;
        width: 350px;
        height: 350px;
        background: rgba(255,255,255,0.08);
        border-radius: 50%;
    }

    .quiz-header-content {
        position: relative;
        z-index: 1;
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 1rem;
    }

    .quiz-header h1 { font-size: 2rem; font-weight: 800; margin-bottom: 0.25rem; }
    .quiz-header p { opacity: 0.85; }

    .btn-new-quiz {
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

    .btn-new-quiz:hover { background: rgba(255,255,255,0.35); color: white; transform: translateY(-2px); }

    .filter-pills { display: flex; gap: 0.5rem; margin-bottom: 2rem; flex-wrap: wrap; }

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

    .filter-pill:hover { border-color: #059669; color: #059669; }
    .filter-pill.active { background: #059669; color: white; border-color: #059669; }

    .quiz-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
        gap: 1.5rem;
    }

    .quiz-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .quiz-card:hover { transform: translateY(-6px); box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1); }

    .quiz-card-banner { height: 6px; width: 100%; }
    .status-draft .quiz-card-banner { background: #94a3b8; }
    .status-scheduled .quiz-card-banner { background: #f59e0b; }
    .status-published .quiz-card-banner { background: #10b981; }
    .status-closed .quiz-card-banner { background: #ef4444; }

    .quiz-card-body { padding: 1.75rem; }

    .quiz-card-meta {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        margin-bottom: 1rem;
        flex-wrap: wrap;
    }

    .status-badge {
        padding: 0.3rem 0.75rem;
        border-radius: 99px;
        font-size: 0.7rem;
        font-weight: 700;
        color: white;
    }

    .quiz-card-title { font-size: 1.15rem; font-weight: 800; color: #1e293b; margin-bottom: 0.5rem; }

    .quiz-card-info {
        display: flex;
        gap: 1rem;
        flex-wrap: wrap;
        margin-top: 1rem;
    }

    .quiz-info-item {
        display: flex;
        align-items: center;
        gap: 0.35rem;
        font-size: 0.8rem;
        color: #64748b;
        font-weight: 600;
    }

    .quiz-card-footer {
        padding: 1rem 1.75rem;
        border-top: 1px solid #f1f5f9;
        background: #f8fafc;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .quiz-action-btn {
        background: none;
        border: none;
        padding: 0.4rem 0.75rem;
        border-radius: 8px;
        cursor: pointer;
        color: #64748b;
        font-size: 0.8rem;
        font-weight: 600;
        text-decoration: none;
        transition: all 0.2s;
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
    }

    .quiz-action-btn:hover { background: #e2e8f0; color: #1e293b; }
    .quiz-action-btn.danger:hover { background: #fee2e2; color: #ef4444; }
    .quiz-action-btn.success:hover { background: #d1fae5; color: #059669; }

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
        .quiz-header { padding: 1.5rem; }
        .quiz-header h1 { font-size: 1.5rem; }
        .quiz-grid { grid-template-columns: 1fr; }
        .quiz-header-content { flex-direction: column; align-items: flex-start; }
    }
</style>

<div class="quiz-header">
    <div class="quiz-header-content">
        <div>
            <h1><i class="fa-solid fa-clipboard-question me-2"></i>كويزاتي</h1>
            <p>إنشاء وإدارة الكويزات والاختبارات القصيرة لطلابك</p>
        </div>
        <a href="{{ route('doctor.quizzes.create') }}" class="btn-new-quiz">
            <i class="fa-solid fa-plus"></i> كويز جديد
        </a>
    </div>
</div>

<div class="filter-pills">
    <a href="{{ route('doctor.quizzes.index') }}" class="filter-pill {{ $status === 'all' ? 'active' : '' }}">
        <i class="fa-solid fa-layer-group me-1"></i> الكل
    </a>
    <a href="{{ route('doctor.quizzes.index', ['status' => 'draft']) }}" class="filter-pill {{ $status === 'draft' ? 'active' : '' }}">
        <i class="fa-solid fa-file-pen me-1"></i> مسودات
    </a>
    <a href="{{ route('doctor.quizzes.index', ['status' => 'published']) }}" class="filter-pill {{ $status === 'published' ? 'active' : '' }}">
        <i class="fa-solid fa-globe me-1"></i> منشورة
    </a>
    <a href="{{ route('doctor.quizzes.index', ['status' => 'closed']) }}" class="filter-pill {{ $status === 'closed' ? 'active' : '' }}">
        <i class="fa-solid fa-lock me-1"></i> مغلقة
    </a>
</div>

@if($quizzes->count() > 0)
<div class="quiz-grid">
    @foreach($quizzes as $quiz)
    <div class="quiz-card status-{{ $quiz->status }}">
        <div class="quiz-card-banner"></div>
        <div class="quiz-card-body">
            <div class="quiz-card-meta">
                <span class="status-badge" style="background: {{ $quiz->status_color }}">{{ $quiz->status_label }}</span>
                <span style="font-size: 0.8rem; color: #94a3b8;">{{ $quiz->created_at->diffForHumans() }}</span>
            </div>
            <h3 class="quiz-card-title">{{ $quiz->title }}</h3>
            <p style="font-size: 0.85rem; color: #64748b; margin-bottom: 0;">{{ $quiz->subject->name ?? '—' }}</p>

            <div class="quiz-card-info">
                <span class="quiz-info-item">
                    <i class="fa-solid fa-layer-group"></i> {{ $quiz->models->count() }} نموذج
                </span>
                <span class="quiz-info-item">
                    <i class="fa-solid fa-users"></i> {{ $quiz->attempts_count }} محاولة
                </span>
                @if($quiz->time_limit_minutes)
                <span class="quiz-info-item">
                    <i class="fa-regular fa-clock"></i> {{ $quiz->time_limit_minutes }} دقيقة
                </span>
                @endif
            </div>
        </div>
        <div class="quiz-card-footer">
            <div style="display: flex; gap: 0.25rem;">
                <a href="{{ route('doctor.quizzes.show', $quiz) }}" class="quiz-action-btn">
                    <i class="fa-solid fa-eye"></i> عرض
                </a>
                <a href="{{ route('doctor.quizzes.edit', $quiz) }}" class="quiz-action-btn" style="color: #0369a1;">
                    <i class="fa-solid fa-edit"></i> تعديل
                </a>
                <a href="{{ route('doctor.quizzes.results', $quiz) }}" class="quiz-action-btn">
                    <i class="fa-solid fa-chart-bar"></i> النتائج
                </a>
            </div>
            <div style="display: flex; gap: 0.25rem;">
                @if($quiz->status === 'draft')
                <form action="{{ route('doctor.quizzes.publish', $quiz) }}" method="POST" style="display:inline;">
                    @csrf @method('PATCH')
                    <button type="submit" class="quiz-action-btn success"><i class="fa-solid fa-paper-plane"></i> نشر</button>
                </form>
                @endif
                @if($quiz->status === 'published')
                <form action="{{ route('doctor.quizzes.close', $quiz) }}" method="POST" style="display:inline;">
                    @csrf @method('PATCH')
                    <button type="submit" class="quiz-action-btn danger"><i class="fa-solid fa-lock"></i> إغلاق</button>
                </form>
                @endif
                <form action="{{ route('doctor.quizzes.destroy', $quiz) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف هذا الكويز؟')" style="display:inline;">
                    @csrf @method('DELETE')
                    <button type="submit" class="quiz-action-btn danger"><i class="fa-solid fa-trash-can"></i></button>
                </form>
            </div>
        </div>
    </div>
    @endforeach
</div>

<div class="mt-4 d-flex justify-content-center">
    {{ $quizzes->appends(['status' => $status])->links() }}
</div>
@else
<div class="empty-state">
    <div class="empty-icon"><i class="fa-solid fa-clipboard-question"></i></div>
    <h2 class="empty-title">لا توجد كويزات حالياً</h2>
    <p class="text-secondary mb-3">أنشئ أول كويز لطلابك الآن</p>
    <a href="{{ route('doctor.quizzes.create') }}" class="btn btn-success" style="border-radius: 12px; padding: 0.6rem 1.5rem;">
        <i class="fa-solid fa-plus me-1"></i> كويز جديد
    </a>
</div>
@endif
@endsection
