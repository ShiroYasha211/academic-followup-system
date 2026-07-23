<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\Delegate\DelegateApiController;
use App\Models\Attendance;
use App\Models\StudentNotification;
use App\Models\Academic\Subject;
use App\Models\User;
use App\Enums\UserRole;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class NotificationController extends DelegateApiController
{
    /**
     * Display a listing of absence statistics and sent notifications.
     */
    public function index(Request $request)
    {
        $delegate = $request->user();
        $filter = $request->get('filter', 'all');

        // 1. Get Base Absence Statistics
        $absenceStatsQuery = DB::table('attendances as a')
            ->join('users as u', 'a.student_id', '=', 'u.id')
            ->join('subjects as s', 'a.subject_id', '=', 's.id')
            ->where('s.major_id', $delegate->major_id)
            ->where('s.level_id', $delegate->level_id)
            ->where('a.status', 'absent')
            ->select(
                'u.id as student_id',
                'u.name as student_name',
                'u.university_id as student_university_id',
                's.id as subject_id',
                's.name as subject_name',
                DB::raw('COUNT(a.id) as absence_count')
            )
            ->groupBy('u.id', 'u.name', 'u.university_id', 's.id', 's.name')
            ->orderByDesc('absence_count');

        $allStats = $absenceStatsQuery->get();

        // 2. Classify and Filter
        $report = [];
        foreach ($allStats as $stat) {
            $report[] = [
                'student_id' => $stat->student_id,
                'student_name' => $stat->student_name,
                'student_university_id' => $stat->student_university_id,
                'subject_id' => $stat->subject_id,
                'subject_name' => $stat->subject_name,
                'absence_count' => $stat->absence_count,
                'status' => $stat->absence_count >= 5 ? 'danger' : ($stat->absence_count >= 3 ? 'warning' : 'normal')
            ];
        }

        $stats = [
            'total' => count($report),
            'danger' => count(array_filter($report, fn($r) => $r['absence_count'] >= 5)),
            'warning' => count(array_filter($report, fn($r) => $r['absence_count'] >= 3 && $r['absence_count'] < 5)),
            'normal' => count(array_filter($report, fn($r) => $r['absence_count'] < 3)),
        ];

        if ($filter !== 'all') {
            $report = array_values(array_filter($report, fn($r) => $r['status'] === $filter));
        }

        // 3. Get history of sent warnings
        $sentWarnings = StudentNotification::where('sender_id', $delegate->id)
            ->where('type', 'absence_warning')
            ->with(['student:id,name,university_id'])
            ->orderBy('created_at', 'desc')
            ->get();

        // 4. Get personal notifications for the delegate
        $notifications = StudentNotification::where('user_id', $delegate->id)
            ->orderByDesc('created_at')
            ->paginate(20);

        return $this->success([
            'stats' => $stats,
            'absence_stats' => $report,
            'sent_warnings' => $sentWarnings,
            'notifications' => $notifications,
        ], 'تم جلب الإحصائيات والتنبيهات بنجاح');
    }

    /**
     * Send an absence warning notification to a student.
     */
    public function store(Request $request)
    {
        $delegate = $request->user();

        $validator = Validator::make($request->all(), [
            'student_id' => 'required|exists:users,id',
            'subject_id' => 'required|exists:subjects,id',
            'absence_count' => 'required|integer|min:1',
            'message' => 'required|string',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        // Validate student belongs to batch
        $student = User::where('id', $request->student_id)
            ->whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->first();

        if (!$student) {
            return $this->error('الطالب غير موجود في دفعتك', 403);
        }

        $notification = StudentNotification::create([
            'user_id' => $request->student_id,
            'sender_id' => $delegate->id,
            'title' => 'إنذار غياب',
            'message' => $request->message,
            'type' => 'absence_warning',
            'data' => [
                'subject_id' => (int) $request->subject_id,
                'absence_count' => (int) $request->absence_count,
                'sender_role' => 'delegate',
            ],
        ]);

        return $this->success($notification, 'تم إرسال إنذار الغياب بنجاح', 201);
    }
    /**
     * Mark a notification as read.
     */
    public function markAsRead($id)
    {
        $notification = StudentNotification::where('user_id', request()->user()->id)
            ->findOrFail($id);

        $notification->markAsRead();

        return $this->success(null, 'تم تحديد التنبيه كمقروء');
    }

    /**
     * Mark all notifications as read.
     */
    public function markAllAsRead()
    {
        StudentNotification::where('user_id', request()->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return $this->success(null, 'تم تحديد جميع التنبيهات كمقروءة');
    }
}
