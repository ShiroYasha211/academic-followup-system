<?php

namespace App\Http\Controllers\Api\Administrative;

use App\Models\Excuse;
use App\Models\StudentNotification;
use Illuminate\Http\Request;

class ExcuseController extends AdministrativeApiController
{
    public function index(Request $request)
    {
        $college = $this->college();
        $query = Excuse::whereHas('student', fn ($q) => $q->where('college_id', $college->id))
            ->with(['student:id,name,student_number,college_id', 'attendance.subject:id,name', 'attachments']);

        $status = $request->get('status', 'pending');
        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        if ($request->filled('search')) {
            $query->whereHas('student', function ($q) use ($request) {
                $q->where('name', 'like', "%{$request->search}%")
                    ->orWhere('student_number', 'like', "%{$request->search}%");
            });
        }

        $excuses = $query->latest()->paginate($request->integer('per_page', 15));

        $statsRaw = Excuse::whereHas('student', fn ($q) => $q->where('college_id', $college->id))
            ->selectRaw("COUNT(*) as total, SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending, SUM(CASE WHEN status = 'accepted' THEN 1 ELSE 0 END) as accepted, SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as rejected")
            ->first();

        $items = collect($excuses->items())->map(function (Excuse $excuse) {
            return [
                'id' => $excuse->id,
                'student_id' => $excuse->student_id,
                'attendance_id' => $excuse->attendance_id,
                'reason' => $excuse->reason,
                'status' => $excuse->status,
                'doctor_comment' => $excuse->doctor_comment,
                'created_at' => $excuse->created_at,
                'student' => $excuse->student,
                'attendance' => $excuse->attendance,
                'attachments' => $excuse->allAttachments()->map(fn ($file) => [
                    'id' => $file['id'] ?? null,
                    'file_name' => $file['file_name'] ?? basename((string) ($file['file_path'] ?? 'attachment')),
                    'file_path' => $file['file_path'] ?? null,
                    'file_url' => $file['file_url'] ?? null,
                ])->values(),
            ];
        })->values();

        return $this->success([
            'excuses' => $items,
            'pagination' => [
                'current_page' => $excuses->currentPage(),
                'last_page' => $excuses->lastPage(),
                'per_page' => $excuses->perPage(),
                'total' => $excuses->total(),
            ],
            'stats' => [
                'all' => $statsRaw->total ?? 0,
                'pending' => $statsRaw->pending ?? 0,
                'accepted' => $statsRaw->accepted ?? 0,
                'rejected' => $statsRaw->rejected ?? 0,
            ],
            'receiver' => $college->excuse_receiver,
        ]);
    }

    public function update(Request $request, Excuse $excuse)
    {
        if ($excuse->student->college_id !== $this->college()->id) {
            return $this->error('العذر لا ينتمي إلى كليتك.', 403);
        }

        $validated = $request->validate([
            'status' => 'required|in:accepted,rejected',
            'comment' => 'nullable|string|max:255',
        ]);

        $excuse->update([
            'status' => $validated['status'],
            'doctor_comment' => $validated['comment'] ?? null,
        ]);

        if ($validated['status'] === 'accepted') {
            $excuse->attendance->update(['status' => 'excused']);
        }

        $subjectName = $excuse->attendance->subject->name ?? 'غير محدد';
        $date = optional($excuse->attendance->date)->format('Y-m-d');
        $statusLabel = $validated['status'] === 'accepted' ? 'قبول' : 'رفض';
        $message = "تم {$statusLabel} عذرك المقدم لمادة {$subjectName} (غياب {$date}) من قبل إدارة الكلية.";
        if (!empty($validated['comment'])) {
            $message .= "\nملاحظة الإدارة: {$validated['comment']}";
        }

        StudentNotification::create([
            'user_id' => $excuse->student_id,
            'type' => 'excuse',
            'title' => 'حالة العذر',
            'message' => $message,
            'data' => [
                'excuse_id' => $excuse->id,
                'status' => $validated['status'],
                'action_url' => route('student.subjects.show', $excuse->attendance->subject_id),
            ],
        ]);

        $excuse = $excuse->fresh()->load(['student:id,name,student_number', 'attendance.subject:id,name', 'attachments']);

        return $this->success([
            'id' => $excuse->id,
            'student_id' => $excuse->student_id,
            'attendance_id' => $excuse->attendance_id,
            'reason' => $excuse->reason,
            'status' => $excuse->status,
            'doctor_comment' => $excuse->doctor_comment,
            'student' => $excuse->student,
            'attendance' => $excuse->attendance,
            'attachments' => $excuse->allAttachments()->map(fn ($file) => [
                'id' => $file['id'] ?? null,
                'file_name' => $file['file_name'] ?? basename((string) ($file['file_path'] ?? 'attachment')),
                'file_path' => $file['file_path'] ?? null,
                'file_url' => $file['file_url'] ?? null,
            ])->values(),
        ], 'تم تحديث حالة العذر بنجاح');
    }
}
