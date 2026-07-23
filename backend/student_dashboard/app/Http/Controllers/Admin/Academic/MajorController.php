<?php

namespace App\Http\Controllers\Admin\Academic;

use App\Http\Controllers\Controller;
use App\Services\AcademicService;
use App\Models\Academic\Major;
use App\Models\Academic\College;
use App\Models\Academic\University;
use App\Models\Academic\Semester;
use App\Support\OwnerPresentationMode;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\DB;

class MajorController extends Controller
{
    protected AcademicService $academicService;

    public function __construct(AcademicService $academicService)
    {
        $this->academicService = $academicService;
    }

    /**
     * عرض قائمة التخصصات.
     */
    public function index(Request $request)
    {
        $ownerPresentationMode = OwnerPresentationMode::enabledFor($request->user());
        $ownerDefaultUniversityId = $ownerPresentationMode
            ? OwnerPresentationMode::defaultUniversityId()
            : null;

        $universities = University::with('colleges')
            ->when($ownerDefaultUniversityId, fn ($query) => $query->whereKey($ownerDefaultUniversityId))
            ->get();

        $colleges = College::with('university')
            ->when($ownerDefaultUniversityId, fn ($query) => $query->where('university_id', $ownerDefaultUniversityId))
            ->get();

        // جلب التخصصات مع مستوياتها لعرض الإحصائيات
        $majors = Major::with(['college.university', 'levels'])->get();

        return view('admin.academic.majors.index', compact(
            'majors',
            'universities',
            'colleges',
            'ownerPresentationMode',
            'ownerDefaultUniversityId'
        ));
    }

    /**
     * تخزين تخصص جديد وإنشاء الهيكل تلقائياً.
     */
    public function store(Request $request)
    {
        $request->validate([
            'college_id' => 'required|exists:colleges,id',
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('majors')->where(function ($query) use ($request) {
                    return $query->where('college_id', $request->college_id);
                }),
            ],
            'levels_count' => 'required|integer|min:1|max:8',
            'terms_count' => 'required|integer|min:1|max:4',
            'semesters_per_term' => 'nullable|integer|min:0|max:10',
        ], [
            'college_id.required' => 'يرجى اختيار الكلية.',
            'name.unique' => 'اسم التخصص مسجل بالفعل في هذه الكلية.',
        ]);

        // استخدام Transaction لضمان إنشاء الهيكل كاملاً أو عدمه
        DB::transaction(function () use ($request) {

            $college = College::findOrFail($request->college_id);

            // 1. Create Major
            $major = $this->academicService->createMajor($college, [
                'name' => $request->name,
                'has_clinical' => $request->boolean('has_clinical'),
                'has_semesters' => $request->boolean('has_semesters'),
            ]);

            // 2. Loop to create Levels (Years)
            for ($i = 1; $i <= $request->levels_count; $i++) {
                // Determine name based on locale or standard (Level 1, Level 2...)
                $levelName = "المستوى $i";

                $level = $this->academicService->createLevel($major, ['name' => $levelName]);

                // 3. Loop to create Terms for each Level
                for ($j = 1; $j <= $request->terms_count; $j++) {
                    $termName = "الترم $j";

                    $term = $this->academicService->createTerm($level, ['name' => $termName]);

                    // 4. Loop to create Semesters if major has them
                    if ($major->has_semesters && $request->semesters_per_term > 0) {
                        for ($k = 1; $k <= $request->semesters_per_term; $k++) {
                            $semesterName = "سيمستر $k";
                            $this->academicService->createSemester($term, ['name' => $semesterName]);
                        }
                    }
                }
            }
        });

        return redirect()->route('admin.majors.index')
            ->with('success', 'تم إضافة التخصص وإنشاء جميع المستويات والفصول الدراسية بنجاح.');
    }


    /**
     * تحديث بيانات التخصص.
     */
    public function update(Request $request, Major $major)
    {
        $request->validate([
            'college_id' => 'required|exists:colleges,id',
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('majors')->where(function ($query) use ($request) {
                    return $query->where('college_id', $request->college_id);
                })->ignore($major->id),
            ],
        ], [
            'college_id.required' => 'يرجى اختيار الكلية.',
            'name.unique' => 'اسم التخصص مسجل بالفعل في هذه الكلية.',
        ]);

        $this->academicService->updateMajor($major, [
            'college_id' => $request->college_id,
            'name' => $request->name,
            'has_clinical' => $request->boolean('has_clinical'),
            'has_semesters' => $request->boolean('has_semesters'),
        ]);

        return redirect()->route('admin.majors.index')
            ->with('success', 'تم تحديث بيانات التخصص بنجاح.');
    }

    /**
     * حذف تخصص.
     */
    public function destroy(Major $major)
    {
        // التحقق من وجود طلاب في هذا التخصص
        $studentsCount = \App\Models\User::where('major_id', $major->id)->count();
        if ($studentsCount > 0) {
            return redirect()->route('admin.majors.index')
                ->with('error', "لا يمكن حذف هذا التخصص لأنه يحتوي على {$studentsCount} طالب مسجل.");
        }

        // التحقق من وجود مستويات
        if ($major->levels()->count() > 0) {
            return redirect()->route('admin.majors.index')
                ->with('error', 'لا يمكن حذف هذا التخصص لأنه يحتوي على مستويات دراسية. قم بحذفها أولاً.');
        }

        $major->delete();

        return redirect()->route('admin.majors.index')
            ->with('success', 'تم حذف التخصص بنجاح.');
    }
}
