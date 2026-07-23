<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Academic\Subject;
use Illuminate\Http\Request;

class SubjectController extends AdminApiController
{
    public function index(Request $request)
    {
        $query = Subject::with(['term.level.major', 'semester', 'doctor']);
        if ($request->term_id) {
            $query->where('term_id', $request->term_id);
        }
        if ($request->semester_id) {
            $query->where('semester_id', $request->semester_id);
        }
        return $this->success($query->latest()->get());
    }

    public function show(Subject $subject)
    {
        return $this->success($subject->load('term.level.major.college', 'semester', 'doctor'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'term_id' => 'required|exists:terms,id',
            'semester_id' => 'nullable|exists:semesters,id',
            'doctor_id' => [
                'nullable',
                \Illuminate\Validation\Rule::exists('users', 'id')->where(function ($query) {
                    $query->where('role', \App\Enums\UserRole::DOCTOR->value);
                }),
            ],
            'max_absences' => 'required|integer|min:1',
            'lecture_count' => 'nullable|integer|min:0',
        ]);

        $term = \App\Models\Academic\Term::with('level')->findOrFail($request->term_id);

        $subject = Subject::create([
            'name' => $request->name,
            'term_id' => $term->id,
            'semester_id' => $request->semester_id,
            'level_id' => $term->level_id,
            'major_id' => $term->level->major_id,
            'doctor_id' => $request->doctor_id,
            'max_absences' => $request->max_absences,
            'lecture_count' => $request->lecture_count ?? 0,
        ]);
        return $this->success($subject->load('term', 'semester', 'doctor'), 'تم إنشاء المادة بنجاح', 201);
    }

    public function update(Request $request, Subject $subject)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'term_id' => 'required|exists:terms,id',
            'semester_id' => 'nullable|exists:semesters,id',
            'doctor_id' => [
                'nullable',
                \Illuminate\Validation\Rule::exists('users', 'id')->where(function ($query) {
                    $query->where('role', \App\Enums\UserRole::DOCTOR->value);
                }),
            ],
            'max_absences' => 'required|integer|min:1',
            'lecture_count' => 'nullable|integer|min:0',
        ]);

        $term = \App\Models\Academic\Term::with('level')->findOrFail($request->term_id);

        $subject->update([
            'name' => $request->name,
            'term_id' => $term->id,
            'semester_id' => $request->semester_id,
            'level_id' => $term->level_id,
            'major_id' => $term->level->major_id,
            'doctor_id' => $request->doctor_id,
            'max_absences' => $request->max_absences,
            'lecture_count' => $request->lecture_count ?? 0,
        ]);

        return $this->success($subject->fresh()->load('term', 'semester', 'doctor'), 'تم تحديث المادة بنجاح');
    }

    public function destroy(Subject $subject)
    {
        // منع الحذف إذا كان هناك سجلات مرتبطة لحماية البيانات
        if ($subject->attendances()->exists() || $subject->grades()->exists()) {
            return $this->error('لا يمكن حذف المادة لوجود سجلات حضور أو درجات مرتبطة بها.', 422);
        }
        
        $subject->delete();
        return $this->success(null, 'تم حذف المادة بنجاح');
    }
}
