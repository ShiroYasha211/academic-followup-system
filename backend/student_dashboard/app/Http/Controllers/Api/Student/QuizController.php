<?php

namespace App\Http\Controllers\Api\Student;

use App\Models\Quiz\Quiz;
use App\Models\Quiz\QuizModel;
use App\Models\Quiz\QuizAttempt;
use App\Models\Quiz\QuizAnswer;
use App\Models\Quiz\QuizOption;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class QuizController extends StudentApiController
{
    /**
     * List available quizzes for this student.
     */
    public function index()
    {
        $student = Auth::user();

        // Get subjects matching this student's major/level
        $subjectIds = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->pluck('id');

        // 1. Doctor quizzes for student's subjects
        $doctorQuizzes = Quiz::where('creator_type', 'doctor')
            ->whereIn('subject_id', $subjectIds)
            ->where(function ($q) {
                $q->where('status', 'published')
                  ->orWhere(function ($sub) {
                      $sub->where('status', 'scheduled')
                          ->where(function ($inner) {
                              $inner->where('notify_students', true)
                                    ->orWhere('scheduled_at', '<=', now());
                          });
                  });
            })
            ->where(function ($q) {
                $q->whereNull('closes_at')->orWhere('closes_at', '>', now());
            })
            ->with(['creator:id,name', 'subject:id,name'])
            ->withCount('models')
            ->latest()
            ->get()
            ->map(fn($quiz) => $this->formatQuiz($quiz, $student));

        // 2. Competition quizzes targeting this student
        $competitions = Quiz::competitions()
            ->where(function ($q) {
                $q->where('status', 'published')
                  ->orWhere(function ($sub) {
                      $sub->where('status', 'scheduled')
                          ->where(function ($inner) {
                              $inner->where('notify_students', true)
                                    ->orWhere('scheduled_at', '<=', now());
                          });
                  });
            })
            ->whereHas('targets', function ($q) use ($student) {
                $q->where(function ($sub) use ($student) {
                    $sub->whereNull('university_id')->orWhere('university_id', $student->university_id);
                })->where(function ($sub) use ($student) {
                    $sub->whereNull('college_id')->orWhere('college_id', $student->college_id);
                })->where(function ($sub) use ($student) {
                    $sub->whereNull('major_id')->orWhere('major_id', $student->major_id);
                })->where(function ($sub) use ($student) {
                    $sub->whereNull('level_id')->orWhere('level_id', $student->level_id);
                });
            })
            ->where(function ($q) {
                $q->whereNull('closes_at')->orWhere('closes_at', '>', now());
            })
            ->with(['creator:id,name'])
            ->latest()
            ->get()
            ->map(fn($quiz) => $this->formatQuiz($quiz, $student));

        // 3. My recent attempts
        $myAttempts = QuizAttempt::where('student_id', $student->id)
            ->with(['quiz.subject', 'quiz.creator:id,name', 'quizModel'])
            ->latest()
            ->take(20)
            ->get()
            ->map(function ($attempt) {
                $pct = $attempt->percentage;
                $resultsHidden = ($attempt->quiz?->results_visibility ?? 'hidden') === 'hidden';
                return [
                    'id'             => $attempt->id,
                    'quiz_id'        => $attempt->quiz_id,
                    'quiz_title'     => $attempt->quiz->title ?? '—',
                    'subject_name'   => $attempt->quiz->subject->name ?? '—',
                    'creator_name'   => $attempt->quiz->creator->name ?? '—',
                    'model_name'     => $attempt->quizModel->name ?? '—',
                    'results_visibility' => $attempt->quiz?->results_visibility ?? 'hidden',
                    'results_hidden' => $resultsHidden,
                    'score'          => $resultsHidden ? null : (float) $attempt->score,
                    'max_score'      => $resultsHidden ? null : (float) $attempt->max_score,
                    'percentage'     => $resultsHidden ? null : $pct,
                    'correct_answers_count' => $resultsHidden ? null : $attempt->correct_count,
                    'wrong_answers_count'   => $resultsHidden ? null : $attempt->wrong_count,
                    'status'         => $attempt->status,
                    'status_label'   => $attempt->status_label,
                    'duration'       => $attempt->duration,
                    'submitted_at'   => $attempt->submitted_at?->toIso8601String(),
                    'started_at'     => $attempt->started_at?->toIso8601String(),
                    'quiz'           => ['id' => $attempt->quiz_id, 'title' => $attempt->quiz->title ?? ''],
                ];
            });

        return $this->success([
            'doctor_quizzes' => $doctorQuizzes,
            'competitions'   => $competitions,
            'my_attempts'    => $myAttempts,
        ], 'تم جلب الكويزات بنجاح');
    }

    /**
     * Format a quiz object into the flat structure expected by the Flutter app.
     */
    private function formatQuiz(Quiz $quiz, $student): array
    {
        $isAttempted = $quiz->hasAttemptBy($student);
        $attemptId   = $isAttempted ? $quiz->attemptBy($student)?->id : null;

        // Calculate total questions across all models
        $questionsCount = $quiz->models()->withCount('questions')->get()->sum('questions_count');

        return [
            'id'               => $quiz->id,
            'title'            => $quiz->title,
            'description'      => $quiz->description,
            'subject_name'     => $quiz->subject->name ?? null,
            'subject_id'       => $quiz->subject_id,
            'creator_name'     => $quiz->creator->name ?? null,
            'creator_type'     => $quiz->creator_type,
            'is_competition'   => $quiz->is_competition,
            'status'           => $quiz->status,
            'status_label'     => $quiz->status_label,
            'status_color'     => $quiz->status_color,
            'duration_minutes' => $quiz->time_limit_minutes,   // Flutter reads 'duration_minutes'
            'time_limit_minutes' => $quiz->time_limit_minutes,
            'timer_mode'       => $quiz->timer_mode ?? 'quiz',
            'allow_question_backtracking' => (bool) $quiz->allow_question_backtracking,
            'questions_count'  => $questionsCount,
            'models_count'     => $quiz->models_count ?? 0,
            'starts_at'        => $quiz->scheduled_at?->toIso8601String(),  // Flutter reads 'starts_at'
            'scheduled_at'     => $quiz->scheduled_at?->toIso8601String(),
            'closes_at'        => $quiz->closes_at?->toIso8601String(),
            'is_upcoming'      => $quiz->isUpcoming(),
            'is_effectively_published' => $quiz->isEffectivelyPublished(),
            'show_countdown'   => $quiz->show_countdown,
            'is_attempted'     => $isAttempted,
            'attempt_id'       => $attemptId,
            'shuffle_questions' => $quiz->shuffle_questions,
            'shuffle_options'  => $quiz->shuffle_options,
            'results_visibility' => $quiz->results_visibility,
            'requires_access_code' => $quiz->models()->whereNotNull('access_code')->where('access_code', '!=', '')->exists(),
            'created_at'       => $quiz->created_at->toIso8601String(),
        ];
    }

    /**
     * Start/resume a quiz attempt.
     */
    public function take(Request $request, Quiz $quiz)
    {
        $student = Auth::user();

        // Check access
        if (!$quiz->isAccessibleBy($student)) {
            return $this->error('لا يمكنك الوصول لهذا الكويز', 403);
        }

        // Check if already attempted and not in progress
        $existingAttempt = $quiz->attemptBy($student);
        if ($existingAttempt && $existingAttempt->status !== 'in_progress') {
            return $this->success([
                'already_submitted' => true,
                'attempt_id'        => $existingAttempt->id,
            ], 'لقد قمت بتسليم هذا الكويز مسبقاً');
        }

        if ($existingAttempt && ! $existingAttempt->isWithinTimeLimit()) {
            $existingAnswers = $existingAttempt->answers()
                ->whereNotNull('selected_option_id')
                ->pluck('selected_option_id', 'question_id')
                ->toArray();
            $existingAttempt->finalizeWithAnswers($existingAnswers);

            return $this->success([
                'already_submitted' => true,
                'attempt_id' => $existingAttempt->id,
                'expired' => true,
            ], 'انتهى وقت الكويز وتم تسليم المحاولة.');
        }

        // Pick or retrieve quiz model
        if ($existingAttempt) {
            $attempt = $existingAttempt;
            $quizModel = $attempt->quizModel;
        } else {
            $requiresAccessCode = $quiz->models()
                ->whereNotNull('access_code')
                ->where('access_code', '!=', '')
                ->exists();

            if ($requiresAccessCode) {
                $accessCode = $this->normalizeAccessCode($request->get('access_code'));

                if (!$accessCode) {
                    return $this->error('رمز الدخول مطلوب', 403, ['requires_access_code' => true]);
                }

                $quizModel = $quiz->models()->where('access_code', $accessCode)->first();

                if (!$quizModel) {
                    return $this->error('رمز الدخول غير صحيح', 403, ['requires_access_code' => true]);
                }
            } else {
                $quizModel = $quiz->models()->inRandomOrder()->first();
            }

            if (!$quizModel) {
                return $this->error('لا توجد نماذج متاحة لهذا الكويز', 404);
            }

            // Create attempt
            $attempt = QuizAttempt::create([
                'quiz_id'       => $quiz->id,
                'quiz_model_id' => $quizModel->id,
                'student_id'    => $student->id,
                'started_at'    => now(),
                'status'        => 'in_progress',
            ]);
        }

        // Load nested questions & options
        $questions = $quizModel->questions()
            ->with(['options' => function ($q) use ($quiz) {
                if ($quiz->shuffle_options) {
                    $q->inRandomOrder();
                } else {
                    $q->orderBy('order');
                }
            }])
            ->when($quiz->shuffle_questions, fn($q) => $q->inRandomOrder())
            ->when(!$quiz->shuffle_questions, fn($q) => $q->orderBy('order'))
            ->get();

        // Get existing answers
        $existingAnswers = $attempt->answers()->pluck('selected_option_id', 'question_id');

        return $this->success([
            'quiz'             => array_merge(
                $quiz->load(['creator:id,name', 'subject:id,name'])->toArray(),
                [
                    'duration_minutes' => $quiz->time_limit_minutes,
                    'timer_mode' => $quiz->timer_mode ?? 'quiz',
                    'allow_question_backtracking' => (bool) $quiz->allow_question_backtracking,
                ]
            ),
            'attempt'          => array_merge($attempt->toArray(), [
                'remaining_seconds' => $attempt->remaining_seconds,
            ]),
            'questions'        => $questions,
            'existing_answers' => $existingAnswers,
        ], 'بدأ المحاولة');
    }

    /**
     * Submit quiz answers.
     */
    public function submit(Request $request, QuizAttempt $attempt)
    {
        $student = Auth::user();

        if ($attempt->student_id !== $student->id) {
            return $this->error('غير مصرح لك بالوصول لهذه المحاولة', 403);
        }

        if ($attempt->status !== 'in_progress') {
            return $this->error('تم تسليم هذا الكويز مسبقاً', 400);
        }

        $validated = $request->validate([
            'answers'   => 'nullable|array',
            'answers.*' => 'nullable|integer|exists:quiz_options,id',
        ]);

        DB::beginTransaction();
        try {
            $attempt->finalizeWithAnswers($validated['answers'] ?? []);

            DB::commit();

            return $this->success([
                'attempt_id' => $attempt->id,
            ], 'تم تسليم الكويز بنجاح');

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->error('حدث خطأ أثناء التسليم: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Show quiz result.
     */
    public function result(QuizAttempt $attempt)
    {
        $student = Auth::user();

        if ($attempt->student_id !== $student->id) {
            return $this->error('غير مصرح لك بالوصول لهذه النتيجة', 403);
        }

        $quiz = $attempt->quiz;

        // Check if results are hidden
        if ($quiz->results_visibility === 'hidden') {
            return $this->success([
                'quiz'    => $quiz->only(['id', 'title']),
                'attempt' => $attempt->only(['id', 'submitted_at', 'status']),
                'message' => 'نتائج هذا الكويز مخفية حالياً من قبل المدرس.',
            ], 'تم إخفاء النتائج');
        }

        $attempt->load(['answers.question.options', 'answers.selectedOption', 'quizModel']);
        $publicResults = [];

        if ($quiz->results_visibility === 'public') {
            $publicResults = QuizAttempt::where('quiz_id', $quiz->id)
                ->where('status', 'graded')
                ->whereNotNull('submitted_at')
                ->with(['student:id,name,student_number', 'quizModel:id,name'])
                ->orderByDesc('score')
                ->orderBy('submitted_at')
                ->get()
                ->values()
                ->map(fn (QuizAttempt $resultAttempt, int $index) => [
                    'rank' => $index + 1,
                    'id' => $resultAttempt->id,
                    'student' => [
                        'id' => $resultAttempt->student?->id,
                        'name' => $resultAttempt->student?->name ?? 'طالب',
                        'student_number' => $resultAttempt->student?->student_number,
                    ],
                    'model_name' => $resultAttempt->quizModel?->name,
                    'score' => (float) ($resultAttempt->score ?? 0),
                    'max_score' => (float) ($resultAttempt->max_score ?? 0),
                    'percentage' => (float) $resultAttempt->percentage,
                    'submitted_at' => $resultAttempt->submitted_at?->toIso8601String(),
                    'is_current_student' => $resultAttempt->student_id === $student->id,
                ])
                ->all();
        }

        return $this->success([
            'quiz'    => $quiz->load(['creator:id,name', 'subject:id,name']),
            'attempt' => array_merge($attempt->toArray(), [
                'percentage' => $attempt->percentage,
                'duration'   => $attempt->duration,
                'correct_answers_count' => $attempt->correct_count,
                'wrong_answers_count'   => $attempt->wrong_count,
                'unanswered_answers_count' => $attempt->answers()->where('answer_status', 'unanswered')->count(),
            ]),
            'public_results' => $publicResults,
        ], 'تم جلب النتيجة بنجاح');
    }

    protected function normalizeAccessCode(?string $code): ?string
    {
        $code = trim((string) $code);

        return $code === '' ? null : Str::upper($code);
    }
}
