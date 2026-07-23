<?php

namespace App\Http\Controllers\Api\Student;

use App\Models\Academic\Assignment;
use App\Models\Academic\Subject;
use App\Models\AssignmentSubmission;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class AssignmentController extends StudentApiController
{
    /**
     * Get Student Assignments (Active and Past)
     */
    public function index(Request $request)
    {
        $student = $request->user();

        $sortBy = $request->get('sort_by', $student->assignment_sort_by ?: 'due_date');

        if ($request->has('sort_by') && $request->sort_by !== $student->assignment_sort_by) {
            $student->update(['assignment_sort_by' => $request->sort_by]);
        }

        $subjectIds = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->pluck('id');

        $query = Assignment::whereIn('subject_id', $subjectIds)
            ->with(['subject:id,name', 'submissions' => function ($q) use ($student) {
                $q->where('student_id', $student->id);
            }]);

        if ($sortBy === 'priority') {
            $query->leftJoin('student_assignment_priorities', function ($join) use ($student) {
                $join->on('assignments.id', '=', 'student_assignment_priorities.assignment_id')
                    ->where('student_assignment_priorities.user_id', '=', $student->id);
            })
                ->select('assignments.*')
                ->orderByRaw('CASE WHEN student_assignment_priorities.priority IS NULL THEN 0 ELSE student_assignment_priorities.priority END DESC')
                ->orderBy('assignments.due_date', 'asc');
        } else {
            $query->orderBy('due_date', 'asc');
        }

        $allAssignments = $query->get();

        $userPriorities = \App\Models\Academic\AssignmentPriority::where('user_id', $student->id)
            ->pluck('priority', 'assignment_id');

        $assignments = $allAssignments->map(function ($assignment) use ($userPriorities) {
            $submission = $assignment->submissions->first();
            $isLate = now()->greaterThan($assignment->due_date);

            $status = 'available';
            if ($submission) {
                $status = 'submitted';
            } elseif ($isLate) {
                $status = 'missing';
            }

            return [
                'id' => $assignment->id,
                'title' => $assignment->title,
                'description' => $assignment->description,
                'subject_name' => $assignment->subject->name ?? '',
                'due_date' => $assignment->due_date,
                'marks' => $assignment->marks,
                'file_path' => $assignment->file_path ? asset('storage/' . $assignment->file_path) : null,
                'requires_submission' => (bool) $assignment->requires_submission,
                'requires_file' => (bool) $assignment->requires_submission,
                'status' => $status,
                'my_priority' => $userPriorities[$assignment->id] ?? 0,
                'submission' => $submission ? $this->serializeSubmission($submission) : null,
            ];
        });

        $activeAssignments = $assignments->filter(function ($assignment) {
            return \Carbon\Carbon::parse($assignment['due_date'])->isFuture() || $assignment['status'] === 'submitted';
        })->values();

        $pastAssignments = $assignments->filter(function ($assignment) {
            return \Carbon\Carbon::parse($assignment['due_date'])->isPast() && $assignment['status'] === 'missing';
        })->values();

        return $this->success([
            'sort_by' => $sortBy,
            'active' => $activeAssignments,
            'past' => $pastAssignments,
        ]);
    }

    /**
     * Update assignment personal priority.
     */
    public function updatePriority(Request $request, $id)
    {
        $request->validate([
            'priority' => 'required|integer|min:0|max:2',
        ]);

        \App\Models\Academic\AssignmentPriority::updateOrCreate(
            ['user_id' => $request->user()->id, 'assignment_id' => $id],
            ['priority' => $request->priority]
        );

        return $this->success([], 'تم تحديث الأولوية بنجاح.');
    }

    /**
     * Update student sorting preference.
     */
    public function updatePreference(Request $request)
    {
        $request->validate([
            'sort_by' => 'required|in:due_date,priority',
        ]);

        $request->user()->update(['assignment_sort_by' => $request->sort_by]);

        return $this->success([], 'تم حفظ تفضيلات الفرز.');
    }

    /**
     * Show assignment details.
     */
    public function show(Request $request, $id)
    {
        return $this->getDetails($request, $id);
    }

    /**
     * Get assignment details.
     */
    public function getDetails(Request $request, $id)
    {
        $student = $request->user();

        $subjectIds = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->pluck('id');

        $assignment = Assignment::whereIn('subject_id', $subjectIds)
            ->with(['subject:id,name'])
            ->findOrFail($id);

        $submission = AssignmentSubmission::where('assignment_id', $id)
            ->where('student_id', $student->id)
            ->first();

        $isOverdue = $assignment->isOverdue();
        $status = 'available';

        if ($submission) {
            $status = 'submitted';
        } elseif ($isOverdue) {
            $status = 'missing';
        }

        return $this->success([
            'assignment' => [
                'id' => $assignment->id,
                'title' => $assignment->title,
                'description' => $assignment->description,
                'due_date' => $assignment->due_date,
                'marks' => $assignment->marks,
                'file_path' => $assignment->file_path ? asset('storage/' . $assignment->file_path) : null,
                'requires_submission' => (bool) $assignment->requires_submission,
                'requires_file' => (bool) $assignment->requires_submission,
                'subject' => $assignment->subject,
                'status' => $status,
                'can_submit' => ! $isOverdue,
            ],
            'submission' => $submission ? $this->serializeSubmission($submission) : null,
            'is_overdue' => $isOverdue,
            'formatted_due_date' => \Carbon\Carbon::parse($assignment->due_date)->format('Y-m-d'),
            'formatted_submitted_at' => $submission ? \Carbon\Carbon::parse($submission->submitted_at)->format('Y-m-d H:i') : null,
            'is_late' => $submission ? $submission->isLate() : false,
        ]);
    }

    /**
     * Submit an assignment.
     */
    public function submit(Request $request, $id)
    {
        $student = $request->user();

        $subjectIds = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->pluck('id');

        $assignment = Assignment::whereIn('subject_id', $subjectIds)->findOrFail($id);

        if ($assignment->isOverdue()) {
            return $this->error('انتهت مهلة تسليم هذا التكليف ولم يعد بالإمكان الإرسال.', 422);
        }

        $rules = [
            'notes' => 'nullable|string|max:500',
        ];

        if ($assignment->requires_submission) {
            $rules['file'] = 'required|file|mimes:pdf,zip,rar,doc,docx,jpeg,png,jpg|max:10240';
        } else {
            $rules['file'] = 'nullable|file|mimes:pdf,zip,rar,doc,docx,jpeg,png,jpg|max:10240';
        }

        $request->validate($rules);

        $existingSubmission = AssignmentSubmission::where('assignment_id', $id)
            ->where('student_id', $student->id)
            ->first();

        $filePath = $existingSubmission ? $existingSubmission->file_path : null;
        $originalFileName = $existingSubmission ? $existingSubmission->file_name : null;
        $fileType = $existingSubmission ? $existingSubmission->file_type : null;
        $fileSize = $existingSubmission ? $existingSubmission->file_size : null;

        if ($request->hasFile('file')) {
            if ($existingSubmission && $existingSubmission->file_path && Storage::disk('public')->exists($existingSubmission->file_path)) {
                Storage::disk('public')->delete($existingSubmission->file_path);
            }

            $file = $request->file('file');
            $fileName = $student->student_number . '_' . $student->name . '_' . time() . '.' . $file->getClientOriginalExtension();
            $filePath = $file->storeAs('submissions/' . $assignment->id, $fileName, 'public');
            $originalFileName = $file->getClientOriginalName();
            $fileType = $file->getClientMimeType();
            $fileSize = $file->getSize();
        }

        $submission = AssignmentSubmission::updateOrCreate(
            ['assignment_id' => $id, 'student_id' => $student->id],
            [
                'file_path' => $filePath,
                'file_name' => $originalFileName,
                'file_type' => $fileType,
                'file_size' => $fileSize,
                'notes' => $request->notes,
                'status' => 'pending',
                'submitted_at' => now(),
            ]
        );

        return $this->success(
            $this->serializeSubmission($submission),
            'تم تسليم التكليف بنجاح.',
            201
        );
    }

    private function serializeSubmission(AssignmentSubmission $submission): array
    {
        $submission->loadMissing('assignment');

        return [
            'file_name' => $submission->file_name,
            'file_path' => $submission->file_path,
            'file_url' => $submission->file_path ? asset('storage/' . $submission->file_path) : null,
            'file_type' => $submission->file_type,
            'file_size' => $submission->file_size,
            'formatted_file_size' => $submission->formatted_file_size,
            'notes' => $submission->notes,
            'submitted_at' => $submission->submitted_at,
            'status' => $submission->status,
            'grade' => $submission->grade,
            'feedback' => $submission->feedback,
            'is_late' => $submission->isLate(),
        ];
    }
}
