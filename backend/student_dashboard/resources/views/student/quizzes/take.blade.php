@extends('layouts.student')

@section('title', 'حل: ' . $quiz->title)

@section('content')
<style>
    .take-container { max-width: 850px; margin: 0 auto; }

    .take-header {
        background: linear-gradient(135deg, #059669 0%, #10b981 100%);
        border-radius: 24px;
        padding: 2rem;
        color: white;
        margin-bottom: 2rem;
        position: relative;
        overflow: hidden;
    }

    .take-header::before { content: ''; position: absolute; top: -50%; right: -10%; width: 300px; height: 300px; background: rgba(255,255,255,0.08); border-radius: 50%; }
    .take-header-content { position: relative; z-index: 1; }
    .take-header h1 { font-size: 1.6rem; font-weight: 800; margin-bottom: 0.25rem; }

    .timer-box {
        background: rgba(255,255,255,0.2);
        backdrop-filter: blur(10px);
        border: 1px solid rgba(255,255,255,0.3);
        padding: 0.5rem 1.25rem;
        border-radius: 14px;
        font-weight: 800;
        font-size: 1.2rem;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
    }

    .timer-box.warning { background: rgba(239,68,68,0.3); border-color: rgba(239,68,68,0.5); }

    .progress-bar-quiz {
        width: 100%;
        height: 8px;
        background: rgba(255,255,255,0.2);
        border-radius: 99px;
        overflow: hidden;
        margin-top: 1rem;
    }

    .progress-fill { height: 100%; background: white; border-radius: 99px; transition: width 0.3s; }

    .question-wrapper {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        margin-bottom: 1.25rem;
        overflow: hidden;
        transition: all 0.2s;
    }

    .question-wrapper:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.05); }

    .question-num-bar {
        background: #f8fafc;
        padding: 0.75rem 1.5rem;
        border-bottom: 1px solid #e2e8f0;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .question-num {
        font-weight: 800;
        color: #059669;
        font-size: 0.9rem;
    }

    .question-score {
        font-size: 0.75rem;
        color: #94a3b8;
        font-weight: 600;
        background: #f1f5f9;
        padding: 0.2rem 0.6rem;
        border-radius: 6px;
    }

    .question-body { padding: 1.5rem; }

    .question-text {
        font-size: 1.05rem;
        font-weight: 700;
        color: #1e293b;
        margin-bottom: 1.25rem;
        line-height: 1.7;
    }

    .option-list { list-style: none; padding: 0; margin: 0; }

    .option-item {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        padding: 0.85rem 1.25rem;
        margin-bottom: 0.5rem;
        border: 2px solid #e2e8f0;
        border-radius: 14px;
        cursor: pointer;
        transition: all 0.2s;
        font-weight: 600;
        color: #334155;
    }

    .option-item:hover { border-color: #10b981; background: #f0fdf4; }

    .option-item.selected {
        border-color: #059669;
        background: #d1fae5;
        color: #065f46;
    }

    .option-radio {
        width: 22px;
        height: 22px;
        border-radius: 50%;
        border: 2px solid #cbd5e1;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        transition: all 0.2s;
    }

    .option-item.selected .option-radio {
        border-color: #059669;
        background: #059669;
    }

    .option-item.selected .option-radio::after {
        content: '';
        width: 8px;
        height: 8px;
        background: white;
        border-radius: 50%;
    }

    .submit-section {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 1rem;
    }

    .answered-counter { font-size: 0.9rem; font-weight: 700; color: #475569; }
    .answered-counter span { color: #059669; }

    .btn-submit-quiz {
        background: linear-gradient(135deg, #059669, #10b981);
        color: white;
        border: none;
        padding: 0.85rem 2.5rem;
        border-radius: 14px;
        font-weight: 800;
        font-size: 1rem;
        cursor: pointer;
        transition: all 0.2s;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
    }

    .btn-submit-quiz:hover { transform: translateY(-2px); box-shadow: 0 10px 25px rgba(5,150,105,0.3); }

    @media (max-width: 768px) {
        .take-header { padding: 1.5rem; }
        .take-header h1 { font-size: 1.3rem; }
    }
</style>

<div class="take-container" x-data="quizTake({{ $questions->count() }}, {{ $quiz->time_limit_minutes ?? 'null' }}, {{ $attempt->remaining_seconds ?? 'null' }})">
    <div class="take-header">
        <div class="take-header-content">
            <div class="d-flex justify-content-between align-items-start flex-wrap gap-2">
                <div>
                    <h1>{{ $quiz->title }}</h1>
                    <p style="opacity:0.85; margin:0;">{{ $quiz->subject->name ?? '' }} — {{ $quiz->creator->name ?? '' }}</p>
                </div>
                @if($quiz->time_limit_minutes && $quiz->show_countdown)
                <div class="timer-box" :class="{ 'warning': remainingSeconds < 60 }">
                    <i class="fa-regular fa-clock"></i>
                    <span x-text="timerText"></span>
                </div>
                @endif
            </div>
            <div class="progress-bar-quiz">
                <div class="progress-fill" :style="'width:' + progressPercent + '%'"></div>
            </div>
        </div>
    </div>

    <form action="{{ route('student.quizzes.submit', $attempt) }}" method="POST" @submit="handleSubmit($event)" id="quizForm">
        @csrf

        @foreach($questions as $i => $question)
        <div class="question-wrapper" id="q-{{ $question->id }}">
            <div class="question-num-bar">
                <span class="question-num">السؤال {{ $i + 1 }} من {{ $questions->count() }}</span>
                <span class="question-score">{{ $question->score }} درجة</span>
            </div>
            <div class="question-body">
                <div class="question-text">{{ $question->question_text }}</div>

                @if($question->image_url)
                <div class="mb-3"><img src="{{ $question->image_url }}" class="img-fluid" style="max-height:250px; border-radius:12px;"></div>
                @endif

                <ul class="option-list">
                    @foreach($question->options as $option)
                    <li class="option-item"
                        :class="{ 'selected': answers[{{ $question->id }}] == {{ $option->id }} }"
                        @click="selectAnswer({{ $question->id }}, {{ $option->id }})">
                        <div class="option-radio"></div>
                        <span>{{ $option->option_text }}</span>
                        <input type="radio"
                            name="answers[{{ $question->id }}]"
                            value="{{ $option->id }}"
                            {{ isset($existingAnswers[$question->id]) && $existingAnswers[$question->id] == $option->id ? 'checked' : '' }}
                            style="display:none;">
                    </li>
                    @endforeach
                </ul>
            </div>
        </div>
        @endforeach

        <div class="submit-section">
            <div class="answered-counter">
                أجبت على <span x-text="answeredCount"></span> من {{ $questions->count() }} سؤال
            </div>
            <button type="submit" class="btn-submit-quiz" :disabled="submitting">
                <i class="fa-solid fa-paper-plane"></i>
                <span x-text="submitting ? 'جاري التسليم...' : 'تسليم الكويز'"></span>
            </button>
        </div>
    </form>
</div>

@push('scripts')
<script>
function quizTake(totalQuestions, timeLimitMinutes, remainingSecondsInit) {
    return {
        answers: {!! json_encode($existingAnswers->mapWithKeys(fn($v, $k) => [$k => $v])->toArray()) !!},
        totalQuestions: totalQuestions,
        submitting: false,
        remainingSeconds: remainingSecondsInit,
        timerInterval: null,

        get answeredCount() {
            return Object.keys(this.answers).length;
        },

        get progressPercent() {
            return this.totalQuestions > 0 ? Math.round((this.answeredCount / this.totalQuestions) * 100) : 0;
        },

        get timerText() {
            if (this.remainingSeconds === null) return '';
            const m = Math.floor(this.remainingSeconds / 60);
            const s = this.remainingSeconds % 60;
            return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
        },

        init() {
            window.addEventListener('beforeunload', (event) => {
                if (this.submitting) return;
                event.preventDefault();
                event.returnValue = 'الخروج من صفحة الكويز قد يؤدي إلى تسليم الاختبار أو فقدان الإجابات غير المرسلة.';
            });

            if (this.remainingSeconds !== null && this.remainingSeconds > 0) {
                this.timerInterval = setInterval(() => {
                    this.remainingSeconds--;
                    if (this.remainingSeconds <= 0) {
                        clearInterval(this.timerInterval);
                        this.autoSubmit();
                    }
                }, 1000);
            }
        },

        selectAnswer(questionId, optionId) {
            this.answers[questionId] = optionId;
            // Check the hidden radio
            const radio = document.querySelector(`input[name="answers[${questionId}]"][value="${optionId}"]`);
            if (radio) radio.checked = true;
        },

        handleSubmit(event) {
            if (this.answeredCount < this.totalQuestions) {
                if (!confirm(`لم تجب على كل الأسئلة (${this.answeredCount}/${this.totalQuestions}). هل تريد التسليم؟`)) {
                    event.preventDefault();
                    return;
                }
            }
            this.submitting = true;
        },

        autoSubmit() {
            this.submitting = true;
            document.getElementById('quizForm').submit();
        }
    };
}
</script>
@endpush
@endsection
