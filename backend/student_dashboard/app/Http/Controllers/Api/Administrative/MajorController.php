<?php

namespace App\Http\Controllers\Api\Administrative;

use App\Models\Academic\Major;
use App\Services\AcademicService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class MajorController extends AdministrativeApiController
{
    public function __construct(protected AcademicService $academicService)
    {
    }

    public function index()
    {
        $majors = Major::where('college_id', $this->college()->id)
            ->with('levels.terms')
            ->withCount('levels')
            ->get();

        return $this->success($majors);
    }

    public function store(Request $request)
    {
        $college = $this->college();

        $validated = $request->validate([
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('majors')->where(fn ($query) => $query->where('college_id', $college->id)),
            ],
            'levels_count' => 'required|integer|min:1|max:8',
            'terms_count' => 'required|integer|min:1|max:4',
            'semesters_per_term' => 'nullable|integer|min:0|max:10',
            'has_clinical' => 'nullable|boolean',
            'has_semesters' => 'nullable|boolean',
        ]);

        $major = null;

        DB::transaction(function () use ($validated, $college, &$major) {
            $major = $this->academicService->createMajor($college, [
                'name' => $validated['name'],
                'has_clinical' => (bool) ($validated['has_clinical'] ?? false),
                'has_semesters' => (bool) ($validated['has_semesters'] ?? false),
            ]);

            for ($i = 1; $i <= $validated['levels_count']; $i++) {
                $level = $this->academicService->createLevel($major, ['name' => "المستوى {$i}"]);

                for ($j = 1; $j <= $validated['terms_count']; $j++) {
                    $term = $this->academicService->createTerm($level, ['name' => "الترم {$j}"]);

                    if ($major->has_semesters && ($validated['semesters_per_term'] ?? 0) > 0) {
                        for ($k = 1; $k <= $validated['semesters_per_term']; $k++) {
                            $this->academicService->createSemester($term, ['name' => "سيستم {$k}"]);
                        }
                    }
                }
            }
        });

        return $this->success($major->load('levels.terms'), 'تم إضافة التخصص بنجاح', 201);
    }

    public function show(Major $major)
    {
        $this->ensureCollegeMajor($major);
        return $this->success($major->load('levels.terms'));
    }

    public function update(Request $request, Major $major)
    {
        $this->ensureCollegeMajor($major);

        $validated = $request->validate([
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('majors')->where(fn ($query) => $query->where('college_id', $this->college()->id))->ignore($major->id),
            ],
            'has_clinical' => 'nullable|boolean',
            'has_semesters' => 'nullable|boolean',
        ]);

        $this->academicService->updateMajor($major, [
            'name' => $validated['name'],
            'has_clinical' => (bool) ($validated['has_clinical'] ?? false),
            'has_semesters' => (bool) ($validated['has_semesters'] ?? false),
        ]);

        return $this->success($major->fresh()->load('levels.terms'), 'تم تحديث بيانات التخصص بنجاح');
    }

    public function destroy(Major $major)
    {
        $this->ensureCollegeMajor($major);

        $studentsCount = \App\Models\User::where('major_id', $major->id)->count();
        if ($studentsCount > 0) {
            return $this->error("لا يمكن حذف هذا التخصص لوجود {$studentsCount} طالب مسجل عليه.", 422);
        }

        if ($major->levels()->count() > 0) {
            return $this->error('لا يمكن حذف هذا التخصص لاحتوائه على مستويات دراسية.', 422);
        }

        $major->delete();

        return $this->success(null, 'تم حذف التخصص بنجاح');
    }

    public function getLevels(Major $major)
    {
        $this->ensureCollegeMajor($major);
        return $this->success($major->levels()->get(['id', 'name', 'major_id']));
    }
}
