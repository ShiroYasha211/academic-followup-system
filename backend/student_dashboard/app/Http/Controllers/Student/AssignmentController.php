<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use App\Models\Academic\Assignment;
use App\Models\Academic\Subject;
use App\Models\AssignmentSubmission;

class AssignmentController extends Controller
{
    public function index(Request $request)
    {
        $student = Auth::user();

        // 1. Fetch Sort Preference (Default to due_date)
        $sortBy = $request->get('sort_by', $student->assignment_sort_by ?: 'due_date');
        
        // 2. Update preference if changed via URL
        if ($request->has('sort_by') && $request->sort_by !== $student->assignment_sort_by) {
            $student->update(['assignment_sort_by' => $request->sort_by]);
        }

        // 3. Fetch subjects for the student
        $subjectIds = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->pluck('id');

        // 4. Build Query for Assignments
        $query = Assignment::whereIn('subject_id', $subjectIds)
            ->with(['subject', 'submissions' => function ($q) use ($student) {
                $q->where('student_id', $student->id);
            }]);

        // 5. Apply Sorting based on Preference
        if ($sortBy === 'priority') {
            // Join with priorities and order by priority level
            $query->leftJoin('student_assignment_priorities', function ($join) use ($student) {
                $join->on('assignments.id', '=', 'student_assignment_priorities.assignment_id')
                     ->where('student_assignment_priorities.user_id', '=', $student->id);
            })
            ->select('assignments.*')
            ->orderByRaw('CASE WHEN student_assignment_priorities.priority IS NULL THEN 0 ELSE student_assignment_priorities.priority END DESC')
            ->orderBy('assignments.due_date', 'asc');
        } else {
            // Default: Due Date ASC (closest first)
            $query->orderBy('due_date', 'asc');
        }

        $allAssignments = $query->get();

        // 6. Map submissions and priorities
        $userPriorities = \App\Models\Academic\AssignmentPriority::where('user_id', $student->id)
            ->pluck('priority', 'assignment_id');

        foreach ($allAssignments as $assignment) {
            $assignment->my_submission = $assignment->submissions->first();
            $assignment->my_priority = $userPriorities[$assignment->id] ?? 0;
        }

        $activeAssignments = $allAssignments->filter(function ($assignment) {
            return \Carbon\Carbon::parse($assignment->due_date)->isFuture() || \Carbon\Carbon::parse($assignment->due_date)->isToday();
        });

        $pastAssignments = $allAssignments->filter(function ($assignment) {
            return \Carbon\Carbon::parse($assignment->due_date)->isPast() && !\Carbon\Carbon::parse($assignment->due_date)->isToday();
        });

        return view('student.assignments.index', compact('activeAssignments', 'pastAssignments', 'sortBy'));
    }

    /**
     * Update assignment personal priority (AJAX).
     */
    public function updatePriority(Request $request, $id)
    {
        $request->validate([
            'priority' => 'required|integer|min:0|max:2',
        ]);

        \App\Models\Academic\AssignmentPriority::updateOrCreate(
            ['user_id' => Auth::id(), 'assignment_id' => $id],
            ['priority' => $request->priority]
        );

        return response()->json(['success' => true]);
    }

    /**
     * Update student sorting preference (AJAX).
     */
    public function updatePreference(Request $request)
    {
        $request->validate([
            'sort_by' => 'required|in:due_date,priority',
        ]);

        Auth::user()->update(['assignment_sort_by' => $request->sort_by]);

        return response()->json(['success' => true]);
    }

    /**
     * Show assignment details and submission form.
     */
    public function show($id)
    {
        $student = Auth::user();

        // Get subject IDs for this student
        $subjectIds = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->pluck('id');

        $assignment = Assignment::whereIn('subject_id', $subjectIds)
            ->with('subject')
            ->findOrFail($id);

        $submission = AssignmentSubmission::where('assignment_id', $id)
            ->where('student_id', $student->id)
            ->first();

        return view('student.assignments.show', compact('assignment', 'submission'));
    }

    /**
     * Get assignment details (AJAX).
     */
    public function getDetails($id)
    {
        $student = Auth::user();

        // Verify student has access to this assignment
        $subjectIds = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->pluck('id');

        $assignment = Assignment::whereIn('subject_id', $subjectIds)
            ->with(['subject'])
            ->findOrFail($id);

        $submission = AssignmentSubmission::where('assignment_id', $id)
            ->where('student_id', $student->id)
            ->first();

        return response()->json([
            'assignment' => $assignment,
            'submission' => $submission,
            'is_overdue' => $assignment->isOverdue(),
            'formatted_due_date' => $assignment->due_date->format('Y-m-d'),
            'formatted_submitted_at' => $submission ? $submission->submitted_at->format('Y-m-d H:i') : null,
            'formatted_file_size' => $submission ? $submission->formatted_file_size : null,
            'is_late' => $submission ? $submission->isLate() : false,
        ]);
    }

    /**
     * Submit assignment.
     */
    public function submit(Request $request, $id)
    {
        $student = Auth::user();

        // Verify student has access to this assignment
        $subjectIds = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->pluck('id');

        $assignment = Assignment::whereIn('subject_id', $subjectIds)->findOrFail($id);

        $rules = [
            'notes' => 'nullable|string|max:500',
        ];

        if ($assignment->requires_submission) {
            $rules['file'] = 'required|file|mimes:pdf,zip,rar|max:10240';
        } else {
            $rules['file'] = 'nullable|file|mimes:pdf,zip,rar|max:10240';
        }

        $request->validate($rules);

        // Check if already submitted
        $existingSubmission = AssignmentSubmission::where('assignment_id', $id)
            ->where('student_id', $student->id)
            ->first();

        // Handle File Upload
        $filePath = $existingSubmission ? $existingSubmission->file_path : null;
        $originalFileName = $existingSubmission ? $existingSubmission->file_name : null;
        $fileType = $existingSubmission ? $existingSubmission->file_type : null;
        $fileSize = $existingSubmission ? $existingSubmission->file_size : null;

        if ($request->hasFile('file')) {
            // Delete old file if exists
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

        // Create or Update submission record
        AssignmentSubmission::updateOrCreate(
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

        return redirect()->route('student.assignments.show', $id)
            ->with('success', 'تم تسليم التكليف بنجاح!');
    }
}
