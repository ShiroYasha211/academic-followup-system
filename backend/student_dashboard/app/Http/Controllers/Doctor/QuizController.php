<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Controller;
use App\Models\Quiz\Quiz;
use App\Models\Quiz\QuizModel;
use App\Models\Quiz\QuizQuestion;
use App\Models\Quiz\QuizOption;
use App\Models\Quiz\QuizAttempt;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use App\Services\QuizNotificationService;

class QuizController extends Controller
{
    protected function ownedQuizOrFail(Quiz $quiz): Quiz
    {
        abort_unless($quiz->created_by === Auth::id() && $quiz->creator_type === 'doctor', 403);

        return $quiz;
    }

    /**
     * List all quizzes created by this doctor.
     */
    public function index(Request $request)
    {
        $doctor = Auth::user();
        $status = $request->get('status', 'all');

        $query = Quiz::forDoctor($doctor->id)
            ->with(['subject', 'models'])
            ->withCount('attempts');

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        $quizzes = $query->latest()->paginate(12);

        return view('doctor.quizzes.index', compact('quizzes', 'status'));
    }

    /**
     * Show quiz creation form.
     */
    public function create()
    {
        $doctor = Auth::user();
        $subjects = Subject::where('doctor_id', $doctor->id)->with('level')->get();

        return view('doctor.quizzes.create', compact('subjects'));
    }

    /**
     * Store a new quiz with models, questions, and options.
     */
    public function store(Request $request)
    {
        $doctor = Auth::user();

        $validated = $request->validate([
            'subject_id'           => 'required|exists:subjects,id',
            'title'                => 'required|string|max:255',
            'description'          => 'nullable|string',
            'timer_mode'           => 'required|in:quiz,per_question',
            'time_limit_minutes'   => 'nullable|required_if:timer_mode,quiz|integer|min:1|max:300',
            'shuffle_questions'    => 'nullable|boolean',
            'shuffle_options'      => 'nullable|boolean',
            'show_correct_answers' => 'nullable|boolean',
            'show_correction_notes'=> 'nullable|boolean',
            'notify_students'      => 'nullable|boolean',
            'show_countdown'       => 'nullable|boolean',
            'use_access_code'      => 'nullable|boolean',
            'results_visibility'   => 'required|in:hidden,individual,public',
            'scheduled_at'         => 'nullable|date',
            'closes_at'            => 'nullable|date|after:scheduled_at',
            'models'               => 'required|array|min:1',
            'models.*.name'        => 'required|string|max:100',
            'models.*.questions'   => 'required|array|min:1',
            'models.*.questions.*.question_text'     => 'required|string',
            'models.*.questions.*.question_type'     => 'required|in:multiple_choice,true_false',
            'models.*.questions.*.score'             => 'nullable|numeric|min:0',
            'models.*.questions.*.time_limit_seconds'=> 'nullable|required_if:timer_mode,per_question|integer|min:1',
            'models.*.questions.*.correction_note'   => 'nullable|string',
            'models.*.questions.*.info_source'       => 'nullable|string',
            'models.*.questions.*.options'           => 'required|array|min:2',
            'models.*.questions.*.options.*.option_text' => 'required|string',
            'models.*.questions.*.options.*.is_correct'  => 'nullable',
        ]);

        // Verify subject ownership
        Subject::where('id', $validated['subject_id'])
            ->where('doctor_id', $doctor->id)
            ->firstOrFail();

        DB::beginTransaction();

        try {
            // Determine status
            $status = 'draft';
            if (!empty($validated['scheduled_at'])) {
                $status = now()->gte($validated['scheduled_at']) ? 'published' : 'scheduled';
            }

            // Create quiz
            $quiz = Quiz::create([
                'created_by'            => $doctor->id,
                'creator_type'          => 'doctor',
                'subject_id'            => $validated['subject_id'],
                'title'                 => $validated['title'],
                'description'           => $validated['description'] ?? null,
                'time_limit_minutes'    => $validated['time_limit_minutes'] ?? null,
                'timer_mode'            => $validated['timer_mode'],
                'shuffle_questions'     => $request->boolean('shuffle_questions'),
                'shuffle_options'       => $request->boolean('shuffle_options'),
                'show_correct_answers'  => $request->boolean('show_correct_answers'),
                'show_correction_notes' => $request->boolean('show_correction_notes', true),
                'results_visibility'    => $validated['results_visibility'],
                'scheduled_at'          => $validated['scheduled_at'] ?? null,
                'closes_at'             => $validated['closes_at'] ?? null,
                'status'                => $status,
                'notify_students'       => $request->boolean('notify_students'),
                'show_countdown'        => $request->boolean('show_countdown'),
            ]);

            // Create models with questions and options
            foreach ($validated['models'] as $modelData) {
                $quizModel = QuizModel::create([
                    'quiz_id'     => $quiz->id,
                    'name'        => $modelData['name'],
                    'access_code' => $request->boolean('use_access_code') ? strtoupper(Str::random(6)) : null,
                ]);

                foreach ($modelData['questions'] as $qIndex => $questionData) {
                    $question = QuizQuestion::create([
                        'quiz_model_id'   => $quizModel->id,
                        'question_text'   => $questionData['question_text'],
                        'question_type'   => $questionData['question_type'],
                        'score'           => $questionData['score'] ?? 1,
                        'time_limit_seconds' => $validated['timer_mode'] === 'per_question' ? ($questionData['time_limit_seconds'] ?? null) : null,
                        'correction_note' => $questionData['correction_note'] ?? null,
                        'info_source'     => $questionData['info_source'] ?? null,
                        'order'           => $qIndex + 1,
                    ]);

                    foreach ($questionData['options'] as $oIndex => $optionData) {
                        QuizOption::create([
                            'question_id' => $question->id,
                            'option_text'  => $optionData['option_text'],
                            'is_correct'   => !empty($optionData['is_correct']),
                            'order'        => $oIndex + 1,
                        ]);
                    }
                }
            }

            DB::commit();

            app(QuizNotificationService::class)->notifyIfEnabled($quiz->fresh(['subject']));

            return redirect()->route('doctor.quizzes.show', $quiz)
                ->with('success', 'تم إنشاء الكويز بنجاح.');

        } catch (\Exception $e) {
            DB::rollBack();
            return back()->withInput()->with('error', 'حدث خطأ أثناء إنشاء الكويز: ' . $e->getMessage());
        }
    }

    /**
     * Show quiz details and stats.
     */
    public function show(Quiz $quiz)
    {
        $quiz = $this->ownedQuizOrFail($quiz);

        $quiz->load(['subject', 'models.questions.options', 'attempts.student']);

        $stats = [
            'total_attempts' => $quiz->attempts_count,
            'avg_score'      => $quiz->attempts->where('status', 'graded')->avg('percentage') ?? 0,
            'highest_score'  => $quiz->attempts->where('status', 'graded')->max('percentage') ?? 0,
            'lowest_score'   => $quiz->attempts->where('status', 'graded')->min('percentage') ?? 0,
        ];

        return view('doctor.quizzes.show', compact('quiz', 'stats'));
    }

    /**
     * Edit quiz form.
     */
    public function edit(Quiz $quiz)
    {
        $doctor = Auth::user();
        $quiz = $this->ownedQuizOrFail($quiz);

        $quiz->load(['models.questions.options']);
        $subjects = Subject::where('doctor_id', $doctor->id)->with('level')->get();
        $canEditContent = $quiz->attempts()->count() === 0;

        // Prepare initial data for the frontend builder
        $initialModels = $quiz->models->map(function($model) {
            return [
                'name' => $model->name,
                'questions' => $model->questions->map(function($q) {
                    return [
                        'text' => $q->question_text,
                        'score' => $q->score,
                        'time_limit_seconds' => $q->time_limit_seconds,
                        'correction_note' => $q->correction_note,
                        'info_source' => $q->info_source,
                        'options' => $q->options->map(function($o) {
                            return [
                                'text' => $o->option_text,
                                'is_correct' => (bool)$o->is_correct
                            ];
                        })
                    ];
                })
            ];
        });

        return view('doctor.quizzes.edit', compact('quiz', 'subjects', 'canEditContent', 'initialModels'));
    }

    /**
     * Update quiz settings and content.
     */
    public function update(Request $request, Quiz $quiz)
    {
        $doctor = Auth::user();
        $quiz = $this->ownedQuizOrFail($quiz);

        $canEditContent = $quiz->attempts()->count() === 0;

        $rules = [
            'subject_id'           => 'required|exists:subjects,id',
            'title'                => 'required|string|max:255',
            'description'          => 'nullable|string',
            'timer_mode'           => 'required|in:quiz,per_question',
            'time_limit_minutes'   => 'nullable|required_if:timer_mode,quiz|integer|min:1|max:300',
            'shuffle_questions'    => 'nullable|boolean',
            'shuffle_options'      => 'nullable|boolean',
            'show_correct_answers' => 'nullable|boolean',
            'show_correction_notes'=> 'nullable|boolean',
            'notify_students'      => 'nullable|boolean',
            'show_countdown'       => 'nullable|boolean',
            'use_access_code'      => 'nullable|boolean',
            'results_visibility'   => 'required|in:hidden,individual,public',
            'scheduled_at'         => 'nullable|date',
            'closes_at'            => 'nullable|date|after:scheduled_at',
        ];

        if ($canEditContent) {
            $rules += [
                'models'               => 'required|array|min:1',
                'models.*.name'        => 'required|string|max:100',
                'models.*.questions'   => 'required|array|min:1',
                'models.*.questions.*.question_text'     => 'required|string',
                'models.*.questions.*.question_type'     => 'required|in:multiple_choice,true_false',
                'models.*.questions.*.score'             => 'nullable|numeric|min:0',
                'models.*.questions.*.time_limit_seconds'=> 'nullable|required_if:timer_mode,per_question|integer|min:1',
                'models.*.questions.*.correction_note'   => 'nullable|string',
                'models.*.questions.*.info_source'       => 'nullable|string',
                'models.*.questions.*.options'           => 'required|array|min:2',
                'models.*.questions.*.options.*.option_text' => 'required|string',
                'models.*.questions.*.options.*.is_correct'  => 'nullable',
            ];
        }

        $validated = $request->validate($rules);

        // Verify subject ownership
        Subject::where('id', $validated['subject_id'])->where('doctor_id', $doctor->id)->firstOrFail();

        DB::beginTransaction();

        try {
            // Determine status
            $status = $quiz->status;
            if ($status === 'draft' || $status === 'scheduled') {
                if (!empty($validated['scheduled_at'])) {
                    $status = now()->gte($validated['scheduled_at']) ? 'published' : 'scheduled';
                }
            }

            // Update quiz basic fields
            $quiz->update([
                'subject_id'            => $validated['subject_id'],
                'title'                 => $validated['title'],
                'description'           => $validated['description'] ?? null,
                'time_limit_minutes'    => $validated['time_limit_minutes'] ?? null,
                'timer_mode'            => $validated['timer_mode'],
                'shuffle_questions'     => $request->boolean('shuffle_questions'),
                'shuffle_options'       => $request->boolean('shuffle_options'),
                'show_correct_answers'  => $request->boolean('show_correct_answers'),
                'show_correction_notes' => $request->boolean('show_correction_notes', true),
                'notify_students'       => $request->boolean('notify_students'),
                'show_countdown'        => $request->boolean('show_countdown'),
                'results_visibility'    => $validated['results_visibility'],
                'scheduled_at'          => $validated['scheduled_at'] ?? null,
                'closes_at'             => $validated['closes_at'] ?? null,
                'status'                => $status,
            ]);

            // Full content replacement if allowed (no attempts yet)
            if ($canEditContent && isset($validated['models'])) {
                // Delete existing models (cascading deletes questions/options)
                $quiz->models()->delete();

                // Recreate models with questions and options (reuse logic from store)
                foreach ($validated['models'] as $modelData) {
                    $quizModel = QuizModel::create([
                        'quiz_id'     => $quiz->id,
                        'name'        => $modelData['name'],
                        'access_code' => $request->boolean('use_access_code') ? strtoupper(Str::random(6)) : null,
                    ]);

                    foreach ($modelData['questions'] as $qIndex => $questionData) {
                        $question = QuizQuestion::create([
                            'quiz_model_id'   => $quizModel->id,
                            'question_text'   => $questionData['question_text'],
                            'question_type'   => $questionData['question_type'],
                            'score'           => $questionData['score'] ?? 1,
                            'time_limit_seconds' => $validated['timer_mode'] === 'per_question' ? ($questionData['time_limit_seconds'] ?? null) : null,
                            'correction_note' => $questionData['correction_note'] ?? null,
                            'info_source'     => $questionData['info_source'] ?? null,
                            'order'           => $qIndex + 1,
                        ]);

                        foreach ($questionData['options'] as $oIndex => $optionData) {
                            QuizOption::create([
                                'question_id' => $question->id,
                                'option_text'  => $optionData['option_text'],
                                'is_correct'   => !empty($optionData['is_correct']),
                                'order'        => $oIndex + 1,
                            ]);
                        }
                    }
                }
            }

            DB::commit();

            app(QuizNotificationService::class)->notifyIfEnabled($quiz->fresh(['subject']));

            return redirect()->route('doctor.quizzes.show', $quiz)
                ->with('success', 'تم تحديث الكويز بنجاح.');

        } catch (\Exception $e) {
            DB::rollBack();
            return back()->withInput()->with('error', 'حدث خطأ أثناء التعديل: ' . $e->getMessage());
        }
    }

    /**
     * Results page for a specific quiz.
     */
    public function results(Quiz $quiz)
    {
        [$quiz, $attempts] = $this->quizResultsData($quiz);

        return view('doctor.quizzes.results', compact('quiz', 'attempts'));
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

        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="quiz_results_' . $quiz->id . '_' . now()->format('Y-m-d_His') . '.csv"',
        ];

        $callback = static function () use ($rows): void {
            $handle = fopen('php://output', 'w');
            fprintf($handle, chr(0xEF) . chr(0xBB) . chr(0xBF));

            foreach ($rows as $row) {
                fputcsv($handle, $row);
            }

            fclose($handle);
        };

        return response()->stream($callback, 200, $headers);
    }

    /**
     * Publish a quiz.
     */
    public function publish(Quiz $quiz)
    {
        $quiz = $this->ownedQuizOrFail($quiz);

        $quiz->update(['status' => 'published']);
        app(QuizNotificationService::class)->notifyIfEnabled($quiz->fresh(['subject']));

        return back()->with('success', 'تم نشر الكويز بنجاح.');
    }

    /**
     * Close a quiz.
     */
    public function close(Quiz $quiz)
    {
        $quiz = $this->ownedQuizOrFail($quiz);

        $quiz->update(['status' => 'closed']);

        return back()->with('success', 'تم إغلاق الكويز.');
    }

    /**
     * Toggle results visibility.
     */
    public function shareResults(Request $request, Quiz $quiz)
    {
        $quiz = $this->ownedQuizOrFail($quiz);

        $visibility = $request->get('visibility', 'individual');
        $quiz->update(['results_visibility' => $visibility]);

        return back()->with('success', 'تم تحديث إعدادات مشاركة النتائج.');
    }

    /**
     * Delete a quiz.
     */
    public function destroy(Quiz $quiz)
    {
        $quiz = $this->ownedQuizOrFail($quiz);

        $quiz->delete();

        return redirect()->route('doctor.quizzes.index')
            ->with('success', 'تم حذف الكويز بنجاح.');
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
