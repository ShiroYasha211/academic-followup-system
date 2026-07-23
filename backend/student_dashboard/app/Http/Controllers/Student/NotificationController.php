<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\StudentNotification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NotificationController extends Controller
{
    /**
     * Display all notifications.
     */
    public function index()
    {
        $user = Auth::user();

        $notifications = StudentNotification::where('user_id', $user->id)
            ->latest()
            ->paginate(20);

        $unreadCount = StudentNotification::where('user_id', $user->id)
            ->unread()
            ->count();

        return view('student.notifications.index', compact('notifications', 'unreadCount'));
    }

    /**
     * Mark a notification as read.
     */
    public function markAsRead($id)
    {
        $notification = StudentNotification::where('user_id', Auth::id())
            ->findOrFail($id);

        $notification->markAsRead();

        return back()->with('success', 'تم تعليم الإشعار كمقروء');
    }

    /**
     * Mark all notifications as read.
     */
    public function markAllAsRead()
    {
        StudentNotification::where('user_id', Auth::id())
            ->unread()
            ->update(['read_at' => now()]);

        return back()->with('success', 'تم تعليم جميع الإشعارات كمقروءة');
    }

    /**
     * Get unread count for header badge (AJAX).
     */
    public function getUnreadCount()
    {
        $count = StudentNotification::where('user_id', Auth::id())
            ->unread()
            ->count();

        return response()->json(['count' => $count]);
    }
}
