<?php

namespace App\Http\Controllers\Api\Doctor;

use App\Models\Academic\Subject;
use App\Models\Grade;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class GradeApprovalController extends DoctorApiController
{
    public function index(int $subjectId)
    {
        $subject = Subject::where('doctor_id', Auth::id())->findOrFail($subjectId);

        $pendingGrades = Grade::where('subject_id', $subjectId)
            ->where('status', 'pending')
            ->with([
                'student:id,name,student_number',
                'gradeCategory:id,name,max_score',
                'creator:id,name',
            ])
            ->orderByDesc('created_at')
            ->get();

        return $this->success([
            'subject' => $subject->only(['id', 'name']),
            'pending_grades' => $pendingGrades,
        ]);
    }

    public function bulkAction(Request $request)
    {
        $validated = $request->validate([
            'grade_ids' => 'required|array|min:1',
            'grade_ids.*' => 'exists:grades,id',
            'action' => 'required|in:approve,reject',
        ]);

        $grades = Grade::whereIn('id', $validated['grade_ids'])
            ->where('status', 'pending')
            ->whereHas('subject', function ($query) {
                $query->where('doctor_id', Auth::id());
            });

        $count = $grades->count();
        $grades->update([
            'status' => $validated['action'] === 'approve' ? 'approved' : 'rejected',
        ]);

        return $this->success([
            'updated_count' => $count,
        ], $validated['action'] === 'approve' ? 'تم اعتماد الدرجات المحددة بنجاح.' : 'تم رفض الدرجات المحددة.');
    }
}
