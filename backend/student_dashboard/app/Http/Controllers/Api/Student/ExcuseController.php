<?php

namespace App\Http\Controllers\Api\Student;

use App\Models\Attendance;
use App\Models\Excuse;
use App\Support\ExcuseWorkflow;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Validator;

class ExcuseController extends StudentApiController
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'attendance_id' => 'required|exists:attendances,id',
            'reason' => 'required|string|max:1000',
            'attachment' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:10240',
            'attachments' => 'nullable|array|max:5',
            'attachments.*' => 'file|mimes:pdf,jpg,jpeg,png|max:10240',
        ]);

        if ($validator->fails()) {
            return $this->error($validator->errors()->first(), 422, $validator->errors());
        }

        $student = Auth::user();
        $student->loadMissing('college');
        $attendance = Attendance::with('subject.major.college')
            ->where('id', $request->attendance_id)
            ->where('student_id', $student->id)
            ->first();

        if (!$attendance) {
            return $this->error('سجل الحضور المحدد لا يخص الطالب الحالي.', 403);
        }

        if ($attendance->status !== 'absent') {
            return $this->error('يمكن تقديم طلب عذر فقط لسجلات الغياب.', 400);
        }

        $deadlineDays = (int) ($student->college?->excuses_deadline_days ?? 3);
        $deadline = Carbon::parse($attendance->date)->copy()->addDays($deadlineDays)->endOfDay();

        if (now()->gt($deadline)) {
            return $this->error("لقد انتهت مهلة تقديم الأعذار (مسموح خلال {$deadlineDays} أيام من تاريخ الغياب).", 400);
        }

        if ($attendance->excuse) {
            return $this->error('تم تقديم عذر مسبقاً لهذا الغياب.', 400);
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

        $attachments = $excuse->allAttachments()->map(function ($file) {
            return [
                'file_name' => $file->file_name,
                'file_path' => $file->file_path,
                'file_url' => $file->file_url,
            ];
        })->values();

        return $this->success([
            'excuse_id' => $excuse->id,
            'status' => $excuse->status,
            'receiver' => [
                'type' => $receiver['receiver_type'],
                'label' => $receiver['receiver_label'],
                'description' => ExcuseWorkflow::receiverDescription($receiver['receiver_type']),
            ],
            'attachment_url' => $attachmentPath ? asset('storage/' . $attachmentPath) : null,
            'attachments' => $attachments,
        ], ExcuseWorkflow::pendingMessage($receiver['receiver_type']), 201);
    }
}
