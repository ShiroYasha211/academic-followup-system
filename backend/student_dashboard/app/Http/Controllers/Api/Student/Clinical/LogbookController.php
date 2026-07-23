<?php

namespace App\Http\Controllers\Api\Student\Clinical;

use App\Http\Controllers\Controller;
use App\Models\Clinical\BodySystem;
use App\Models\Clinical\CaseAssignment;
use App\Models\Clinical\ClinicalDepartment;
use App\Models\Clinical\DailyLogActivity;
use App\Models\Clinical\StudentDailyLog;
use App\Models\Clinical\TrainingCenter;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class LogbookController extends Controller
{
    public function index(Request $request)
    {
        $student = $request->user();

        $logs = StudentDailyLog::with([
            'trainingCenter',
            'department',
            'doctor',
            'caseAssignment.clinicalCase.trainingCenter',
            'caseAssignment.clinicalCase.clinicalDepartment',
            'caseAssignment.clinicalCase.bodySystem',
            'caseAssignment.reviewer',
            'confirmedBy',
            'activities.bodySystem',
            'activities.confirmedBy',
        ])->where('student_id', $student->id)
            ->latest()
            ->get();

        $confirmedCount = $logs->where('status', 'confirmed')->count();
        $pendingCount = $logs->whereIn('status', ['pending', 'partially_confirmed'])->count();

        $assignments = CaseAssignment::with([
            'clinicalCase.trainingCenter',
            'clinicalCase.clinicalDepartment',
            'clinicalCase.bodySystem',
            'assigner',
            'reviewer',
            'dailyLogs.trainingCenter',
            'dailyLogs.department',
            'dailyLogs.doctor',
            'dailyLogs.confirmedBy',
            'dailyLogs.activities.bodySystem',
            'dailyLogs.activities.confirmedBy',
        ])->where('student_id', $student->id)
            ->latest()
            ->get();

        $options = [
            'training_centers' => TrainingCenter::select('id', 'name')->orderBy('name')->get(),
            'departments' => ClinicalDepartment::select('id', 'name')->orderBy('name')->get(),
            'body_systems' => BodySystem::select('id', 'name')->orderBy('name')->get(),
            'doctors' => User::where('role', 'doctor')
                ->whereHas('subjects', function ($query) use ($student) {
                    $query->where('major_id', $student->major_id)
                        ->where('level_id', $student->level_id);
                })
                ->select('id', 'name')
                ->orderBy('name')
                ->get(),
        ];

        return response()->json([
            'success' => true,
            'data' => [
                'stats' => [
                    'confirmed_logs' => $confirmedCount,
                    'pending_logs' => $pendingCount,
                ],
                'assignments' => $assignments->map(fn (CaseAssignment $assignment) => $this->serializeAssignment($assignment))->values(),
                'logs' => $logs->map(fn ($log) => $this->serializeLog($log))->values(),
                'form_options' => $options,
            ],
        ]);
    }

    public function store(Request $request)
    {
        $student = $request->user();

        $request->validate([
            'case_assignment_id' => 'nullable|exists:case_assignments,id',
            'training_center_id' => 'required|exists:training_centers,id',
            'department_id' => 'required|exists:clinical_departments,id',
            'doctor_id' => ['required', Rule::exists('users', 'id')->where('role', 'doctor')],
            'histories' => 'nullable|array',
            'histories.*.body_system_id' => 'required|exists:body_systems,id',
            'exams' => 'nullable|array',
            'exams.*.body_system_id' => 'required|exists:body_systems,id',
            'did_round' => 'nullable|boolean',
            'rounds' => 'nullable|array',
            'rounds.*.case_name' => 'required|string|max:255',
            'round_notes' => 'nullable|string',
        ]);

        $assignment = $this->resolveAssignmentForAttempt($student->id, $request->input('case_assignment_id'));

        if ($assignment && $this->hasBlockingAttempt($assignment)) {
            return response()->json([
                'success' => false,
                'message' => 'يوجد سجل عملي مرتبط بهذا التكليف بانتظار مراجعة الدكتور. لا تحتاج إلى إرسال رسالة منفصلة.',
            ], 422);
        }

        $doctor = $assignment?->assigner;
        if (! $doctor) {
            $doctor = User::where('role', 'doctor')
                ->whereHas('subjects', function ($query) use ($student) {
                    $query->where('major_id', $student->major_id)
                        ->where('level_id', $student->level_id);
                })
                ->findOrFail($request->doctor_id);
        }

        $trainingCenterId = $assignment?->clinicalCase?->training_center_id ?: $request->training_center_id;
        $departmentId = $assignment?->clinicalCase?->clinical_department_id ?: $request->department_id;

        $dailyLog = StudentDailyLog::create([
            'student_id' => $student->id,
            'case_assignment_id' => $assignment?->id,
            'training_center_id' => $trainingCenterId,
            'department_id' => $departmentId,
            'doctor_id' => $doctor->id,
            'history_count' => count($request->histories ?? []),
            'exam_count' => count($request->exams ?? []),
            'did_round' => $request->boolean('did_round'),
            'round_notes' => $request->round_notes,
            'qr_token' => StudentDailyLog::generateToken(),
            'qr_generated_at' => now(),
            'status' => 'pending',
            'log_date' => now()->toDateString(),
            'log_time' => now()->toTimeString(),
        ]);

        if ($assignment) {
            $assignment->update([
                'status' => 'submitted_for_review',
                'student_completion_message' => trim((string) ($request->round_notes ?: 'تم إنشاء محاولة عملية مرتبطة بالتكليف.')),
                'submitted_at' => now(),
                'reviewed_at' => null,
                'reviewed_by' => null,
                'review_notes' => null,
                'review_rating' => null,
                'is_completed' => false,
                'completed_at' => null,
            ]);
        }

        foreach ($request->histories ?? [] as $history) {
            DailyLogActivity::create([
                'daily_log_id' => $dailyLog->id,
                'activity_type' => 'history_taking',
                'body_system_id' => $history['body_system_id'],
            ]);
        }

        foreach ($request->exams ?? [] as $exam) {
            DailyLogActivity::create([
                'daily_log_id' => $dailyLog->id,
                'activity_type' => 'clinical_examination',
                'body_system_id' => $exam['body_system_id'],
            ]);
        }

        if ($request->boolean('did_round')) {
            foreach ($request->rounds ?? [] as $round) {
                DailyLogActivity::create([
                    'daily_log_id' => $dailyLog->id,
                    'activity_type' => 'round',
                    'case_name' => $round['case_name'],
                ]);
            }
        }

        $dailyLog->load([
            'trainingCenter',
            'department',
            'doctor',
            'caseAssignment.clinicalCase.trainingCenter',
            'caseAssignment.clinicalCase.clinicalDepartment',
            'caseAssignment.clinicalCase.bodySystem',
            'caseAssignment.reviewer',
            'confirmedBy',
            'activities.bodySystem',
            'activities.confirmedBy',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Clinical daily log created successfully.',
            'data' => $this->serializeLog($dailyLog),
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $student = $request->user();

        $dailyLog = StudentDailyLog::where('student_id', $student->id)->findOrFail($id);

        if ($dailyLog->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Only pending logs can be updated.',
            ], 403);
        }

        $request->validate([
            'training_center_id' => 'required|exists:training_centers,id',
            'department_id' => 'required|exists:clinical_departments,id',
            'doctor_id' => ['required', Rule::exists('users', 'id')->where('role', 'doctor')],
            'histories' => 'nullable|array',
            'exams' => 'nullable|array',
            'did_round' => 'nullable|boolean',
            'rounds' => 'nullable|array',
            'round_notes' => 'nullable|string',
        ]);

        $doctor = User::where('role', 'doctor')
            ->whereHas('subjects', function ($query) use ($student) {
                $query->where('major_id', $student->major_id)
                    ->where('level_id', $student->level_id);
            })
            ->findOrFail($request->doctor_id);

        $dailyLog->update([
            'training_center_id' => $request->training_center_id,
            'department_id' => $request->department_id,
            'doctor_id' => $doctor->id,
            'history_count' => count($request->histories ?? []),
            'exam_count' => count($request->exams ?? []),
            'did_round' => $request->boolean('did_round'),
            'round_notes' => $request->round_notes,
        ]);

        $dailyLog->activities()->delete();

        foreach ($request->histories ?? [] as $history) {
            DailyLogActivity::create([
                'daily_log_id' => $dailyLog->id,
                'activity_type' => 'history_taking',
                'body_system_id' => $history['body_system_id'] ?? null,
            ]);
        }

        foreach ($request->exams ?? [] as $exam) {
            DailyLogActivity::create([
                'daily_log_id' => $dailyLog->id,
                'activity_type' => 'clinical_examination',
                'body_system_id' => $exam['body_system_id'] ?? null,
            ]);
        }

        if ($request->boolean('did_round')) {
            foreach ($request->rounds ?? [] as $round) {
                DailyLogActivity::create([
                    'daily_log_id' => $dailyLog->id,
                    'activity_type' => 'round',
                    'case_name' => $round['case_name'] ?? 'Round case',
                ]);
            }
        }

        $dailyLog->load([
            'trainingCenter',
            'department',
            'doctor',
            'caseAssignment.clinicalCase.trainingCenter',
            'caseAssignment.clinicalCase.clinicalDepartment',
            'caseAssignment.clinicalCase.bodySystem',
            'caseAssignment.reviewer',
            'confirmedBy',
            'activities.bodySystem',
            'activities.confirmedBy',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Clinical daily log updated successfully.',
            'data' => $this->serializeLog($dailyLog),
        ]);
    }

    public function destroy(Request $request, $id)
    {
        $student = $request->user();
        $dailyLog = StudentDailyLog::where('student_id', $student->id)->findOrFail($id);

        if ($dailyLog->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Only pending logs can be deleted.',
            ], 403);
        }

        $dailyLog->delete();

        return response()->json([
            'success' => true,
            'message' => 'Clinical daily log deleted successfully.',
        ]);
    }

    public function regenerateQr(Request $request, $id)
    {
        $student = $request->user();
        $dailyLog = StudentDailyLog::where('student_id', $student->id)
            ->whereIn('status', ['pending', 'partially_confirmed'])
            ->findOrFail($id);

        $dailyLog->update([
            'qr_token' => StudentDailyLog::generateToken(),
            'qr_generated_at' => now(),
        ]);

        $dailyLog->load([
            'trainingCenter',
            'department',
            'doctor',
            'caseAssignment.clinicalCase.trainingCenter',
            'caseAssignment.clinicalCase.clinicalDepartment',
            'caseAssignment.clinicalCase.bodySystem',
            'caseAssignment.reviewer',
            'confirmedBy',
            'activities.bodySystem',
            'activities.confirmedBy',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'تم تجديد الباركود بنجاح.',
            'data' => $this->serializeLog($dailyLog),
        ]);
    }

    public function submitAssignment(Request $request, $assignmentId)
    {
        $student = $request->user();
        $assignment = CaseAssignment::with([
            'dailyLogs.activities',
        ])->where('student_id', $student->id)->findOrFail($assignmentId);

        if ($assignment->dailyLogs()
            ->whereIn('status', ['pending', 'partially_confirmed'])
            ->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'يوجد سجل عملي مرتبط بهذا التكليف بانتظار مراجعة الدكتور. لا تحتاج إلى إرسال رسالة منفصلة.',
            ], 422);
        }

        if (!in_array($assignment->status, ['assigned', 'rejected'], true)) {
            return response()->json([
                'success' => false,
                'message' => 'لا يمكن إرسال إنجاز لهذا التكليف في حالته الحالية.',
            ], 422);
        }

        $validated = $request->validate([
            'student_completion_message' => 'required|string|min:5|max:2000',
        ]);

        $assignment->update([
            'status' => 'submitted_for_review',
            'student_completion_message' => trim($validated['student_completion_message']),
            'submitted_at' => now(),
            'reviewed_at' => null,
            'reviewed_by' => null,
            'review_notes' => null,
            'is_completed' => false,
            'completed_at' => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Assignment submitted for review successfully.',
            'data' => $assignment->fresh(['clinicalCase', 'assigner', 'reviewer']),
        ]);
    }

    public function exportPdf()
    {
        return response()->json([
            'success' => true,
            'message' => 'Use this URL to download the PDF logbook.',
            'data' => [
                'download_url' => url('/student/clinical/logbook/export-pdf'),
            ],
        ]);
    }

    protected function resolveAssignmentForAttempt(int $studentId, mixed $assignmentId): ?CaseAssignment
    {
        if (! $assignmentId) {
            return null;
        }

        $assignment = CaseAssignment::with([
            'clinicalCase',
            'assigner',
            'dailyLogs',
        ])->where('student_id', $studentId)->findOrFail($assignmentId);

        if (! in_array($assignment->status, ['assigned', 'rejected', 'submitted_for_review'], true)) {
            throw new \Illuminate\Http\Exceptions\HttpResponseException(response()->json([
                'success' => false,
                'message' => 'لا يمكن إنشاء محاولة جديدة لهذا التكليف في حالته الحالية.',
            ], 422));
        }

        return $assignment;
    }

    protected function serializeAssignment(CaseAssignment $assignment): array
    {
        $logs = $assignment->dailyLogs
            ? $assignment->dailyLogs->map(fn (StudentDailyLog $log) => $this->serializeLog($log))->values()
            : collect();

        return array_merge($assignment->toArray(), [
            'status_label' => $assignment->status_label,
            'task_type_label' => $assignment->task_type_label,
            'review_rating_label' => $assignment->review_rating_label,
            'is_overdue' => $assignment->is_overdue,
            'attempts' => $logs,
            'latest_attempt' => $logs->first(),
            'can_start_attempt' => in_array($assignment->status, ['assigned', 'rejected', 'submitted_for_review'], true)
                && ! $this->hasBlockingAttempt($assignment),
        ]);
    }

    protected function hasBlockingAttempt(CaseAssignment $assignment): bool
    {
        return $assignment->dailyLogs()
            ->where(function ($query) {
                $query->where('status', 'pending')
                    ->orWhere(function ($query) {
                        $query->where('status', 'partially_confirmed')
                            ->whereDoesntHave('activities', function ($query) {
                                $query->where('review_status', 'rejected');
                            });
                    });
            })
            ->exists();
    }

    protected function serializeLog(StudentDailyLog $log): array
    {
        $generatedAt = $log->qr_generated_at ?? $log->created_at;
        $expiresAt = $generatedAt?->copy()->addMinutes(30);
        $groups = collect($log->groupedActivities())->map(function ($group) {
            $items = $group['items']->map(function ($item) {
                return [
                    'id' => $item->id,
                    'activity_type' => $item->activity_type,
                    'body_system' => $item->bodySystem,
                    'case_name' => $item->case_name,
                    'is_confirmed' => (bool) $item->is_confirmed,
                    'review_status' => $item->is_confirmed ? 'approved' : ($item->review_status ?: 'pending'),
                    'review_status_label' => $item->review_status_label,
                    'review_notes' => $item->review_notes,
                    'diagnosis' => $item->diagnosis,
                    'confirmed_by' => $item->confirmedBy,
                    'confirmed_at' => $item->confirmed_at,
                ];
            })->values();

            return [
                'key' => $group['key'],
                'label' => $group['label'],
                'activity_type' => $group['activity_type'],
                'all_confirmed' => $items->isNotEmpty() && $items->every(fn ($item) => $item['is_confirmed']),
                'approved_count' => $items->where('review_status', 'approved')->count(),
                'rejected_count' => $items->where('review_status', 'rejected')->count(),
                'pending_count' => $items->where('review_status', 'pending')->count(),
                'has_rejected' => $items->contains(fn ($item) => $item['review_status'] === 'rejected'),
                'diagnosis' => $items->pluck('diagnosis')->filter()->first(),
                'items' => $items,
            ];
        })->values();

        return array_merge($log->toArray(), [
            'status_label' => $log->status_label,
            'case_assignment' => $log->caseAssignment ? [
                'id' => $log->caseAssignment->id,
                'status' => $log->caseAssignment->status,
                'status_label' => $log->caseAssignment->status_label,
                'task_type' => $log->caseAssignment->task_type,
                'task_type_label' => $log->caseAssignment->task_type_label,
                'instructions' => $log->caseAssignment->instructions,
                'review_notes' => $log->caseAssignment->review_notes,
                'review_rating_label' => $log->caseAssignment->review_rating_label,
                'clinical_case' => $log->caseAssignment->clinicalCase,
            ] : null,
            'qr_generated_at' => $generatedAt?->toIso8601String(),
            'qr_expires_at' => $expiresAt?->toIso8601String(),
            'is_qr_expired' => $expiresAt ? now()->greaterThanOrEqualTo($expiresAt) : false,
            'can_regenerate_qr' => in_array($log->status, ['pending', 'partially_confirmed'], true),
            'grouped_activities' => $groups,
        ]);
    }
}
