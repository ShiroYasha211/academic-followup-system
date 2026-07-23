<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;
use App\Models\Academic\Subject;
use App\Models\User;
use App\Models\Attendance;
use App\Models\Excuse;
use App\Models\Inquiry;
use App\Models\DoctorConversation;
use App\Models\Grade;
use App\Models\QrAttendanceSession;
use App\Models\StudentNotification;
use App\Enums\UserRole;
use App\Support\ExcuseWorkflow;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class DashboardController extends Controller
{
    public function index()
    {
        $doctor = Auth::user();

        // Fetch subjects assigned to this doctor
        $subjects = Subject::where('doctor_id', $doctor->id)
            ->with(['major', 'level', 'term', 'major.college.university'])
            ->get();

        $subjectIds = $subjects->pluck('id');

        // جلب الإحصائيات المجمعة للطلاب
        $studentsCountPerSubject = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->whereIn('major_id', $subjects->pluck('major_id')->unique())
            ->whereIn('level_id', $subjects->pluck('level_id')->unique())
            ->select('major_id', 'level_id', \Illuminate\Support\Facades\DB::raw('count(*) as count'))
            ->groupBy('major_id', 'level_id')
            ->get()
            ->keyBy(function ($item) {
                return $item->major_id . '_' . $item->level_id;
            });

        // جلب إحصائيات الحضور المجمعة
        $attendanceStats = Attendance::whereIn('subject_id', $subjectIds)
            ->select(
                'subject_id',
                \Illuminate\Support\Facades\DB::raw('count(*) as total'),
                \Illuminate\Support\Facades\DB::raw("SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present_count")
            )
            ->groupBy('subject_id')
            ->get()
            ->keyBy('subject_id');

        // Append student count and attendance stats to each subject
        $subjects->each(function ($subject) use ($studentsCountPerSubject, $attendanceStats) {
            $key = $subject->major_id . '_' . $subject->level_id;
            $subject->students_count = $studentsCountPerSubject->has($key) ? $studentsCountPerSubject->get($key)->count : 0;

            // Calculate attendance rate
            $stats = $attendanceStats->get($subject->id);
            $totalAttendances = $stats ? $stats->total : 0;
            $presentAttendances = $stats ? $stats->present_count : 0;

            $subject->attendance_rate = $totalAttendances > 0
                ? round(($presentAttendances / $totalAttendances) * 100)
                : 0;
        });

        // Calculate total students across all doctor's subjects
        $uniqueStudentIdsQuery = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where(function ($query) use ($subjects) {
                foreach ($subjects as $subject) {
                    $query->orWhere(function ($q) use ($subject) {
                        $q->where('major_id', $subject->major_id)
                            ->where('level_id', $subject->level_id);
                    });
                }
            })->pluck('id');

        $studentsCount = $uniqueStudentIdsQuery->count();

        // Calculate pending excuses
        $pendingExcusesCount = ExcuseWorkflow::scopeDoctorQueue(Excuse::query(), $doctor->id)
            ->where('status', 'pending')
            ->count();

        // Pending inquiries count
        $pendingInquiriesCount = Inquiry::whereIn('subject_id', $subjectIds)
            ->where('status', 'forwarded')
            ->count();

        // Unread messages count (optimized: avoid loading all conversations)
        $unreadMessagesCount = \App\Models\DoctorMessage::whereHas('conversation', function ($q) use ($doctor) {
            $q->where('doctor_id', $doctor->id);
        })->where('sender_id', '!=', $doctor->id)->whereNull('read_at')->count();

        // Recent activities (last 5)
        $recentExcuses = ExcuseWorkflow::scopeDoctorQueue(Excuse::query(), $doctor->id)
            ->with(['student', 'attendance.subject'])
            ->latest()
            ->take(5)
            ->get()
            ->map(function ($excuse) {
                return [
                    'type' => 'excuse',
                    'title' => 'عذر جديد من ' . ($excuse->student->name ?? 'طالب'),
                    'subtitle' => $excuse->attendance->subject->name ?? '',
                    'status' => $excuse->status,
                    'date' => $excuse->created_at,
                ];
            });

        $recentInquiries = Inquiry::whereIn('subject_id', $subjectIds)
            ->with(['student', 'subject'])
            ->latest()
            ->take(5)
            ->get()
            ->map(function ($inquiry) {
                return [
                    'type' => 'inquiry',
                    'title' => 'استفسار من ' . ($inquiry->student->name ?? 'طالب'),
                    'subtitle' => $inquiry->subject->name ?? '',
                    'status' => $inquiry->status,
                    'date' => $inquiry->created_at,
                ];
            });

        // Merge and sort activities
        $recentActivities = $recentExcuses->concat($recentInquiries)
            ->sortByDesc('date')
            ->take(5)
            ->values();

        // Attendance chart data (last 7 days) — single optimized query
        $startDate = Carbon::now()->subDays(6)->startOfDay();
        $endDate = Carbon::now()->endOfDay();

        $dailyStats = Attendance::whereIn('subject_id', $subjectIds)
            ->whereBetween('date', [$startDate, $endDate])
            ->selectRaw('DATE(date) as day, status, COUNT(*) as count')
            ->groupBy('day', 'status')
            ->get()
            ->groupBy('day');

        $attendanceChartData = ['present' => [], 'absent' => []];
        $attendanceLabels = [];
        for ($i = 6; $i >= 0; $i--) {
            $date = Carbon::now()->subDays($i);
            $dateKey = $date->format('Y-m-d');
            $attendanceLabels[] = $date->format('m/d');

            $dayData = $dailyStats->get($dateKey, collect());
            $attendanceChartData['present'][] = $dayData->where('status', 'present')->sum('count');
            $attendanceChartData['absent'][] = $dayData->where('status', 'absent')->sum('count');
        }

        // Grades stats — students with grades entered
        $gradesCount = Grade::whereIn('subject_id', $subjectIds)
            ->distinct('student_id')
            ->count('student_id');

        // Administrative Announcements
        $adminAnnouncements = StudentNotification::with('sender:id,name,role')
            ->where('user_id', $doctor->id)
            ->whereNotNull('batch_id')
            ->whereIn('type', ['announcement', 'exam', 'assignment', 'attendance', 'poll'])
            ->latest()
            ->get()
            ->groupBy('batch_id')
            ->map(function (Collection $group) {
                return $group->first();
            })
            ->take(5)
            ->values();

        return view('doctor.dashboard', compact(
            'doctor',
            'subjects',
            'studentsCount',
            'pendingExcusesCount',
            'pendingInquiriesCount',
            'unreadMessagesCount',
            'recentActivities',
            'attendanceChartData',
            'attendanceLabels',
            'gradesCount',
            'adminAnnouncements'
        ));
    }

    public function showSubjectReport(Subject $subject)
    {
        // Ensure the subject belongs to the authenticated doctor
        if ($subject->doctor_id !== Auth::id()) {
            abort(403, 'غير مصرح لك بالوصول لهذا المقرر.');
        }

        // Fetch students for this subject (same logic: match major/level)
        $students = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->with(['attendances' => function ($query) use ($subject) {
                $query->where('subject_id', $subject->id);
            }])
            ->get();

        return view('doctor.reports.subject_report', compact('subject', 'students'));
    }
}
