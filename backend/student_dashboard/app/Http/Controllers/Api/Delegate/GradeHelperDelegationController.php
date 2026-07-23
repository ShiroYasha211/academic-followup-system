<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Enums\UserRole;
use App\Models\DelegateGradeDelegation;
use App\Models\GradeCategory;
use App\Models\User;
use Illuminate\Http\Request;

class GradeHelperDelegationController extends DelegateApiController
{
    public function index(Request $request)
    {
        $delegate = $request->user();

        $tasks = $delegate->issuedGradeHelperTasks()
            ->active()
            ->with([
                'category.subject:id,name,major_id,level_id',
                'category.doctor:id,name',
                'helperUser:id,name,student_number,role',
                'students:id,name,student_number,role',
            ])
            ->latest()
            ->get();

        return $this->success([
            'summary' => [
                'issued_tasks_count' => $tasks->count(),
                'active_tasks_count' => $tasks->where('is_revoked', false)->count(),
            ],
            'tasks' => $tasks,
        ]);
    }

    public function getStudents(Request $request)
    {
        $delegate = $request->user();
        $category = $delegate->delegatedGradeCategories()
            ->with(['subject:id,name,major_id,level_id', 'doctor:id,name'])
            ->findOrFail($request->integer('category_id'));

        $students = User::query()
            ->whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])
            ->where('major_id', $category->subject->major_id)
            ->where('level_id', $category->subject->level_id)
            ->orderBy('name')
            ->get(['id', 'name', 'student_number', 'role']);

        return $this->success([
            'category' => $category,
            'eligible_students' => $students,
        ]);
    }

    public function store(Request $request)
    {
        $delegate = $request->user();

        $validated = $request->validate([
            'category_id' => 'required|exists:grade_categories,id',
            'helper_user_id' => 'required|exists:users,id',
            'delegation_type' => 'required|in:full,partial',
            'title' => 'required|string|max:255',
            'notes' => 'nullable|string|max:1000',
            'due_at' => 'nullable|date',
            'student_ids' => 'nullable|array',
            'student_ids.*' => 'exists:users,id',
        ]);

        if ((int) $validated['helper_user_id'] === (int) $delegate->id) {
            return $this->error('Delegate cannot create a helper task for the same account.', 422);
        }

        $category = $delegate->delegatedGradeCategories()
            ->with(['subject:id,name,major_id,level_id', 'doctor:id,name'])
            ->findOrFail($validated['category_id']);

        $eligibleIds = User::query()
            ->whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])
            ->where('major_id', $category->subject->major_id)
            ->where('level_id', $category->subject->level_id)
            ->pluck('id');

        if (!$eligibleIds->contains((int) $validated['helper_user_id'])) {
            return $this->error('Helper user is outside the delegated scope.', 422);
        }

        $existingTask = DelegateGradeDelegation::query()
            ->where('category_id', $category->id)
            ->where('delegated_by_id', $delegate->id)
            ->where('helper_user_id', $validated['helper_user_id'])
            ->where('is_revoked', false)
            ->exists();

        if ($existingTask) {
            return $this->error('An active helper delegation already exists for this user and category.', 422);
        }

        $selectedIds = collect($validated['student_ids'] ?? [])->map(fn ($id) => (int) $id)->unique()->values();
        if ($validated['delegation_type'] === DelegateGradeDelegation::TYPE_PARTIAL) {
            if ($selectedIds->isEmpty() || $selectedIds->diff($eligibleIds)->isNotEmpty()) {
                return $this->error('Selected students are outside the delegated scope.', 422);
            }
        }

        $task = DelegateGradeDelegation::create([
            'category_id' => $category->id,
            'delegated_by_id' => $delegate->id,
            'helper_user_id' => $validated['helper_user_id'],
            'delegation_type' => $validated['delegation_type'],
            'title' => $validated['title'],
            'notes' => $validated['notes'] ?? null,
            'due_at' => $validated['due_at'] ?? null,
        ]);

        if ($selectedIds->isNotEmpty()) {
            $task->students()->sync($selectedIds);
        }

        return $this->success([
            'workflow' => [
                'step_1' => 'The main delegate creates a helper task for the selected category.',
                'step_2' => 'The helper enters grades only inside the assigned scope.',
                'step_3' => 'Saved grades remain pending for doctor review.',
            ],
            'task' => $task->load([
                'category.subject:id,name,major_id,level_id',
                'category.doctor:id,name',
                'helperUser:id,name,student_number,role',
                'students:id,name,student_number,role',
            ]),
        ], 'Grade helper task created.', 201);
    }

    public function revoke(Request $request, DelegateGradeDelegation $delegation)
    {
        if ((int) $delegation->delegated_by_id !== (int) $request->user()->id) {
            return $this->error('This helper task does not belong to you.', 403);
        }

        $delegation->update([
            'is_revoked' => true,
            'revoked_at' => now(),
        ]);

        return $this->success(null, 'Grade helper task revoked.');
    }
}
