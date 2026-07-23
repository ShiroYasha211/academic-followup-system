<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Excuse;
use App\Support\ExcuseWorkflow;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Arr;

class ExcuseController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'attendance_id' => 'required|exists:attendances,id',
            'reason' => 'required|string|max:1000',
            'attachment' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:10240',
            'attachments' => 'nullable|array|max:5',
            'attachments.*' => 'file|mimes:pdf,jpg,jpeg,png|max:10240',
        ]);

        $student = Auth::user();
        $attendance = Attendance::with('subject.major.college')
            ->where('id', $request->attendance_id)
            ->where('student_id', $student->id)
            ->firstOrFail();

        if ($attendance->status !== 'absent') {
            return back()->with('error', 'Only absent attendance records can receive a new excuse request.');
        }

        $deadlineDays = (int) ($student->college?->excuses_deadline_days ?? 7);
        $deadline = Carbon::parse($attendance->date)->copy()->addDays($deadlineDays);

        if (now()->gt($deadline)) {
            return back()->with('error', "Excuse submission deadline has passed ({$deadlineDays} days from the absence date).");
        }

        if ($attendance->excuse) {
            return back()->with('error', 'An excuse has already been submitted for this absence.');
        }

        $attachmentPath = null;
        if ($request->hasFile('attachment')) {
            $attachmentPath = $request->file('attachment')->store('excuses', 'public');
        }

        $receiver = ExcuseWorkflow::determineReceiver($attendance, $student->loadMissing('college'));

        $excuse = Excuse::create([
            'attendance_id' => $attendance->id,
            'student_id' => $student->id,
            'receiver_type' => $receiver['receiver_type'],
            'receiver_id' => $receiver['receiver_id'],
            'reason' => $request->reason,
            'attachment' => $attachmentPath,
            'status' => 'pending',
        ]);

        foreach (Arr::wrap($request->file('attachments')) as $file) {
            $path = $file->store('excuses', 'public');
            $excuse->attachments()->create([
                'file_path' => $path,
                'file_name' => $file->getClientOriginalName(),
                'mime_type' => $file->getClientMimeType(),
                'file_size' => $file->getSize(),
            ]);
        }

        return back()->with('success', ExcuseWorkflow::pendingMessage($receiver['receiver_type']));
    }
}
