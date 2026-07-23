<?php

namespace App\Http\Controllers\Api\Doctor;

use App\Models\Academic\Subject;
use App\Models\Quiz\Quiz;
use App\Models\Quiz\QuizAttempt;
use App\Models\Quiz\QuizModel;
use App\Models\Quiz\QuizOption;
use App\Models\Quiz\QuizQuestion;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use App\Services\QuizNotificationService;

class QuizController extends DoctorApiController
{
    protected function ownedQuizOrFail(Quiz $quiz): Quiz
    {
        abort_unless($quiz->created_by === Auth::id() && $quiz->creator_type === 'doctor', 403);

        return $quiz;
    }

    public function index(Request $request)
    {
        $query = Quiz::forDoctor(Auth::id())
            ->with(['subject:id,name', 'models:id,quiz_id,name'])
            ->withCount('attempts');

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        $quizzes = $query->latest()->paginate($request->integer('per_page', 12));

        return $this->success([
            'quizzes' => $quizzes->items(),
            'filters' => [
                'subjects' => Subject::where('doctor_id', Auth::id())
                    ->orderBy('name')
                    ->get(['id', 'name']),
            ],
            'pagination' => [
                'current_page' => $quizzes->currentPage(),
                'last_page' => $quizzes->lastPage(),
                'per_page' => $quizzes->perPage(),
                'total' => $quizzes->total(),
            ],
            'stats' => [
                'total' => Quiz::forDoctor(Auth::id())->count(),
                'draft' => Quiz::forDoctor(Auth::id())->where('status', 'draft')->count(),
                'published' => Quiz::forDoctor(Auth::id())->where('status', 'published')->count(),
                'scheduled' => Quiz::forDoctor(Auth::id())->where('status', 'scheduled')->count(),
                'closed' => Quiz::forDoctor(Auth::id())->where('status', 'closed')->count(),
            ],
        ]);
    }

    public function store(Request $request)
    {
        $doctor = $request->user();
        $validated = $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'timer_mode' => 'required|in:quiz,per_question',
            'time_limit_minutes' => 'nullable|required_if:timer_mode,quiz|integer|min:1|max:300',
            'allow_question_backtracking' => 'nullable|boolean',
            'shuffle_questions' => 'nullable|boolean',
            'shuffle_options' => 'nullable|boolean',
            'show_correct_answers' => 'nullable|boolean',
            'show_correction_notes' => 'nullable|boolean',
            'notify_students' => 'nullable|boolean',
            'show_countdown' => 'nullable|boolean',
            'use_access_code' => 'nullable|boolean',
            'results_visibility' => 'required|in:hidden,individual,public',
            'scheduled_at' => 'nullable|date',
            'closes_at' => 'nullable|date|after:scheduled_at',
            'models' => 'required|array|min:1',
            'models.*.name' => 'required|string|max:100',
            'models.*.access_code' => [
                'nullable',
                Rule::requiredIf(fn () => $request->boolean('use_access_code')),
                'string',
                'max:50',
            ],
            'models.*.questions' => 'required|array|min:1',
            'models.*.questions.*.question_text' => 'required|string',
            'models.*.questions.*.question_type' => 'required|in:multiple_choice,true_false',
            'models.*.questions.*.score' => 'nullable|numeric|min:0',
            'models.*.questions.*.time_limit_seconds' => 'nullable|required_if:timer_mode,per_question|integer|min:1',
            'models.*.questions.*.correction_note' => 'nullable|string',
            'models.*.questions.*.info_source' => 'nullable|string',
            'models.*.questions.*.options' => 'required|array|min:2',
            'models.*.questions.*.options.*.option_text' => 'required|string',
            'models.*.questions.*.options.*.is_correct' => 'nullable|boolean',
        ]);
        $this->ensureDistinctModelAccessCodes(
            $validated['models'],
            $request->boolean('use_access_code')
        );

        Subject::where('id', $validated['subject_id'])
            ->where('doctor_id', $doctor->id)
            ->firstOrFail();

        DB::beginTransaction();

        try {
            $status = 'draft';
            if (!empty($validated['scheduled_at'])) {
                $status = now()->gte($validated['scheduled_at']) ? 'published' : 'scheduled';
            }

            $quiz = Quiz::create([
                'created_by' => $doctor->id,
                'creator_type' => 'doctor',
                'subject_id' => $validated['subject_id'],
                'title' => $validated['title'],
                'description' => $validated['description'] ?? null,
                'time_limit_minutes' => $validated['time_limit_minutes'] ?? null,
                'timer_mode' => $validated['timer_mode'],
                'allow_question_backtracking' => $request->has('allow_question_backtracking')
                    ? $request->boolean('allow_question_backtracking')
                    : true,
                'shuffle_questions' => $request->boolean('shuffle_questions'),
                'shuffle_options' => $request->boolean('shuffle_options'),
                'show_correct_answers' => $request->boolean('show_correct_answers'),
                'show_correction_notes' => $request->boolean('show_correction_notes', true),
                'results_visibility' => $validated['results_visibility'],
                'scheduled_at' => $validated['scheduled_at'] ?? null,
                'closes_at' => $validated['closes_at'] ?? null,
                'status' => $status,
                'notify_students' => $request->boolean('notify_students'),
                'show_countdown' => $request->boolean('show_countdown'),
            ]);

            $this->syncModels(
                $quiz,
                $validated['models'],
                $request->boolean('use_access_code'),
                $validated['timer_mode']
            );

            DB::commit();

            app(QuizNotificationService::class)->notifyIfEnabled($quiz->fresh(['subject']));

            return $this->success($quiz->load('subject:id,name', 'models.questions.options'), 'تم إنشاء الكويز بنجاح.', 201);
        } catch (\Throwable $exception) {
            DB::rollBack();
            return $this->error('حدث خطأ أثناء إنشاء الكويز: ' . $exception->getMessage(), 500);
        }
    }

    public function show(Quiz $quiz)
    {
        $quiz = $this->ownedQuizOrFail($quiz);
        $quiz->load(['subject:id,name', 'models.questions.options', 'attempts.student:id,name,student_number']);

        $gradedAttempts = $quiz->attempts->where('status', 'graded');

        return $this->success([
            'quiz' => $quiz,
            'stats' => [
                'total_attempts' => $quiz->attempts->count(),
                'avg_score' => round($gradedAttempts->avg('percentage') ?? 0, 1),
                'highest_score' => $gradedAttempts->max('percentage') ?? 0,
                'lowest_score' => $gradedAttempts->min('percentage') ?? 0,
            ],
            'can_edit_content' => $quiz->attempts->count() === 0,
        ]);
    }

    public function update(Request $request, Quiz $quiz)
    {
        $quiz = $this->ownedQuizOrFail($quiz);
        $canEditContent = $quiz->attempts()->count() === 0;

        $rules = [
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'timer_mode' => 'required|in:quiz,per_question',
            'time_limit_minutes' => 'nullable|required_if:timer_mode,quiz|integer|min:1|max:300',
            'allow_question_backtracking' => 'nullable|boolean',
            'shuffle_questions' => 'nullable|boolean',
            'shuffle_options' => 'nullable|boolean',
            'show_correct_answers' => 'nullable|boolean',
            'show_correction_notes' => 'nullable|boolean',
            'notify_students' => 'nullable|boolean',
            'show_countdown' => 'nullable|boolean',
            'use_access_code' => 'nullable|boolean',
            'results_visibility' => 'required|in:hidden,individual,public',
            'scheduled_at' => 'nullable|date',
            'closes_at' => 'nullable|date|after:scheduled_at',
        ];

        if ($canEditContent) {
            $rules += [
                'models' => 'required|array|min:1',
                'models.*.name' => 'required|string|max:100',
                'models.*.access_code' => [
                    'nullable',
                    Rule::requiredIf(fn () => $request->boolean('use_access_code')),
                    'string',
                    'max:50',
                ],
                'models.*.questions' => 'required|array|min:1',
                'models.*.questions.*.question_text' => 'required|string',
                'models.*.questions.*.question_type' => 'required|in:multiple_choice,true_false',
                'models.*.questions.*.score' => 'nullable|numeric|min:0',
                'models.*.questions.*.time_limit_seconds' => 'nullable|required_if:timer_mode,per_question|integer|min:1',
                'models.*.questions.*.correction_note' => 'nullable|string',
                'models.*.questions.*.info_source' => 'nullable|string',
                'models.*.questions.*.options' => 'required|array|min:2',
                'models.*.questions.*.options.*.option_text' => 'required|string',
                'models.*.questions.*.options.*.is_correct' => 'nullable|boolean',
            ];
        }

        $validated = $request->validate($rules);
        if ($canEditContent && isset($validated['models'])) {
            $this->ensureDistinctModelAccessCodes(
                $validated['models'],
                $request->boolean('use_access_code')
            );
        }

        Subject::where('id', $validated['subject_id'])
            ->where('doctor_id', Auth::id())
            ->firstOrFail();

        DB::beginTransaction();

        try {
            $status = $quiz->status;
            if (in_array($status, ['draft', 'scheduled'], true) && !empty($validated['scheduled_at'])) {
                $status = now()->gte($validated['scheduled_at']) ? 'published' : 'scheduled';
            }

            $quiz->update([
                'subject_id' => $validated['subject_id'],
                'title' => $validated['title'],
                'description' => $validated['description'] ?? null,
                'time_limit_minutes' => $validated['time_limit_minutes'] ?? null,
                'timer_mode' => $validated['timer_mode'],
                'allow_question_backtracking' => $request->has('allow_question_backtracking')
                    ? $request->boolean('allow_question_backtracking')
                    : (bool) $quiz->allow_question_backtracking,
                'shuffle_questions' => $request->boolean('shuffle_questions'),
                'shuffle_options' => $request->boolean('shuffle_options'),
                'show_correct_answers' => $request->boolean('show_correct_answers'),
                'show_correction_notes' => $request->boolean('show_correction_notes', true),
                'notify_students' => $request->boolean('notify_students'),
                'show_countdown' => $request->boolean('show_countdown'),
                'results_visibility' => $validated['results_visibility'],
                'scheduled_at' => $validated['scheduled_at'] ?? null,
                'closes_at' => $validated['closes_at'] ?? null,
                'status' => $status,
            ]);

            if ($canEditContent && isset($validated['models'])) {
                $quiz->models()->delete();
                $this->syncModels(
                    $quiz,
                    $validated['models'],
                    $request->boolean('use_access_code'),
                    $validated['timer_mode']
                );
            }

            DB::commit();

            app(QuizNotificationService::class)->notifyIfEnabled($quiz->fresh(['subject']));

            return $this->success($quiz->fresh()->load('subject:id,name', 'models.questions.options'), 'تم تحديث الكويز بنجاح.');
        } catch (\Throwable $exception) {
            DB::rollBack();
            return $this->error('حدث خطأ أثناء تعديل الكويز: ' . $exception->getMessage(), 500);
        }
    }

    public function results(Quiz $quiz)
    {
        [$quiz, $attempts] = $this->quizResultsData($quiz);
        $formattedAttempts = $attempts->map(fn (QuizAttempt $attempt) => $this->formatResultAttempt($attempt))->values();
        $percentages = $formattedAttempts->pluck('percentage')->filter(fn ($value) => $value !== null);

        return $this->success([
            'quiz' => [
                'id' => $quiz->id,
                'title' => $quiz->title,
                'status' => $quiz->status,
                'results_visibility' => $quiz->results_visibility,
                'subject_name' => $quiz->subject?->name,
                'major_name' => $quiz->subject?->major?->name,
                'level_name' => $quiz->subject?->level?->name,
            ],
            'stats' => [
                'total_attempts' => $formattedAttempts->count(),
                'avg_score' => $percentages->isEmpty() ? 0 : round($percentages->avg(), 1),
                'highest_score' => $percentages->isEmpty() ? 0 : round($percentages->max(), 1),
                'lowest_score' => $percentages->isEmpty() ? 0 : round($percentages->min(), 1),
            ],
            'attempts' => $formattedAttempts,
        ]);
    }

    public function exportResults(Quiz $quiz)
    {
        [$quiz, $attempts] = $this->quizResultsData($quiz);

        $rows = [
            ['Quiz Results Report'],
            ['Subject', $quiz->subject?->name ?? '-'],
            ['Quiz', $quiz->title],
            ['Major', $quiz->subject?->major?->name ?? '-'],
            ['Level', $quiz->subject?->level?->name ?? '-'],
            ['Attempts Count', $attempts->count()],
            ['Exported At', now()->format('Y-m-d H:i:s')],
            [],
            ['#', 'Student Name', 'Student Number', 'Quiz Model', 'Score', 'Max Score', 'Percentage', 'Correct Answers', 'Wrong Answers', 'Duration (Minutes)', 'Status', 'Submitted At'],
        ];

        foreach ($attempts as $index => $attempt) {
            $rows[] = [
                $index + 1,
                $attempt->student?->name ?? '-',
                $attempt->student?->student_number ?? '-',
                $attempt->quizModel?->name ?? '-',
                (float) ($attempt->score ?? 0),
                (float) ($attempt->max_score ?? 0),
                $attempt->percentage,
                $attempt->correct_count,
                $attempt->wrong_count,
                $attempt->duration ?? '-',
                $attempt->status_label,
                $attempt->submitted_at?->format('Y-m-d H:i') ?? '-',
            ];
        }

        $csvContent = chr(0xEF) . chr(0xBB) . chr(0xBF);
        foreach ($rows as $row) {
            $escaped = array_map(static function ($value) {
                $value = (string) $value;
                return '"' . str_replace('"', '""', $value) . '"';
            }, $row);
            $csvContent .= implode(',', $escaped) . "\n";
        }

        return response($csvContent)
            ->header('Content-Type', 'text/csv; charset=UTF-8')
            ->header('Content-Disposition', 'attachment; filename="quiz_results_' . $quiz->id . '_' . now()->format('Y-m-d_His') . '.csv"');
    }

    public function publish(Quiz $quiz)
    {
        $quiz = $this->ownedQuizOrFail($quiz);
        $quiz->update(['status' => 'published']);
        app(QuizNotificationService::class)->notifyIfEnabled($quiz->fresh(['subject']));

        return $this->success($quiz->only(['id', 'status']), 'تم نشر الكويز بنجاح.');
    }

    public function close(Quiz $quiz)
    {
        $quiz = $this->ownedQuizOrFail($quiz);
        $quiz->update(['status' => 'closed']);

        return $this->success($quiz->only(['id', 'status']), 'تم إغلاق الكويز.');
    }

    public function shareResults(Request $request, Quiz $quiz)
    {
        $quiz = $this->ownedQuizOrFail($quiz);
        $validated = $request->validate([
            'visibility' => 'required|in:hidden,individual,public',
        ]);

        $quiz->update(['results_visibility' => $validated['visibility']]);

        return $this->success($quiz->only(['id', 'results_visibility']), 'تم تحديث إعدادات مشاركة النتائج.');
    }

    public function destroy(Quiz $quiz)
    {
        $quiz = $this->ownedQuizOrFail($quiz);
        $quiz->delete();

        return $this->success(null, 'تم حذف الكويز بنجاح.');
    }

    protected function syncModels(
        Quiz $quiz,
        array $models,
        bool $useAccessCode,
        string $timerMode
    ): void
    {
        foreach ($models as $modelData) {
            $accessCode = $useAccessCode
                ? $this->normalizeAccessCode($modelData['access_code'] ?? null)
                : null;

            $quizModel = QuizModel::create([
                'quiz_id' => $quiz->id,
                'name' => $modelData['name'],
                'access_code' => $accessCode,
            ]);

            foreach ($modelData['questions'] as $qIndex => $questionData) {
                $question = QuizQuestion::create([
                    'quiz_model_id' => $quizModel->id,
                    'question_text' => $questionData['question_text'],
                    'question_type' => $questionData['question_type'],
                    'score' => $questionData['score'] ?? 1,
                    'time_limit_seconds' => $timerMode === 'per_question' ? ($questionData['time_limit_seconds'] ?? null) : null,
                    'correction_note' => $questionData['correction_note'] ?? null,
                    'info_source' => $questionData['info_source'] ?? null,
                    'order' => $qIndex + 1,
                ]);

                foreach ($questionData['options'] as $oIndex => $optionData) {
                    QuizOption::create([
                        'question_id' => $question->id,
                        'option_text' => $optionData['option_text'],
                        'is_correct' => !empty($optionData['is_correct']),
                        'order' => $oIndex + 1,
                    ]);
                }
            }
        }
    }

    protected function normalizeAccessCode(?string $code): ?string
    {
        $code = trim((string) $code);

        return $code === '' ? null : Str::upper($code);
    }

    protected function ensureDistinctModelAccessCodes(array $models, bool $useAccessCode): void
    {
        if (! $useAccessCode) {
            return;
        }

        $seen = [];

        foreach ($models as $modelData) {
            $accessCode = $this->normalizeAccessCode($modelData['access_code'] ?? null);

            if (! $accessCode) {
                continue;
            }

            if (isset($seen[$accessCode])) {
                throw ValidationException::withMessages([
                    'models' => 'كود الدخول مكرر داخل نفس الكويز. استخدم كوداً مختلفاً لكل نموذج.',
                ]);
            }

            $seen[$accessCode] = true;
        }
    }

    protected function formatResultAttempt(QuizAttempt $attempt): array
    {
        return [
            'id' => $attempt->id,
            'quiz_id' => $attempt->quiz_id,
            'student' => $attempt->student ? [
                'id' => $attempt->student->id,
                'name' => $attempt->student->name,
                'student_number' => $attempt->student->student_number,
            ] : null,
            'quiz_model' => $attempt->quizModel ? [
                'id' => $attempt->quizModel->id,
                'name' => $attempt->quizModel->name,
            ] : null,
            'score' => (float) ($attempt->score ?? 0),
            'max_score' => (float) ($attempt->max_score ?? 0),
            'percentage' => (float) $attempt->percentage,
            'correct_count' => (int) $attempt->correct_count,
            'wrong_count' => (int) $attempt->wrong_count,
            'duration' => $attempt->duration,
            'status' => $attempt->status,
            'status_label' => $attempt->status_label,
            'submitted_at' => $attempt->submitted_at?->toIso8601String(),
            'submitted_at_label' => $attempt->submitted_at?->format('Y-m-d H:i'),
            'started_at' => $attempt->started_at?->toIso8601String(),
        ];
    }

    protected function quizResultsData(Quiz $quiz): array
    {
        $quiz = $this->ownedQuizOrFail($quiz);
        $quiz->loadMissing(['subject.major', 'subject.level']);

        $attempts = QuizAttempt::where('quiz_id', $quiz->id)
            ->with(['student:id,name,student_number', 'quizModel:id,name', 'answers.question'])
            ->orderByDesc('score')
            ->get();

        return [$quiz, $attempts];
    }
}
