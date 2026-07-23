<?php

namespace App\Http\Controllers\Api\Doctor;

use App\Models\Academic\Subject;
use App\Models\Excuse;
use App\Models\StudentNotification;
use App\Support\ExcuseWorkflow;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ExcuseController extends DoctorApiController
{
    public function index(Request $request)
    {
        $doctorId = Auth::id();
        $subjectIds = Subject::where('doctor_id', $doctorId)->pluck('id');

        $query = ExcuseWorkflow::scopeDoctorQueue(Excuse::query(), $doctorId)
            ->with(['student:id,name,student_number', 'attendance.subject:id,name', 'reviewer:id,name', 'attachments']);

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        if ($request->filled('subject_id')) {
            $query->whereHas('attendance', fn ($query) => $query->where('subject_id', $request->subject_id));
        }

        if ($request->filled('search')) {
            $query->whereHas('student', fn ($query) => $query->where('name', 'like', "%{$request->search}%")
                ->orWhere('student_number', 'like', "%{$request->search}%"));
        }

        $all = $request->boolean('all');
        $excuses = $all
            ? $query->latest()->get()
            : $query->latest()->paginate(15);

        $statsRaw = ExcuseWorkflow::scopeDoctorQueue(Excuse::query(), $doctorId)
            ->selectRaw("
                COUNT(*) as total,
                SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
                SUM(CASE WHEN status = 'accepted' THEN 1 ELSE 0 END) as accepted,
                SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as rejected
            ")
            ->first();

        $excuseItems = $all ? $excuses : collect($excuses->items());
        $items = collect($excuseItems)->map(function ($excuse) {
            return [
                'id' => $excuse->id,
                'status' => $excuse->status,
                'resolution' => $excuse->resolution,
                'reason' => $excuse->reason,
                'doctor_comment' => $excuse->doctor_comment,
                'student' => $excuse->student,
                'attendance' => $excuse->attendance,
                'reviewer' => $excuse->reviewer,
                'attachments' => $excuse->allAttachments()->map(fn ($file) => [
                    'file_name' => $file->file_name,
                    'file_path' => $file->file_path,
                    'file_url' => $file->file_url,
                ])->values(),
            ];
        })->values();

        return $this->success([
            'stats' => [
                'total' => $statsRaw->total ?? 0,
                'pending' => $statsRaw->pending ?? 0,
                'accepted' => $statsRaw->accepted ?? 0,
                'rejected' => $statsRaw->rejected ?? 0,
            ],
            'workflow' => [
                'accept_requires_resolution' => true,
                'resolution_options' => collect(ExcuseWorkflow::resolutionOptions())
                    ->map(fn ($value) => ['value' => $value, 'label' => ExcuseWorkflow::resolutionLabel($value)])
                    ->values(),
            ],
            'subjects' => Subject::whereIn('id', $subjectIds)
                ->orderBy('name')
                ->get(['id', 'name']),
            'excuses' => $items,
            'pagination' => [
                'current_page' => $all ? 1 : $excuses->currentPage(),
                'last_page' => $all ? 1 : $excuses->lastPage(),
                'per_page' => $all ? $items->count() : $excuses->perPage(),
                'total' => $all ? $items->count() : $excuses->total(),
            ],
        ]);
    }

    public function update(Request $request, Excuse $excuse)
    {
        $validated = $request->validate([
            'status' => 'required|in:accepted,rejected',
            'resolution' => 'nullable|in:' . implode(',', ExcuseWorkflow::resolutionOptions()),
            'comment' => 'nullable|string|max:255',
        ]);

        if ($excuse->attendance->subject->doctor_id !== Auth::id()) {
            return $this->error('غير مصرح لك بمراجعة هذا العذر.', 403);
        }

        if (($excuse->receiver_type ?? ExcuseWorkflow::RECEIVER_DOCTOR) !== ExcuseWorkflow::RECEIVER_DOCTOR) {
            return $this->error('هذا العذر محول إلى قائمة المسؤول الإداري.', 403);
        }

        if ($validated['status'] === 'accepted' && empty($validated['resolution'])) {
            return $this->error('يجب اختيار الإجراء النهائي عند قبول العذر.', 422);
        }

        $excuse->update([
            'status' => $validated['status'],
            'resolution' => $validated['status'] === 'accepted' ? $validated['resolution'] : null,
            'reviewed_by' => Auth::id(),
            'doctor_comment' => $validated['comment'] ?? null,
        ]);

        if ($validated['status'] === 'accepted') {
            $excuse->attendance->update([
                'status' => ExcuseWorkflow::finalAttendanceStatus($validated['resolution']),
                'recorded_by' => Auth::id(),
            ]);
        }

        $subjectName = $excuse->attendance->subject->name ?? 'مادة غير معروفة';
        $statusLabel = $validated['status'] === 'accepted' ? 'مقبولًا' : 'مرفوضًا';
        $resolutionLabel = $validated['status'] === 'accepted'
            ? (' الإجراء النهائي: ' . ExcuseWorkflow::resolutionLabel($validated['resolution']) . '.')
            : '';

        $message = "تم اعتبار عذرك المقدم لمادة {$subjectName} بتاريخ {$excuse->attendance->date->format('Y-m-d')} {$statusLabel} من قبل مدرس المادة.{$resolutionLabel}";
        if (!empty($validated['comment'])) {
            $message .= "\nملاحظة المدرس: {$validated['comment']}";
        }

        StudentNotification::create([
            'user_id' => $excuse->student_id,
            'type' => 'excuse',
            'title' => 'قرار بشأن العذر',
            'message' => $message,
            'data' => [
                'excuse_id' => $excuse->id,
                'status' => $validated['status'],
                'resolution' => $excuse->resolution,
                'action_url' => route('student.subjects.show', $excuse->attendance->subject_id),
            ],
        ]);

        return $this->success([
            'excuse_id' => $excuse->id,
            'status' => $validated['status'],
            'resolution' => $excuse->resolution,
            'attendance_status' => $excuse->attendance->status,
            'comment' => $excuse->doctor_comment,
        ], 'تم تحديث قرار العذر بنجاح.');
    }
}
