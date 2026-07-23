@extends('layouts.doctor')

@section('title', $quiz->title)

@section('content')
<style>
    .quiz-detail-header {
        background: linear-gradient(135deg, #059669 0%, #10b981 100%);
        border-radius: 24px;
        padding: 2.5rem 2rem;
        color: white;
        margin-bottom: 2rem;
        position: relative;
        overflow: hidden;
    }

    .quiz-detail-header::before { content: ''; position: absolute; top: -50%; right: -10%; width: 300px; height: 300px; background: rgba(255,255,255,0.08); border-radius: 50%; }
    .quiz-detail-header-content { position: relative; z-index: 1; }
    .quiz-detail-header h1 { font-size: 1.8rem; font-weight: 800; margin-bottom: 0.5rem; }

    .quiz-meta-row { display: flex; gap: 1rem; flex-wrap: wrap; margin-top: 1rem; }

    .quiz-meta-pill {
        background: rgba(255,255,255,0.2);
        padding: 0.4rem 0.9rem;
        border-radius: 99px;
        font-size: 0.8rem;
        font-weight: 600;
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
    }

    .stats-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 1rem; margin-bottom: 2rem; }

    .stat-card {
        background: white;
        border-radius: 16px;
        padding: 1.5rem;
        border: 1px solid #e2e8f0;
        text-align: center;
    }

    .stat-value { font-size: 2rem; font-weight: 800; color: #1e293b; }
    .stat-label { font-size: 0.85rem; color: #64748b; font-weight: 600; margin-top: 0.25rem; }

    .detail-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        padding: 1.75rem;
        margin-bottom: 1.5rem;
    }

    .detail-card-title { font-size: 1.1rem; font-weight: 800; color: #1e293b; margin-bottom: 1.25rem; display: flex; align-items: center; gap: 0.5rem; }
    .detail-card-title i { color: #059669; }

    .model-section { border: 1px solid #e2e8f0; border-radius: 14px; padding: 1.25rem; margin-bottom: 1rem; background: #fafafa; }

    .model-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; padding-bottom: 0.75rem; border-bottom: 1px solid #e2e8f0; }
    .model-name { font-weight: 800; color: #059669; font-size: 1rem; }

    .access-code-badge { background: #fef3c7; color: #92400e; padding: 0.3rem 0.75rem; border-radius: 8px; font-size: 0.85rem; font-weight: 700; font-family: monospace; letter-spacing: 2px; }

    .q-item { padding: 0.75rem 0; border-bottom: 1px solid #f1f5f9; }
    .q-item:last-child { border-bottom: none; }

    .q-text { font-weight: 700; color: #1e293b; margin-bottom: 0.5rem; }
    .q-options { padding-right: 1rem; }

    .q-opt { font-size: 0.85rem; color: #475569; padding: 0.2rem 0; display: flex; align-items: center; gap: 0.4rem; }
    .q-opt.correct { color: #059669; font-weight: 700; }
    .q-opt.correct::before { content: '✓'; font-weight: 800; }

    .btn-action-row { display: flex; gap: 0.75rem; flex-wrap: wrap; }

    .btn-action {
        padding: 0.6rem 1.25rem;
        border-radius: 12px;
        font-weight: 700;
        font-size: 0.85rem;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        transition: all 0.2s;
        border: none;
        cursor: pointer;
    }

    .btn-action-primary { background: #059669; color: white; }
    .btn-action-primary:hover { background: #047857; color: white; }
    .btn-action-secondary { background: #f1f5f9; color: #475569; }
    .btn-action-secondary:hover { background: #e2e8f0; color: #334155; }
    .btn-action-danger { background: #fee2e2; color: #ef4444; }
    .btn-action-danger:hover { background: #fecaca; }
</style>

<div class="quiz-detail-header">
    <div class="quiz-detail-header-content">
        <h1><i class="fa-solid fa-clipboard-question me-2"></i>{{ $quiz->title }}</h1>
        @if($quiz->description)
        <p style="opacity:0.85;">{{ $quiz->description }}</p>
        @endif
        <div class="quiz-meta-row">
            <span class="quiz-meta-pill"><i class="fa-solid fa-circle" style="font-size:0.5rem;"></i> {{ $quiz->status_label }}</span>
            <span class="quiz-meta-pill"><i class="fa-solid fa-book"></i> {{ $quiz->subject->name ?? '—' }}</span>
            @if($quiz->time_limit_minutes)
            <span class="quiz-meta-pill"><i class="fa-regular fa-clock"></i> {{ $quiz->time_limit_minutes }} دقيقة</span>
            @endif
            <span class="quiz-meta-pill"><i class="fa-solid fa-eye"></i> النتائج: {{ $quiz->results_visibility_label }}</span>
        </div>
    </div>
</div>

{{-- Stats --}}
<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-value">{{ $stats['total_attempts'] }}</div>
        <div class="stat-label">محاولات</div>
    </div>
    <div class="stat-card">
        <div class="stat-value" style="color: #059669;">{{ round($stats['avg_score'], 1) }}%</div>
        <div class="stat-label">المعدل</div>
    </div>
    <div class="stat-card">
        <div class="stat-value" style="color: #10b981;">{{ round($stats['highest_score'], 1) }}%</div>
        <div class="stat-label">أعلى درجة</div>
    </div>
    <div class="stat-card">
        <div class="stat-value" style="color: #ef4444;">{{ round($stats['lowest_score'], 1) }}%</div>
        <div class="stat-label">أدنى درجة</div>
    </div>
</div>

{{-- Scheduled Countdown --}}
@if($quiz->isUpcoming())
<div class="detail-card border-warning" x-data="countdown('{{ $quiz->scheduled_at->toIso8601String() }}')">
    <div class="d-flex align-items-center justify-content-between">
        <div>
            <h4 class="mb-1 fw-bold text-warning"><i class="fa-solid fa-clock me-1"></i> العد التنازلي للنشر</h4>
            <p class="text-secondary small mb-0">سيتم نشر هذا الكويز للطلاب تلقائياً عند انتهاء الوقت.</p>
        </div>
        <div class="text-end">
            <div class="fs-4 fw-black text-warning" x-text="displayText">--:--:--</div>
            <div class="text-secondary smaller">{{ $quiz->scheduled_at->format('Y-m-d H:i') }}</div>
        </div>
    </div>
</div>
@endif

{{-- Actions --}}
<div class="detail-card">
    <div class="btn-action-row">
        <a href="{{ route('doctor.quizzes.results', $quiz) }}" class="btn-action btn-action-primary"><i class="fa-solid fa-chart-bar"></i> عرض النتائج التفصيلية</a>

        {{-- Edit Button --}}
        <a href="{{ route('doctor.quizzes.edit', $quiz) }}" class="btn-action btn-action-secondary" style="background: #e0f2fe; color: #0369a1; border: 1px solid #bae6fd;">
            <i class="fa-solid fa-edit"></i> تعديل الكويز
        </a>

        @if($quiz->status === 'draft' || $quiz->isUpcoming())
        <form action="{{ route('doctor.quizzes.publish', $quiz) }}" method="POST" style="display:inline;">@csrf @method('PATCH')
            <button class="btn-action btn-action-primary"><i class="fa-solid fa-paper-plane"></i> نشر الكويز الآن</button>
        </form>
        @endif

        @if($quiz->isEffectivelyPublished() && $quiz->status !== 'closed')
        <form action="{{ route('doctor.quizzes.close', $quiz) }}" method="POST" style="display:inline;">@csrf @method('PATCH')
            <button class="btn-action btn-action-danger"><i class="fa-solid fa-lock"></i> إغلاق الكويز</button>
        </form>
        @endif

        <a href="{{ route('doctor.quizzes.index') }}" class="btn-action btn-action-secondary"><i class="fa-solid fa-arrow-right"></i> رجوع</a>
    </div>
</div>

{{-- Models & Questions --}}
<div class="detail-card">
    <h3 class="detail-card-title"><i class="fa-solid fa-layer-group"></i> النماذج والأسئلة</h3>

    @foreach($quiz->models as $model)
    <div class="model-section">
        <div class="model-head">
            <span class="model-name"><i class="fa-solid fa-file-alt me-1"></i> {{ $model->name }}</span>
            @if($model->access_code)
            <span class="access-code-badge" title="رمز الدخول">{{ $model->access_code }}</span>
            @endif
        </div>

        @foreach($model->questions as $i => $question)
        <div class="q-item">
            <div class="q-text">{{ $i + 1 }}. {{ $question->question_text }}</div>
            <div class="q-options">
                @foreach($question->options as $option)
                <div class="q-opt {{ $option->is_correct ? 'correct' : '' }}">
                    @if(!$option->is_correct)
                    <span style="color: #94a3b8;">○</span>
                    @endif
                    {{ $option->option_text }}
                </div>
                @endforeach
            </div>
            @if($question->correction_note)
            <div style="font-size: 0.8rem; color: #f59e0b; margin-top: 0.5rem;"><i class="fa-solid fa-lightbulb me-1"></i>{{ $question->correction_note }}</div>
            @endif
        </div>
        @endforeach
    </div>
    @endforeach
</div>
@push('scripts')
<script>
function countdown(targetDate) {
    return {
        target: new Date(targetDate).getTime(),
        displayText: '',
        timer: null,

        init() {
            this.updateCounter();
            this.timer = setInterval(() => {
                this.updateCounter();
            }, 1000);
        },

        updateCounter() {
            const now = new Date().getTime();
            const distance = this.target - now;

            if (distance < 0) {
                this.displayText = "00:00:00";
                clearInterval(this.timer);
                window.location.reload();
                return;
            }

            const days = Math.floor(distance / (1000 * 60 * 60 * 24));
            const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
            const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
            const seconds = Math.floor((distance % (1000 * 60)) / 1000);

            let res = "";
            if (days > 0) res += days + "ي ";
            res += String(hours).padStart(2, '0') + ":" + String(minutes).padStart(2, '0') + ":" + String(seconds).padStart(2, '0');
            this.displayText = res;
        }
    }
}
</script>
@endpush
@endsection
