<?php

namespace App\Http\Controllers\Admin\Academic;

use App\Http\Controllers\Controller;
use App\Services\AcademicService;
use App\Models\Academic\Term;
use App\Models\Academic\Level;
use App\Models\Academic\Major;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class TermController extends Controller
{
    protected AcademicService $academicService;

    public function __construct(AcademicService $academicService)
    {
        $this->academicService = $academicService;
    }

    /**
     * عرض قائمة الفصول الدراسية.
     */
    public function index()
    {
        // جلب التخصصات مع المستويات
        $majors = Major::with('levels')->get();

        // جلب التيرمات للعرض
        $terms = Term::with('level.major')->get();

        return view('admin.academic.terms.index', compact('terms', 'majors'));
    }

    /**
     * تخزين فصل دراسي جديد.
     */
    public function store(Request $request)
    {
        $request->validate([
            'level_id' => 'required|exists:levels,id',
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('terms')->where(function ($query) use ($request) {
                    return $query->where('level_id', $request->level_id);
                }),
            ],
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
        ], [
            'level_id.required' => 'يرجى اختيار المستوى.',
            'name.unique' => 'اسم الترم مسجل بالفعل لهذا المستوى.',
            'end_date.after_or_equal' => 'تاريخ النهاية يجب أن يكون بعد أو يساوي تاريخ البداية.',
        ]);

        $level = Level::findOrFail($request->level_id);

        $this->academicService->createTerm($level, [
            'name' => $request->name,
            'start_date' => $request->start_date,
            'end_date' => $request->end_date,
        ]);

        return redirect()->route('admin.terms.index')
            ->with('success', 'تم إضافة الفصل الدراسي بنجاح.');
    }

    /**
     * حذف فصل دراسي.
     */
    public function destroy(Term $term)
    {
        // التحقق من وجود مواد مرتبطة بهذا الفصل
        if ($term->subjects()->count() > 0) {
            return redirect()->route('admin.terms.index')
                ->with('error', 'لا يمكن حذف هذا الفصل الدراسي لأنه يحتوي على مواد دراسية. قم بحذفها أولاً.');
        }

        $term->delete();

        return redirect()->route('admin.terms.index')
            ->with('success', 'تم حذف الفصل الدراسي بنجاح.');
    }
}
