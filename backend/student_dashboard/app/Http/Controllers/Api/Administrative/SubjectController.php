<?php

namespace App\Http\Controllers\Api\Administrative;

use App\Enums\UserRole;
use App\Models\Academic\Subject;
use App\Models\Academic\Term;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class SubjectController extends AdministrativeApiController
{
    public function index(Request $request)
    {
        $majorIds = $this->collegeMajorIds();

        $query = Subject::whereIn('major_id', $majorIds)
            ->with(['major:id,name', 'level:id,name', 'term:id,name,level_id', 'semester:id,name,term_id', 'doctor:id,name']);

        if ($request->filled('search')) {
            $query->where(function ($q) use ($request) {
                $q->where('name', 'like', "%{$request->search}%")
                    ->orWhere('code', 'like', "%{$request->search}%");
            });
        }

        if ($request->filled('major_id')) {
            $majorId = $request->integer('major_id');
            if ($majorIds->contains($majorId)) {
                $query->where('major_id', $majorId);
            }
        }

        if ($request->filled('level_id')) {
            $query->where('level_id', $request->integer('level_id'));
        }

        if ($request->filled('term_id')) {
            $query->where('term_id', $request->integer('term_id'));
        }

        if ($request->filled('doctor_id')) {
            $query->where('doctor_id', $request->integer('doctor_id'));
        }

        $subjects = $query->latest()->paginate($request->integer('per_page', 15));

        $terms = Term::whereIn('level_id', function ($query) use ($majorIds) {
            $query->select('id')->from('levels')->whereIn('major_id', $majorIds);
        })->with(['level.major', 'semesters:id,name,term_id'])->get();

        $doctors = User::where('college_id', $this->college()->id)
            ->where('role', UserRole::DOCTOR)
            ->get(['id', 'name']);

        return $this->success([
            'subjects' => $subjects->items(),
            'pagination' => [
                'current_page' => $subjects->currentPage(),
                'last_page' => $subjects->lastPage(),
                'per_page' => $subjects->perPage(),
                'total' => $subjects->total(),
            ],
            'terms' => $terms,
            'doctors' => $doctors,
        ]);
    }

    public function store(Request $request)
    {
        $college = $this->college();
        $majorIds = $this->collegeMajorIds();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|max:50',
            'description' => 'nullable|string',
            'term_id' => [
                'required',
                'exists:terms,id',
                function ($attribute, $value, $fail) use ($majorIds) {
                    $term = Term::with('level')->find($value);
                    if (!$term || !in_array($term->level->major_id, $majorIds->all(), true)) {
                        $fail('الترم المحدد لا ينتمي إلى كليتك.');
                    }
                },
            ],
            'doctor_id' => [
                'nullable',
                Rule::exists('users', 'id')->where(function ($query) use ($college) {
                    $query->where('college_id', $college->id)->where('role', UserRole::DOCTOR->value);
                }),
            ],
            'semester_id' => 'nullable|integer',
        ]);

        $term = Term::with('level')->findOrFail($validated['term_id']);

        $subject = Subject::create([
            'name' => $validated['name'],
            'code' => $validated['code'] ?? null,
            'description' => $validated['description'] ?? null,
            'term_id' => $term->id,
            'semester_id' => $validated['semester_id'] ?? null,
            'level_id' => $term->level_id,
            'major_id' => $term->level->major_id,
            'doctor_id' => $validated['doctor_id'] ?? null,
        ]);

        return $this->success($subject->load(['major:id,name', 'level:id,name', 'term:id,name', 'semester:id,name,term_id', 'doctor:id,name']), 'تم إضافة المادة بنجاح', 201);
    }

    public function show(Subject $subject)
    {
        $this->ensureCollegeSubject($subject);
        return $this->success($subject->load(['major:id,name', 'level:id,name', 'term:id,name', 'semester:id,name,term_id', 'doctor:id,name']));
    }

    public function update(Request $request, Subject $subject)
    {
        $this->ensureCollegeSubject($subject);
        $college = $this->college();
        $majorIds = $this->collegeMajorIds();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|max:50',
            'description' => 'nullable|string',
            'term_id' => [
                'required',
                'exists:terms,id',
                function ($attribute, $value, $fail) use ($majorIds) {
                    $term = Term::with('level')->find($value);
                    if (!$term || !in_array($term->level->major_id, $majorIds->all(), true)) {
                        $fail('الترم المحدد لا ينتمي إلى كليتك.');
                    }
                },
            ],
            'doctor_id' => [
                'nullable',
                Rule::exists('users', 'id')->where(function ($query) use ($college) {
                    $query->where('college_id', $college->id)->where('role', UserRole::DOCTOR->value);
                }),
            ],
            'semester_id' => 'nullable|integer',
        ]);

        $updateData = [
            'name' => $validated['name'],
            'code' => $validated['code'] ?? null,
            'description' => $validated['description'] ?? null,
            'semester_id' => $validated['semester_id'] ?? null,
            'doctor_id' => $validated['doctor_id'] ?? null,
        ];

        if ((int) $validated['term_id'] !== (int) $subject->term_id) {
            $term = Term::with('level')->findOrFail($validated['term_id']);
            $updateData['term_id'] = $term->id;
            $updateData['level_id'] = $term->level_id;
            $updateData['major_id'] = $term->level->major_id;
        }

        $subject->update($updateData);

        return $this->success($subject->fresh()->load(['major:id,name', 'level:id,name', 'term:id,name', 'semester:id,name,term_id', 'doctor:id,name']), 'تم تحديث المادة بنجاح');
    }

    public function destroy(Subject $subject)
    {
        $this->ensureCollegeSubject($subject);

        $attendanceCount = \App\Models\Attendance::where('subject_id', $subject->id)->count();
        if ($attendanceCount > 0) {
            return $this->error("لا يمكن حذف المادة لوجود {$attendanceCount} سجل حضور مرتبط بها.", 422);
        }

        $subject->delete();
        return $this->success(null, 'تم حذف المادة بنجاح');
    }
}
