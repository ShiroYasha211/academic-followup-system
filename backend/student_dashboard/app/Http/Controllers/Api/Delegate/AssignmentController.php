<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\Delegate\DelegateApiController;
use App\Models\Academic\Assignment;
use App\Models\Academic\AssignmentDelegatePermission;
use App\Models\Academic\Subject;
use Illuminate\Support\Facades\Validator;

class AssignmentController extends DelegateApiController
{
    /**
     * Display a listing of assignments for the delegate's batch.
     */
    public function index(Request $request)
    {
        $delegate = $request->user();

        $assignments = Assignment::whereHas('subject', function ($q) use ($delegate) {
            $q->where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id);
        })
            ->with(['subject:id,name,code,major_id,level_id,doctor_id', 'creator:id,name,role'])
            ->orderBy('due_date', 'asc')
            ->get()
            ->map(fn (Assignment $assignment) => $this->assignmentPayload($assignment, $delegate));

        return $this->success($assignments, 'تم جلب التكاليف بنجاح');
    }

    /**
     * Return assignment permissions for the delegate's subjects.
     */
    public function permissions(Request $request)
    {
        $delegate = $request->user();

        $subjects = Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->with('doctor:id,name')
            ->orderBy('name')
            ->get(['id', 'name', 'code', 'major_id', 'level_id', 'doctor_id']);

        $permissions = AssignmentDelegatePermission::where('delegate_id', $delegate->id)
            ->whereIn('subject_id', $subjects->pluck('id'))
            ->get()
            ->keyBy('subject_id');

        $items = $subjects->map(function (Subject $subject) use ($permissions) {
            $permission = $permissions->get($subject->id);

            return [
                'subject' => $subject,
                'permissions' => $permission
                    ? $permission->toFlags()
                    : AssignmentDelegatePermission::emptyFlags(),
            ];
        })->values();

        return $this->success([
            'subjects' => $items,
            'can_create_any' => $items->contains(fn ($item) => (bool) $item['permissions']['can_create']),
        ]);
    }

    /**
     * Store a newly created assignment.
     */
    public function store(Request $request)
    {
        $delegate = $request->user();

        $validator = Validator::make($request->all(), [
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'due_date' => 'required|date|after_or_equal:today',
            'requires_submission' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        // Validate subject scope
        $subject = Subject::where('id', $request->subject_id)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->first();

        if (!$subject) {
            return $this->error('المادة غير موجودة أو غير مصرح لك', 403);
        }

        if (! $this->hasAssignmentPermission($subject, $delegate, 'can_create')) {
            return $this->error('ليس لديك صلاحية إنشاء تكليف لهذه المادة. راجع دكتور المادة لمنحك الصلاحية.', 403);
        }

        $data = $request->only(['subject_id', 'title', 'description', 'due_date', 'requires_submission']);
        $data['created_by'] = $delegate->id;
        $data['requires_submission'] = $request->boolean('requires_submission', true);

        $assignment = Assignment::create($data);

        return $this->success($this->assignmentPayload($assignment->load('subject', 'creator'), $delegate), 'تم إضافة التكليف بنجاح', 201);
    }

    /**
     * Update the specified assignment.
     */
    public function update(Request $request, string $id)
    {
        $delegate = $request->user();

        $assignment = Assignment::with('subject')->find($id);

        if (!$assignment || ! $this->isDelegateSubject($assignment->subject, $delegate)) {
            return $this->error('التكليف غير موجود أو غير مصرح لك', 404);
        }

        if (! $this->canModifyAssignment($assignment, $delegate, 'edit')) {
            return $this->error('ليس لديك صلاحية تعديل هذا التكليف. راجع دكتور المادة لمنحك الصلاحية.', 403);
        }

        $validator = Validator::make($request->all(), [
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'due_date' => 'required|date',
            'requires_submission' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        $targetSubject = Subject::where('id', $request->subject_id)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->first();

        if (! $targetSubject) {
            return $this->error('المادة المحددة غير مصرح بها.', 403);
        }

        $targetPermissionKey = (int) $assignment->created_by === (int) $delegate->id
            ? 'can_edit_own'
            : 'can_edit_doctor_assignments';

        if (! $this->hasAssignmentPermission($targetSubject, $delegate, $targetPermissionKey)) {
            return $this->error('ليس لديك صلاحية نقل هذا التكليف إلى المادة المحددة.', 403);
        }

        if ($request->subject_id != $assignment->subject_id) {
            $subject = Subject::where('id', $request->subject_id)
                ->where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)
                ->first();

            if (!$subject) {
                return $this->error('المادة الجديدة غير مصرح بها', 403);
            }
        }

        $data = $request->only(['subject_id', 'title', 'description', 'due_date', 'requires_submission']);
        $data['requires_submission'] = $request->boolean('requires_submission');

        $assignment->update($data);

        return $this->success($this->assignmentPayload($assignment->load('subject', 'creator'), $delegate), 'تم تحديث التكليف بنجاح');
    }

    /**
     * Remove the specified assignment.
     */
    public function destroy(Request $request, string $id)
    {
        $delegate = $request->user();

        $assignment = Assignment::with('subject')->find($id);

        if (!$assignment || ! $this->isDelegateSubject($assignment->subject, $delegate)) {
            return $this->error('التكليف غير موجود أو غير مصرح لك', 404);
        }

        if (! $this->canModifyAssignment($assignment, $delegate, 'delete')) {
            return $this->error('ليس لديك صلاحية حذف هذا التكليف. راجع دكتور المادة لمنحك الصلاحية.', 403);
        }

        $assignment->delete();

        return $this->success(null, 'تم حذف التكليف بنجاح');
    }

    private function assignmentPayload(Assignment $assignment, $delegate): array
    {
        $assignment->loadMissing(['subject:id,name,code,major_id,level_id,doctor_id', 'creator:id,name,role']);
        $isOwn = (int) $assignment->created_by === (int) $delegate->id;

        return array_merge($assignment->toArray(), [
            'owner_type' => $isOwn ? 'delegate' : 'doctor',
            'owner_label' => $isOwn ? 'من المندوب' : 'من الدكتور',
            'can_edit' => $this->canModifyAssignment($assignment, $delegate, 'edit'),
            'can_delete' => $this->canModifyAssignment($assignment, $delegate, 'delete'),
        ]);
    }

    private function isDelegateSubject(?Subject $subject, $delegate): bool
    {
        return $subject
            && (int) $subject->major_id === (int) $delegate->major_id
            && (int) $subject->level_id === (int) $delegate->level_id;
    }

    private function canModifyAssignment(Assignment $assignment, $delegate, string $action): bool
    {
        if (! $this->isDelegateSubject($assignment->subject, $delegate)) {
            return false;
        }

        $isOwn = (int) $assignment->created_by === (int) $delegate->id;
        $permissionKey = match ($action) {
            'edit' => $isOwn ? 'can_edit_own' : 'can_edit_doctor_assignments',
            'delete' => $isOwn ? 'can_delete_own' : 'can_delete_doctor_assignments',
            default => null,
        };

        return $permissionKey
            ? $this->hasAssignmentPermission($assignment->subject, $delegate, $permissionKey)
            : false;
    }

    private function hasAssignmentPermission(Subject $subject, $delegate, string $key): bool
    {
        if (! $subject->doctor_id) {
            return false;
        }

        return AssignmentDelegatePermission::where('doctor_id', $subject->doctor_id)
            ->where('delegate_id', $delegate->id)
            ->where('subject_id', $subject->id)
            ->where($key, true)
            ->exists();
    }
}
