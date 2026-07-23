<?php

namespace App\Http\Controllers\Admin\Academic;

use App\Http\Controllers\Controller;
use App\Models\Academic\Subject;
use App\Models\Academic\Term;
use App\Models\User;
use App\Enums\UserRole;
use App\Traits\LogsActivity;
use Illuminate\Http\Request;

class SubjectController extends Controller
{
    use LogsActivity;

    /**
     * عرض قائمة المواد مع نموذج الإضافة.
     */
    public function index()
    {
        // جلب المواد للعرض في الجدول
        $subjects = Subject::with(['major', 'level', 'term', 'doctor'])
            ->latest()
            ->paginate(10); // Pagination kept for subjects as they can be numerous

        // بيانات لنموذج الإضافة (Dropdowns)
        $terms = Term::with('level.major.college')->get();
        $doctors = User::where('role', UserRole::DOCTOR)->get();

        return view('admin.academic.subjects.index', compact('subjects', 'terms', 'doctors'));
    }

    /**
     * حفظ مادة جديدة.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|max:50',
            'term_id' => 'required|exists:terms,id',
            'semester_id' => 'nullable|exists:semesters,id',
            'doctor_id' => 'nullable|exists:users,id',
        ], [
            'term_id.required' => 'يرجى اختيار الترم (الفصل الدراسي) لهذه المادة.',
        ]);

        $term = Term::with('level.major')->findOrFail($request->term_id);

        $subject = Subject::create([
            'name' => $request->name,
            'code' => $request->code,
            'description' => $request->description,
            'term_id' => $term->id,
            'semester_id' => $request->semester_id,
            'level_id' => $term->level_id,
            'major_id' => $term->level->major_id,
            'doctor_id' => $request->doctor_id,
        ]);

        $this->logCreate('Subject', $subject, "تم إضافة مادة: {$subject->name}");

        return redirect()->route('admin.subjects.index')
            ->with('success', 'تم إضافة المادة الدراسية بنجاح.');
    }

    /**
     * تحديث بيانات المادة.
     */
    public function update(Request $request, Subject $subject)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|max:50',
            'term_id' => 'required|exists:terms,id',
            'semester_id' => 'nullable|exists:semesters,id',
            'doctor_id' => 'nullable|exists:users,id',
        ]);

        $updateData = [
            'name' => $request->name,
            'code' => $request->code,
            'semester_id' => $request->semester_id,
            'doctor_id' => $request->doctor_id,
        ];

        // If term changed, we must update the hierarchy fields (major, level)
        if ($request->term_id != $subject->term_id) {
            $term = Term::with('level.major')->findOrFail($request->term_id);

            $updateData['term_id'] = $term->id;
            $updateData['level_id'] = $term->level_id;
            $updateData['major_id'] = $term->level->major_id;
        }

        $subject->update($updateData);

        $this->logUpdate('Subject', $subject, "تم تعديل مادة: {$subject->name}");

        return redirect()->route('admin.subjects.index')
            ->with('success', 'تم تحديث بيانات المادة بنجاح.');
    }

    /**
     * حذف مادة.
     */
    public function destroy(Subject $subject)
    {
        // التحقق من وجود سجلات حضور مرتبطة
        $attendanceCount = \App\Models\Attendance::where('subject_id', $subject->id)->count();
        if ($attendanceCount > 0) {
            return redirect()->route('admin.subjects.index')
                ->with('error', "لا يمكن حذف هذه المادة لأنها تحتوي على {$attendanceCount} سجل حضور.");
        }

        $this->logDelete('Subject', $subject, "تم حذف مادة: {$subject->name}");

        $subject->delete();
        return redirect()->route('admin.subjects.index')
            ->with('success', 'تم حذف المادة بنجاح.');
    }
}
