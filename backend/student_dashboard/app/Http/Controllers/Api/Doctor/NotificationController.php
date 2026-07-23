<?php

namespace App\Http\Controllers\Api\Doctor;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\StudentNotification;

class NotificationController extends DoctorApiController
{
    /** GET /api/doctor/notifications */
    public function index()
    {
        $notifications = StudentNotification::where('user_id', Auth::id())
            ->latest()
            ->paginate(20);

        $notifications->getCollection()->each->append('attachment_url');

        $unreadCount = StudentNotification::where('user_id', Auth::id())->unread()->count();

        return $this->success([
            'unread_count' => $unreadCount,
            'notifications' => $notifications->items(),
            'pagination' => [
                'current_page' => $notifications->currentPage(),
                'last_page' => $notifications->lastPage(),
                'per_page' => $notifications->perPage(),
                'total' => $notifications->total(),
            ],
        ]);
    }

    /** POST /api/doctor/notifications/{id}/read */
    public function markAsRead($id)
    {
        $notification = StudentNotification::where('user_id', Auth::id())->findOrFail($id);
        $notification->markAsRead();
        return $this->success(null, 'تم تعليم الإشعار كمقروء.');
    }

    /** POST /api/doctor/notifications/mark-all-read */
    public function markAllAsRead()
    {
        StudentNotification::where('user_id', Auth::id())->unread()->update(['read_at' => now()]);
        return $this->success(null, 'تم تعليم جميع الإشعارات كمقروءة.');
    }
}
