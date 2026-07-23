@extends('layouts.student')

@section('title', 'نتيجة: ' . $quiz->title)

@section('content')
<style>
    .result-container { max-width: 850px; margin: 0 auto; }

    .result-header {
        border-radius: 24px;
        padding: 2.5rem 2rem;
        color: white;
        margin-bottom: 2rem;
        position: relative;
        overflow: hidden;
        text-align: center;
    }

    .result-header.grade-high { background: linear-gradient(135deg, #059669, #34d399); }
    .result-header.grade-mid { background: linear-gradient(135deg, #d97706, #f59e0b); }
    .result-header.grade-low { background: linear-gradient(135deg, #dc2626, #ef4444); }

    .result-header::before { content: ''; position: absolute; top: -50%; right: -10%; width: 300px; height: 300px; background: rgba(255,255,255,0.08); border-radius: 50%; }
    .result-header-content { position: relative; z-index: 1; }

    .result-score-big { font-size: 4rem; font-weight: 900; line-height: 1; margin-bottom: 0.25rem; }
    .result-score-sub { font-size: 1.1rem; opacity: 0.85; font-weight: 600; }

    .result-stats {
        display: flex;
        justify-content: center;
        gap: 2rem;
        margin-top: 1.5rem;
        flex-wrap: wrap;
    }

    .result-stat { text-align: center; }
    .result-stat-value { font-size: 1.5rem; font-weight: 800; }
    .result-stat-label { font-size: 0.8rem; opacity: 0.75; }

    .answers-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        margin-bottom: 1.5rem;
    }

    .answers-card-title {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid #e2e8f0;
        font-weight: 800;
        font-size: 1.05rem;
        color: #1e293b;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .answer-item {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid #f1f5f9;
    }

    .answer-item:last-child { border-bottom: none; }

    .answer-q-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 0.75rem;
    }

    .answer-q-num {
        font-weight: 800;
        font-size: 0.8rem;
        padding: 0.2rem 0.6rem;
        border-radius: 8px;
    }

    .answer-q-num.correct { background: #d1fae5; color: #065f46; }
    .answer-q-num.wrong { background: #fee2e2; color: #991b1b; }

    .answer-q-score { font-size: 0.8rem; font-weight: 700; color: #64748b; }

    .answer-q-text { font-weight: 700; color: #1e293b; margin-bottom: 0.75rem; line-height: 1.6; }

    .answer-options { padding-right: 1rem; }

    .answer-opt {
        padding: 0.4rem 0;
        font-size: 0.85rem;
        display: flex;
        align-items: center;
        gap: 0.4rem;
        color: #475569;
    }

    .answer-opt.user-correct { color: #059669; font-weight: 700; }
    .answer-opt.user-wrong { color: #ef4444; font-weight: 700; text-decoration: line-through; }
    .answer-opt.correct-answer { color: #059669; font-weight: 700; }

    .correction-note {
        margin-top: 0.75rem;
        padding: 0.5rem 0.75rem;
        background: #fffbeb;
        border-radius: 10px;
        border: 1px solid #fde68a;
        font-size: 0.8rem;
        color: #92400e;
    }

    .btn-action-row { display: flex; gap: 0.75rem; flex-wrap: wrap; margin-bottom: 2rem; }

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
    }

    .btn-action-primary { background: #059669; color: white; }
    .btn-action-primary:hover { background: #047857; color: white; }
    .btn-action-secondary { background: #f1f5f9; color: #475569; }
    .btn-action-secondary:hover { background: #e2e8f0; }

    @media (max-width: 768px) {
        .result-score-big { font-size: 3rem; }
        .result-stats { gap: 1.5rem; }
    }
</style>

@php
    $pct = $attempt->percentage;
    $gradeClass = $pct >= 70 ? 'grade-high' : ($pct >= 50 ? 'grade-mid' : 'grade-low');
@endphp

<div class="result-container">
    <div class="result-header {{ $gradeClass }}">
        <div class="result-header-content">
            <div class="result-score-big">{{ $pct }}%</div>
            <div class="result-score-sub">{{ $attempt->score }} / {{ $attempt->max_score }} درجة</div>
            <h2 style="font-size: 1.3rem; font-weight: 800; margin-top: 0.75rem;">{{ $quiz->title }}</h2>

            <div class="result-stats">
                <div class="result-stat">
                    <div class="result-stat-value">{{ $attempt->correct_count }}</div>
                    <div class="result-stat-label">إجابات صحيحة</div>
                </div>
                <div class="result-stat">
                    <div class="result-stat-value">{{ $attempt->wrong_count }}</div>
                    <div class="result-stat-label">إجابات خاطئة</div>
                </div>
                @if($attempt->duration)
                <div class="result-stat">
                    <div class="result-stat-value">{{ $attempt->duration }}</div>
                    <div class="result-stat-label">دقيقة</div>
                </div>
                @endif
            </div>
        </div>
    </div>

    <div class="btn-action-row">
        <a href="{{ route('student.quizzes.index') }}" class="btn-action btn-action-secondary"><i class="fa-solid fa-arrow-right"></i> الكويزات</a>
    </div>

    @if(($publicAttempts ?? collect())->isNotEmpty())
    <div class="answers-card">
        <div class="answers-card-title"><i class="fa-solid fa-ranking-star" style="color:#2563eb;"></i> نتائج الطلاب</div>
        <div class="table-responsive">
            <table class="table align-middle mb-0">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>الطالب</th>
                        <th>النموذج</th>
                        <th>الدرجة</th>
                        <th>النسبة</th>
                        <th>وقت التسليم</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($publicAttempts as $rank => $publicAttempt)
                    <tr class="{{ $publicAttempt->student_id === auth()->id() ? 'table-primary' : '' }}">
                        <td class="fw-bold">{{ $rank + 1 }}</td>
                        <td>
                            <div class="fw-bold">{{ $publicAttempt->student?->name ?? 'طالب' }}</div>
                            @if($publicAttempt->student?->student_number)
                                <small class="text-muted">{{ $publicAttempt->student->student_number }}</small>
                            @endif
                        </td>
                        <td>{{ $publicAttempt->quizModel?->name ?? '—' }}</td>
                        <td>{{ number_format((float) $publicAttempt->score, 0) }} / {{ number_format((float) $publicAttempt->max_score, 0) }}</td>
                        <td class="fw-bold">{{ $publicAttempt->percentage }}%</td>
                        <td>{{ $publicAttempt->submitted_at?->format('Y-m-d H:i') ?? '—' }}</td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
    @endif

    {{-- Detailed Answers --}}
    @if($quiz->show_correct_answers)
    <div class="answers-card">
        <div class="answers-card-title"><i class="fa-solid fa-list-check" style="color:#059669;"></i> مراجعة الإجابات</div>

        @foreach($attempt->answers as $i => $answer)
        @php
            $q = $answer->question;
            $isCorrect = $answer->is_correct;
        @endphp
        <div class="answer-item">
            <div class="answer-q-header">
                <span class="answer-q-num {{ $isCorrect ? 'correct' : 'wrong' }}">
                    <i class="fa-solid {{ $isCorrect ? 'fa-check' : 'fa-xmark' }} me-1"></i>
                    السؤال {{ $i + 1 }}
                </span>
                <span class="answer-q-score">{{ $answer->score_awarded ?? 0 }} / {{ $q->score }}</span>
            </div>

            <div class="answer-q-text">{{ $q->question_text }}</div>

            <div class="answer-options">
                @foreach($q->options as $option)
                @php
                    $isUserAnswer = $answer->selected_option_id === $option->id;
                    $isCorrectOpt = $option->is_correct;
                    $optClass = '';
                    if ($isUserAnswer && $isCorrectOpt) $optClass = 'user-correct';
                    elseif ($isUserAnswer && !$isCorrectOpt) $optClass = 'user-wrong';
                    elseif ($isCorrectOpt) $optClass = 'correct-answer';
                @endphp
                <div class="answer-opt {{ $optClass }}">
                    @if($isUserAnswer && $isCorrectOpt)
                        <i class="fa-solid fa-circle-check"></i>
                    @elseif($isUserAnswer && !$isCorrectOpt)
                        <i class="fa-solid fa-circle-xmark"></i>
                    @elseif($isCorrectOpt)
                        <i class="fa-solid fa-circle-check" style="opacity:0.5;"></i>
                    @else
                        <i class="fa-regular fa-circle" style="opacity:0.3;"></i>
                    @endif
                    {{ $option->option_text }}
                </div>
                @endforeach
            </div>

            @if($quiz->show_correction_notes && ($q->correction_note || $q->info_source || $q->scientific_source))
            <div class="correction-note">
                @if($q->correction_note)
                    <div class="mb-1"><i class="fa-solid fa-lightbulb me-1"></i> <strong>الشرح:</strong> {{ $q->correction_note }}</div>
                @endif
                @if($q->info_source)
                    <div class="small opacity-75"><i class="fa-solid fa-book me-1"></i> <strong>المصدر:</strong> {{ $q->info_source }}</div>
                @endif
            </div>
            @endif
        </div>
        @endforeach
    </div>
    @endif
</div>
@endsection
