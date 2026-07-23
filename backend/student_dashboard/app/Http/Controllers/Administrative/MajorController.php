<?php

namespace App\Http\Controllers\Administrative;

use App\Http\Controllers\Controller;
use App\Services\AcademicService;
use App\Models\Academic\Major;
use App\Models\Academic\College;
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
     * Display a listing of majors within the admin's college.
     */
    public function index()
    {
        $college = auth()->user()->college;

        if (!$college) {
            abort(403, 'حسابك غير مرتبط بكلية. يرجى التواصل مع مدير النظام.');
        }

        $majors = Major::where('college_id', $college->id)
            ->with(['levels'])
            ->get();

        return view('administrative.majors.index', compact('majors', 'college'));
    }

    /**
     * Store a newly created major and generate its hierarchy.
     */
    public function store(Request $request)
    {
        $college = auth()->user()->college;

        $request->validate([
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('majors')->where(function ($query) use ($college) {
                    return $query->where('college_id', $college->id);
                }),
            ],
            'levels_count' => 'required|integer|min:1|max:8',
            'terms_count' => 'required|integer|min:1|max:4',
            'semesters_per_term' => 'nullable|integer|min:0|max:10',
        ], [
            'name.unique' => 'اسم التخصص مسجل بالفعل في كليتك.',
        ]);

        DB::transaction(function () use ($request, $college) {
            // 1. Create Major
            $major = $this->academicService->createMajor($college, [
                'name' => $request->name,
                'has_clinical' => $request->boolean('has_clinical'),
                'has_semesters' => $request->boolean('has_semesters'),
            ]);

            // 2. Loop to create Levels (Years)
            for ($i = 1; $i <= $request->levels_count; $i++) {
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

        return redirect()->route('administrative.majors.index')
            ->with('success', 'تم إضافة التخصص وإنشاء جميع المستويات والفصول الدراسية بنجاح.');
    }

    /**
     * Update the specified major.
     */
    public function update(Request $request, Major $major)
    {
        $college = auth()->user()->college;

        if ($major->college_id !== $college->id) {
            abort(403);
        }

        $request->validate([
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('majors')->where(function ($query) use ($college) {
                    return $query->where('college_id', $college->id);
                })->ignore($major->id),
            ],
        ], [
            'name.unique' => 'اسم التخصص مسجل بالفعل في كليتك.',
        ]);

        $this->academicService->updateMajor($major, [
            'name' => $request->name,
            'has_clinical' => $request->boolean('has_clinical'),
            'has_semesters' => $request->boolean('has_semesters'),
        ]);

        return redirect()->route('administrative.majors.index')
            ->with('success', 'تم تحديث بيانات التخصص بنجاح.');
    }

    /**
     * Remove the specified major.
     */
    public function destroy(Major $major)
    {
        $college = auth()->user()->college;

        if ($major->college_id !== $college->id) {
            abort(403);
        }

        // Check for students
        $studentsCount = \App\Models\User::where('major_id', $major->id)->count();
        if ($studentsCount > 0) {
            return redirect()->route('administrative.majors.index')
                ->with('error', "لا يمكن حذف هذا التخصص لأنه يحتوي على {$studentsCount} طالب مسجل.");
        }

        // Check for levels
        if ($major->levels()->count() > 0) {
            return redirect()->route('administrative.majors.index')
                ->with('error', 'لا يمكن حذف هذا التخصص لأنه يحتوي على مستويات دراسية. قم بحذفها من الإدارة العامة أولاً.');
        }

        $major->delete();

        return redirect()->route('administrative.majors.index')
            ->with('success', 'تم حذف التخصص بنجاح.');
    }
}
