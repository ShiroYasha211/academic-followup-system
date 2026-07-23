<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\Quiz\Quiz;
use App\Models\Academic\Subject;
use App\Models\Quiz\QuizModel;
use App\Models\Quiz\QuizQuestion;
use App\Models\Quiz\QuizOption;
use App\Models\Quiz\QuizAttempt;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use App\Services\QuizNotificationService;

class QuizController extends BaseController
{
    /**
     * Display a listing of admin quizzes.
     */
    public function index(Request $request)
    {
        $query = Quiz::with(['subject', 'targets'])
            ->withCount('attempts')
            ->where('creator_type', 'admin');

        // Optional filtering
        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('subject_id')) {
            $query->where('subject_id', $request->subject_id);
        }

        $quizzes = $query->latest()->paginate($request->get('per_page', 15));

        return $this->success($quizzes, 'تم جلب الكويزات بنجاح');
    }

    /**
     * Store a newly created quiz in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'subject_id'            => 'nullable|exists:subjects,id',
            'title'                 => 'required|string|max:255',
            'description'           => 'nullable|string',
            'timer_mode'            => 'required|in:quiz,per_question',
            'time_limit_minutes'    => 'nullable|required_if:timer_mode,quiz|integer|min:1|max:300',
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

            // Array structures for quiz content
            'models'                                => 'required|array|min:1',
            'models.*.name'                         => 'required|string|max:255',
            'models.*.questions'                    => 'required|array|min:1',
            'models.*.questions.*.question_text'    => 'required|string',
            'models.*.questions.*.question_type'    => 'required|string|in:multiple_choice,true_false',
            'models.*.questions.*.score'            => 'nullable|numeric|default:1',
            'models.*.questions.*.time_limit_seconds'=> 'nullable|required_if:timer_mode,per_question|integer|min:1',
            'models.*.questions.*.correction_note'  => 'nullable|string',
            'models.*.questions.*.info_source'      => 'nullable|string',
            'models.*.questions.*.options'          => 'required|array|min:2',
            'models.*.questions.*.options.*.option_text' => 'required|string',
            'models.*.questions.*.options.*.is_correct'  => 'nullable|boolean',
            
            // Educational targets
            'targets'               => 'nullable|array',
            'targets.*.university_id' => 'nullable|exists:universities,id',
            'targets.*.college_id'    => 'nullable|exists:colleges,id',
            'targets.*.major_id'      => 'nullable|exists:majors,id',
            'targets.*.level_id'      => 'nullable|exists:levels,id',
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
                    $quizModel = QuizModel::create([
                        'quiz_id'     => $quiz->id,
                        'name'        => $modelData['name'],
                        'access_code' => $request->boolean('use_access_code') ? Str::random(6) : null,
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
                // If no target provided, default to global
                $quiz->targets()->create([
                    'university_id' => null, 'college_id' => null, 'major_id' => null, 'level_id' => null,
                ]);
            }

            DB::commit();

            app(QuizNotificationService::class)->notifyIfEnabled($quiz->fresh(['subject', 'targets']));

            return $this->success($quiz->load('models.questions.options', 'targets'), 'تم إنشاء الكويز بنجاح', 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->error('حدث خطأ أثناء إنشاء الكويز: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Display the specified quiz.
     */
    public function show(Quiz $quiz)
    {
        if ($quiz->creator_type !== 'admin') {
            return $this->error('غير مصرح لك بعرض هذا الكويز', 403);
        }

        $quiz->isEffectivelyPublished(); // Sync status
        $quiz->load(['subject', 'models.questions.options', 'targets.university', 'targets.college', 'targets.major', 'targets.level']);

        $stats = [
            'total_attempts' => $quiz->attempts()->count(),
            'avg_score'      => $quiz->attempts->where('status', 'graded')->avg('percentage') ?? 0,
            'highest_score'  => $quiz->attempts->where('status', 'graded')->max('percentage') ?? 0,
            'lowest_score'   => $quiz->attempts->where('status', 'graded')->min('percentage') ?? 0,
        ];

        return $this->success([
            'quiz'  => $quiz,
            'stats' => $stats
        ], 'تم جلب الكويز بنجاح');
    }

    /**
     * Update the specified quiz.
     */
    public function update(Request $request, Quiz $quiz)
    {
        if ($quiz->creator_type !== 'admin') {
            return $this->error('غير مصرح لك بتعديل هذا الكويز', 403);
        }

        $validated = $request->validate([
            'subject_id'            => 'nullable|exists:subjects,id',
            'title'                 => 'required|string|max:255',
            'description'           => 'nullable|string',
            'timer_mode'            => 'required|in:quiz,per_question',
            'time_limit_minutes'    => 'nullable|required_if:timer_mode,quiz|integer|min:1|max:300',
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
            $status = $quiz->status;
            if (!empty($validated['scheduled_at'])) {
                if (now()->lt(\Carbon\Carbon::parse($validated['scheduled_at']))) {
                    $status = 'scheduled';
                } else {
                    $status = 'published';
                }
            }

            $quiz->update([
                'subject_id'            => $validated['subject_id'] ?? null,
                'title'                 => $validated['title'],
                'description'           => $validated['description'] ?? null,
                'time_limit_minutes'    => $validated['time_limit_minutes'] ?? null,
                'timer_mode'            => $validated['timer_mode'],
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

            // Only update content if no attempts have been made
            if ($quiz->attempts()->count() === 0 && isset($validated['models'])) {
                $quiz->models()->delete();
                foreach ($validated['models'] as $m) {
                    $model = $quiz->models()->create([
                        'name' => $m['name'],
                        'access_code' => $request->boolean('use_access_code') ? strtoupper(Str::random(6)) : null,
                    ]);
                    if (isset($m['questions']) && is_array($m['questions'])) {
                        foreach ($m['questions'] as $qIdx => $q) {
                            $question = $model->questions()->create([
                                'question_text'   => $q['question_text'],
                                'question_type'   => $q['question_type'] ?? 'multiple_choice',
                                'score'           => $q['score'] ?? 1,
                                'time_limit_seconds' => $validated['timer_mode'] === 'per_question' ? ($q['time_limit_seconds'] ?? null) : null,
                                'correction_note' => $q['correction_note'] ?? null,
                                'info_source'     => $q['info_source'] ?? null,
                                'order'           => $qIdx + 1
                            ]);
                            if (isset($q['options']) && is_array($q['options'])) {
                                foreach ($q['options'] as $oIdx => $o) {
                                    $question->options()->create([
                                        'option_text' => $o['option_text'], 
                                        'is_correct'  => !empty($o['is_correct']), 
                                        'order'       => $oIdx + 1
                                    ]);
                                }
                            }
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
                    'university_id' => null, 'college_id' => null, 'major_id' => null, 'level_id' => null,
                ]);
            }

            DB::commit();
            app(QuizNotificationService::class)->notifyIfEnabled($quiz->fresh(['subject', 'targets']));

            return $this->success($quiz->load('models.questions.options', 'targets'), 'تم تحديث الكويز بنجاح.');
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->error('خطأ: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Delete a quiz.
     */
    public function destroy(Quiz $quiz)
    {
        if ($quiz->creator_type !== 'admin') {
            return $this->error('غير مصرح لك بحذف هذا الكويز', 403);
        }

        $quiz->delete();
        return $this->success(null, 'تم حذف الكويز بنجاح.');
    }

    /**
     * Publish a quiz immediately.
     */
    public function publish(Quiz $quiz)
    {
        if ($quiz->creator_type !== 'admin') {
            return $this->error('غير مصرح لك بتعديل هذا الكويز', 403);
        }

        $quiz->update(['status' => 'published']);
        app(QuizNotificationService::class)->notifyIfEnabled($quiz->fresh(['subject', 'targets']));

        return $this->success(null, 'تم نشر الكويز بنجاح.');
    }

    /**
     * Close a quiz immediately.
     */
    public function close(Quiz $quiz)
    {
        if ($quiz->creator_type !== 'admin') {
            return $this->error('غير مصرح لك بتعديل هذا الكويز', 403);
        }

        $quiz->update(['status' => 'closed']);
        return $this->success(null, 'تم إغلاق الكويز.');
    }

    /**
     * Retrieve student attempts/results for a specific quiz.
     */
    public function results(Quiz $quiz)
    {
        if ($quiz->creator_type !== 'admin') {
            return $this->error('غير مصرح لك بعرض نتائج هذا الكويز', 403);
        }

        $attempts = QuizAttempt::where('quiz_id', $quiz->id)
            ->with(['student:id,name,email,student_number', 'quizModel:id,name'])
            ->orderByDesc('score')
            ->get();

        return $this->success([
            'quiz'     => $quiz->only(['id', 'title', 'status', 'total_score']),
            'attempts' => $attempts
        ], 'تم جلب النتائج بنجاح.');
    }
}
