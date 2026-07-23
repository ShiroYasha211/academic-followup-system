<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Models\PollOption;
use App\Models\PollVote;
use App\Models\StudentNotification;
use Illuminate\Http\Request;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\Validator;

class NewsController extends DelegateApiController
{
    /**
     * Display a listing of college admin broadcast news visible to the delegate.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $newsItems = StudentNotification::with('sender:id,name,role')
            ->where('user_id', $user->id)
            ->whereNotNull('batch_id')
            ->whereIn('type', ['announcement', 'exam', 'assignment', 'attendance', 'poll'])
            ->latest()
            ->get()
            ->groupBy('batch_id')
            ->map(function ($group) {
                return $group->first();
            })
            ->values();

        $perPage = $request->integer('per_page', 15);
        $page = LengthAwarePaginator::resolveCurrentPage();
        $news = new LengthAwarePaginator(
            $newsItems->forPage($page, $perPage)->values(),
            $newsItems->count(),
            $perPage,
            $page,
            [
                'path' => $request->url(),
                'query' => $request->query(),
            ]
        );

        return $this->success($news, 'تم جلب المركز الإخباري بنجاح');
    }

    /**
     * Display the specified news batch.
     */
    public function show(Request $request, string $batchId)
    {
        $user = $request->user();
        $notifications = StudentNotification::where('user_id', $user->id)
            ->where('batch_id', $batchId)
            ->with('sender:id,name,role')
            ->get();

        if ($notifications->isEmpty()) {
            return $this->error('الخبر غير موجود', 404);
        }

        $notification = $notifications->first();
        $notification->markAsRead();

        $data = [
            'notification' => $notification,
            'related_notifications' => $notifications,
            'poll_options' => [],
            'user_vote' => null,
            'has_voted' => false,
        ];

        if ($notification->type === 'poll') {
            $data['poll_options'] = PollOption::where('batch_id', $batchId)->withCount('votes')->get();

            $userVote = PollVote::where('batch_id', $batchId)
                ->where('student_id', $user->id)
                ->first();

            $data['user_vote'] = $userVote;
            $data['has_voted'] = $userVote !== null;
        }

        return $this->success($data, 'تم جلب تفاصيل الخبر');
    }

    /**
     * Cast a vote on a poll batch.
     */
    public function vote(Request $request, string $batchId)
    {
        $user = $request->user();
        $notification = StudentNotification::where('user_id', $user->id)
            ->where('batch_id', $batchId)
            ->where('type', 'poll')
            ->first();

        if (! $notification) {
            return $this->error('الاستبيان غير موجود', 404);
        }

        $validator = Validator::make($request->all(), [
            'option_id' => 'required|exists:poll_options,id',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        $exists = PollVote::where('batch_id', $batchId)
            ->where('student_id', $user->id)
            ->exists();

        if ($exists) {
            return $this->error('لقد قمت بالتصويت بالفعل', 400);
        }

        $vote = PollVote::create([
            'student_id' => $user->id,
            'batch_id' => $batchId,
            'poll_option_id' => $request->option_id,
        ]);

        return $this->success($vote, 'تم تسجيل صوتك بنجاح');
    }

    /**
     * Mark a specific news batch as read.
     */
    public function markAsRead(Request $request, string $batchId)
    {
        $user = $request->user();
        $notification = StudentNotification::where('user_id', $user->id)
            ->where('batch_id', $batchId)
            ->first();

        if (! $notification) {
            return $this->error('الخبر غير موجود', 404);
        }

        $notification->markAsRead();

        return $this->success(null, 'تم تحديد الخبر كمقروء');
    }

    /**
     * Mark all delegate news batches as read.
     */
    public function markAllAsRead(Request $request)
    {
        $user = $request->user();

        StudentNotification::where('user_id', $user->id)
            ->whereNotNull('batch_id')
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return $this->success(null, 'تم تحديد الكل كمقروء');
    }
}
