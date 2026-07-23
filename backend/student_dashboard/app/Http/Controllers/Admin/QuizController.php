<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Quiz\Quiz;
use App\Models\Quiz\QuizModel;
use App\Models\Quiz\QuizQuestion;
use App\Models\Quiz\QuizOption;
use App\Models\Quiz\QuizAttempt;
use App\Models\Academic\Subject;
use App\Models\Academic\University;
use App\Models\Academic\College;
use App\Models\Academic\Major;
use App\Models\Academic\Level;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use App\Services\QuizNotificationService;

class QuizController extends Controller
{
    /**
     * List admin-created quizzes.
     */
    public function index(Request $request)
    {
        $status = $request->get('status', 'all');

        $query = Quiz::where('creator_type', 'admin');

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        $quizzes = $query->with(['subject', 'creator'])
            ->withCount('attempts')
            ->latest()
            ->paginate(12);

        return view('admin.quizzes.index', compact('quizzes', 'status'));
    }

    /**
     * Create quiz form.
     */
    public function create()
    {
        $subjects     = Subject::with('level')->get();
        $universities = University::all();
        $colleges     = College::all();
        $majors       = Major::all();
        $levels       = Level::all();

        return view('admin.quizzes.create', compact('subjects', 'universities', 'colleges', 'majors', 'levels'));
    }

    /**
     * Store a new quiz.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'subject_id'            => 'nullable|exists:subjects,id',
            'title'                 => 'required|string|max:255',
            'description'           => 'nullable|string',
            'timer_mode'            => 'required|in:quiz,per_question',
            'time_limit_minutes'    => 'nullable|required_if:timer_mode,quiz|integer|min:1|max:300',
            'allow_question_backtracking' => 'nullable|boolean',
            'shuffle_questions'     => 'nullable|boolean',
            'shuffle_options'       => 'nullable|boolean',
            'show_correct_answers'  => 'nullable|boolean',
            'show_correction_notes' => 'nullable|boolean',
            'notify_students'       => 'nullable|boolean',
            'show_countdown'        => 'nullable|boolean',
            'use_access_code'       => 'nullable|boolean',
            'results_visibility'    => 'required|in:hidden,individual,public',
            'scheduled_at'          => 'nullable|date',
            'closes_at'             => 'nullable|date|after:scheduled_at',

            // Content
            'models'                => 'required|array|min:1',
            'models.*.name'         => 'required|string|max:100',
            'models.*.access_code'  => 'nullable|string|max:100',
            'models.*.questions'    => 'required|array|min:1',
            'models.*.questions.*.question_text' => 'required|string',
            'models.*.questions.*.question_type' => 'required|in:multiple_choice,true_false',
            'models.*.questions.*.score'         => 'nullable|numeric|min:0',
            'models.*.questions.*.time_limit_seconds' => 'nullable|required_if:timer_mode,per_question|integer|min:1',
            'models.*.questions.*.options'       => 'required|array|min:2',
            'models.*.questions.*.options.*.option_text' => 'required|string',
            'models.*.questions.*.options.*.is_correct'  => 'nullable',

            // Targets
            'targets'               => 'nullable|array',
            'targets.*.university_id' => 'nullable|exists:universities,id',
            'targets.*.college_id'    => 'nullable|exists:colleges,id',
            'targets.*.major_id'      => 'nullable|exists:majors,id',
            'targets.*.level_id'      => 'nullable|exists:levels,id',

            'models.*.questions.*.correction_note' => 'nullable|string',
            'models.*.questions.*.info_source'     => 'nullable|string',
        ]);

        DB::beginTransaction();

        try {
            // Automatically determine status
            $status = 'published';
            if (!empty($validated['scheduled_at'])) {
                if (now()->lt(\Carbon\Carbon::parse($validated['scheduled_at']))) {
                    $status = 'scheduled';
                }
            }

            $quiz = Quiz::create([
                'created_by'            => Auth::id(),
                'creator_type'          => 'admin',
                'subject_id'            => $validated['subject_id'] ?? null,
                'title'                 => $validated['title'],
                'description'           => $validated['description'] ?? null,
                'time_limit_minutes'    => $validated['time_limit_minutes'] ?? null,
                'timer_mode'            => $validated['timer_mode'],
                'allow_question_backtracking' => $request->boolean('allow_question_backtracking', true),
                'shuffle_questions'     => $request->boolean('shuffle_questions'),
                'shuffle_options'       => $request->boolean('shuffle_options', true),
                'show_correct_answers'  => $request->boolean('show_correct_answers'),
                'show_correction_notes' => $request->boolean('show_correction_notes', true),
                'notify_students'       => $request->boolean('notify_students'),
                'show_countdown'        => $request->boolean('show_countdown', true),
                'results_visibility'    => $validated['results_visibility'],
                'scheduled_at'          => $validated['scheduled_at'] ?? null,
                'closes_at'             => $validated['closes_at'] ?? null,
                'status'                => $status,
                'is_competition'        => true, // Admin quizzes are competitions/global by default
            ]);

            // Save Models, Questions, Options
            if (isset($validated['models']) && is_array($validated['models'])) {
                foreach ($validated['models'] as $mIndex => $modelData) {
                    $accessCode = null;
                    if ($request->boolean('use_access_code')) {
                        $accessCode = !empty($modelData['access_code']) ? strtoupper(trim($modelData['access_code'])) : strtoupper(Str::random(6));
                    }
                    $quizModel = QuizModel::create([
                        'quiz_id'     => $quiz->id,
                        'name'        => $modelData['name'],
                        'access_code' => $accessCode,
                        'order'       => $mIndex + 1,
                    ]);

                    if (isset($modelData['questions']) && is_array($modelData['questions'])) {
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

                            if (isset($questionData['options']) && is_array($questionData['options'])) {
                                foreach ($questionData['options'] as $oIndex => $optionData) {
                                    QuizOption::create([
                                        'question_id' => $question->id,
                                        'option_text' => $optionData['option_text'],
                                        'is_correct'  => !empty($optionData['is_correct']),
                                        'order'       => $oIndex + 1,
                                    ]);
                                }
                            }
                        }
                    }
                }
            }

            // Save Targets
            if (!empty($validated['targets'])) {
                foreach ($validated['targets'] as $targetData) {
                    $quiz->targets()->create([
                        'university_id' => $targetData['university_id'] ?? null,
                        'college_id'    => $targetData['college_id'] ?? null,
                        'major_id'      => $targetData['major_id'] ?? null,
                        'level_id'      => $targetData['level_id'] ?? null,
                    ]);
                }
            } else {
                // If no target provided, default to global (all nulls)
                $quiz->targets()->create([
                    'university_id' => null,
                    'college_id'    => null,
                    'major_id'      => null,
                    'level_id'      => null,
                ]);
            }

            DB::commit();

            app(QuizNotificationService::class)->notifyIfEnabled($quiz->fresh(['subject', 'targets']));

            return redirect()->route('admin.quizzes.show', $quiz)
                ->with('success', 'تم إنشاء الكويز الإداري بنجاح.');

        } catch (\Exception $e) {
            DB::rollBack();
            return back()->withInput()->with('error', 'حدث خطأ: ' . $e->getMessage());
        }
    }

    /**
     * Show quiz details and stats.
     */
    public function show(Quiz $quiz)
    {
        // Admin can see any quiz, sync its status first
        $quiz->isEffectivelyPublished();
        $quiz->load(['subject', 'models.questions.options', 'attempts.student', 'targets.university', 'targets.college', 'targets.major', 'targets.level']);

        $stats = [
            'total_attempts' => $quiz->attempts()->count(),
            'avg_score'      => $quiz->attempts->where('status', 'graded')->avg('percentage') ?? 0,
            'highest_score'  => $quiz->attempts->where('status', 'graded')->max('percentage') ?? 0,
            'lowest_score'   => $quiz->attempts->where('status', 'graded')->min('percentage') ?? 0,
        ];

        return view('admin.quizzes.show', compact('quiz', 'stats'));
    }

    /**
     * Results page for a specific quiz.
     */
    public function results(Quiz $quiz)
    {
        [$quiz, $attempts] = $this->quizResultsData($quiz);

        return view('admin.quizzes.results', compact('quiz', 'attempts'));
    }

    public function exportResults(Quiz $quiz)
    {
        [$quiz, $attempts] = $this->quizResultsData($quiz);

        $targetSummary = $quiz->targets->map(function ($target) {
            $parts = array_filter([
                $target->university?->name,
                $target->college?->name,
                $target->major?->name,
                $target->level?->name,
            ]);

            return empty($parts) ? 'All students' : implode(' / ', $parts);
        })->implode(' | ');

        $rows = [
            ['Quiz Results Report'],
            ['Quiz', $quiz->title],
            ['Subject', $quiz->subject?->name ?? '-'],
            ['Targets', $targetSummary ?: '-'],
            ['Results Visibility', $quiz->results_visibility_label],
            ['Attempts Count', $attempts->count()],
            ['Exported At', now()->format('Y-m-d H:i:s')],
            [],
            ['#', 'Student Name', 'Student Number', 'Major', 'Level', 'Quiz Model', 'Score', 'Max Score', 'Percentage', 'Correct Answers', 'Wrong Answers', 'Duration (Minutes)', 'Status', 'Submitted At'],
        ];

        foreach ($attempts as $index => $attempt) {
            $rows[] = [
                $index + 1,
                $attempt->student?->name ?? '-',
                $attempt->student?->student_number ?? '-',
                $attempt->student?->major?->name ?? '-',
                $attempt->student?->level?->name ?? '-',
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
            'Content-Disposition' => 'attachment; filename="admin_quiz_results_' . $quiz->id . '_' . now()->format('Y-m-d_His') . '.csv"',
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
     * Toggle results visibility.
     */
    public function shareResults(Request $request, Quiz $quiz)
    {
        $validated = $request->validate([
            'visibility' => 'required|in:hidden,individual,public',
        ]);

        $quiz->update(['results_visibility' => $validated['visibility']]);

        return back()->with('success', 'تم تحديث إعدادات ظهور النتائج.');
    }

    /**
     * Delete a quiz.
     */
    public function destroy(Quiz $quiz)
    {
        $quiz->delete();

        return redirect()->route('admin.quizzes.index')
            ->with('success', 'تم حذف الكويز بنجاح.');
    }

    /**
     * Publish a quiz.
     */
    public function publish(Quiz $quiz)
    {
        $quiz->update(['status' => 'published']);
        app(QuizNotificationService::class)->notifyIfEnabled($quiz->fresh(['subject', 'targets']));

        return back()->with('success', 'تم نشر الكويز بنجاح.');
    }

    /**
     * Close a quiz.
     */
    public function close(Quiz $quiz)
    {
        $quiz->update(['status' => 'closed']);
        return back()->with('success', 'تم إغلاق الكويز.');
    }

    /**
     * Edit quiz form.
     */
    public function edit(Quiz $quiz)
    {
        $quiz->load(['subject', 'models.questions.options', 'targets']);
        
        $subjects     = Subject::with('level')->get();
        $universities = University::all();
        $colleges     = College::all();
        $majors       = Major::all();
        $levels       = Level::all();

        $canEditContent = $quiz->attempts()->count() === 0;

        // Prepare data for Alpine
        $initialModels = $quiz->models->map(function($m) {
            return [
                'name' => $m->name,
                'access_code' => $m->access_code,
                'questions' => $m->questions->map(function($q) {
                    return [
                        'text' => $q->question_text,
                        'question_type' => $q->question_type ?? 'multiple_choice',
                        'score' => $q->score,
                        'time_limit_seconds' => $q->time_limit_seconds,
                        'correction_note' => $q->correction_note,
                        'info_source' => $q->info_source,
                        'options' => $q->options->map(function($o) {
                            return ['text' => $o->option_text, 'is_correct' => (bool)$o->is_correct];
                        })
                    ];
                })
            ];
        });

        $initialTargets = $quiz->targets->map(function($t) {
            return [
                'university_id' => $t->university_id,
                'college_id' => $t->college_id,
                'major_id' => $t->major_id,
                'level_id' => $t->level_id
            ];
        });

        return view('admin.quizzes.edit', compact('quiz', 'subjects', 'universities', 'colleges', 'majors', 'levels', 'canEditContent', 'initialModels', 'initialTargets'));
    }

    /**
     * Update quiz.
     */
    public function update(Request $request, Quiz $quiz)
    {
        $validated = $request->validate([
            'subject_id'            => 'nullable|exists:subjects,id',
            'title'                 => 'required|string|max:255',
            'description'           => 'nullable|string',
            'timer_mode'            => 'required|in:quiz,per_question',
            'time_limit_minutes'    => 'nullable|required_if:timer_mode,quiz|integer|min:1|max:300',
            'allow_question_backtracking' => 'nullable|boolean',
            'shuffle_questions'     => 'nullable|boolean',
            'shuffle_options'       => 'nullable|boolean',
            'show_correct_answers'  => 'nullable|boolean',
            'show_correction_notes' => 'nullable|boolean',
            'notify_students'       => 'nullable|boolean',
            'show_countdown'        => 'nullable|boolean',
            'use_access_code'       => 'nullable|boolean',
            'results_visibility'    => 'required|in:hidden,individual,public',
            'scheduled_at'          => 'nullable|date',
            'closes_at'             => 'nullable|date|after:scheduled_at',
            'models'                => 'sometimes|array',
            'models.*.name'         => 'required_with:models|string|max:100',
            'models.*.access_code'  => 'nullable|string|max:100',
            'models.*.questions'    => 'required_with:models|array|min:1',
            'models.*.questions.*.question_text' => 'required_with:models|string',
            'models.*.questions.*.question_type' => 'nullable|in:multiple_choice,true_false',
            'models.*.questions.*.score' => 'nullable|numeric|min:0',
            'models.*.questions.*.time_limit_seconds' => 'nullable|required_if:timer_mode,per_question|integer|min:1',
            'models.*.questions.*.options' => 'required_with:models|array|min:2',
            'models.*.questions.*.options.*.option_text' => 'required_with:models|string',
            'models.*.questions.*.options.*.is_correct' => 'nullable',
            'targets'               => 'nullable|array',
        ]);

        DB::beginTransaction();
        try {
            // Automatically determine status
            $status = 'published';
            if (!empty($validated['scheduled_at'])) {
                if (now()->lt(\Carbon\Carbon::parse($validated['scheduled_at']))) {
                    $status = 'scheduled';
                }
            }

            $quiz->update([
                'subject_id'            => $validated['subject_id'] ?? null,
                'title'                 => $validated['title'],
                'description'           => $validated['description'] ?? null,
                'time_limit_minutes'    => $validated['time_limit_minutes'] ?? null,
                'timer_mode'            => $validated['timer_mode'],
                'allow_question_backtracking' => $request->boolean('allow_question_backtracking', true),
                'shuffle_questions'     => $request->boolean('shuffle_questions'),
                'shuffle_options'       => $request->boolean('shuffle_options', true),
                'show_correct_answers'  => $request->boolean('show_correct_answers'),
                'show_correction_notes' => $request->boolean('show_correction_notes', true),
                'notify_students'       => $request->boolean('notify_students'),
                'show_countdown'        => $request->boolean('show_countdown', true),
                'results_visibility'    => $validated['results_visibility'],
                'scheduled_at'          => $validated['scheduled_at'] ?? null,
                'closes_at'             => $validated['closes_at'] ?? null,
                'status'                => $status,
            ]);

            // Only update content if no attempts
            if ($quiz->attempts()->count() === 0 && isset($validated['models'])) {
                $quiz->models()->delete();
                foreach ($validated['models'] as $m) {
                    $accessCode = null;
                    if ($request->boolean('use_access_code')) {
                        $accessCode = !empty($m['access_code']) ? strtoupper(trim($m['access_code'])) : strtoupper(Str::random(6));
                    }
                    $model = $quiz->models()->create([
                        'name' => $m['name'],
                        'access_code' => $accessCode,
                    ]);
                    foreach ($m['questions'] as $qIdx => $q) {
                        $question = $model->questions()->create([
                            'question_text' => $q['question_text'],
                            'question_type' => $q['question_type'] ?? 'multiple_choice',
                            'score' => $q['score'] ?? 1,
                            'time_limit_seconds' => $validated['timer_mode'] === 'per_question' ? ($q['time_limit_seconds'] ?? null) : null,
                            'correction_note' => $q['correction_note'] ?? null,
                            'info_source' => $q['info_source'] ?? null,
                            'order' => $qIdx + 1
                        ]);
                        foreach ($q['options'] as $oIdx => $o) {
                            $question->options()->create(['option_text' => $o['option_text'], 'is_correct' => !empty($o['is_correct']), 'order' => $oIdx + 1]);
                        }
                    }
                }
            }

            // Sync targets
            $quiz->targets()->delete();
            if (!empty($validated['targets'])) {
                foreach ($validated['targets'] as $t) {
                    $quiz->targets()->create($t);
                }
            } else {
                $quiz->targets()->create([
                    'university_id' => null,
                    'college_id' => null,
                    'major_id' => null,
                    'level_id' => null,
                ]);
            }

            DB::commit();
            app(QuizNotificationService::class)->notifyIfEnabled($quiz->fresh(['subject', 'targets']));

            return redirect()->route('admin.quizzes.show', $quiz)->with('success', 'تم تحديث الكويز بنجاح.');
        } catch (\Exception $e) {
            DB::rollBack();
            return back()->with('error', 'خطأ: ' . $e->getMessage());
        }
    }

    protected function quizResultsData(Quiz $quiz): array
    {
        $quiz->loadMissing([
            'subject.major',
            'subject.level',
            'models:id,quiz_id,name',
            'targets.university',
            'targets.college',
            'targets.major',
            'targets.level',
        ]);

        $attempts = QuizAttempt::where('quiz_id', $quiz->id)
            ->with([
                'student:id,name,student_number,major_id,level_id',
                'student.major:id,name',
                'student.level:id,name',
                'quizModel:id,name',
                'answers.question',
            ])
            ->orderByDesc('score')
            ->get();

        return [$quiz, $attempts];
    }
}
