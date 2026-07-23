<?php

namespace App\Http\Controllers\Api\Student;

use App\Models\Academic\Subject;
use App\Models\Inquiry;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;

class InquiryController extends StudentApiController
{
    /**
     * Display student's inquiries.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $status = $request->get('status');

        $query = Inquiry::where('student_id', $user->id)
            ->with(['subject.doctor:id,name', 'delegate:id,name', 'answeredBy:id,name,role'])
            ->latest();

        if ($status) {
            $query->where('status', $status);
        }

        $inquiries = $query->paginate(15);

        $stats = [
            'total' => Inquiry::where('student_id', $user->id)->count(),
            'pending' => Inquiry::where('student_id', $user->id)->where('status', 'pending')->count(),
            'answered' => Inquiry::where('student_id', $user->id)->where('status', 'answered')->count(),
        ];

        return $this->success([
            'module' => [
                'name' => 'student_doctor_inquiries',
                'purpose' => 'Student questions that are created against a subject and routed to the responsible doctor.',
                'how_to_use' => 'Use inquiry-options first to get valid doctor + subject choices, then create the inquiry with subject_id, title, and question.',
            ],
            'stats' => $stats,
            'inquiries' => $inquiries,
        ]);
    }

    /**
     * Return available inquiry destinations for the student.
     */
    public function options(Request $request)
    {
        $user = $request->user();
        $subjects = $this->eligibleSubjects($user);

        return $this->success([
            'module' => [
                'name' => 'student_doctor_inquiry_options',
                'purpose' => 'Allowed destinations for creating a new doctor inquiry.',
                'how_to_use' => 'Show each option as doctor name next to subject name. If inquiries are closed, display a clear warning and prevent submission.',
            ],
            'options' => $subjects->map(function (Subject $subject) {
                $doctorName = $subject->doctor?->name ?? 'دكتور غير محدد';
                $open = (bool) ($subject->doctor_id && $subject->inquiries_enabled);
                $closedReason = $subject->inquiries_closed_reason;

                return [
                    'subject_id' => $subject->id,
                    'subject_name' => $subject->name,
                    'subject_code' => $subject->code,
                    'doctor_id' => $subject->doctor?->id,
                    'doctor_name' => $doctorName,
                    'display_label' => $doctorName . ' - ' . $subject->name,
                    'inquiries_enabled' => (bool) $subject->inquiries_enabled,
                    'can_receive_inquiries' => $open,
                    'closed_reason' => $closedReason,
                    'status_label' => $open ? 'مفتوحة' : 'مغلقة',
                    'status_message' => $open
                        ? 'الاستفسارات متاحة لهذه المادة.'
                        : ($closedReason ?: 'هذا الدكتور لا يستقبل استفسارات جديدة على هذه المادة حالياً.'),
                    'label' => $doctorName . ' - ' . $subject->name,
                ];
            })->values(),
        ]);
    }

    /**
     * Store a new inquiry.
     */
    public function store(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'subject_id' => 'required|integer',
            'title' => 'required|string|max:255',
            'question' => 'required|string',
        ]);

        $subject = Subject::with('doctor:id,name')
            ->where('id', $validated['subject_id'])
            ->where('major_id', $user->major_id)
            ->where('level_id', $user->level_id)
            ->first();

        if (!$subject) {
            return $this->error('المادة المختارة غير متاحة لك.', 422, [
                'subject_id' => ['المادة المختارة غير متاحة لك.'],
            ]);
        }

        if (!$subject->doctor_id || !$subject->inquiries_enabled) {
            $doctorName = $subject->doctor?->name ?? 'الدكتور';
            $message = !$subject->doctor_id
                ? 'لا يوجد دكتور مرتبط بهذه المادة حالياً.'
                : 'استفسارات ' . $doctorName . ' لهذه المادة مغلقة حالياً.';

            return $this->error($message, 422, [
                'subject_id' => [$message],
            ]);
        }

        $inquiry = Inquiry::create([
            'student_id' => $user->id,
            'subject_id' => $subject->id,
            'title' => $validated['title'],
            'question' => $validated['question'],
            'status' => 'pending',
        ]);

        $inquiry->load(['subject.doctor:id,name', 'delegate:id,name', 'answeredBy:id,name,role']);

        return $this->success([
            'inquiry' => $inquiry,
        ], 'تم إرسال استفسارك بنجاح وسيتم تحويله للدكتور', 201);
    }

    /**
     * Show a specific inquiry.
     */
    public function show(Request $request, $id)
    {
        $user = $request->user();

        $inquiry = Inquiry::where('student_id', $user->id)
            ->with(['subject.doctor:id,name', 'delegate:id,name', 'answeredBy:id,name,role'])
            ->findOrFail($id);

        return $this->success([
            'inquiry' => $inquiry,
        ]);
    }

    private function eligibleSubjects($user): Collection
    {
        return Subject::with('doctor:id,name')
            ->where('major_id', $user->major_id)
            ->where('level_id', $user->level_id)
            ->orderBy('name')
            ->get();
    }
}
