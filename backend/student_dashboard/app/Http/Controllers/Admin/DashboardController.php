<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;
use App\Enums\UserRole;
use App\Services\DashboardService;

class DashboardController extends Controller
{
    /**
     * عرض لوحة تحكم المدير المحسّنة باستخدام DashboardService.
     */
    public function index(DashboardService $dashboardService)
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        // الحماية الإضافية (Middleware موجود بالفعل ولكن للزيادة)
        if ($user->role !== UserRole::ADMIN) {
            Auth::logout();
            return redirect()->route('admin.login')
                ->withErrors(['email' => 'ليس لديك صلاحية الوصول إلى لوحة الإدارة.']);
        }

        // جلب جميع الإحصائيات من الخدمة الموحدة (Optimized Logic)
        $stats = $dashboardService->getAllStats($user);

        return view('admin.dashboard', [
            'user' => $user,
            'userStats' => $stats['user_stats'],
            'academicStats' => $stats['academic_stats'],
            'attendanceStats' => $stats['attendance_stats'],
            'atRiskStudents' => $stats['at_risk_students'],
            'todayAttendance' => $stats['today_stats']['today_attendance'],
            'todayAbsent' => $stats['today_stats']['today_absent'],
            'weeklyTrend' => $stats['weekly_trend'],
            'topAbsentSubjects' => $stats['top_absent_subjects'],
            'studentsPerMajor' => $stats['students_per_major'],
            'latestAttendance' => $stats['latest_activity']['latest_attendance'],
            'latestUsers' => $stats['latest_activity']['latest_users'],
        ]);
    }

    /**
     * عرض صفحة عن المطور.
     */
    public function about()
    {
        return view('admin.about');
    }
}
