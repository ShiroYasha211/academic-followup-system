<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Academic\Major;
use App\Models\Academic\College;
use App\Services\AcademicService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class MajorController extends AdminApiController
{
    protected AcademicService $academicService;

    public function __construct(AcademicService $academicService)
    {
        $this->academicService = $academicService;
    }

    public function index(Request $request)
    {
        $query = Major::with('college.university')->withCount('levels');
        if ($request->college_id) {
            $query->where('college_id', $request->college_id);
        }
        return $this->success($query->latest()->get());
    }

    public function show(Major $major)
    {
        return $this->success($major->load('college.university', 'levels.terms.subjects'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'college_id' => 'required|exists:colleges,id',
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('majors')->where(fn($q) => $q->where('college_id', $request->college_id)),
            ],
            'levels_count' => 'required|integer|min:1|max:8',
            'terms_count' => 'required|integer|min:1|max:4',
            'has_clinical' => 'boolean',
        ]);

        $major = null;

        DB::transaction(function () use ($request, &$major) {
            $college = College::findOrFail($request->college_id);

            $major = $this->academicService->createMajor($college, [
                'name' => $request->name,
                'has_clinical' => $request->boolean('has_clinical'),
            ]);

            for ($i = 1; $i <= $request->levels_count; $i++) {
                $level = $this->academicService->createLevel($major, ['name' => "المستوى $i"]);
                for ($j = 1; $j <= $request->terms_count; $j++) {
                    $this->academicService->createTerm($level, ['name' => "الترم $j"]);
                }
            }
        });

        return $this->success($major->load('levels.terms'), 'تم إنشاء التخصص بنجاح', 201);
    }

    public function update(Request $request, Major $major)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'college_id' => 'required|exists:colleges,id',
            'has_clinical' => 'boolean',
        ]);

        $this->academicService->updateMajor($major, [
            'college_id' => $request->college_id,
            'name' => $request->name,
            'has_clinical' => $request->boolean('has_clinical'),
        ]);

        return $this->success($major->fresh(), 'تم تحديث التخصص بنجاح');
    }

    public function destroy(Major $major)
    {
        // Enforce data integrity: check for both levels and students
        if ($major->levels()->exists() || $major->students()->exists()) {
            return $this->error('لا يمكن حذف التخصص لوجود مستويات أو طلاب مسجلين به.', 422);
        }
        $major->delete();
        return $this->success(null, 'تم حذف التخصص بنجاح');
    }

    public function getLevels(Major $major)
    {
        return $this->success($major->levels);
    }
}
