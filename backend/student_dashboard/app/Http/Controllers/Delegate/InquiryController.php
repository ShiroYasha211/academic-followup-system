<?php

namespace App\Http\Controllers\Delegate;

use App\Http\Controllers\Controller;
use App\Models\Inquiry;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class InquiryController extends Controller
{
    public function index(Request $request)
    {
        $user = Auth::user();
        $status = $request->string('status')->toString();

        $query = Inquiry::whereHas('student', function ($studentQuery) use ($user) {
            $studentQuery
                ->where('major_id', $user->major_id)
                ->where('level_id', $user->level_id);
        })
            ->with(['student', 'subject', 'answeredBy', 'delegate'])
            ->latest();

        if ($status !== '') {
            $query->where('status', $status);
        }

        $inquiries = $query->paginate(15);

        $statsRaw = Inquiry::whereHas('student', function ($studentQuery) use ($user) {
            $studentQuery
                ->where('major_id', $user->major_id)
                ->where('level_id', $user->level_id);
        })->selectRaw("
            COUNT(*) as total,
            SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
            SUM(CASE WHEN status = 'forwarded' THEN 1 ELSE 0 END) as forwarded,
            SUM(CASE WHEN status = 'answered' THEN 1 ELSE 0 END) as answered
        ")->first();

        $stats = [
            'total' => $statsRaw->total ?? 0,
            'pending' => $statsRaw->pending ?? 0,
            'forwarded' => $statsRaw->forwarded ?? 0,
            'answered' => $statsRaw->answered ?? 0,
        ];

        return view('delegate.inquiries.index', compact('inquiries', 'stats', 'status'));
    }

    public function show($id)
    {
        $user = Auth::user();

        $inquiry = Inquiry::whereHas('student', function ($studentQuery) use ($user) {
            $studentQuery
                ->where('major_id', $user->major_id)
                ->where('level_id', $user->level_id);
        })
            ->with(['student', 'subject', 'answeredBy', 'delegate'])
            ->findOrFail($id);

        return view('delegate.inquiries.show', compact('inquiry'));
    }

    public function forward($id)
    {
        $user = Auth::user();

        $inquiry = Inquiry::whereHas('student', function ($studentQuery) use ($user) {
            $studentQuery
                ->where('major_id', $user->major_id)
                ->where('level_id', $user->level_id);
        })
            ->where('status', 'pending')
            ->findOrFail($id);

        $inquiry->update([
            'status' => 'forwarded',
            'delegate_id' => $user->id,
        ]);

        return back()->with('success', 'تم تحويل الاستفسار إلى الدكتور.');
    }

    public function answer(Request $request, $id)
    {
        $request->validate([
            'answer' => 'required|string',
        ]);

        $user = Auth::user();

        $inquiry = Inquiry::whereHas('student', function ($studentQuery) use ($user) {
            $studentQuery
                ->where('major_id', $user->major_id)
                ->where('level_id', $user->level_id);
        })
            ->where('status', 'pending')
            ->findOrFail($id);

        $inquiry->update([
            'answer' => $request->answer,
            'status' => 'answered',
            'delegate_id' => $user->id,
            'answered_by' => $user->id,
            'answered_at' => now(),
        ]);

        return redirect()
            ->route('delegate.inquiries.show', $id)
            ->with('success', 'تم إرسال الرد بنجاح.');
    }

    public function close($id)
    {
        $user = Auth::user();

        $inquiry = Inquiry::whereHas('student', function ($studentQuery) use ($user) {
            $studentQuery
                ->where('major_id', $user->major_id)
                ->where('level_id', $user->level_id);
        })
            ->where(function ($statusQuery) use ($user) {
                $statusQuery->where('status', 'pending')
                    ->orWhere(function ($answeredQuery) use ($user) {
                        $answeredQuery->where('status', 'answered')
                            ->where('answered_by', $user->id);
                    });
            })
            ->findOrFail($id);

        $inquiry->update(['status' => 'closed']);

        return back()->with('success', 'تم إغلاق الاستفسار.');
    }
}
