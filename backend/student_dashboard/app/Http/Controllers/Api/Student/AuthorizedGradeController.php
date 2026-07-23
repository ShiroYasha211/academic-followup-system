<?php

namespace App\Http\Controllers\Api\Student;

use App\Enums\UserRole;
use App\Models\DelegateGradeDelegation;
use App\Models\Grade;
use App\Models\GradeCategory;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AuthorizedGradeController extends StudentApiController
{
    public function index(Request $request)
    {
        $user = $request->user();

        $directDelegations = $user->delegatedGradeCategories()
            ->with(['subject.major', 'subject.level', 'doctor'])
            ->get();

        $helperTasks = $user->delegatedGradeHelperTasks()
            ->active()
            ->with(['category.subject.major', 'category.subject.level', 'category.doctor', 'delegatedBy', 'helperUser', 'students'])
            ->get();

        return $this->success([
            'module' => [
                'name' => 'authorized_grade_tasks',
                'purpose' => 'Shows the categories delegated to the current user for score entry.',
                'approval_rule' => 'All delegated entries remain pending until the doctor reviews and approves them.',
                'helper_rule' => 'If this user receives a helper task from a delegate, the same approval rule still applies.',
            ],
            'direct_delegations' => $directDelegations->map(fn ($category) => $this->mapDelegationCategory($category)),
            'helper_tasks' => $helperTasks->map(fn ($task) => $this->mapHelperTask($task)),
        ]);
    }

    public function show(Request $request, $categoryId)
    {
        $user = $request->user();
        [$category, $helperTask, $students] = $this->resolveCategoryAccess($user, (int) $categoryId);

        return $this->success([
            'workflow' => [
                'step_1' => 'Doctor creates a grade category for a subject.',
                'step_2' => 'Doctor delegates the category directly, or a delegate creates a helper task under that category.',
                'step_3' => 'Authorized user enters scores for the allowed students only.',
                'step_4' => 'Scores stay pending until reviewed by the doctor.',
            ],
            'category' => $this->mapDelegationCategory($category),
            'delegation_context' => $this->buildDelegationContext($category, $helperTask, $students),
            'students' => $students->map(fn ($student) => $this->mapStudentRow($student)),
        ]);
    }

    public function store(Request $request, $categoryId)
    {
        $user = $request->user();

        [$category, $helperTask, $students] = $this->resolveCategoryAccess($user, (int) $categoryId);
        $allowedStudentIds = $students->pluck('id');

        $request->validate([
            'grades' => 'required|array',
            'grades.*.student_id' => 'required|exists:users,id',
            'grades.*.score' => 'nullable|numeric|min:0|max:' . $category->max_score,
        ]);

        DB::beginTransaction();

        try {
            foreach ($request->grades as $gradeData) {
                if (!array_key_exists('score', $gradeData) || $gradeData['score'] === null || $gradeData['score'] === '') {
                    continue;
                }

                if (!$allowedStudentIds->contains((int) $gradeData['student_id'])) {
                    return $this->error('One or more selected students are outside your delegated scope.', 422);
                }

                Grade::updateOrCreate(
                    [
                        'student_id' => $gradeData['student_id'],
                        'subject_id' => $category->subject_id,
                        'category_id' => $category->id,
                        'type' => 'continuous',
                    ],
                    [
                        'score' => $gradeData['score'],
                        'max_score' => $category->max_score,
                        'created_by' => $user->id,
                        'status' => 'pending',
                    ]
                );
            }

            DB::commit();

            return $this->success([
                'status' => 'pending_review',
                'access_mode' => $helperTask ? 'helper_task' : 'direct_delegation',
                'next_step' => 'The doctor must review and approve the delegated grades before they become final.',
            ], 'Grades saved and sent for doctor review.');
        } catch (\Throwable $exception) {
            DB::rollBack();

            return $this->error('Failed to save delegated grades.', 500);
        }
    }

    protected function resolveCategoryAccess(User $user, int $categoryId): array
    {
        $category = $user->delegatedGradeCategories()
            ->with(['subject.major', 'subject.level', 'doctor'])
            ->find($categoryId);

        $helperTask = null;

        if (!$category) {
            $helperTask = $user->delegatedGradeHelperTasks()
                ->active()
                ->with(['category.subject.major', 'category.subject.level', 'category.doctor', 'delegatedBy', 'helperUser', 'students'])
                ->where('category_id', $categoryId)
                ->latest()
                ->firstOrFail();

            $category = $helperTask->category;
        }

        $students = User::query()
            ->whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])
            ->where('major_id', $category->subject->major_id)
            ->where('level_id', $category->subject->level_id)
            ->with(['grades' => function ($query) use ($category) {
                $query->where('category_id', $category->id);
            }])
            ->orderBy('name');

        if ($helperTask && $helperTask->delegation_type === DelegateGradeDelegation::TYPE_PARTIAL) {
            $students->whereIn('id', $helperTask->students->pluck('id'));
        }

        return [$category, $helperTask, $students->get(['users.id', 'users.name', 'users.student_number', 'users.role'])];
    }

    protected function mapDelegationCategory(GradeCategory $category): array
    {
        return [
            'id' => $category->id,
            'name' => $category->name,
            'max_score' => $category->max_score,
            'subject' => [
                'id' => $category->subject?->id,
                'name' => $category->subject?->name,
                'major' => $category->subject?->major?->name,
                'level' => $category->subject?->level?->name,
            ],
            'doctor' => [
                'id' => $category->doctor?->id,
                'name' => $category->doctor?->name,
            ],
        ];
    }

    protected function mapHelperTask(DelegateGradeDelegation $task): array
    {
        return [
            'id' => $task->id,
            'title' => $task->title,
            'notes' => $task->notes,
            'delegation_type' => $task->delegation_type,
            'due_at' => $task->due_at,
            'student_scope_count' => $task->delegation_type === DelegateGradeDelegation::TYPE_PARTIAL
                ? $task->students->count()
                : null,
            'category' => $this->mapDelegationCategory($task->category),
            'delegated_by' => [
                'id' => $task->delegatedBy?->id,
                'name' => $task->delegatedBy?->name,
            ],
            'helper_user' => [
                'id' => $task->helperUser?->id,
                'name' => $task->helperUser?->name,
            ],
        ];
    }

    protected function mapStudentRow(User $student): array
    {
        $currentGrade = $student->grades->first();

        return [
            'id' => $student->id,
            'name' => $student->name,
            'student_number' => $student->student_number,
            'role' => $student->role?->value ?? (string) $student->role,
            'current_grade' => $currentGrade ? [
                'score' => $currentGrade->score,
                'max_score' => $currentGrade->max_score,
                'status' => $currentGrade->status,
            ] : null,
        ];
    }

    protected function buildDelegationContext(GradeCategory $category, ?DelegateGradeDelegation $helperTask, $students): array
    {
        return [
            'access_mode' => $helperTask ? 'helper_task' : 'direct_delegation',
            'scope_label' => $helperTask
                ? ($helperTask->delegation_type === DelegateGradeDelegation::TYPE_PARTIAL ? 'selected_students_only' : 'full_category_students')
                : 'direct_doctor_delegation',
            'student_scope_count' => $students->count(),
            'doctor_name' => $category->doctor?->name,
            'helper_task' => $helperTask ? $this->mapHelperTask($helperTask) : null,
        ];
    }
}
