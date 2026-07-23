<?php

namespace App\Http\Controllers\Api\Admin;

use App\Services\DashboardService;
use Illuminate\Http\JsonResponse;

class DashboardController extends AdminApiController
{
    /**
     * GET /api/admin/dashboard
     * جلب إحصائيات لوحة التحكم للمدير (نسخة الـ API المحسنة).
     */
    public function index(DashboardService $dashboardService): JsonResponse
    {
        // جلب جميع الإحصائيات من الخدمة الموحدة (Optimized Logic)
        $stats = $dashboardService->getAllStats();

        return $this->success([
            'user_stats' => $stats['user_stats'],
            'academic_stats' => $stats['academic_stats'],
            'attendance_stats' => $stats['attendance_stats'],
            'at_risk_students' => $stats['at_risk_students'],
            'today_attendance' => $stats['today_stats']['today_attendance'],
            'today_absent' => $stats['today_stats']['today_absent'],
            'weekly_trend' => $stats['weekly_trend'],
            'top_absent_subjects' => $stats['top_absent_subjects'],
            'students_per_major' => $stats['students_per_major'],
            'latest_activity' => [
                'latest_attendance' => $stats['latest_activity']['latest_attendance'],
                'latest_users' => $stats['latest_activity']['latest_users'],
            ]
        ]);
    }
}
