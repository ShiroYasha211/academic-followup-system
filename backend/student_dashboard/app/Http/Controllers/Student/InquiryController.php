<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Inquiry;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Collection;

class InquiryController extends Controller
{
    /**
     * Display student's inquiries.
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        $status = $request->get('status');

        $query = Inquiry::where('student_id', $user->id)
            ->with(['subject', 'delegate', 'answeredBy'])
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

        return view('student.inquiries.index', compact('inquiries', 'stats', 'status'));
    }

    /**
     * Show inquiry creation form.
     */
    public function create()
    {
        $user = Auth::user();

        $subjects = $this->eligibleSubjects($user);

        return view('student.inquiries.create', compact('subjects'));
    }

    /**
     * Store a new inquiry.
     */
    public function store(Request $request)
    {
        $user = Auth::user();

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
            return back()
                ->withErrors(['subject_id' => 'المادة المختارة غير متاحة لك.'])
                ->withInput();
        }

        if (!$subject->doctor_id || !$subject->inquiries_enabled) {
            $doctorName = $subject->doctor?->name ?? 'الدكتور';
            $message = !$subject->doctor_id
                ? 'لا يوجد دكتور مرتبط بهذه المادة حالياً.'
                : 'استفسارات ' . $doctorName . ' لهذه المادة مغلقة حالياً.';

            return back()
                ->withErrors(['subject_id' => $message])
                ->withInput();
        }

        Inquiry::create([
            'student_id' => $user->id,
            'subject_id' => $subject->id,
            'title' => $validated['title'],
            'question' => $validated['question'],
            'status' => 'pending',
        ]);

        return redirect()->route('student.inquiries.index')
            ->with('success', 'تم إرسال استفسارك بنجاح وسيتم تحويله للدكتور');
    }

    /**
     * Show a specific inquiry.
     */
    public function show($id)
    {
        $user = Auth::user();

        $inquiry = Inquiry::where('student_id', $user->id)
            ->with(['subject', 'delegate', 'answeredBy'])
            ->findOrFail($id);

        return view('student.inquiries.show', compact('inquiry'));
    }

    private function eligibleSubjects($user): Collection
    {
        return Subject::with(['doctor:id,name'])
            ->where('major_id', $user->major_id)
            ->where('level_id', $user->level_id)
            ->orderBy('name')
            ->get();
    }
}
