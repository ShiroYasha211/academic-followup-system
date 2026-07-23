<?php

namespace App\Http\Controllers\Admin\Academic;

use App\Http\Controllers\Controller;
use App\Services\AcademicService;
use App\Models\Academic\Level;
use App\Models\Academic\Major;
use App\Models\Academic\College;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class LevelController extends Controller
{
    protected AcademicService $academicService;

    public function __construct(AcademicService $academicService)
    {
        $this->academicService = $academicService;
    }

    /**
     * عرض قائمة المستويات.
     */
    public function index()
    {
        // جلب الكليات مع التخصصات لعمل قائمة منسدلة
        $colleges = College::with('majors')->get();

        // جلب المستويات للعرض
        $levels = Level::with('major.college')->get();

        return view('admin.academic.levels.index', compact('levels', 'colleges'));
    }

    /**
     * تخزين مستوى جديد.
     */
    public function store(Request $request)
    {
        $request->validate([
            'major_id' => 'required|exists:majors,id',
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('levels')->where(function ($query) use ($request) {
                    return $query->where('major_id', $request->major_id);
                }),
            ],
        ], [
            'major_id.required' => 'يرجى اختيار التخصص.',
            'name.unique' => 'اسم المستوى مسجل بالفعل لهذا التخصص.',
        ]);

        $major = Major::findOrFail($request->major_id);

        $this->academicService->createLevel($major, ['name' => $request->name]);

        return redirect()->route('admin.levels.index')
            ->with('success', 'تم إضافة المستوى بنجاح.');
    }

    /**
     * حذف مستوى.
     */
    public function destroy(Level $level)
    {
        // التحقق من وجود طلاب في هذا المستوى
        $studentsCount = \App\Models\User::where('level_id', $level->id)->count();
        if ($studentsCount > 0) {
            return redirect()->route('admin.levels.index')
                ->with('error', "لا يمكن حذف هذا المستوى لأنه يحتوي على {$studentsCount} طالب مسجل.");
        }

        // التحقق من وجود فصول دراسية (ترمات)
        if ($level->terms()->count() > 0) {
            return redirect()->route('admin.levels.index')
                ->with('error', 'لا يمكن حذف هذا المستوى لأنه يحتوي على فصول دراسية. قم بحذفها أولاً.');
        }

        $level->delete();

        return redirect()->route('admin.levels.index')
            ->with('success', 'تم حذف المستوى بنجاح.');
    }
}
