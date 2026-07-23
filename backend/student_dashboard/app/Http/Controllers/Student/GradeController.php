<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Academic\Subject;
use App\Models\Grade;

class GradeController extends Controller
{
    public function index()
    {
        $student = Auth::user();

        // Get student's subjects
        $subjects = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->get();

        // Get all grades for this student
        $grades = Grade::where('student_id', $student->id)
            ->whereIn('subject_id', $subjects->pluck('id'))
            ->with('subject')
            ->get()
            ->groupBy('subject_id');

        // Calculate overall stats
        $totalGrades = 0;
        $totalPercentage = 0;

        foreach ($grades as $subjectId => $subjectGrades) {
            $continuousSum = $subjectGrades->where('type', 'continuous')->where('status', 'approved')->sum('score');
            $final = $subjectGrades->where('type', 'final')->first();

            if ($continuousSum > 0 || $final) {
                $fWeight = $final ? ($final->score / ($final->max_score ?: 60)) * 60 : 0;
                $totalPercentage += ($continuousSum + $fWeight);
                $totalGrades++;
            }
        }

        $overallAverage = $totalGrades > 0 ? round($totalPercentage / $totalGrades, 1) : 0;

        return view('student.grades.index', compact('student', 'subjects', 'grades', 'overallAverage', 'totalGrades'));
    }
}
