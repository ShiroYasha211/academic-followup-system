<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Controller;
use App\Models\Academic\Subject;
use App\Models\Inquiry;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class InquiryController extends Controller
{
    public function index(Request $request)
    {
        $user = Auth::user();
        $status = $request->string('status')->toString();
        $subjects = Subject::with('level:id,name')
            ->where('doctor_id', $user->id)
            ->orderBy('name')
            ->get();

        $query = Inquiry::visibleToDoctor($user->id)
            ->with(['student', 'subject', 'answeredBy'])
            ->latest();

        if ($status !== '') {
            $query->where('status', $status);
        }

        if ($request->filled('subject_id')) {
            $query->where('subject_id', $request->subject_id);
        }

        if ($request->filled('search')) {
            $search = $request->string('search')->trim()->toString();
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('question', 'like', "%{$search}%")
                  ->orWhereHas('student', function ($sq) use ($search) {
                      $sq->where('name', 'like', "%{$search}%")
                        ->orWhere('student_number', 'like', "%{$search}%");
                  });
            });
        }

        $inquiries = $query->paginate(15);

        $statsRaw = Inquiry::visibleToDoctor($user->id)
            ->selectRaw("
                COUNT(*) as total,
                SUM(CASE WHEN status = 'forwarded' THEN 1 ELSE 0 END) as forwarded,
                SUM(CASE WHEN status = 'answered' THEN 1 ELSE 0 END) as answered,
                SUM(CASE WHEN status = 'closed' THEN 1 ELSE 0 END) as closed
            ")
            ->first();

        $stats = [
            'total' => $statsRaw->total ?? 0,
            'forwarded' => $statsRaw->forwarded ?? 0,
            'answered' => $statsRaw->answered ?? 0,
            'closed' => $statsRaw->closed ?? 0,
        ];

        return view('doctor.inquiries.index', compact('inquiries', 'stats', 'status', 'subjects'));
    }

    public function show($id)
    {
        $inquiry = Inquiry::visibleToDoctor(Auth::id())
            ->with(['student', 'subject', 'answeredBy'])
            ->findOrFail($id);

        return view('doctor.inquiries.show', compact('inquiry'));
    }

    public function answer(Request $request, $id)
    {
        $request->validate([
            'answer' => 'required|string',
        ]);

        $inquiry = Inquiry::visibleToDoctor(Auth::id())
            ->where('status', 'forwarded')
            ->findOrFail($id);

        $inquiry->update([
            'answer' => $request->answer,
            'answered_by' => Auth::id(),
            'answered_at' => now(),
            'status' => 'answered',
        ]);

        return redirect()
            ->route('doctor.inquiries.index')
            ->with('success', 'تم الرد على الاستفسار بنجاح.');
    }

    public function updateSettings(Request $request, Subject $subject)
    {
        abort_unless($subject->doctor_id === Auth::id(), 403);

        $validated = $request->validate([
            'inquiries_enabled' => ['required', 'boolean'],
            'inquiries_closed_reason' => ['nullable', 'string', 'max:1000'],
        ]);

        $enabled = filter_var($validated['inquiries_enabled'], FILTER_VALIDATE_BOOLEAN);
        $reason = trim((string) ($validated['inquiries_closed_reason'] ?? ''));

        $subject->update([
            'inquiries_enabled' => $enabled,
            'inquiries_closed_reason' => $enabled
                ? null
                : ($reason !== '' ? $reason : $subject->inquiries_closed_reason),
        ]);

        return back()->with(
            'success',
            $enabled
                ? 'تم فتح الاستفسارات لهذه المادة.'
                : 'تم إغلاق الاستفسارات لهذه المادة.'
        );
    }
}
