<?php

namespace App\Http\Controllers\Api\Doctor\Clinical;

use App\Http\Controllers\Api\Doctor\DoctorApiController;
use App\Models\Academic\Subject;
use App\Models\Clinical\StudentDailyLog;
use App\Models\StudentNotification;
use App\Models\User;
use App\Services\ClinicalLogbookPortfolioService;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class LogbookController extends DoctorApiController
{
    public function processQr(Request $request)
    {
        $request->validate(['qr_token' => 'required|string']);

        $log = StudentDailyLog::with([
            'student',
            'trainingCenter',
            'department',
            'doctor',
            'caseAssignment.clinicalCase.trainingCenter',
            'caseAssignment.clinicalCase.clinicalDepartment',
            'caseAssignment.clinicalCase.bodySystem',
            'caseAssignment.reviewer',
            'activities.bodySystem',
            'activities.confirmedBy',
        ])->where('qr_token', $request->qr_token)
            ->where('doctor_id', Auth::id())
            ->first();

        if (!$log) {
            return $this->error('رمز QR غير صالح.', 404);
        }
        if ($log->status === 'confirmed') {
            return $this->error('هذا السجل معتمد بالكامل بالفعل.', 422);
        }
        if ($log->status === 'rejected') {
            return $this->error('هذا السجل مرفوض ولا يمكن اعتماده من هذه الشاشة.', 422);
        }
        if ($log->status === 'pending' && $log->isExpired()) {
            return $this->error('انتهت صلاحية رمز QR لهذا السجل.', 422);
        }

        return $this->success($this->serializeLog($log), 'تم تحميل السجل العملي بنجاح.');
    }

    public function confirm(Request $request)
    {
        $validated = $request->validate([
            'log_id' => 'required|exists:student_daily_logs,id',
            'action' => 'required|in:confirm,reject',
            'doctor_notes' => 'nullable|string|max:1000',
            'confirmations' => 'nullable|array',
            'confirmations.history.confirm' => 'nullable|boolean',
            'confirmations.history.status' => 'nullable|in:pending,approved,rejected',
            'confirmations.history.diagnosis' => 'nullable|string|max:1000',
            'confirmations.exam.confirm' => 'nullable|boolean',
            'confirmations.exam.status' => 'nullable|in:pending,approved,rejected',
            'confirmations.exam.diagnosis' => 'nullable|string|max:1000',
            'confirmations.round.confirm' => 'nullable|boolean',
            'confirmations.round.status' => 'nullable|in:pending,approved,rejected',
            'confirmations.round.diagnosis' => 'nullable|string|max:1000',
        ]);

        $log = StudentDailyLog::with(['activities', 'caseAssignment.student', 'caseAssignment.clinicalCase'])
            ->where('doctor_id', Auth::id())
            ->findOrFail($validated['log_id']);

        if (!in_array($log->status, ['pending', 'partially_confirmed'], true)) {
            return $this->error('تمت معالجة هذا السجل مسبقًا.', 422);
        }

        if ($validated['action'] === 'reject') {
            $log->activities()->update([
                'is_confirmed' => false,
                'review_status' => 'rejected',
                'review_notes' => $validated['doctor_notes'] ?? null,
                'diagnosis' => null,
                'confirmed_by' => null,
                'confirmed_at' => null,
            ]);

            $log->update([
                'status' => 'rejected',
                'confirmed_by' => Auth::id(),
                'confirmed_at' => now(),
                'doctor_notes' => $validated['doctor_notes'] ?? null,
            ]);

            $this->syncLinkedAssignment($log->fresh(['caseAssignment.student', 'caseAssignment.clinicalCase']), 'rejected', $validated['doctor_notes'] ?? null);

            return $this->success([
                'status' => $log->status,
            ], 'تم رفض السجل العملي.');
        }

        $groups = $log->groupedActivities();
        $confirmations = $validated['confirmations'] ?? [];
        $selectedAny = false;

        DB::transaction(function () use ($log, $groups, $confirmations, &$selectedAny, $validated) {
            foreach ($groups as $key => $group) {
                $status = data_get($confirmations, $key . '.status');
                if (! $status) {
                    $status = (bool) data_get($confirmations, $key . '.confirm', false) ? 'approved' : 'pending';
                }

                if ($status === 'pending') {
                    continue;
                }

                $selectedAny = true;
                $diagnosis = trim((string) data_get($confirmations, $key . '.diagnosis', ''));
                $approved = $status === 'approved';

                $log->activities()
                    ->where('activity_type', $group['activity_type'])
                    ->update([
                        'is_confirmed' => $approved,
                        'review_status' => $status,
                        'diagnosis' => $approved && $diagnosis !== '' ? $diagnosis : null,
                        'review_notes' => ! $approved ? ($validated['doctor_notes'] ?? null) : null,
                        'confirmed_by' => Auth::id(),
                        'confirmed_at' => now(),
                    ]);
            }

            if (!$selectedAny) {
                return;
            }

            $log->refresh();
            $log->syncApprovalStatus();
            $log->update([
                'confirmed_by' => Auth::id(),
                'confirmed_at' => now(),
                'doctor_notes' => $validated['doctor_notes'] ?? null,
            ]);
        });

        if (!$selectedAny) {
            return $this->error('اختر قسمًا واحدًا على الأقل لاعتماده.', 422);
        }

        $log->refresh();
        $this->syncLinkedAssignment($log->load(['caseAssignment.student', 'caseAssignment.clinicalCase']), $log->status, $validated['doctor_notes'] ?? null);

        return $this->success([
            'status' => $log->status,
            'status_label' => $log->status_label,
            'log' => $this->serializeLog($log->load([
                'student',
                'trainingCenter',
                'department',
                'doctor',
                'caseAssignment.clinicalCase.trainingCenter',
                'caseAssignment.clinicalCase.clinicalDepartment',
                'caseAssignment.clinicalCase.bodySystem',
                'caseAssignment.reviewer',
                'activities.bodySystem',
                'activities.confirmedBy',
            ])),
        ], $log->status === 'confirmed' ? 'تم اعتماد جميع أقسام السجل.' : 'تم اعتماد جزء من أقسام السجل، وما زال المتبقي بانتظار المراجعة.');
    }

    public function records(Request $request)
    {
        $query = StudentDailyLog::with([
            'student:id,name,student_number',
            'trainingCenter',
            'department',
            'confirmedBy:id,name',
            'caseAssignment.clinicalCase.trainingCenter',
            'caseAssignment.clinicalCase.clinicalDepartment',
            'caseAssignment.clinicalCase.bodySystem',
            'caseAssignment.reviewer',
            'activities.bodySystem',
            'activities.confirmedBy:id,name',
        ])->where('doctor_id', Auth::id());

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('date')) {
            $query->whereDate('log_date', $request->date);
        }

        $paginator = $query->latest()->paginate(20);
        $paginator->setCollection(
            $paginator->getCollection()->map(fn (StudentDailyLog $log) => $this->serializeLog($log))
        );

        return $this->paginated($paginator);
    }

    public function portfolioStudents(Request $request, ClinicalLogbookPortfolioService $service)
    {
        $paginator = $service->studentsForDoctor(Auth::user(), $request);

        return response()->json([
            'success' => true,
            'message' => 'تم جلب تقارير إنجازات الطلاب بنجاح.',
            'data' => $paginator->items(),
            'filters' => $service->filtersForDoctor(Auth::user()),
            'pagination' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
            ],
        ]);
    }

    public function portfolioShow(Request $request, User $student, ClinicalLogbookPortfolioService $service)
    {
        $portfolio = $service->portfolioForDoctor(Auth::user(), $student, $request);

        if (($portfolio['summary']['approved_activities'] ?? 0) === 0) {
            return $this->error('لا توجد إنجازات عملية معتمدة لهذا الطالب ضمن نطاقك.', 404);
        }

        return $this->success($portfolio, 'تم جلب تقرير الطالب العملي بنجاح.');
    }

    public function portfolioPdf(Request $request, User $student, ClinicalLogbookPortfolioService $service)
    {
        $portfolio = $service->portfolioForDoctor(Auth::user(), $student, $request);

        if (($portfolio['summary']['approved_activities'] ?? 0) === 0) {
            return $this->error('لا توجد إنجازات عملية معتمدة لهذا الطالب ضمن نطاقك.', 404);
        }

        $pdf = Pdf::loadView('doctor.clinical.logbook_portfolios.pdf', compact('portfolio'));
        $filename = 'clinical_portfolio_' . ($student->student_number ?: $student->id) . '_' . now()->format('Y-m-d') . '.pdf';

        return $pdf->download($filename);
    }

    public function portfolioCsv(Request $request, User $student, ClinicalLogbookPortfolioService $service)
    {
        $portfolio = $service->portfolioForDoctor(Auth::user(), $student, $request);

        if (($portfolio['summary']['approved_activities'] ?? 0) === 0) {
            return $this->error('لا توجد إنجازات عملية معتمدة لهذا الطالب ضمن نطاقك.', 404);
        }

        $filename = 'clinical_portfolio_' . ($student->student_number ?: $student->id) . '_' . now()->format('Y-m-d') . '.csv';

        return response()->streamDownload(function () use ($portfolio) {
            $handle = fopen('php://output', 'w');
            fprintf($handle, chr(0xEF) . chr(0xBB) . chr(0xBF));
            fputcsv($handle, ['نظام الجسم/المهارة', 'قصص مرضية', 'فحوصات سريرية', 'مرور', 'الإجمالي']);
            foreach ($portfolio['matrix'] as $row) {
                fputcsv($handle, [
                    $row['body_system'],
                    $row['history_taking'],
                    $row['clinical_examination'],
                    $row['round'],
                    $row['total'],
                ]);
            }
            fputcsv($handle, []);
            fputcsv($handle, ['التاريخ', 'المركز', 'القسم', 'الدكتور', 'نوع النشاط', 'النظام/الحالة', 'الملاحظات']);
            foreach ($portfolio['logs'] as $log) {
                foreach ($log['activities'] as $activity) {
                    fputcsv($handle, [
                        $log['date'],
                        $log['training_center'],
                        $log['department'],
                        $log['doctor'],
                        $activity['type_label'],
                        $activity['body_system'],
                        $activity['diagnosis'] ?: $log['doctor_notes'],
                    ]);
                }
            }
            fclose($handle);
        }, $filename, ['Content-Type' => 'text/csv; charset=UTF-8']);
    }

    public function manualAttendance(Request $request)
    {
        $request->validate([
            'student_id' => 'required|exists:users,id',
            'training_center_id' => 'required|exists:training_centers,id',
            'department_id' => 'required|exists:clinical_departments,id',
            'doctor_notes' => 'nullable|string|max:1000',
        ]);

        $doctorScopes = Subject::where('doctor_id', Auth::id())
            ->select('major_id', 'level_id')
            ->distinct()
            ->get();

        $studentQuery = User::whereKey($request->student_id)
            ->whereIn('role', ['student', 'delegate', 'practical_delegate']);

        if ($doctorScopes->isEmpty()) {
            $studentQuery->whereRaw('1 = 0');
        } else {
            $studentQuery->where(function ($query) use ($doctorScopes) {
                foreach ($doctorScopes as $scope) {
                    $query->orWhere(function ($inner) use ($scope) {
                        $inner->where('major_id', $scope->major_id)
                            ->where('level_id', $scope->level_id);
                    });
                }
            });
        }

        $studentQuery->firstOrFail();

        $log = StudentDailyLog::create([
            'student_id' => $request->student_id,
            'training_center_id' => $request->training_center_id,
            'department_id' => $request->department_id,
            'doctor_id' => Auth::id(),
            'qr_token' => StudentDailyLog::generateToken(),
            'status' => 'confirmed',
            'confirmed_by' => Auth::id(),
            'confirmed_at' => now(),
            'doctor_notes' => $request->doctor_notes ?: 'Manual attendance',
            'log_date' => now()->toDateString(),
            'log_time' => now()->toTimeString(),
        ]);

        return $this->success($log, 'Manual attendance recorded successfully.', 201);
    }

    protected function serializeLog(StudentDailyLog $log): array
    {
        $groups = [];
        foreach ($log->groupedActivities() as $key => $group) {
            $items = $group['items'];
            $groups[] = [
                'key' => $key,
                'label' => $group['label'],
                'count' => $items->count(),
                'confirmed' => $items->every(fn ($item) => (bool) $item->is_confirmed),
                'approved_count' => $items->filter(fn ($item) => $item->is_confirmed || $item->review_status === 'approved')->count(),
                'rejected_count' => $items->where('review_status', 'rejected')->count(),
                'pending_count' => $items->where('review_status', 'pending')->count(),
                'has_rejected' => $items->contains(fn ($item) => $item->review_status === 'rejected'),
                'diagnosis' => $items->pluck('diagnosis')->filter()->first(),
                'items' => $items->map(function ($item) {
                    return [
                        'id' => $item->id,
                        'label' => $item->activity_type === 'round'
                            ? ($item->case_name ?: 'Round case')
                            : ($item->bodySystem->name ?? '-'),
                        'is_confirmed' => (bool) $item->is_confirmed,
                        'review_status' => $item->is_confirmed ? 'approved' : ($item->review_status ?: 'pending'),
                        'review_status_label' => $item->review_status_label,
                        'review_notes' => $item->review_notes,
                        'diagnosis' => $item->diagnosis,
                        'confirmed_at' => optional($item->confirmed_at)?->toIso8601String(),
                    ];
                })->values(),
            ];
        }

        return [
            'log_id' => $log->id,
            'student_name' => $log->student?->name,
            'student_number' => $log->student?->student_number,
            'training_center' => $log->trainingCenter?->name,
            'department' => $log->department?->name,
            'doctor_name' => $log->doctor?->name,
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
            'log_date' => $log->log_date?->format('Y-m-d'),
            'log_time' => $log->log_time,
            'status' => $log->status,
            'status_label' => $log->status_label,
            'doctor_notes' => $log->doctor_notes,
            'groups' => $groups,
        ];
    }

    protected function syncLinkedAssignment(StudentDailyLog $log, string $logStatus, ?string $notes): void
    {
        $assignment = $log->caseAssignment;
        if (! $assignment) {
            return;
        }

        $now = now();
        if ($logStatus === 'confirmed') {
            $assignment->update([
                'status' => 'approved',
                'reviewed_at' => $now,
                'reviewed_by' => Auth::id(),
                'review_notes' => trim((string) $notes) ?: 'تم اعتماد التكليف بنجاح.',
                'review_rating' => $assignment->review_rating ?: 'good',
                'is_completed' => true,
                'completed_at' => $now,
            ]);
            $this->notifyAssignmentStudent($assignment->fresh(['student', 'clinicalCase']), 'approved');
            return;
        }

        if ($logStatus === 'rejected') {
            $assignment->update([
                'status' => 'rejected',
                'reviewed_at' => $now,
                'reviewed_by' => Auth::id(),
                'review_notes' => trim((string) $notes) ?: 'تم رفض المحاولة. يجب تنفيذ محاولة جديدة بعد مراجعة ملاحظات الدكتور.',
                'review_rating' => null,
                'is_completed' => false,
                'completed_at' => null,
            ]);
            $this->notifyAssignmentStudent($assignment->fresh(['student', 'clinicalCase']), 'rejected');
            return;
        }

        if ($logStatus === 'partially_confirmed') {
            $assignment->update([
                'status' => 'submitted_for_review',
                'reviewed_at' => $now,
                'reviewed_by' => Auth::id(),
                'review_notes' => trim((string) $notes) ?: 'تم اعتماد جزء من المحاولة، وما زالت هناك عناصر تحتاج إكمالًا.',
                'is_completed' => false,
                'completed_at' => null,
            ]);
            $this->notifyAssignmentStudent($assignment->fresh(['student', 'clinicalCase']), 'partially_confirmed');
        }
    }

    protected function notifyAssignmentStudent($assignment, string $event): void
    {
        $student = $assignment->student;
        if (! $student) {
            return;
        }

        $title = match ($event) {
            'approved' => 'تم اعتماد تكليفك السريري',
            'rejected' => 'تم رفض محاولة التكليف السريري',
            'partially_confirmed' => 'تم اعتماد جزء من التكليف السريري',
            default => 'تحديث على تكليفك السريري',
        };

        $message = match ($event) {
            'approved' => 'تم اعتماد التكليف بنجاح.',
            'rejected' => 'تم رفض المحاولة. يمكنك تنفيذ محاولة جديدة بعد مراجعة ملاحظات الدكتور.',
            'partially_confirmed' => 'تم اعتماد بعض العناصر، وما زالت هناك عناصر تحتاج إكمالًا.',
            default => 'يوجد تحديث جديد على تكليفك السريري.',
        };

        StudentNotification::create([
            'user_id' => $student->id,
            'college_id' => $student->college_id,
            'sender_id' => Auth::id(),
            'type' => 'clinical_assignment',
            'title' => $title,
            'message' => $message,
            'data' => [
                'assignment_id' => $assignment->id,
                'clinical_case_id' => $assignment->clinical_case_id,
                'screen' => 'clinical_assignment',
                'target_screen' => 'clinical_assignment',
            ],
        ]);

    }
}
