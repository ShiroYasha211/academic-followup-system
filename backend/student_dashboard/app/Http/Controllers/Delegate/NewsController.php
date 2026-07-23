<?php

namespace App\Http\Controllers\Delegate;

use App\Http\Controllers\Controller;
use App\Models\StudentNotification;
use App\Models\PollOption;
use App\Models\PollVote;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NewsController extends Controller
{
    public function index()
    {
        $user = Auth::user();
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

        $perPage = 12;
        $page = LengthAwarePaginator::resolveCurrentPage();
        $news = new LengthAwarePaginator(
            $newsItems->forPage($page, $perPage)->values(),
            $newsItems->count(),
            $perPage,
            $page,
            [
                'path' => request()->url(),
                'query' => request()->query(),
            ]
        );

        return view('delegate.news.index', compact('news'));
    }

    public function show($batchId)
    {
        $user = Auth::user();
        $notifications = StudentNotification::where('user_id', $user->id)
            ->where('batch_id', $batchId)
            ->get();

        if ($notifications->isEmpty()) {
            abort(404);
        }

        $item = $notifications->first();

        // Mark as read
        $item->markAsRead();

        $pollOptions = [];
        $hasVoted = false;
        $userVote = null;

        if ($item->type === 'poll') {
            $pollOptions = PollOption::where('batch_id', $batchId)->get();
            $userVote = PollVote::where('batch_id', $batchId)
                ->where('student_id', $user->id)
                ->first();
            $hasVoted = !is_null($userVote);
        }

        return view('delegate.news.show', compact('item', 'pollOptions', 'hasVoted', 'userVote'));
    }

    public function vote(Request $request, $batchId)
    {
        $user = Auth::user();
        $request->validate([
            'option_id' => 'required|exists:poll_options,id'
        ]);

        $exists = PollVote::where('batch_id', $batchId)
            ->where('student_id', $user->id)
            ->exists();

        if ($exists) {
            return back()->with('error', 'لقد قمت بالتصويت بالفعل.');
        }

        PollVote::create([
            'student_id' => $user->id,
            'batch_id' => $batchId,
            'poll_option_id' => $request->option_id
        ]);

        return back()->with('success', 'تم تسجيل صوتك بنجاح.');
    }
}
