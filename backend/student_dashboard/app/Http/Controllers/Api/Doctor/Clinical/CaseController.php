<?php

namespace App\Http\Controllers\Api\Doctor\Clinical;

use App\Http\Controllers\Api\Doctor\DoctorApiController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Clinical\CaseAssignment;
use App\Models\Clinical\ClinicalCase;
use App\Models\Clinical\TrainingCenter;
use App\Models\Clinical\ClinicalDepartment;
use App\Models\Clinical\BodySystem;

class CaseController extends DoctorApiController
{
    /** GET /api/doctor/clinical/cases */
    public function index(Request $request)
    {
        $perPage = min(max((int) $request->integer('per_page', 100), 1), 200);

        $query = ClinicalCase::with(['trainingCenter', 'clinicalDepartment', 'bodySystem', 'doctor'])
            ->where('doctor_id', Auth::id());

        if ($request->filled('patient_name')) {
            $query->where('patient_name', 'like', "%{$request->patient_name}%");
        }
        if ($request->filled('training_center_id')) {
            $query->where('training_center_id', $request->training_center_id);
        }
        if ($request->filled('clinical_department_id')) {
            $query->where('clinical_department_id', $request->clinical_department_id);
        }
        if ($request->filled('body_system_id')) {
            $query->where('body_system_id', $request->body_system_id);
        }
        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $cases = $query->latest()->paginate($perPage);
        $includeSummary = $request->boolean('include_assignment_summary');
        $cases->getCollection()->transform(
            fn (ClinicalCase $case) => $this->serializeCase($case, includeSummary: $includeSummary)
        );

        return $this->paginated($cases);
    }

    /** POST /api/doctor/clinical/cases */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'patient_name' => 'required|string|max:255',
            'age' => 'nullable|integer|min:0|max:150',
            'gender' => 'nullable|in:male,female',
            'training_center_id' => 'required|exists:training_centers,id',
            'clinical_department_id' => 'required|exists:clinical_departments,id',
            'body_system_id' => 'required|exists:body_systems,id',
            'diagnosis_or_description' => 'nullable|string',
            'status' => 'required|in:active,discharged,transferred',
        ]);
        $validated['doctor_id'] = Auth::id();
        $validated['approval_status'] = 'approved';

        $case = ClinicalCase::create($validated);

        return $this->success(
            $this->serializeCase($case->load(['trainingCenter', 'clinicalDepartment', 'bodySystem', 'doctor'])),
            'تم إدراج الحالة بنجاح.',
            201
        );
    }

    /** GET /api/doctor/clinical/cases/{id} */
    public function show($id)
    {
        $case = ClinicalCase::with(['trainingCenter', 'clinicalDepartment', 'bodySystem', 'doctor'])
            ->where('doctor_id', Auth::id())
            ->findOrFail($id);
        return $this->success($this->serializeCase(
            $case,
            includeSummary: true,
            includeAssignments: request()->boolean('include_assignments')
        ));
    }

    /** PUT /api/doctor/clinical/cases/{id} */
    public function update(Request $request, $id)
    {
        $case = ClinicalCase::where('doctor_id', Auth::id())->findOrFail($id);
        $validated = $request->validate([
            'patient_name' => 'required|string|max:255',
            'age' => 'nullable|integer|min:0|max:150',
            'gender' => 'nullable|in:male,female',
            'training_center_id' => 'required|exists:training_centers,id',
            'clinical_department_id' => 'required|exists:clinical_departments,id',
            'body_system_id' => 'required|exists:body_systems,id',
            'diagnosis_or_description' => 'nullable|string',
            'status' => 'required|in:active,discharged,transferred',
        ]);
        $case->update($validated);

        return $this->success(
            $this->serializeCase($case->load(['trainingCenter', 'clinicalDepartment', 'bodySystem', 'doctor'])),
            'تم تحديث الحالة بنجاح.'
        );
    }

    /** DELETE /api/doctor/clinical/cases/{id} */
    public function destroy($id)
    {
        $case = ClinicalCase::where('doctor_id', Auth::id())->findOrFail($id);
        $case->delete();
        return $this->success(null, 'تم مسح الحالة بنجاح.');
    }

    protected function serializeCase(
        ClinicalCase $case,
        bool $includeSummary = false,
        bool $includeAssignments = false
    ): array
    {
        $payload = [
            'id' => $case->id,
            'patient_name' => $case->patient_name,
            'age' => $case->age,
            'gender' => $case->gender,
            'training_center_id' => $case->training_center_id,
            'clinical_department_id' => $case->clinical_department_id,
            'body_system_id' => $case->body_system_id,
            'doctor_id' => $case->doctor_id,
            'diagnosis_or_description' => $case->diagnosis_or_description,
            'status' => $case->status,
            'status_label' => $this->statusLabel($case->status),
            'approval_status' => $case->approval_status,
            'approval_status_label' => $this->approvalStatusLabel($case->approval_status),
            'training_center' => $case->trainingCenter,
            'clinical_department' => $case->clinicalDepartment,
            'body_system' => $case->bodySystem,
            'doctor' => $case->doctor,
            'created_at' => optional($case->created_at)->toISOString(),
            'updated_at' => optional($case->updated_at)->toISOString(),
        ];

        if ($includeSummary || $includeAssignments) {
            $payload['assignment_summary'] = $this->assignmentSummary($case);
            $payload['similar_cases_summary'] = $this->similarCasesSummary($case);
        }

        if ($includeAssignments) {
            $payload['assignments_preview'] = $this->caseAssignments($case)
                ->latest()
                ->limit(100)
                ->get()
                ->map(fn (CaseAssignment $assignment) => $this->serializeAssignmentPreview($assignment))
                ->values();

            $payload['similar_cases'] = $this->similarCases($case)
                ->with([
                    'doctor:id,name,college_id',
                    'trainingCenter:id,name',
                    'clinicalDepartment:id,name',
                    'bodySystem:id,name',
                ])
                ->withCount('assignments')
                ->latest()
                ->limit(20)
                ->get()
                ->map(fn (ClinicalCase $similarCase) => [
                    'id' => $similarCase->id,
                    'patient_name' => $similarCase->patient_name,
                    'age' => $similarCase->age,
                    'gender' => $similarCase->gender,
                    'diagnosis_or_description' => $similarCase->diagnosis_or_description,
                    'status' => $similarCase->status,
                    'status_label' => $this->statusLabel($similarCase->status),
                    'doctor' => $similarCase->doctor ? [
                        'id' => $similarCase->doctor->id,
                        'name' => $similarCase->doctor->name,
                    ] : null,
                    'training_center' => $similarCase->trainingCenter,
                    'clinical_department' => $similarCase->clinicalDepartment,
                    'body_system' => $similarCase->bodySystem,
                    'assignments_count' => $similarCase->assignments_count,
                    'created_at' => optional($similarCase->created_at)->toISOString(),
                ])
                ->values();
        }

        return $payload;
    }

    protected function assignmentSummary(ClinicalCase $case): array
    {
        $assignments = $this->caseAssignments($case)->get();
        $activeStatuses = ['assigned', 'submitted_for_review'];
        $activeCount = $assignments->filter(function (CaseAssignment $assignment) use ($activeStatuses) {
            return in_array($assignment->status, $activeStatuses, true)
                || $assignment->is_overdue;
        })->count();

        $lastAssignment = $assignments->sortByDesc('created_at')->first();

        return [
            'students_count' => $assignments->pluck('student_id')->unique()->count(),
            'doctors_count' => $assignments->pluck('assigned_by')->unique()->count(),
            'assignments_count' => $assignments->count(),
            'active_assignments_count' => $activeCount,
            'has_active_assignments' => $activeCount > 0,
            'last_assignment_at' => optional($lastAssignment?->created_at)->toISOString(),
        ];
    }

    protected function similarCasesSummary(ClinicalCase $case): array
    {
        $cases = $this->similarCases($case)->withCount('assignments')->get();

        return [
            'cases_count' => $cases->count(),
            'assignments_count' => $cases->sum('assignments_count'),
            'doctors_count' => $cases->pluck('doctor_id')->unique()->count(),
            'has_similar_cases' => $cases->isNotEmpty(),
        ];
    }

    protected function caseAssignments(ClinicalCase $case)
    {
        $collegeId = Auth::user()?->college_id;

        return CaseAssignment::query()
            ->with([
                'student:id,name,student_number,major_id,level_id,college_id',
                'student.major:id,name',
                'student.level:id,name',
                'assigner:id,name,college_id',
            ])
            ->where('clinical_case_id', $case->id)
            ->whereHas('clinicalCase.doctor', fn ($query) => $query->where('college_id', $collegeId));
    }

    protected function similarCases(ClinicalCase $case)
    {
        $collegeId = Auth::user()?->college_id;
        $patientName = trim((string) $case->patient_name);

        return ClinicalCase::query()
            ->where('id', '!=', $case->id)
            ->where('training_center_id', $case->training_center_id)
            ->where('clinical_department_id', $case->clinical_department_id)
            ->whereHas('doctor', fn ($query) => $query->where('college_id', $collegeId))
            ->when($patientName !== '', fn ($query) => $query->whereRaw('LOWER(patient_name) = ?', [mb_strtolower($patientName)]))
            ->when($case->gender, fn ($query) => $query->where('gender', $case->gender))
            ->when($case->age !== null, fn ($query) => $query->where('age', $case->age));
    }

    protected function serializeAssignmentPreview(CaseAssignment $assignment): array
    {
        return [
            'id' => $assignment->id,
            'task_type' => $assignment->task_type,
            'task_type_label' => $assignment->task_type_label,
            'status' => $assignment->status,
            'status_label' => $assignment->status_label,
            'is_overdue' => $assignment->is_overdue,
            'due_at' => optional($assignment->due_at)->toISOString(),
            'due_at_label' => optional($assignment->due_at)->format('Y-m-d H:i'),
            'created_at' => optional($assignment->created_at)->toISOString(),
            'created_at_label' => optional($assignment->created_at)->format('Y-m-d H:i'),
            'student' => $assignment->student ? [
                'id' => $assignment->student->id,
                'name' => $assignment->student->name,
                'student_number' => $assignment->student->student_number,
                'major' => $assignment->student->major ? [
                    'id' => $assignment->student->major->id,
                    'name' => $assignment->student->major->name,
                ] : null,
                'level' => $assignment->student->level ? [
                    'id' => $assignment->student->level->id,
                    'name' => $assignment->student->level->name,
                ] : null,
            ] : null,
            'assigner' => $assignment->assigner ? [
                'id' => $assignment->assigner->id,
                'name' => $assignment->assigner->name,
            ] : null,
        ];
    }

    protected function statusLabel(?string $status): string
    {
        return match ($status) {
            'discharged' => 'تم الخروج',
            'transferred' => 'تم التحويل',
            default => 'حالة نشطة',
        };
    }

    protected function approvalStatusLabel(?string $status): string
    {
        return match ($status) {
            'pending' => 'بانتظار الاعتماد',
            'rejected' => 'مرفوضة',
            default => 'معتمدة',
        };
    }
}
