<?php

namespace App\Http\Controllers\Api\Student;

use App\Models\PollOption;
use App\Models\PollVote;
use App\Models\StudentNotification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NotificationController extends StudentApiController
{
    /**
     * Display a listing of the student's notifications.
     */
    public function index(Request $request)
    {
        $user = Auth::user();

        $notifications = StudentNotification::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->paginate(20);

        $notifications->getCollection()->transform(function ($notification) use ($user) {
            if ($notification->type === 'poll') {
                $options = PollOption::where('batch_id', $notification->batch_id)->get();
                $votedOption = PollVote::where('batch_id', $notification->batch_id)
                    ->where('student_id', $user->id)
                    ->first();

                $notification->poll_data = [
                    'options' => $options->map(function ($option) {
                        return [
                            'id' => $option->id,
                            'text' => $option->option_text,
                            'votes_count' => PollVote::where('poll_option_id', $option->id)->count(),
                        ];
                    }),
                    'has_voted' => (bool) $votedOption,
                    'voted_option_id' => $votedOption?->poll_option_id,
                ];
            }

            return $notification;
        });

        return $this->success([
            'module' => [
                'name' => 'student_notifications_feed',
                'purpose' => 'Personal notification feed for the student including polls, unread state, and targeted alerts.',
                'how_to_use' => 'Use this endpoint for inbox-style notifications. For the unified public stream, prefer news-hub.',
            ],
            'notifications' => $notifications,
        ], 'تم جلب الإشعارات بنجاح');
    }

    /**
     * Cast a vote on a poll.
     */
    public function vote(Request $request, $notificationId)
    {
        $user = Auth::user();
        $notification = StudentNotification::where('user_id', $user->id)
            ->findOrFail($notificationId);

        if ($notification->type !== 'poll') {
            return $this->error('هذا الإشعار ليس استطلاعًا.', 400);
        }

        $request->validate([
            'poll_option_id' => 'required|exists:poll_options,id',
        ]);

        $option = PollOption::findOrFail($request->poll_option_id);
        if ($option->batch_id !== $notification->batch_id) {
            return $this->error('خيار التصويت غير صالح لهذا الاستطلاع.', 400);
        }

        $existingVote = PollVote::where('batch_id', $notification->batch_id)
            ->where('student_id', $user->id)
            ->first();

        if ($existingVote) {
            return $this->error('لقد قمت بالتصويت مسبقًا في هذا الاستطلاع.', 400);
        }

        PollVote::create([
            'batch_id' => $notification->batch_id,
            'poll_option_id' => $request->poll_option_id,
            'student_id' => $user->id,
        ]);

        $notification->markAsRead();

        return $this->success(null, 'تم تسجيل تصويتك بنجاح');
    }

    /**
     * Retract a vote on a poll.
     */
    public function unvote($notificationId)
    {
        $user = Auth::user();
        $notification = StudentNotification::where('user_id', $user->id)
            ->findOrFail($notificationId);

        if ($notification->type !== 'poll') {
            return $this->error('هذا الإشعار ليس استطلاعًا.', 400);
        }

        $existingVote = PollVote::where('batch_id', $notification->batch_id)
            ->where('student_id', $user->id)
            ->first();

        if (!$existingVote) {
            return $this->error('لم تقم بالتصويت في هذا الاستطلاع بعد.', 400);
        }

        $existingVote->delete();

        return $this->success(null, 'تم سحب تصويتك بنجاح');
    }

    /**
     * Mark the specified notification as read.
     */
    public function markAsRead($id)
    {
        $notification = StudentNotification::where('user_id', Auth::id())
            ->findOrFail($id);

        $notification->markAsRead();

        return $this->success(null, 'تم تحديد الإشعار كمقروء');
    }

    /**
     * Mark all notifications as read.
     */
    public function markAllAsRead()
    {
        StudentNotification::where('user_id', Auth::id())
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return $this->success(null, 'تم تحديد جميع الإشعارات كمقروءة');
    }

    /**
     * Get unread notifications count.
     */
    public function unreadCount()
    {
        $count = StudentNotification::where('user_id', Auth::id())
            ->whereNull('read_at')
            ->count();
        $byScreen = StudentNotification::where('user_id', Auth::id())
            ->whereNull('read_at')
            ->get()
            ->groupBy(fn ($notification) => $this->screenForType($notification->type))
            ->map(fn ($items) => $items->count());

        return $this->success([
            'module' => [
                'name' => 'student_notifications_unread_count',
                'purpose' => 'Returns the unread count for the personal student notification inbox.',
            ],
            'unread_count' => $count,
            'by_screen' => $byScreen,
        ], 'تم جلب عدد الإشعارات غير المقروءة');
    }

    private function screenForType(?string $type): string
    {
        return match ($type) {
            'message' => 'messages',
            'inquiry', 'doctor_inquiry' => 'inquiries',
            'star', 'stars' => 'stars',
            'quiz', 'quizzes' => 'quizzes',
            'grade_delegation' => 'authorized_grades',
            'assignment' => 'assignments',
            'study_reminder' => 'study_center',
            'schedule' => 'schedule',
            'reminder' => 'reminders',
            'resource' => 'resources',
            'library' => 'library',
            'attendance', 'absence_warning', 'lecture_report' => 'attendance',
            'exam', 'announcement', 'poll', 'alert' => 'news_hub',
            default => 'notifications',
        };
    }
}
