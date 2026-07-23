<?php

namespace App\Http\Controllers\Api\Doctor;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Enums\UserRole;
use App\Models\Academic\Assignment;
use App\Models\Academic\AssignmentDelegatePermission;
use App\Models\Academic\Subject;
use App\Models\AssignmentSubmission;
use App\Models\User;

class AssignmentController extends DoctorApiController
{
    /** GET /api/doctor/assignments */
    public function index(Request $request)
    {
        $subjectIds = Subject::where('doctor_id', Auth::id())->pluck('id');

        $subjects = Subject::where('doctor_id', Auth::id())
            ->with(['major:id,name', 'level:id,name'])
            ->orderBy('name')
            ->get(['id', 'name', 'major_id', 'level_id']);

        $query = Assignment::with(['subject:id,name'])
            ->withCount('submissions')
            ->whereIn('subject_id', $subjectIds);

        if ($request->filled('subject_id')) {
            $query->where('subject_id', $request->subject_id);
        }
        if ($request->status === 'upcoming') {
            $query->where('due_date', '>=', now());
        } elseif ($request->status === 'overdue') {
            $query->where('due_date', '<', now());
        }

        $all = $request->boolean('all');
        $assignments = $all
            ? $query->latest()->get()
            : $query->latest()->paginate(15);

        $stats = [
            'total' => Assignment::whereIn('subject_id', $subjectIds)->count(),
            'upcoming' => Assignment::whereIn('subject_id', $subjectIds)->where('due_date', '>=', now())->count(),
            'overdue' => Assignment::whereIn('subject_id', $subjectIds)->where('due_date', '<', now())->count(),
            'submissions' => AssignmentSubmission::whereHas('assignment', fn ($query) => $query->whereIn('subject_id', $subjectIds))->count(),
        ];

        return $this->success([
            'stats' => $stats,
            'filters' => [
                'subjects' => $subjects,
            ],
            'assignments' => $all ? $assignments->values() : $assignments->items(),
            'pagination' => [
                'current_page' => $all ? 1 : $assignments->currentPage(),
                'last_page' => $all ? 1 : $assignments->lastPage(),
                'per_page' => $all ? $assignments->count() : $assignments->perPage(),
                'total' => $all ? $assignments->count() : $assignments->total(),
            ],
        ]);
    }

    /** POST /api/doctor/assignments */
    public function store(Request $request)
    {
        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'due_date' => 'required|date|after_or_equal:today',
            'requires_submission' => 'nullable|boolean',
        ]);

        $subject = Subject::where('id', $request->subject_id)->where('doctor_id', Auth::id())->firstOrFail();

        $assignment = Assignment::create([
            'subject_id' => $request->subject_id,
            'title' => $request->title,
            'description' => $request->description,
            'due_date' => $request->due_date,
            'requires_submission' => $request->boolean('requires_submission'),
            'created_by' => Auth::id(),
        ]);

        return $this->success($assignment, 'تم إضافة التكليف بنجاح.', 201);
    }

    /** GET /api/doctor/assignments/{id} */
    public function show(Assignment $assignment)
    {
        if ($assignment->subject->doctor_id !== Auth::id()) {
            return $this->error('غير مصرح لك.', 403);
        }

        $assignment->load(['subject:id,name,major_id,level_id', 'subject.major:id,name', 'subject.level:id,name'])
            ->loadCount('submissions');

        return $this->success([
            'assignment' => $assignment,
        ]);
    }

    /** GET /api/doctor/assignments/delegate-permissions */
    public function delegatePermissions(Request $request)
    {
        $doctor = $request->user();

        $subjectsQuery = Subject::where('doctor_id', $doctor->id)
            ->with(['major:id,name', 'level:id,name'])
            ->orderBy('name');

        if ($request->filled('subject_id')) {
            $subjectsQuery->where('id', $request->integer('subject_id'));
        }

        $subjects = $subjectsQuery->get(['id', 'name', 'code', 'major_id', 'level_id', 'doctor_id']);
        $delegates = $this->eligibleDelegatesForSubjects($doctor, $subjects);

        $permissions = AssignmentDelegatePermission::where('doctor_id', $doctor->id)
            ->whereIn('subject_id', $subjects->pluck('id'))
            ->whereIn('delegate_id', $delegates->pluck('id'))
            ->get()
            ->keyBy(fn (AssignmentDelegatePermission $permission) => "{$permission->subject_id}:{$permission->delegate_id}");

        return $this->success([
            'subjects' => $subjects->map(function (Subject $subject) use ($delegates, $permissions) {
                $subjectDelegates = $delegates
                    ->where('major_id', $subject->major_id)
                    ->where('level_id', $subject->level_id)
                    ->values()
                    ->map(function (User $delegate) use ($subject, $permissions) {
                        $permission = $permissions->get("{$subject->id}:{$delegate->id}");

                        return [
                            'delegate' => [
                                'id' => $delegate->id,
                                'name' => $delegate->name,
                                'student_number' => $delegate->student_number,
                                'major' => $delegate->major,
                                'level' => $delegate->level,
                            ],
                            'permissions' => $permission
                                ? $permission->toFlags()
                                : AssignmentDelegatePermission::emptyFlags(),
                        ];
                    });

                return [
                    'subject' => $subject,
                    'delegates' => $subjectDelegates,
                ];
            })->values(),
        ]);
    }

    /** PUT /api/doctor/assignments/delegate-permissions */
    public function updateDelegatePermissions(Request $request)
    {
        $doctor = $request->user();

        $validated = $request->validate([
            'subject_id' => 'required|integer|exists:subjects,id',
            'delegate_id' => 'required|integer|exists:users,id',
            'can_create' => 'nullable|boolean',
            'can_edit_own' => 'nullable|boolean',
            'can_delete_own' => 'nullable|boolean',
            'can_edit_doctor_assignments' => 'nullable|boolean',
            'can_delete_doctor_assignments' => 'nullable|boolean',
        ]);

        $subject = Subject::where('doctor_id', $doctor->id)
            ->findOrFail($validated['subject_id']);

        $delegate = User::where('college_id', $doctor->college_id)
            ->where('role', UserRole::DELEGATE)
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->findOrFail($validated['delegate_id']);

        $flags = [
            'can_create' => $request->boolean('can_create'),
            'can_edit_own' => $request->boolean('can_edit_own'),
            'can_delete_own' => $request->boolean('can_delete_own'),
            'can_edit_doctor_assignments' => $request->boolean('can_edit_doctor_assignments'),
            'can_delete_doctor_assignments' => $request->boolean('can_delete_doctor_assignments'),
        ];

        if (! in_array(true, $flags, true)) {
            AssignmentDelegatePermission::where('doctor_id', $doctor->id)
                ->where('delegate_id', $delegate->id)
                ->where('subject_id', $subject->id)
                ->delete();

            return $this->success([
                'subject_id' => $subject->id,
                'delegate_id' => $delegate->id,
                'permissions' => AssignmentDelegatePermission::emptyFlags(),
            ], 'تم سحب صلاحيات التكليف من المندوب.');
        }

        $permission = AssignmentDelegatePermission::updateOrCreate(
            [
                'doctor_id' => $doctor->id,
                'delegate_id' => $delegate->id,
                'subject_id' => $subject->id,
            ],
            $flags
        );

        return $this->success([
            'subject_id' => $subject->id,
            'delegate_id' => $delegate->id,
            'permissions' => $permission->toFlags(),
        ], 'تم تحديث صلاحيات التكليف بنجاح.');
    }

    /** PUT /api/doctor/assignments/{id} */
    public function update(Request $request, Assignment $assignment)
    {
        if ($assignment->subject->doctor_id !== Auth::id()) {
            return $this->error('غير مصرح لك.', 403);
        }

        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'due_date' => 'required|date',
            'requires_submission' => 'nullable|boolean',
        ]);

        $assignment->update([
            'title' => $request->title,
            'description' => $request->description,
            'due_date' => $request->due_date,
            'requires_submission' => $request->boolean('requires_submission'),
        ]);

        return $this->success($assignment, 'تم تحديث التكليف بنجاح.');
    }

    /** DELETE /api/doctor/assignments/{id} */
    public function destroy(Assignment $assignment)
    {
        if ($assignment->subject->doctor_id !== Auth::id()) {
            return $this->error('غير مصرح لك.', 403);
        }

        $assignment->delete();
        return $this->success(null, 'تم حذف التكليف بنجاح.');
    }

    /** GET /api/doctor/assignments/{id}/submissions */
    public function submissions(Assignment $assignment)
    {
        if ($assignment->subject->doctor_id !== Auth::id()) {
            return $this->error('غير مصرح لك.', 403);
        }

        $submissions = $assignment->submissions()
            ->with(['student:id,name,student_number,email', 'assignment:id,due_date'])
            ->latest()
            ->get()
            ->map(fn (AssignmentSubmission $submission) => $this->submissionPayload($submission));

        return $this->success($submissions);
    }

    public function exportSubmissions(Assignment $assignment)
    {
        if ($assignment->subject->doctor_id !== Auth::id()) {
            return $this->error('غير مصرح لك.', 403);
        }

        $submissions = $assignment->submissions()->with('student:id,name,student_number')->latest()->get();
        $rows = [
            ['اسم الطالب', 'رقم القيد', 'حالة التسليم', 'الدرجة', 'الملاحظات', 'تاريخ التسليم'],
        ];

        foreach ($submissions as $submission) {
            $rows[] = [
                $submission->student?->name ?? '-',
                $submission->student?->student_number ?? '-',
                $submission->status ?? '-',
                $submission->grade ?? '-',
                $submission->feedback ?? '-',
                $submission->submitted_at?->format('Y-m-d H:i') ?? '-',
            ];
        }

        $csvContent = chr(0xEF) . chr(0xBB) . chr(0xBF);
        foreach ($rows as $row) {
            $csvContent .= implode(',', array_map(fn ($value) => '"' . str_replace('"', '""', (string) $value) . '"', $row)) . "\n";
        }

        return response($csvContent)
            ->header('Content-Type', 'text/csv; charset=UTF-8')
            ->header('Content-Disposition', 'attachment; filename="assignment_submissions_' . $assignment->id . '_' . now()->format('Y-m-d_His') . '.csv"');
    }

    /** POST /api/doctor/submissions/{id}/review */
    public function reviewSubmission(Request $request, AssignmentSubmission $submission)
    {
        if ($submission->assignment->subject->doctor_id !== Auth::id()) {
            return $this->error('غير مصرح لك.', 403);
        }

        $request->validate([
            'status' => 'required|in:accepted,rejected',
            'feedback' => 'nullable|string|max:1000',
            'grade' => 'nullable|integer|min:0|max:100',
        ]);

        $submission->update([
            'status' => $request->status,
            'feedback' => $request->feedback,
            'grade' => $request->grade,
        ]);

        return $this->success($submission, 'تم تقييم التسليم بنجاح.');
    }

    protected function submissionPayload(AssignmentSubmission $submission): array
    {
        $filePath = $submission->file_path ? ltrim($submission->file_path, '/') : null;

        return [
            'id' => $submission->id,
            'assignment_id' => $submission->assignment_id,
            'student_id' => $submission->student_id,
            'student' => $submission->student,
            'file_path' => $submission->file_path,
            'file_url' => $filePath ? asset('storage/' . $filePath) : null,
            'file_name' => $submission->file_name ?: ($filePath ? basename($filePath) : null),
            'file_type' => $submission->file_type,
            'file_size' => $submission->file_size,
            'formatted_file_size' => $submission->formatted_file_size,
            'notes' => $submission->notes,
            'status' => $submission->status,
            'feedback' => $submission->feedback,
            'grade' => $submission->grade,
            'submitted_at' => $submission->submitted_at?->toIso8601String(),
            'is_late' => $submission->submitted_at && $submission->assignment
                ? $submission->isLate()
                : false,
        ];
    }

    private function eligibleDelegatesForSubjects(User $doctor, $subjects)
    {
        $query = User::where('college_id', $doctor->college_id)
            ->where('role', UserRole::DELEGATE)
            ->with(['major:id,name', 'level:id,name']);

        $query->where(function ($scope) use ($subjects) {
            foreach ($subjects as $subject) {
                $scope->orWhere(function ($q) use ($subject) {
                    $q->where('major_id', $subject->major_id)
                        ->where('level_id', $subject->level_id);
                });
            }
        });

        return $subjects->isEmpty()
            ? collect()
            : $query->orderBy('name')->get(['id', 'name', 'student_number', 'major_id', 'level_id']);
    }
}
