<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Quiz\Quiz;
use App\Models\Quiz\QuizModel;
use App\Models\Quiz\QuizAttempt;
use App\Models\Quiz\QuizAnswer;
use App\Models\Quiz\QuizOption;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class QuizController extends Controller
{
    /**
     * List available quizzes for this student.
     */
    public function index()
    {
        $student = Auth::user();

        // Get subjects that match this student's major/level
        $subjectIds = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->pluck('id');

        // Doctor quizzes for student's subjects (Published or Scheduled past time or Scheduled with notification)
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
            ->get();

        // Competition quizzes targeting this student
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
            ->get();

        // My attempts
        $myAttempts = QuizAttempt::where('student_id', $student->id)
            ->with(['quiz.subject', 'quiz.creator:id,name', 'quizModel'])
            ->latest()
            ->get();

        return view('student.quizzes.index', compact('doctorQuizzes', 'competitions', 'myAttempts'));
    }

    /**
     * Start/resume a quiz attempt.
     */
    public function take(Request $request, Quiz $quiz)
    {
        $student = Auth::user();

        // Check access
        if (!$quiz->isAccessibleBy($student)) {
            return back()->with('error', 'لا يمكنك الوصول لهذا الكويز.');
        }

        // Check if already attempted
        $existingAttempt = $quiz->attemptBy($student);

        if ($existingAttempt && $existingAttempt->status !== 'in_progress') {
            return redirect()->route('student.quizzes.result', $existingAttempt)
                ->with('info', 'لقد أكملت هذا الكويز مسبقاً.');
        }

        if ($existingAttempt && ! $existingAttempt->isWithinTimeLimit()) {
            $existingAnswers = $existingAttempt->answers()
                ->whereNotNull('selected_option_id')
                ->pluck('selected_option_id', 'question_id')
                ->toArray();
            $existingAttempt->finalizeWithAnswers($existingAnswers);

            return redirect()->route('student.quizzes.result', $existingAttempt)
                ->with('info', 'انتهى وقت الكويز وتم تسليم المحاولة.');
        }

        // Pick or retrieve quiz model
        if ($existingAttempt) {
            $attempt = $existingAttempt;
            $quizModel = $attempt->quizModel;
        } else {
            // Assign a random or specified model
            $quizModel = $quiz->models()->inRandomOrder()->first();

            if (!$quizModel) {
                return back()->with('error', 'لا توجد نماذج متاحة لهذا الكويز.');
            }

            // Handle access code if needed
            if ($quizModel->access_code && $request->get('access_code') !== $quizModel->access_code) {
                // Show access code input page
                if (!$request->has('access_code')) {
                    return view('student.quizzes.access-code', compact('quiz'));
                }
                return back()->with('error', 'رمز الدخول غير صحيح.');
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

        // Load questions (shuffled if quiz setting is on)
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

        // Get existing answers for this attempt
        $existingAnswers = $attempt->answers()->pluck('selected_option_id', 'question_id');

        return view('student.quizzes.take', compact('quiz', 'attempt', 'questions', 'existingAnswers'));
    }

    /**
     * Submit quiz answers.
     */
    public function submit(Request $request, QuizAttempt $attempt)
    {
        $student = Auth::user();

        if ($attempt->student_id !== $student->id) {
            abort(403);
        }

        if ($attempt->status !== 'in_progress') {
            return redirect()->route('student.quizzes.result', $attempt)
                ->with('info', 'تم تسليم هذا الكويز مسبقاً.');
        }

        $validated = $request->validate([
            'answers'   => 'nullable|array',
            'answers.*' => 'nullable|integer|exists:quiz_options,id',
        ]);

        DB::beginTransaction();

        try {
            $attempt->finalizeWithAnswers($validated['answers'] ?? []);

            DB::commit();

            return redirect()->route('student.quizzes.result', $attempt)
                ->with('success', 'تم تسليم الكويز بنجاح!');

        } catch (\Exception $e) {
            DB::rollBack();
            return back()->with('error', 'حدث خطأ أثناء التسليم: ' . $e->getMessage());
        }
    }

    /**
     * Show quiz result.
     */
    public function result(QuizAttempt $attempt)
    {
        $student = Auth::user();

        if ($attempt->student_id !== $student->id) {
            abort(403);
        }

        $quiz = $attempt->quiz;

        // Check results visibility
        if ($quiz->results_visibility === 'hidden' && $quiz->created_by !== $student->id) {
            return view('student.quizzes.result-hidden', compact('quiz', 'attempt'));
        }

        $attempt->load(['answers.question.options', 'answers.selectedOption', 'quizModel']);
        $publicAttempts = collect();

        if ($quiz->results_visibility === 'public') {
            $publicAttempts = QuizAttempt::where('quiz_id', $quiz->id)
                ->where('status', 'graded')
                ->whereNotNull('submitted_at')
                ->with(['student:id,name,student_number', 'quizModel:id,name'])
                ->orderByDesc('score')
                ->orderBy('submitted_at')
                ->get();
        }

        return view('student.quizzes.result', compact('quiz', 'attempt', 'publicAttempts'));
    }
}
