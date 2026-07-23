<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Academic\Subject;
use App\Models\User;
use App\Enums\UserRole;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AttendanceController extends Controller
{
    /**
     * صفحة اختيار المادة لتسجيل الحضور.
     */
    public function create()
    {
        // عرض المواد المتاحة لاختيار واحدة منها
        $subjects = Subject::with(['level', 'major'])->get();
        return view('admin.attendance.create', compact('subjects'));
    }

    /**
     * عرض قائمة الطلاب لتسجيل الحضور لمادة معينة وتاريخ معين.
     * (الخطوة الثانية بعد اختيار المادة)
     */
    public function showCorrectionForm(Request $request)
    {
        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'date' => 'required|date',
        ]);

        $subject = Subject::findOrFail($request->subject_id);
        $date = $request->date;

        // جلب الطلاب المسجلين في نفس مستوى وتخصص المادة
        // ملاحظة: هذا المنطق بسيء، يمكن تطويره للتحقق من تسجيل الطلاب في مواد محددة لو كان النظام يدعم جداول مخصصة
        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->orderBy('name')
            ->get();

        // جلب الحضور المسجل سابقاً لهذا التاريخ والمادة (إن وجد) لتعبئة النموذج
        $attendanceRecords = Attendance::where('subject_id', $subject->id)
            ->where('date', $date)
            ->get()
            ->keyBy('student_id');

        return view('admin.attendance.form', compact('subject', 'students', 'date', 'attendanceRecords'));
    }

    /**
     * حفظ سجلات الحضور.
     */
    public function store(Request $request)
    {
        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'date' => 'required|date',
            'attendances' => 'required|array',
            'attendances.*' => 'required|in:present,absent,late,excused',
        ]);

        DB::transaction(function () use ($request) {
            foreach ($request->attendances as $studentId => $status) {
                Attendance::updateOrCreate(
                    [
                        'student_id' => $studentId,
                        'subject_id' => $request->subject_id,
                        'date' => $request->date,
                    ],
                    [
                        'status' => $status,
                        'recorded_by' => \Illuminate\Support\Facades\Auth::id(), // الأدمن هو من سجل
                    ]
                );
            }
        });

        return redirect()->route('admin.attendance.create')
            ->with('success', 'تم حفظ سجل الحضور بنجاح للمادة: ' . Subject::find($request->subject_id)->name);
    }
}
