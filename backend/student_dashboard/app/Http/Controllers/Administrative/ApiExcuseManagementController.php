<?php

namespace App\Http\Controllers\Administrative;

use App\Http\Controllers\Api\Administrative\AdministrativeApiController;
use App\Models\Excuse;
use App\Models\StudentNotification;
use App\Support\ExcuseWorkflow;
use Illuminate\Http\Request;

class ApiExcuseManagementController extends AdministrativeApiController
{
    public function index(Request $request)
    {
        $college = $this->college();

        $query = Excuse::whereHas('student', fn ($query) => $query->where('college_id', $college->id))
            ->with(['student:id,name,student_number,college_id', 'attendance.subject:id,name', 'reviewer:id,name']);

        $status = $request->get('status', 'pending');
        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        if ($request->filled('search')) {
            $query->whereHas('student', function ($query) use ($request) {
                $query->where('name', 'like', "%{$request->search}%")
                    ->orWhere('student_number', 'like', "%{$request->search}%");
            });
        }

        $excuses = $query->latest()->paginate($request->integer('per_page', 15));

        $statsRaw = Excuse::whereHas('student', fn ($query) => $query->where('college_id', $college->id))
            ->selectRaw("
                COUNT(*) as total,
                SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
                SUM(CASE WHEN status = 'accepted' THEN 1 ELSE 0 END) as accepted,
                SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as rejected
            ")
            ->first();

        return $this->success([
            'excuses' => $excuses->items(),
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
            'can_review' => ExcuseWorkflow::canAdministrativeReview($college),
            'resolution_options' => collect(ExcuseWorkflow::resolutionOptions())
                ->map(fn ($value) => ['value' => $value, 'label' => ExcuseWorkflow::resolutionLabel($value)])
                ->values(),
        ]);
    }

    public function update(Request $request, Excuse $excuse)
    {
        if ($excuse->student->college_id !== $this->college()->id) {
            return $this->error('العذر لا ينتمي إلى هذه الكلية.', 403);
        }

        if (!ExcuseWorkflow::canAdministrativeReview($this->college())) {
            return $this->error('الأعذار محولة حاليًا إلى دكتور المادة. مراجعة المسؤول الإداري للعرض فقط.', 403);
        }

        if (($excuse->receiver_type ?? ExcuseWorkflow::RECEIVER_ADMINISTRATIVE) !== ExcuseWorkflow::RECEIVER_ADMINISTRATIVE) {
            return $this->error('هذا العذر محول إلى دكتور المادة ولا يمكن اتخاذ القرار من قائمة المسؤول الإداري.', 403);
        }

        $validated = $request->validate([
            'status' => 'required|in:accepted,rejected',
            'resolution' => 'nullable|in:' . implode(',', ExcuseWorkflow::resolutionOptions()),
            'comment' => 'nullable|string|max:255',
        ]);

        if ($validated['status'] === 'accepted' && empty($validated['resolution'])) {
            return $this->error('يجب اختيار الإجراء النهائي عند قبول العذر.', 422);
        }

        $excuse->update([
            'status' => $validated['status'],
            'resolution' => $validated['status'] === 'accepted' ? $validated['resolution'] : null,
            'reviewed_by' => $this->administrative()->id,
            'doctor_comment' => $validated['comment'] ?? null,
        ]);

        if ($validated['status'] === 'accepted') {
            $excuse->attendance->update([
                'status' => ExcuseWorkflow::finalAttendanceStatus($validated['resolution']),
                'recorded_by' => $this->administrative()->id,
            ]);
        }

        $subjectName = $excuse->attendance->subject->name ?? 'مادة غير معروفة';
        $date = optional($excuse->attendance->date)->format('Y-m-d');
        $statusLabel = $validated['status'] === 'accepted' ? 'مقبولًا' : 'مرفوضًا';
        $resolutionLabel = $validated['status'] === 'accepted'
            ? (' الإجراء النهائي: ' . ExcuseWorkflow::resolutionLabel($validated['resolution']) . '.')
            : '';

        $message = "تم اعتبار عذرك المقدم لمادة {$subjectName} بتاريخ {$date} {$statusLabel} من قبل إدارة الكلية.{$resolutionLabel}";
        if (!empty($validated['comment'])) {
            $message .= "\nملاحظة الإدارة: {$validated['comment']}";
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

        return $this->success(
            $excuse->fresh()->load(['student:id,name,student_number', 'attendance.subject:id,name', 'reviewer:id,name']),
            'تم تحديث قرار العذر بنجاح.'
        );
    }
}
