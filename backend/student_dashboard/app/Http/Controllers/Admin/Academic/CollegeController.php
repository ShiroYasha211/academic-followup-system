<?php

namespace App\Http\Controllers\Admin\Academic;

use App\Http\Controllers\Controller;
use App\Services\AcademicService;
use App\Models\Academic\College;
use App\Models\Academic\University;
use App\Support\OwnerPresentationMode;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CollegeController extends Controller
{
    protected AcademicService $academicService;

    public function __construct(AcademicService $academicService)
    {
        $this->academicService = $academicService;
    }

    /**
     * عرض قائمة الكليات.
     */
    public function index(Request $request)
    {
        $ownerPresentationMode = OwnerPresentationMode::enabledFor($request->user());
        $ownerDefaultUniversity = $ownerPresentationMode
            ? OwnerPresentationMode::defaultUniversity()
            : null;

        // نحتاج الجامعات من أجل القائمة المنسدلة في نموذج الإضافة
        $universities = $this->academicService->getAllUniversities();

        // جلب الكليات مع بيانات الجامعة التابعة لها
        $colleges = College::with('university')->get();

        return view('admin.academic.colleges.index', compact(
            'colleges',
            'universities',
            'ownerPresentationMode',
            'ownerDefaultUniversity'
        ));
    }

    /**
     * تخزين كلية جديدة.
     */
    public function store(Request $request)
    {
        if (OwnerPresentationMode::enabledFor($request->user()) && OwnerPresentationMode::defaultUniversityId()) {
            $request->merge(['university_id' => OwnerPresentationMode::defaultUniversityId()]);
        }

        $request->validate([
            'university_id' => 'required|exists:universities,id',
            'name' => [
                'required',
                'string',
                'max:255',
                // التأكد من عدم تكرار اسم الكلية داخل نفس الجامعة
                Rule::unique('colleges')->where(function ($query) use ($request) {
                    return $query->where('university_id', $request->university_id);
                }),
            ],
        ], [
            'university_id.required' => 'يرجى اختيار الجامعة.',
            'name.unique' => 'اسم الكلية مسجل بالفعل في هذه الجامعة.',
        ]);

        $university = University::findOrFail($request->university_id);

        $this->academicService->createCollege($university, ['name' => $request->name]);

        return redirect()->route('admin.colleges.index')
            ->with('success', 'تم إضافة الكلية بنجاح.');
    }

    /**
     * تحديث بيانات الكلية.
     */
    public function update(Request $request, College $college)
    {
        $request->validate([
            'university_id' => 'required|exists:universities,id',
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('colleges')->where(function ($query) use ($request) {
                    return $query->where('university_id', $request->university_id);
                })->ignore($college->id),
            ],
        ], [
            'university_id.required' => 'يرجى اختيار الجامعة.',
            'name.unique' => 'اسم الكلية مسجل بالفعل في هذه الجامعة.',
        ]);

        $this->academicService->updateCollege($college, [
            'university_id' => $request->university_id,
            'name' => $request->name
        ]);

        return redirect()->route('admin.colleges.index')
            ->with('success', 'تم تحديث الكلية بنجاح.');
    }

    /**
     * حذف كلية.
     */
    public function destroy(College $college)
    {
        // التحقق من وجود تخصصات مرتبطة
        if ($college->majors()->count() > 0) {
            return redirect()->route('admin.colleges.index')
                ->with('error', 'لا يمكن حذف هذه الكلية لأنها تحتوي على تخصصات. قم بحذفها أولاً.');
        }

        $this->academicService->deleteCollege($college);

        return redirect()->route('admin.colleges.index')
            ->with('success', 'تم حذف الكلية بنجاح.');
    }
}
