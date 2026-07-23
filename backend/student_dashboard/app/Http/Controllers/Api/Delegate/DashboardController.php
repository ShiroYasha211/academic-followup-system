<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\Delegate\DelegateApiController;
use App\Models\Academic\Subject;
use App\Models\Academic\Assignment;
use App\Models\ExamSchedule;
use App\Models\User;
use App\Enums\UserRole;

class DashboardController extends DelegateApiController
{
    /**
     * Get dashboard overview statistics for the delegate.
     */
    public function index(Request $request)
    {
        $delegate = $request->user();

        $subjects = Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->with(['doctor:id,name', 'term:id,name'])
            ->orderBy('name')
            ->get();

        // 1. Total Subjects in the delegate's batch
        $totalSubjects = $subjects->count();

        // 2. Total Students in the delegate's batch
        $totalStudents = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->count();

        // 3. Active Assignments (Deadline >= today)
        $activeAssignments = Assignment::whereHas('subject', function ($q) use ($delegate) {
                $q->where('major_id', $delegate->major_id)
                    ->where('level_id', $delegate->level_id);
            })
            ->where('due_date', '>=', now()->toDateString())
            ->count();

        // 4. Upcoming Exams
        $upcomingExams = \App\Models\ExamSchedule::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->whereHas('items', function ($query) {
                $query->where('exam_date', '>=', now()->toDateString());
            })
            ->count();

        // 5. Today's Lectures
        $todayDayOfWeek = \Carbon\Carbon::now()->dayOfWeekIso;
        $todayLecturesCount = \App\Models\Academic\Schedule::where('day_of_week', $todayDayOfWeek)
            ->whereHas('subject', function ($q) use ($delegate) {
                $q->where('major_id', $delegate->major_id)
                    ->where('level_id', $delegate->level_id);
            })
            ->count();

        // 6. Alerts (Today's Absences)
        $alertsCount = \App\Models\Attendance::where('date', date('Y-m-d'))
            ->where('status', 'absent')
            ->whereHas('student', function ($q) use ($delegate) {
                $q->where('major_id', $delegate->major_id)
                    ->where('level_id', $delegate->level_id);
            })
            ->count();

        // 7. Weekly Attendance Rate
        $weekStart = \Carbon\Carbon::now()->subDays(7);
        $weeklyAttendance = \App\Models\Attendance::where('date', '>=', $weekStart->format('Y-m-d'))
            ->whereHas('student', function ($q) use ($delegate) {
                $q->where('major_id', $delegate->major_id)
                    ->where('level_id', $delegate->level_id);
            });
        $totalWeeklyRecords = (clone $weeklyAttendance)->count();
        $presentWeeklyRecords = (clone $weeklyAttendance)->where('status', 'present')->count();
        $weeklyAttendanceRate = $totalWeeklyRecords > 0 ? round(($presentWeeklyRecords / $totalWeeklyRecords) * 100, 1) : 0;

        // 8. Top Absent Students
        $topAbsentStudents = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->withCount(['attendances as absence_count' => function ($q) {
                $q->where('status', 'absent');
            }])
            ->having('absence_count', '>', 0)
            ->orderByDesc('absence_count')
            ->take(5)
            ->get(['id', 'name', 'student_number']);

        // 9. Recent Attendance
        $latestAttendance = \App\Models\Attendance::whereHas('student', function ($q) use ($delegate) {
            $q->where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id);
        })
            ->with(['student:id,name,student_number', 'subject:id,name'])
            ->latest()
            ->take(5)
            ->get();

        // 11. At-Risk Students (Students with high absence percentage in any subject)
        // Threshold: 20% absence rate = at risk of probation
        $atRiskStudents = collect();
        $allStudents = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->get()->keyBy('id');

        $subjectsIds = $subjects->pluck('id');

        // Get total sessions count per student per subject
        $totalSessionsQuery = \App\Models\Attendance::whereIn('student_id', $allStudents->pluck('id'))
            ->whereIn('subject_id', $subjectsIds)
            ->select('student_id', 'subject_id', \Illuminate\Support\Facades\DB::raw('count(*) as total'))
            ->groupBy('student_id', 'subject_id')
            ->get();

        // Get absences count per student per subject
        $absencesQuery = \App\Models\Attendance::whereIn('student_id', $allStudents->pluck('id'))
            ->whereIn('subject_id', $subjectsIds)
            ->where('status', 'absent')
            ->select('student_id', 'subject_id', \Illuminate\Support\Facades\DB::raw('count(*) as absences'))
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
                            'student' => [
                                'id' => $student->id,
                                'name' => $student->name,
                                'student_number' => $student->student_number,
                            ],
                            'subject' => [
                                'id' => $subject->id,
                                'name' => $subject->name
                            ],
                            'absence_rate' => round($absenceRate, 1),
                            'absences' => $absences,
                            'total' => $totalSessions
                        ]);
                    }
                }
            }
        }

        return $this->success([
            'stats' => [
                'total_subjects' => $totalSubjects,
                'total_students' => $totalStudents,
                'active_assignments' => $activeAssignments,
                'upcoming_exams' => $upcomingExams,
                'today_lectures' => $todayLecturesCount,
                'absence_alerts' => $alertsCount,
                'weekly_attendance_rate' => $weeklyAttendanceRate,
            ],
            'subjects' => $subjects,
            'top_absent_students' => $topAbsentStudents,
            'at_risk_students' => $atRiskStudents->sortByDesc('absence_rate')->values()->take(5),
            'latest_attendance' => $latestAttendance,
            'latest_students' => User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
                ->where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)
                ->latest()
                ->take(5)
                ->get(['id', 'name', 'student_number', 'created_at']),
        ], 'تم جلب بيانات لوحة القيادة بنجاح');
    }
}
