<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\StudentNotification;
use App\Models\PollOption;
use App\Models\PollVote;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NewsController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        $news = StudentNotification::where('user_id', $user->id)
            ->whereIn('type', ['announcement', 'exam', 'assignment', 'poll'])
            ->latest()
            ->paginate(12);

        return view('student.news.index', compact('news'));
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

        return view('student.news.show', compact('item', 'pollOptions', 'hasVoted', 'userVote'));
    }

    public function vote(Request $request, $batchId)
    {
        $user = Auth::user();
        $request->validate([
            'option_id' => 'required|exists:poll_options,id'
        ]);

        // Check if already voted
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
