<?php

namespace App\Http\Controllers\Api\Doctor\Clinical;

use App\Http\Controllers\Api\Doctor\DoctorApiController;
use App\Models\Clinical\CaseAssignment;
use App\Models\Clinical\ClinicalCase;
use App\Models\StudentNotification;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CaseAssignmentController extends DoctorApiController
{
    public function index(Request $request)
    {
        $query = CaseAssignment::with($this->assignmentRelations())
            ->where('assigned_by', Auth::id());

        if ($request->filled('student_id')) {
            $query->where('student_id', $request->student_id);
        }
        if ($request->filled('clinical_case_id')) {
            $query->where('clinical_case_id', $request->clinical_case_id);
        }
        if ($request->filled('task_type')) {
            $query->where('task_type', $request->task_type);
        }
        if ($request->filled('status')) {
            if ($request->status === 'overdue') {
                $query->whereNotNull('due_at')
                    ->where('due_at', '<', now())
                    ->whereNotIn('status', ['approved', 'rejected']);
            } else {
                $query->where('status', $request->status);
            }
        }

        $perPage = min(max((int) $request->input('per_page', 20), 1), 100);
        $paginator = $query->latest()->paginate($perPage);
        $paginator->setCollection(
            $paginator->getCollection()->map(fn (CaseAssignment $assignment) => $this->serializeAssignment($assignment))
        );

        return $this->paginated($paginator);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'student_id' => 'required|exists:users,id',
            'clinical_case_id' => 'required|exists:clinical_cases,id',
            'task_type' => 'required|in:history_taking,clinical_examination,follow_up',
            'instructions' => 'nullable|string',
            'due_at' => 'nullable|date',
            'attachment' => 'nullable|file|max:10240',
        ]);

        $case = ClinicalCase::where('doctor_id', Auth::id())
            ->where('status', 'active')
            ->find($validated['clinical_case_id']);

        if (! $case) {
            return $this->error('لا يمكن تكليف حالة غير نشطة أو غير تابعة لك.', 422);
        }

        if (! $this->studentBelongsToDoctorScope((int) $validated['student_id'])) {
            return $this->error('الطالب المحدد ليس ضمن نطاق المواد المرتبطة بك.', 422);
        }

        $validated['assigned_by'] = Auth::id();
        $validated['status'] = 'assigned';

        if ($request->hasFile('attachment')) {
            $file = $request->file('attachment');
            $validated['attachment_path'] = $file->store('clinical/case_assignments', 'public');
            $validated['attachment_name'] = $file->getClientOriginalName();
            $validated['attachment_type'] = $file->getClientMimeType();
        }
        unset($validated['attachment']);

        $exists = CaseAssignment::where('student_id', $validated['student_id'])
            ->where('clinical_case_id', $validated['clinical_case_id'])
            ->where('task_type', $validated['task_type'])
            ->exists();

        if ($exists) {
            return $this->error('هذا الطالب لديه نفس المهمة لهذه الحالة مسبقًا.', 422);
        }

        $assignment = CaseAssignment::create($validated);
        $assignment->load($this->assignmentRelations());
        $this->notifyStudent($assignment, 'created');

        return $this->success(
            $this->serializeAssignment($assignment),
            'تم إنشاء تكليف الحالة بنجاح.',
            201
        );
    }

    public function review(Request $request, CaseAssignment $assignment)
    {
        if ($assignment->assigned_by !== Auth::id()) {
            return $this->error('لا تملك صلاحية مراجعة هذا التكليف.', 403);
        }

        if ($assignment->status !== 'submitted_for_review') {
            return $this->error('هذا التكليف ليس بانتظار المراجعة.', 422);
        }

        $validated = $request->validate([
            'action' => 'required|in:approve,reject',
            'review_notes' => 'required_if:action,reject|nullable|string|max:2000',
            'review_rating' => 'nullable|required_if:action,approve|in:excellent,good,needs_improvement',
        ]);

        $now = now();
        if ($validated['action'] === 'approve') {
            $assignment->update([
                'status' => 'approved',
                'reviewed_at' => $now,
                'reviewed_by' => Auth::id(),
                'review_notes' => trim((string) ($validated['review_notes'] ?? '')) ?: null,
                'review_rating' => $validated['review_rating'] ?? null,
                'is_completed' => true,
                'completed_at' => $now,
            ]);
            $this->notifyStudent($assignment->fresh($this->assignmentRelations()), 'approved');

            return $this->success(
                $this->serializeAssignment($assignment->fresh($this->assignmentRelations())),
                'تم اعتماد التكليف بنجاح.'
            );
        }

        $assignment->update([
            'status' => 'rejected',
            'reviewed_at' => $now,
            'reviewed_by' => Auth::id(),
            'review_notes' => trim($validated['review_notes']),
            'review_rating' => null,
            'is_completed' => false,
            'completed_at' => null,
        ]);
        $this->notifyStudent($assignment->fresh($this->assignmentRelations()), 'rejected');

        return $this->success(
            $this->serializeAssignment($assignment->fresh($this->assignmentRelations())),
            'تم رفض التكليف بنجاح.'
        );
    }

    private function assignmentRelations(): array
    {
        return [
            'student:id,name,student_number,major_id,level_id',
            'student.major:id,name',
            'student.level:id,name',
            'clinicalCase.trainingCenter:id,name',
            'clinicalCase.clinicalDepartment:id,name',
            'clinicalCase.bodySystem:id,name',
            'reviewer:id,name',
            'dailyLogs.trainingCenter',
            'dailyLogs.department',
            'dailyLogs.doctor',
            'dailyLogs.confirmedBy',
            'dailyLogs.activities.bodySystem',
            'dailyLogs.activities.confirmedBy',
        ];
    }

    private function studentBelongsToDoctorScope(int $studentId): bool
    {
        return User::query()
            ->where('id', $studentId)
            ->inDoctorClinicalScope(Auth::id())
            ->exists();
    }

    private function serializeAssignment(CaseAssignment $assignment): array
    {
        $student = $assignment->student;
        $case = $assignment->clinicalCase;

        return [
            'id' => $assignment->id,
            'student_id' => $assignment->student_id,
            'clinical_case_id' => $assignment->clinical_case_id,
            'task_type' => $assignment->task_type,
            'task_type_label' => $assignment->task_type_label,
            'instructions' => $assignment->instructions,
            'due_at' => optional($assignment->due_at)->toISOString(),
            'due_at_label' => optional($assignment->due_at)->format('Y-m-d H:i'),
            'attachment_path' => $assignment->attachment_path,
            'attachment_name' => $assignment->attachment_name,
            'attachment_type' => $assignment->attachment_type,
            'attachment_url' => $assignment->attachment_path
                ? asset('storage/' . $assignment->attachment_path)
                : null,
            'is_overdue' => $assignment->is_overdue,
            'status' => $assignment->status,
            'status_label' => $assignment->status_label,
            'student_completion_message' => $assignment->student_completion_message,
            'submitted_at' => optional($assignment->submitted_at)->toISOString(),
            'submitted_at_label' => optional($assignment->submitted_at)->format('Y-m-d H:i'),
            'reviewed_at' => optional($assignment->reviewed_at)->toISOString(),
            'reviewed_at_label' => optional($assignment->reviewed_at)->format('Y-m-d H:i'),
            'review_notes' => $assignment->review_notes,
            'review_rating' => $assignment->review_rating,
            'review_rating_label' => $assignment->review_rating_label,
            'is_completed' => (bool) $assignment->is_completed,
            'completed_at' => optional($assignment->completed_at)->toISOString(),
            'completed_at_label' => optional($assignment->completed_at)->format('Y-m-d H:i'),
            'created_at' => optional($assignment->created_at)->toISOString(),
            'created_at_label' => optional($assignment->created_at)->format('Y-m-d H:i'),
            'updated_at' => optional($assignment->updated_at)->toISOString(),
            'student' => $student ? [
                'id' => $student->id,
                'name' => $student->name,
                'student_number' => $student->student_number,
                'major' => $student->major ? [
                    'id' => $student->major->id,
                    'name' => $student->major->name,
                ] : null,
                'level' => $student->level ? [
                    'id' => $student->level->id,
                    'name' => $student->level->name,
                ] : null,
            ] : null,
            'clinical_case' => $case ? [
                'id' => $case->id,
                'patient_name' => $case->patient_name,
                'age' => $case->age,
                'gender' => $case->gender,
                'diagnosis_or_description' => $case->diagnosis_or_description,
                'status' => $case->status,
                'training_center' => $case->trainingCenter ? [
                    'id' => $case->trainingCenter->id,
                    'name' => $case->trainingCenter->name,
                ] : null,
                'clinical_department' => $case->clinicalDepartment ? [
                    'id' => $case->clinicalDepartment->id,
                    'name' => $case->clinicalDepartment->name,
                ] : null,
                'body_system' => $case->bodySystem ? [
                    'id' => $case->bodySystem->id,
                    'name' => $case->bodySystem->name,
                ] : null,
            ] : null,
            'reviewer' => $assignment->reviewer ? [
                'id' => $assignment->reviewer->id,
                'name' => $assignment->reviewer->name,
            ] : null,
            'attempts' => $assignment->dailyLogs
                ? $assignment->dailyLogs->map(fn ($log) => [
                    'id' => $log->id,
                    'status' => $log->status,
                    'status_label' => $log->status_label,
                    'doctor_notes' => $log->doctor_notes,
                    'log_date' => optional($log->log_date)->format('Y-m-d'),
                    'log_time' => $log->log_time,
                    'training_center' => $log->trainingCenter,
                    'department' => $log->department,
                    'confirmed_by' => $log->confirmedBy,
                    'groups' => collect($log->groupedActivities())->map(function ($group, $key) {
                        $items = $group['items'];
                        return [
                            'key' => $key,
                            'label' => $group['label'],
                            'count' => $items->count(),
                            'confirmed' => $items->isNotEmpty() && $items->every(fn ($item) => (bool) $item->is_confirmed),
                            'approved_count' => $items->filter(fn ($item) => $item->is_confirmed || $item->review_status === 'approved')->count(),
                            'rejected_count' => $items->where('review_status', 'rejected')->count(),
                            'pending_count' => $items->where('review_status', 'pending')->count(),
                            'has_rejected' => $items->contains(fn ($item) => $item->review_status === 'rejected'),
                            'items' => $items->map(fn ($item) => [
                                'id' => $item->id,
                                'activity_type' => $item->activity_type,
                                'body_system' => $item->bodySystem,
                                'case_name' => $item->case_name,
                                'is_confirmed' => (bool) $item->is_confirmed,
                                'review_status' => $item->is_confirmed ? 'approved' : ($item->review_status ?: 'pending'),
                                'review_status_label' => $item->review_status_label,
                                'review_notes' => $item->review_notes,
                                'diagnosis' => $item->diagnosis,
                            ])->values(),
                        ];
                    })->values(),
                ])->values()
                : [],
        ];
    }

    private function notifyStudent(CaseAssignment $assignment, string $event): void
    {
        $student = $assignment->student;
        $case = $assignment->clinicalCase;

        if (! $student) {
            return;
        }
        $title = match ($event) {
            'updated' => 'تم تحديث تكليف سريري',
            'approved' => 'تم اعتماد تكليفك السريري',
            'rejected' => 'تم رفض محاولة التكليف السريري',
            default => 'تكليف سريري جديد',
        };

        $message = match ($event) {
            'approved' => 'تم اعتماد التكليف السريري بنجاح.',
            'rejected' => 'تم رفض المحاولة. راجع ملاحظات الدكتور ثم نفذ محاولة جديدة.',
            'updated' => 'تم تحديث تفاصيل تكليفك السريري.',
            default => 'تم تكليفك بحالة سريرية: ' . ($case?->patient_name ?: 'حالة سريرية'),
        };

        StudentNotification::create([
            'user_id' => $student->id,
            'college_id' => $student->college_id,
            'sender_id' => Auth::id(),
            'type' => 'clinical_assignment',
            'title' => $title,
            'message' => $message,
            'attachment_path' => $assignment->attachment_path,
            'attachment_name' => $assignment->attachment_name,
            'data' => [
                'assignment_id' => $assignment->id,
                'clinical_case_id' => $assignment->clinical_case_id,
                'screen' => 'clinical_assignment',
                'target_screen' => 'clinical_assignment',
            ],
        ]);

    }
}
