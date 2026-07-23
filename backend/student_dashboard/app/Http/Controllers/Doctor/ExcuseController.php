<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Controller;
use App\Models\Academic\Subject;
use App\Models\Excuse;
use App\Models\StudentNotification;
use App\Support\ExcuseWorkflow;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ExcuseController extends Controller
{
    public function index(Request $request)
    {
        $doctorId = Auth::id();
        $subjectIds = Subject::where('doctor_id', $doctorId)->pluck('id');
        $status = $request->get('status', 'pending');

        $query = ExcuseWorkflow::scopeDoctorQueue(Excuse::query(), $doctorId)
            ->with(['student', 'attendance.subject', 'reviewer', 'attachments']);

        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        $subjectId = $request->get('subject');
        if ($subjectId && $subjectId !== 'all') {
            $query->whereHas('attendance', fn ($query) => $query->where('subject_id', $subjectId));
        }

        $search = $request->get('search');
        if ($search) {
            $query->whereHas('student', function ($query) use ($search) {
                $query->where('name', 'like', "%{$search}%")
                    ->orWhere('student_number', 'like', "%{$search}%");
            });
        }

        $excuses = $query->latest()->paginate(15)->withQueryString();

        $statsRaw = ExcuseWorkflow::scopeDoctorQueue(Excuse::query(), $doctorId)
            ->selectRaw("
                COUNT(*) as total,
                SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
                SUM(CASE WHEN status = 'accepted' THEN 1 ELSE 0 END) as accepted,
                SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as rejected
            ")
            ->first();

        $stats = [
            'all' => $statsRaw->total ?? 0,
            'pending' => $statsRaw->pending ?? 0,
            'accepted' => $statsRaw->accepted ?? 0,
            'rejected' => $statsRaw->rejected ?? 0,
        ];

        $doctorSubjects = Subject::whereIn('id', $subjectIds)->get();

        return view('doctor.excuses.index-clean', compact('excuses', 'stats', 'status', 'doctorSubjects', 'subjectId', 'search'));
    }

    public function update(Request $request, Excuse $excuse)
    {
        $validated = $request->validate([
            'status' => 'required|in:accepted,rejected',
            'resolution' => 'nullable|in:' . implode(',', ExcuseWorkflow::resolutionOptions()),
            'comment' => 'nullable|string|max:255',
        ]);

        if ($excuse->attendance->subject->doctor_id !== Auth::id()) {
            abort(403);
        }

        if (($excuse->receiver_type ?? ExcuseWorkflow::RECEIVER_DOCTOR) !== ExcuseWorkflow::RECEIVER_DOCTOR) {
            return back()->with('error', 'هذا العذر محول إلى قائمة المسؤول الإداري.');
        }

        if ($validated['status'] === 'accepted' && empty($validated['resolution'])) {
            return back()->withErrors(['resolution' => 'يجب اختيار الإجراء النهائي عند قبول العذر.']);
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
        $statusLabel = $validated['status'] === 'accepted' ? 'مقبولاً' : 'مرفوضاً';
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

        return back()->with('success', 'تم حفظ القرار بشأن العذر بنجاح.');
    }
}
