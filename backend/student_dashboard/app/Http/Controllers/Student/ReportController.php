<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Grade;
use App\Models\ExamScheduleItem;
use App\Models\Academic\Subject;
use App\Support\ExcuseWorkflow;
use Illuminate\Support\Facades\Auth;
use Barryvdh\DomPDF\Facade\Pdf;

class ReportController extends Controller
{
    /**
     * Export attendance report as PDF.
     */
    public function attendancePdf()
    {
        $user = Auth::user();

        $subjects = Subject::where('major_id', $user->major_id)
            ->where('level_id', $user->level_id)
            ->with(['attendances' => function ($q) use ($user) {
                $q->where('student_id', $user->id);
            }])
            ->get();

        $stats = [
            'total_lectures' => 0,
            'present' => 0,
            'absent' => 0,
            'late' => 0,
            'excused' => 0,
        ];

        foreach ($subjects as $subject) {
            $stats['total_lectures'] += $subject->attendances->count();
            $stats['present'] += $subject->attendances->where('status', 'present')->count();
            $stats['absent'] += $subject->attendances->where('status', 'absent')->count();
            $stats['late'] += $subject->attendances->where('status', 'late')->count();
            $stats['excused'] += $subject->attendances->whereIn('status', ExcuseWorkflow::countedAsExcusedStatuses())->count();
        }

        $data = [
            'user' => $user,
            'subjects' => $subjects,
            'stats' => $stats,
            'generated_at' => now(),
        ];

        $pdf = Pdf::loadView('student.reports.attendance-pdf', $data);
        $pdf->setPaper('A4', 'portrait');

        return $pdf->download('تقرير_الحضور_' . $user->name . '.pdf');
    }

    /**
     * Export grades report as PDF.
     */
    public function gradesPdf()
    {
        $user = Auth::user();

        $grades = Grade::where('student_id', $user->id)
            ->with('subject')
            ->get();

        $totalPercentage = 0;
        $count = 0;

        foreach ($grades as $grade) {
            $total = ($grade->continuous_score ?? 0) + ($grade->final_score ?? 0);
            $percentage = min(100, $total);
            $totalPercentage += $percentage;
            $count++;
        }

        $average = $count > 0 ? round($totalPercentage / $count, 1) : 0;

        $data = [
            'user' => $user,
            'grades' => $grades,
            'average' => $average,
            'generated_at' => now(),
        ];

        $pdf = Pdf::loadView('student.reports.grades-pdf', $data);
        $pdf->setPaper('A4', 'portrait');

        return $pdf->download('كشف_الدرجات_' . $user->name . '.pdf');
    }

    /**
     * Export exam schedule as PDF.
     */
    public function examsPdf()
    {
        $user = Auth::user();

        $exams = ExamScheduleItem::whereHas('subject', function ($q) use ($user) {
            $q->where('major_id', $user->major_id)
                ->where('level_id', $user->level_id);
        })
            ->with('subject')
            ->orderBy('exam_date')
            ->get();

        $data = [
            'user' => $user,
            'exams' => $exams,
            'generated_at' => now(),
        ];

        $pdf = Pdf::loadView('student.reports.exams-pdf', $data);
        $pdf->setPaper('A4', 'landscape');

        return $pdf->download('جدول_الاختبارات_' . $user->name . '.pdf');
    }
}
