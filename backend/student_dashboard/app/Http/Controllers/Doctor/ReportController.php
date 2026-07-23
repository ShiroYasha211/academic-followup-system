<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Controller;
use App\Models\Academic\Subject;
use App\Models\Attendance;
use App\Models\QrAttendanceSession;
use App\Models\User;
use App\Support\ExcuseWorkflow;
use Illuminate\Support\Facades\Auth;

class ReportController extends Controller
{
    public function index()
    {
        $subjects = Subject::where('doctor_id', Auth::id())
            ->with(['major', 'level', 'term'])
            ->get();

        // Students count per subject (by major/level)
        $studentsCountPerSubject = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->whereIn('major_id', $subjects->pluck('major_id')->unique())
            ->whereIn('level_id', $subjects->pluck('level_id')->unique())
            ->select('major_id', 'level_id', \Illuminate\Support\Facades\DB::raw('count(*) as count'))
            ->groupBy('major_id', 'level_id')
            ->get()
            ->keyBy(function ($item) {
                return $item->major_id . '_' . $item->level_id;
            });

        // Attendance stats per subject
        $attendanceStats = Attendance::whereIn('subject_id', $subjects->pluck('id'))
            ->select(
                'subject_id',
                \Illuminate\Support\Facades\DB::raw('count(*) as total'),
                \Illuminate\Support\Facades\DB::raw("SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present_count"),
                \Illuminate\Support\Facades\DB::raw("SUM(CASE WHEN status = 'absent' THEN 1 ELSE 0 END) as absent_count"),
                \Illuminate\Support\Facades\DB::raw("SUM(CASE WHEN status IN ('excused','permitted','exempted') THEN 1 ELSE 0 END) as excused_count"),
                \Illuminate\Support\Facades\DB::raw("SUM(CASE WHEN status = 'permitted' THEN 1 ELSE 0 END) as permitted_count"),
                \Illuminate\Support\Facades\DB::raw("SUM(CASE WHEN status = 'exempted' THEN 1 ELSE 0 END) as exempted_count"),
                \Illuminate\Support\Facades\DB::raw('COUNT(DISTINCT date) as lectures_count')
            )
            ->groupBy('subject_id')
            ->get()
            ->keyBy('subject_id');

        // Add statistics to each subject
        $subjects->each(function ($subject) use ($studentsCountPerSubject, $attendanceStats) {
            // Students count
            $key = $subject->major_id . '_' . $subject->level_id;
            $subject->students_count = $studentsCountPerSubject->has($key) ? $studentsCountPerSubject->get($key)->count : 0;

            // Attendance stats
            $stats = $attendanceStats->get($subject->id);

            $subject->total_attendances = $stats ? $stats->total : 0;
            $subject->present_count = $stats ? $stats->present_count : 0;
            $subject->absent_count = $stats ? $stats->absent_count : 0;
            $subject->excused_count = $stats ? $stats->excused_count : 0;
            $subject->permitted_count = $stats ? $stats->permitted_count : 0;
            $subject->exempted_count = $stats ? $stats->exempted_count : 0;
            $subject->lectures_count = $stats ? $stats->lectures_count : 0;

            $subject->attendance_rate = $subject->total_attendances > 0
                ? round(($subject->present_count / $subject->total_attendances) * 100)
                : 0;
        });

        return view('doctor.reports.index', compact('subjects'));
    }
}
