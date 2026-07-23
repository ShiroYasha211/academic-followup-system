<?php

namespace App\Services;

use App\Models\User;
use App\Models\Attendance;
use App\Models\Academic\Subject;
use App\Models\Academic\Major;
use App\Models\Academic\University;
use App\Enums\UserRole;
use App\Support\ExcuseWorkflow;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class DashboardService
{
    /**
     * Get all essential dashboard statistics in an optimized way.
     */
    public function getAllStats(?User $viewer = null): array
    {
        return [
            'user_stats' => $this->getUserStats($viewer),
            'academic_stats' => $this->getAcademicStats(),
            'attendance_stats' => $this->getAttendanceStats(),
            'at_risk_students' => $this->getAtRiskStudentsCount(),
            'today_stats' => $this->getTodayStats(),
            'weekly_trend' => $this->getWeeklyTrend(),
            'top_absent_subjects' => $this->getTopAbsentSubjects(),
            'students_per_major' => $this->getStudentsPerMajor(),
            'latest_activity' => $this->getLatestActivity($viewer),
        ];
    }

    /**
     * Efficiently get user counts using a single SQL query.
     */
    public function getUserStats(?User $viewer = null): array
    {
        $stats = User::query()
            ->visibleToAdmin($viewer)
            ->selectRaw("
            COUNT(CASE WHEN role IN (?, ?) THEN 1 END) as students_count,
            COUNT(CASE WHEN role = ? THEN 1 END) as doctors_count,
            COUNT(CASE WHEN role = ? THEN 1 END) as delegates_count,
            COUNT(CASE WHEN status = 'inactive' THEN 1 END) as pending_users
        ", [
            UserRole::STUDENT->value,
            UserRole::DELEGATE->value,
            UserRole::DOCTOR->value,
            UserRole::DELEGATE->value
        ])->first();

        return [
            'students_count' => (int) $stats->students_count,
            'doctors_count' => (int) $stats->doctors_count,
            'delegates_count' => (int) $stats->delegates_count,
            'pending_users' => (int) $stats->pending_users,
        ];
    }

    /**
     * Get academic structural counts.
     */
    public function getAcademicStats(): array
    {
        return [
            'universities_count' => University::count(),
            'majors_count' => Major::count(),
            'subjects_count' => Subject::count(),
        ];
    }

    /**
     * Get attendance distribution and rate.
     */
    public function getAttendanceStats(): array
    {
        $counts = Attendance::select('status', DB::raw('count(*) as count'))
            ->groupBy('status')
            ->pluck('count', 'status');

        $distribution = ExcuseWorkflow::statusDistribution($counts);
        $total = $distribution['total'];

        return [
            'total' => $total,
            'present' => $distribution['present'],
            'absent' => $distribution['absent'],
            'late' => $distribution['late'],
            'excused' => $distribution['excused_total'],
            'permitted' => $distribution['permitted'],
            'exempted' => $distribution['exempted'],
            'attendance_rate' => $total > 0 
                ? round((($distribution['present'] + $distribution['late'] + $distribution['excused_total']) / $total) * 100, 1) 
                : 0,
        ];
    }

    /**
     * Get the number of students at risk of deprivation.
     * Optimized: Performs calculation at the database level.
     */
    public function getAtRiskStudentsCount(): int
    {
        // We find students whose absence count in a specific subject 
        // exceeds or equals the max_absences allowed for that subject.
        return DB::table('attendances')
            ->join('subjects', 'attendances.subject_id', '=', 'subjects.id')
            ->where('attendances.status', 'absent')
            ->select('attendances.student_id', 'attendances.subject_id')
            ->groupBy('attendances.student_id', 'attendances.subject_id', 'subjects.max_absences')
            ->havingRaw('COUNT(*) >= COALESCE(subjects.max_absences, 4)')
            ->count();
    }

    /**
     * Get today's fast statistics.
     */
    public function getTodayStats(): array
    {
        $today = Carbon::today();
        $stats = Attendance::whereDate('date', $today)
            ->selectRaw("
                COUNT(*) as total,
                COUNT(CASE WHEN status = 'absent' THEN 1 END) as absent
            ")->first();

        return [
            'today_attendance' => (int) $stats->total,
            'today_absent' => (int) $stats->absent,
        ];
    }

    /**
     * Get 7-day attendance trends.
     */
    public function getWeeklyTrend()
    {
        return Attendance::select(
            DB::raw('DATE(date) as day'),
            DB::raw('SUM(CASE WHEN status = "present" THEN 1 ELSE 0 END) as present'),
            DB::raw('SUM(CASE WHEN status = "absent" THEN 1 ELSE 0 END) as absent'),
            DB::raw('COUNT(*) as total')
        )
            ->where('date', '>=', now()->subDays(6)->startOfDay())
            ->groupBy(DB::raw('DATE(date)'))
            ->orderBy('day')
            ->get();
    }

    /**
     * Get subjects with most absences.
     */
    public function getTopAbsentSubjects(int $limit = 5)
    {
        return Subject::select('id', 'name')
            ->withCount(['attendances as absent_count' => function($query) {
                $query->where('status', 'absent');
            }])
            ->orderByDesc('absent_count')
            ->take($limit)
            ->get();
    }

    /**
     * Get distribution of students per major.
     */
    public function getStudentsPerMajor(int $limit = 5)
    {
        return Major::select('id', 'name')
            ->withCount(['students as students_count' => function($query) {
                $query->where('role', UserRole::STUDENT);
            }])
            ->orderByDesc('students_count')
            ->take($limit)
            ->get();
    }

    /**
     * Get latest activities for the dashboard.
     */
    public function getLatestActivity(?User $viewer = null): array
    {
        return [
            'latest_attendance' => Attendance::with(['student', 'subject'])
                ->latest('date')
                ->take(5)
                ->get(),
            'latest_users' => User::query()
                ->visibleToAdmin($viewer)
                ->latest()
                ->take(5)
                ->get(),
        ];
    }
}
