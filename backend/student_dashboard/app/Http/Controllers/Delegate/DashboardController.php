<?php

namespace App\Http\Controllers\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use App\Models\Academic\Subject;
use App\Enums\UserRole;
use App\Models\StudentNotification;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index()
    {
        $delegate = Auth::user();

        // Scope: Same Major and Level
        $studentsCount = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->count();

        // Subjects with Doctor info
        $subjects = Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->with('doctor')
            ->get();


        // Latest Students
        $latestStudents = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->latest()
            ->take(5)
            ->get();

        // Latest Attendance
        $latestAttendance = \App\Models\Attendance::whereHas('student', function ($q) use ($delegate) {
            $q->where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id);
        })
            ->with(['student' => fn($q) => $q->select('id', 'name', 'student_number'), 'subject' => fn($q) => $q->select('id', 'name')])
            ->latest()
            ->take(5)
            ->get();

        // Today's Lectures Count
        $todayDayOfWeek = \Carbon\Carbon::now()->dayOfWeekIso; // 1 (Mon) - 7 (Sun)
        $todayLecturesCount = \App\Models\Academic\Schedule::where('day_of_week', $todayDayOfWeek)
            ->whereHas('subject', function ($q) use ($delegate) {
                $q->where('major_id', $delegate->major_id)
                    ->where('level_id', $delegate->level_id);
            })
            ->count();

        // Today's Subjects with Schedule (for Quick Attendance Modal)
        $todaySubjects = \App\Models\Academic\Schedule::where('day_of_week', $todayDayOfWeek)
            ->whereHas('subject', function ($q) use ($delegate) {
                $q->where('major_id', $delegate->major_id)
                    ->where('level_id', $delegate->level_id);
            })
            ->with(['subject' => fn($q) => $q->select('id', 'name')])
            ->orderBy('start_time')
            ->get();

        // Alerts Count (e.g. Absences today)
        $alertsCount = \App\Models\Attendance::where('date', date('Y-m-d'))
            ->where('status', 'absent')
            ->whereHas('student', function ($q) use ($delegate) {
                $q->where('major_id', $delegate->major_id)
                    ->where('level_id', $delegate->level_id);
            })
            ->count();

        // === NEW: Enhanced Statistics ===

        // Weekly Attendance Stats (Last 7 days)
        $weekStart = \Carbon\Carbon::now()->subDays(7);
        $weeklyAttendance = \App\Models\Attendance::where('date', '>=', $weekStart->format('Y-m-d'))
            ->whereHas('student', function ($q) use ($delegate) {
                $q->where('major_id', $delegate->major_id)
                    ->where('level_id', $delegate->level_id);
            });

        $totalWeeklyRecords = (clone $weeklyAttendance)->count();
        $presentWeeklyRecords = (clone $weeklyAttendance)->where('status', 'present')->count();
        $weeklyAttendanceRate = $totalWeeklyRecords > 0
            ? round(($presentWeeklyRecords / $totalWeeklyRecords) * 100, 1)
            : 0;

        // Top 5 Absent Students (Most absences overall)
        $topAbsentStudents = \App\Models\User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->withCount(['attendances as absence_count' => function ($q) {
                $q->where('status', 'absent');
            }])
            ->having('absence_count', '>', 0)
            ->orderByDesc('absence_count')
            ->take(5)
            ->get();

        // At-Risk Students (Students with high absence percentage in any subject)
        // Threshold: 20% absence rate = at risk of probation
        $atRiskStudents = collect();
        $allStudents = \App\Models\User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->get()->keyBy('id');

        // جلب الإحصائيات مجمعة
        // 1. عدد الجلسات الكلي لكل طالب في كل مادة
        $totalSessionsQuery = \App\Models\Attendance::whereIn('student_id', $allStudents->pluck('id'))
            ->whereIn('subject_id', $subjects->pluck('id'))
            ->select('student_id', 'subject_id', DB::raw('count(*) as total'))
            ->groupBy('student_id', 'subject_id')
            ->get();

        // 2. عدد الغيابات لكل طالب في كل مادة
        $absencesQuery = \App\Models\Attendance::whereIn('student_id', $allStudents->pluck('id'))
            ->whereIn('subject_id', $subjects->pluck('id'))
            ->where('status', 'absent')
            ->select('student_id', 'subject_id', DB::raw('count(*) as absences'))
            ->groupBy('student_id', 'subject_id')
            ->get()
            ->keyBy(function ($item) {
                return $item->student_id . '_' . $item->subject_id;
            });

        foreach ($totalSessionsQuery as $sessionStat) {
            $studentId = $sessionStat->student_id;
            $subjectId = $sessionStat->subject_id;
            $totalSessions = $sessionStat->total;

            if ($totalSessions >= 3) {
                $absenceKey = $studentId . '_' . $subjectId;
                $absences = $absencesQuery->has($absenceKey) ? $absencesQuery->get($absenceKey)->absences : 0;
                $absenceRate = ($absences / $totalSessions) * 100;

                if ($absenceRate >= 20) {
                    $student = $allStudents->get($studentId);
                    $subject = $subjects->firstWhere('id', $subjectId);

                    if ($student && $subject) {
                        $atRiskStudents->push([
                            'student' => $student,
                            'subject' => $subject,
                            'absence_rate' => round($absenceRate, 1),
                            'absences' => $absences,
                            'total' => $totalSessions
                        ]);
                    }
                }
            }
        }

        // Sort by highest absence rate and limit
        $atRiskStudents = $atRiskStudents->sortByDesc('absence_rate')->take(5);

        // Administrative Announcements
        $adminAnnouncements = StudentNotification::where('user_id', $delegate->id)
            ->latest()
            ->take(5)
            ->get();

        return view('delegate.dashboard', compact(
            'delegate',
            'studentsCount',
            'subjects',
            'latestStudents',
            'latestAttendance',
            'todayLecturesCount',
            'alertsCount',
            'weeklyAttendanceRate',
            'topAbsentStudents',
            'todaySubjects',
            'atRiskStudents',
            'adminAnnouncements'
        ));
    }
}
