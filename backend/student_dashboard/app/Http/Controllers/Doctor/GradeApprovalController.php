<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Controller;
use App\Models\Grade;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class GradeApprovalController extends Controller
{
    /**
     * Display pending grades for approval.
     */
    public function index($subjectId)
    {
        $subject = Subject::where('doctor_id', Auth::id())->findOrFail($subjectId);

        $pendingGrades = Grade::where('subject_id', $subjectId)
            ->where('status', 'pending')
            ->with(['student', 'gradeCategory', 'creator'])
            ->orderBy('created_at', 'desc')
            ->get();

        return view('doctor.grades.approvals.index', compact('subject', 'pendingGrades'));
    }

    /**
     * Bulk approve or reject grades.
     */
    public function bulkAction(Request $request)
    {
        $request->validate([
            'grade_ids' => 'required|array',
            'grade_ids.*' => 'exists:grades,id',
            'action' => 'required|in:approve,reject',
        ]);

        $grades = Grade::whereIn('id', $request->grade_ids)
            ->whereHas('subject', function($q) {
                $q->where('doctor_id', Auth::id());
            })
            ->where('status', 'pending');

        if ($request->action === 'approve') {
            $grades->update(['status' => 'approved']);
            $message = 'تم اعتماد الدرجات المحددة بنجاح.';
        } else {
            $grades->update(['status' => 'rejected']);
            $message = 'تم رفض الدرجات المحددة.';
        }

        return back()->with('success', $message);
    }
}
