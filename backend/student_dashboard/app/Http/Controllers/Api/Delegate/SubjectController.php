<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\Delegate\DelegateApiController;
use App\Models\Academic\Semester;
use App\Models\Academic\Subject;
use App\Models\Academic\Term;
use App\Models\User;
use App\Enums\UserRole;

use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;

class SubjectController extends DelegateApiController implements HasMiddleware
{
    /**
     * Get the middleware that should be assigned to the controller.
     */
    public static function middleware(): array
    {
        return [
            new Middleware('delegate.permission:subjects,create', only: ['store']),
            new Middleware('delegate.permission:subjects,update', only: ['update']),
            new Middleware('delegate.permission:subjects,delete', only: ['destroy']),
        ];
    }
    /**
     * Display a listing of subjects for the delegate's batch.
     */
    public function index(Request $request)
    {
        $delegate = $request->user();

        $subjects = Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->with(['doctor:id,name', 'term:id,name', 'semester:id,name,term_id']);

        return $this->success($subjects->orderBy('name')->get(), 'تم جلب المواد بنجاح');
    }

    /**
     * Store a newly created subject in the delegate's batch.
     */
    public function store(Request $request)
    {
        $delegate = $request->user();

        $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|max:50',
            'term_id' => 'required|exists:terms,id',
            'semester_id' => 'nullable|exists:semesters,id',
            'doctor_id' => 'required|exists:users,id',
        ]);

        // Ensure the term belongs to the delegate's level
        $term = Term::findOrFail($request->term_id);
        if ($term->level_id != $delegate->level_id) {
            return $this->error('غير مصرح بإضافة مادة في ترم خارج مستواك الأكاديمي.', 403);
        }

        $semesterId = $this->resolveSemesterId($request, $delegate, $term);
        if ($semesterId instanceof \Illuminate\Http\JsonResponse) {
            return $semesterId;
        }

        // Ensure doctor_id belongs to a Doctor
        $doctor = User::findOrFail($request->doctor_id);
        if ($doctor->role != UserRole::DOCTOR) {
            return $this->error('المستخدم المحدد ليس دكتوراً.', 422);
        }

        $subject = Subject::create([
            'name' => $request->name,
            'code' => $request->code,
            'term_id' => $request->term_id,
            'semester_id' => $semesterId,
            'doctor_id' => $request->doctor_id,
            'level_id' => $delegate->level_id,
            'major_id' => $delegate->major_id,
        ]);

        return $this->success($subject, 'تم إضافة المادة الدراسية بنجاح', 201);
    }

    /**
     * Display the specified subject with its resources & assignments.
     */
    public function show(Request $request, Subject $subject)
    {
        $delegate = $request->user();

        // Ensure subject belongs to delegate scope
        if ($subject->major_id != $delegate->major_id || $subject->level_id != $delegate->level_id) {
            return $this->error('المادة غير موجودة أو غير مصرح لك بالوصول', 404);
        }

        $subject->load(['doctor:id,name', 'term:id,name', 'semester:id,name,term_id', 'resources', 'assignments']);

        return $this->success($subject, 'تم جلب بيانات المادة بنجاح');
    }

    /**
     * Update the specified subject.
     */
    public function update(Request $request, Subject $subject)
    {
        $delegate = $request->user();

        if ($subject->major_id != $delegate->major_id || $subject->level_id != $delegate->level_id) {
            return $this->error('غير مصرح لك بتعديل هذه المادة', 403);
        }

        $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|max:50',
            'term_id' => 'required|exists:terms,id',
            'semester_id' => 'nullable|exists:semesters,id',
            'doctor_id' => 'required|exists:users,id',
        ]);

        // Ensure the term belongs to the delegate's level
        $term = Term::findOrFail($request->term_id);
        if ($term->level_id != $delegate->level_id) {
            return $this->error('غير مصرح بتعديل المادة لترم خارج مستواك الأكاديمي.', 403);
        }

        // Ensure doctor_id belongs to a Doctor
        $doctor = User::findOrFail($request->doctor_id);
        if ($doctor->role != UserRole::DOCTOR) {
            return $this->error('المستخدم المحدد ليس دكتوراً.', 422);
        }

        $subject->update([
            'name' => $request->name,
            'code' => $request->code,
            'term_id' => $request->term_id,
            'semester_id' => $this->resolveSemesterId($request, $delegate, $term),
            'doctor_id' => $request->doctor_id,
        ]);

        return $this->success($subject, 'تم تحديث بيانات المادة الدراسية بنجاح');
    }

    /**
     * Remove the specified subject.
     */
    public function destroy(Request $request, Subject $subject)
    {
        $delegate = $request->user();

        if ($subject->major_id != $delegate->major_id || $subject->level_id != $delegate->level_id) {
            return $this->error('غير مصرح لك بحذف هذه المادة', 403);
        }

        $attendanceCount = \App\Models\Attendance::where('subject_id', $subject->id)->count();
        if ($attendanceCount > 0) {
            return $this->error("لا يمكن حذف هذه المادة لأنها تحتوي على {$attendanceCount} سجل حضور.", 422);
        }

        $subject->delete();

        return $this->success(null, 'تم حذف المادة الدراسية بنجاح');
    }

    /**
     * List all doctors for selection.
     */
    public function doctors()
    {
        $doctors = User::where('role', UserRole::DOCTOR)
            ->orderBy('name')
            ->get(['id', 'name', 'avatar']);
        
        return $this->success($doctors, 'تم جلب قائمة الدكاترة');
    }

    /**
     * List terms for delegate's level for selection.
     */
    public function terms(Request $request)
    {
        $delegate = $request->user();
        $terms = Term::where('level_id', $delegate->level_id)
            ->with(['semesters:id,term_id,name'])
            ->get(['id', 'name']);
        $terms = [
            'terms' => $terms,
            'major' => [
                'id' => $delegate->major_id,
                'has_semesters' => (bool) optional($delegate->major)->has_semesters,
            ],
        ];
        
        return $this->success($terms, 'تم جلب قائمة الأترام الدراسية');
    }

    private function resolveSemesterId(Request $request, User $delegate, Term $term)
    {
        if (! optional($delegate->major)->has_semesters) {
            return null;
        }

        if (! $request->filled('semester_id')) {
            throw \Illuminate\Validation\ValidationException::withMessages([
                'semester_id' => 'يرجى اختيار السيمستر الدراسي.',
            ]);
        }

        $semester = Semester::findOrFail($request->semester_id);
        if ((int) $semester->term_id !== (int) $term->id) {
            throw \Illuminate\Validation\ValidationException::withMessages([
                'semester_id' => 'السيمستر المختار لا يتبع الترم الدراسي المحدد.',
            ]);
        }

        return (int) $semester->id;
    }
}
