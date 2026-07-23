<?php

namespace App\Http\Controllers\Administrative;

use App\Http\Controllers\Controller;
use App\Models\Excuse;
use App\Models\StudentNotification;
use App\Support\ExcuseWorkflow;
use Illuminate\Http\Request;

class ExcuseController extends Controller
{
    public function index(Request $request)
    {
        $college = auth()->user()->college;

        $query = Excuse::whereHas('student', function ($query) use ($college) {
            $query->where('college_id', $college->id);
        })
            ->with(['student', 'attendance.subject', 'reviewer', 'attachments']);

        $status = $request->get('status', 'pending');
        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        $search = $request->get('search');
        if ($search) {
            $query->whereHas('student', function ($query) use ($search) {
                $query->where('name', 'like', "%{$search}%")
                    ->orWhere('student_number', 'like', "%{$search}%");
            });
        }

        $excuses = $query->latest()->paginate(15)->withQueryString();

        $statsRaw = Excuse::whereHas('student', fn($query) => $query->where('college_id', $college->id))
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

        return view('administrative.excuses.index-clean', compact('excuses', 'stats', 'status', 'search', 'college'));
    }

    public function update(Request $request, Excuse $excuse)
    {
        $college = auth()->user()->college;

        if ($excuse->student->college_id !== $college->id) {
            abort(403);
        }

        if (!ExcuseWorkflow::canAdministrativeReview($college)) {
            return back()->with('error', 'الأعذار محولة حاليًا إلى دكتور المادة. مراجعة المسؤول الإداري للعرض فقط.');
        }

        if (($excuse->receiver_type ?? ExcuseWorkflow::RECEIVER_ADMINISTRATIVE) !== ExcuseWorkflow::RECEIVER_ADMINISTRATIVE) {
            return back()->with('error', 'هذا العذر محول إلى دكتور المادة ولا يمكن اتخاذ القرار من قائمة المسؤول الإداري.');
        }

        $validated = $request->validate([
            'status' => 'required|in:accepted,rejected',
            'resolution' => 'nullable|in:' . implode(',', ExcuseWorkflow::resolutionOptions()),
            'comment' => 'nullable|string|max:255',
        ]);

        if ($validated['status'] === 'accepted' && empty($validated['resolution'])) {
            return back()->withErrors(['resolution' => 'يجب اختيار الإجراء النهائي عند قبول العذر.']);
        }

        $excuse->update([
            'status' => $validated['status'],
            'resolution' => $validated['status'] === 'accepted' ? $validated['resolution'] : null,
            'reviewed_by' => auth()->id(),
            'doctor_comment' => $validated['comment'] ?? null,
        ]);

        if ($validated['status'] === 'accepted') {
            $excuse->attendance->update([
                'status' => ExcuseWorkflow::finalAttendanceStatus($validated['resolution']),
                'recorded_by' => auth()->id(),
            ]);
        }

        $subjectName = $excuse->attendance->subject->name ?? 'مادة غير معروفة';
        $statusLabel = $validated['status'] === 'accepted' ? 'مقبولاً' : 'مرفوضاً';
        $resolutionLabel = $validated['status'] === 'accepted'
            ? (' الإجراء النهائي: ' . ExcuseWorkflow::resolutionLabel($validated['resolution']) . '.')
            : '';

        $message = "تم اعتبار عذرك المقدم لمادة {$subjectName} بتاريخ {$excuse->attendance->date->format('Y-m-d')} {$statusLabel} من قبل إدارة الكلية.{$resolutionLabel}";
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

        return back()->with('success', 'تم حفظ القرار بشأن العذر بنجاح.');
    }
}
