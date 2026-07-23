<?php

namespace App\Http\Controllers\Api\Doctor;

use App\Models\Academic\Subject;
use App\Models\Inquiry;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class InquiryController extends DoctorApiController
{
    public function index(Request $request)
    {
        $doctorId = Auth::id();
        $subjects = Subject::where('doctor_id', $doctorId)
            ->orderBy('name')
            ->get();

        $query = Inquiry::visibleToDoctor($doctorId)
            ->with(['student:id,name,student_number', 'subject:id,name', 'answeredBy:id,name,role']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
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

        $inquiries = $query->latest()->paginate(15);

        $statsRaw = Inquiry::visibleToDoctor($doctorId)
            ->selectRaw("
                COUNT(*) as total,
                SUM(CASE WHEN status = 'forwarded' THEN 1 ELSE 0 END) as forwarded,
                SUM(CASE WHEN status = 'answered' THEN 1 ELSE 0 END) as answered,
                SUM(CASE WHEN status = 'closed' THEN 1 ELSE 0 END) as closed
            ")
            ->first();

        return $this->success([
            'settings' => [
                'subjects' => $subjects->map(function (Subject $subject) {
                    $open = (bool) $subject->inquiries_enabled;

                    return [
                        'subject_id' => $subject->id,
                        'subject_name' => $subject->name,
                        'subject_code' => $subject->code,
                        'inquiries_enabled' => $open,
                        'status_label' => $open ? 'مفتوحة' : 'مغلقة',
                        'closed_reason' => $subject->inquiries_closed_reason,
                        'status_message' => $open
                            ? 'الاستفسارات مفتوحة لهذه المادة.'
                            : ($subject->inquiries_closed_reason ?: 'الاستفسارات مغلقة حاليًا لهذه المادة.'),
                    ];
                })->values(),
            ],
            'stats' => [
                'total' => $statsRaw->total ?? 0,
                'forwarded' => $statsRaw->forwarded ?? 0,
                'answered' => $statsRaw->answered ?? 0,
                'closed' => $statsRaw->closed ?? 0,
            ],
            'inquiries' => $inquiries->items(),
            'pagination' => [
                'current_page' => $inquiries->currentPage(),
                'last_page' => $inquiries->lastPage(),
                'per_page' => $inquiries->perPage(),
                'total' => $inquiries->total(),
            ],
        ]);
    }

    public function settings()
    {
        $subjects = Subject::where('doctor_id', Auth::id())
            ->orderBy('name')
            ->get();

        return $this->success([
            'subjects' => $subjects->map(function (Subject $subject) {
                $open = (bool) $subject->inquiries_enabled;

                return [
                    'subject_id' => $subject->id,
                    'subject_name' => $subject->name,
                    'subject_code' => $subject->code,
                    'inquiries_enabled' => $open,
                    'status_label' => $open ? 'مفتوحة' : 'مغلقة',
                    'closed_reason' => $subject->inquiries_closed_reason,
                    'status_message' => $open
                        ? 'الاستفسارات مفتوحة لهذه المادة.'
                        : ($subject->inquiries_closed_reason ?: 'الاستفسارات مغلقة حاليًا لهذه المادة.'),
                ];
            })->values(),
        ]);
    }

    public function show($id)
    {
        $inquiry = Inquiry::visibleToDoctor(Auth::id())
            ->with(['student:id,name,student_number', 'subject:id,name', 'answeredBy:id,name,role'])
            ->findOrFail($id);

        return $this->success($inquiry);
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

        return $this->success([
            'subject' => [
                'subject_id' => $subject->id,
                'subject_name' => $subject->name,
                'subject_code' => $subject->code,
                'inquiries_enabled' => (bool) $subject->inquiries_enabled,
                'status_label' => $subject->inquiries_enabled ? 'مفتوحة' : 'مغلقة',
                'closed_reason' => $subject->inquiries_closed_reason,
            ],
        ], $enabled ? 'تم فتح الاستفسارات لهذه المادة.' : 'تم إغلاق الاستفسارات لهذه المادة.');
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

        return $this->success(null, 'تم الرد على الاستفسار بنجاح.');
    }
}
