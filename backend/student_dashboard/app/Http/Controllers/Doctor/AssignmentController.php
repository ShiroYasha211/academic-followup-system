<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Controller;
use App\Models\Academic\Assignment;
use App\Models\Academic\Subject;
use App\Models\AssignmentSubmission;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AssignmentController extends Controller
{
    public function index(Request $request)
    {
        // Get subjects assigned to the doctor with major and level
        $doctorSubjects = Subject::where('doctor_id', Auth::id())
            ->with(['major', 'level'])
            ->get();
        $subjectIds = $doctorSubjects->pluck('id');

        // Base query
        $query = Assignment::with(['subject.major', 'subject.level', 'submissions'])
            ->whereIn('subject_id', $subjectIds);

        // Filter by subject
        $subjectFilter = $request->get('subject');
        if ($subjectFilter && $subjectFilter !== 'all') {
            $query->where('subject_id', $subjectFilter);
        }

        // Filter by status
        $statusFilter = $request->get('status', 'all');
        if ($statusFilter === 'upcoming') {
            $query->where('due_date', '>=', now());
        } elseif ($statusFilter === 'overdue') {
            $query->where('due_date', '<', now());
        }

        $assignments = $query->latest()->paginate(12)->withQueryString();

        // Stats
        $stats = [
            'total' => Assignment::whereIn('subject_id', $subjectIds)->count(),
            'upcoming' => Assignment::whereIn('subject_id', $subjectIds)->where('due_date', '>=', now())->count(),
            'overdue' => Assignment::whereIn('subject_id', $subjectIds)->where('due_date', '<', now())->count(),
            'submissions' => AssignmentSubmission::whereHas('assignment', fn($q) => $q->whereIn('subject_id', $subjectIds))->count(),
        ];

        return view('doctor.assignments.index', compact('assignments', 'doctorSubjects', 'stats', 'subjectFilter', 'statusFilter'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'due_date' => 'required|date|after_or_equal:today',
        ]);

        // Ensure the doctor owns this subject
        $subject = Subject::where('id', $request->subject_id)
            ->where('doctor_id', Auth::id())
            ->firstOrFail();

        Assignment::create([
            'subject_id' => $request->subject_id,
            'title' => $request->title,
            'description' => $request->description,
            'due_date' => $request->due_date,
            'requires_submission' => $request->has('requires_submission') && $request->requires_submission == '1',
            'created_by' => Auth::id(),
        ]);

        return redirect()->back()->with('success', 'تم إضافة التكليف بنجاح.');
    }

    public function update(Request $request, Assignment $assignment)
    {
        // Ensure the doctor owns the subject of this assignment
        if ($assignment->subject->doctor_id !== Auth::id()) {
            abort(403);
        }

        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'due_date' => 'required|date',
        ]);

        $assignment->update([
            'title' => $request->title,
            'description' => $request->description,
            'due_date' => $request->due_date,
            'requires_submission' => $request->has('requires_submission') && $request->requires_submission == '1',
        ]);

        return redirect()->back()->with('success', 'تم تحديث التكليف بنجاح.');
    }

    public function destroy(Assignment $assignment)
    {
        // Ensure the doctor owns the subject of this assignment
        if ($assignment->subject->doctor_id !== Auth::id()) {
            abort(403);
        }

        $assignment->delete();

        return redirect()->back()->with('success', 'تم حذف التكليف بنجاح.');
    }

    /**
     * Show submissions for an assignment.
     */
    public function submissions(Assignment $assignment)
    {
        // Ensure the doctor owns the subject
        if ($assignment->subject->doctor_id !== Auth::id()) {
            abort(403);
        }

        $submissions = $assignment->submissions()->with('student')->latest()->get();

        return view('doctor.assignments.submissions', compact('assignment', 'submissions'));
    }

    public function exportSubmissions(Assignment $assignment)
    {
        if ($assignment->subject->doctor_id !== Auth::id()) {
            abort(403);
        }

        $submissions = $assignment->submissions()->with('student')->latest()->get();
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

    /**
     * Review a submission.
     */
    public function reviewSubmission(Request $request, AssignmentSubmission $submission)
    {
        // Ensure the doctor owns the subject
        if ($submission->assignment->subject->doctor_id !== Auth::id()) {
            abort(403);
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

        return back()->with('success', 'تم تقييم التسليم بنجاح.');
    }
}
