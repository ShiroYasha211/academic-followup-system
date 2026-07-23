<?php

namespace App\Http\Controllers\Api\Doctor;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Models\Academic\Schedule;
use App\Models\Academic\Subject;
use App\Models\User;
use App\Models\Attendance;
use App\Models\Excuse;
use App\Models\Inquiry;
use App\Models\Grade;
use App\Models\StudentNotification;
use App\Models\DoctorMessage;
use App\Enums\UserRole;
use App\Support\ExcuseWorkflow;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class DashboardController extends DoctorApiController
{
    /** GET /api/doctor/dashboard */
    public function index()
    {
        $doctor = Auth::user();
        $subjects = Subject::where('doctor_id', $doctor->id)->with(['major', 'level'])->get();
        $subjectIds = $subjects->pluck('id');

        // Students count
        $studentsCount = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where(function ($query) use ($subjects) {
                foreach ($subjects as $subject) {
                    $query->orWhere(function ($q) use ($subject) {
                        $q->where('major_id', $subject->major_id)->where('level_id', $subject->level_id);
                    });
                }
            })->count();

        // Pending excuses
        $pendingExcuses = ExcuseWorkflow::scopeDoctorQueue(Excuse::query(), $doctor->id)
            ->where('status', 'pending')
            ->count();

        // Pending inquiries
        $pendingInquiries = Inquiry::whereIn('subject_id', $subjectIds)->where('status', 'forwarded')->count();

        // Unread messages
        $unreadMessages = \App\Models\DoctorMessage::whereHas('conversation', fn($q) => $q->where('doctor_id', $doctor->id))
            ->where('sender_id', '!=', $doctor->id)->whereNull('read_at')->count();

        // Grades count
        $gradesCount = Grade::whereIn('subject_id', $subjectIds)->distinct('student_id')->count('student_id');

        // Attendance chart (7 days)
        $startDate = Carbon::now()->subDays(6)->startOfDay();
        $dailyStats = Attendance::whereIn('subject_id', $subjectIds)
            ->whereBetween('date', [$startDate, Carbon::now()->endOfDay()])
            ->selectRaw('DATE(date) as day, status, COUNT(*) as count')
            ->groupBy('day', 'status')->get()->groupBy('day');

        $chart = ['labels' => [], 'present' => [], 'absent' => []];
        for ($i = 6; $i >= 0; $i--) {
            $date = Carbon::now()->subDays($i);
            $dateKey = $date->format('Y-m-d');
            $chart['labels'][] = $date->format('m/d');
            $dayData = $dailyStats->get($dateKey, collect());
            $chart['present'][] = $dayData->where('status', 'present')->sum('count');
            $chart['absent'][] = $dayData->where('status', 'absent')->sum('count');
        }

        $studentsCountPerSubject = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->whereIn('major_id', $subjects->pluck('major_id')->unique())
            ->whereIn('level_id', $subjects->pluck('level_id')->unique())
            ->select('major_id', 'level_id', DB::raw('count(*) as count'))
            ->groupBy('major_id', 'level_id')
            ->get()
            ->keyBy(fn ($item) => $item->major_id . '_' . $item->level_id);

        $attendanceStats = Attendance::whereIn('subject_id', $subjectIds)
            ->select(
                'subject_id',
                DB::raw('count(*) as total'),
                DB::raw("SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present_count")
            )
            ->groupBy('subject_id')
            ->get()
            ->keyBy('subject_id');

        $subjectsData = $subjects->map(function ($subject) use ($studentsCountPerSubject, $attendanceStats) {
            $key = $subject->major_id . '_' . $subject->level_id;
            $stats = $attendanceStats->get($subject->id);
            $totalAttendances = $stats ? (int) $stats->total : 0;
            $presentAttendances = $stats ? (int) $stats->present_count : 0;

            return [
                'id' => $subject->id,
                'name' => $subject->name,
                'major' => $subject->major?->name,
                'level' => $subject->level?->name,
                'students_count' => $studentsCountPerSubject->get($key)?->count ?? 0,
                'attendance_rate' => $totalAttendances > 0
                    ? round(($presentAttendances / $totalAttendances) * 100)
                    : 0,
            ];
        });

        $recentExcuses = ExcuseWorkflow::scopeDoctorQueue(Excuse::query(), $doctor->id)
            ->with(['student', 'attendance.subject'])
            ->latest()
            ->take(5)
            ->get()
            ->map(fn ($excuse) => [
                'type' => 'excuse',
                'title' => 'عذر جديد من ' . ($excuse->student->name ?? 'طالب'),
                'subtitle' => $excuse->attendance->subject->name ?? '',
                'status' => $excuse->status,
                'date' => $excuse->created_at,
            ]);

        $recentInquiries = Inquiry::whereIn('subject_id', $subjectIds)
            ->with(['student', 'subject'])
            ->latest()
            ->take(5)
            ->get()
            ->map(fn ($inquiry) => [
                'type' => 'inquiry',
                'title' => 'استفسار من ' . ($inquiry->student->name ?? 'طالب'),
                'subtitle' => $inquiry->subject->name ?? '',
                'status' => $inquiry->status,
                'date' => $inquiry->created_at,
            ]);

        $recentActivities = $recentExcuses
            ->concat($recentInquiries)
            ->sortByDesc('date')
            ->take(5)
            ->values();

        $adminAnnouncements = StudentNotification::with('sender:id,name,role')
            ->where('user_id', $doctor->id)
            ->whereNotNull('batch_id')
            ->whereIn('type', ['announcement', 'exam', 'assignment', 'attendance', 'poll'])
            ->latest()
            ->get()
            ->groupBy('batch_id')
            ->map(fn (Collection $group) => $group->first())
            ->take(5)
            ->values();

        $todayDayOfWeek = Carbon::now()->dayOfWeekIso;
        $todaySchedule = Schedule::where('day_of_week', $todayDayOfWeek)
            ->whereHas('subject', fn ($query) => $query->where('doctor_id', $doctor->id))
            ->with(['subject:id,name,code,major_id,level_id', 'subject.major:id,name', 'subject.level:id,name'])
            ->orderBy('start_time')
            ->get()
            ->map(fn ($schedule) => [
                'id' => $schedule->id,
                'subject_id' => $schedule->subject_id,
                'subject_name' => $schedule->subject?->name,
                'subject_code' => $schedule->subject?->code,
                'major' => $schedule->subject?->major?->name,
                'level' => $schedule->subject?->level?->name,
                'start_time' => $schedule->start_time,
                'end_time' => $schedule->end_time,
                'start_time_label' => $this->formatScheduleTime($schedule->start_time),
                'end_time_label' => $this->formatScheduleTime($schedule->end_time),
                'hall_name' => $schedule->hall_name,
            ]);

        return $this->success([
            'subjects_count' => $subjects->count(),
            'students_count' => $studentsCount,
            'pending_excuses' => $pendingExcuses,
            'pending_inquiries' => $pendingInquiries,
            'unread_messages' => $unreadMessages,
            'grades_entered' => $gradesCount,
            'attendance_chart' => $chart,
            'subjects' => $subjectsData,
            'today_schedule' => $todaySchedule,
            'recent_activities' => $recentActivities,
            'admin_announcements' => $adminAnnouncements,
        ]);
    }

    public function badges()
    {
        $doctor = Auth::user();
        $subjectIds = Subject::where('doctor_id', $doctor->id)->pluck('id');

        return $this->success([
            'notifications_unread' => StudentNotification::where('user_id', $doctor->id)
                ->unread()
                ->count(),
            'messages_unread' => DoctorMessage::whereHas(
                    'conversation',
                    fn ($query) => $query->where('doctor_id', $doctor->id)
                )
                ->where('sender_id', '!=', $doctor->id)
                ->whereNull('read_at')
                ->count(),
            'inquiries_pending' => Inquiry::whereIn('subject_id', $subjectIds)
                ->where('status', 'forwarded')
                ->count(),
        ]);
    }

    private function formatScheduleTime($value): ?string
    {
        if (!$value) {
            return null;
        }

        try {
            return Carbon::parse($value)->format('H:i');
        } catch (\Throwable) {
            return (string) $value;
        }
    }
}
