<?php

namespace App\Http\Controllers\Admin\Academic;

use App\Http\Controllers\Controller;
use App\Services\AcademicService;
use App\Models\Academic\University;
use Illuminate\Http\Request;

class UniversityController extends Controller
{
    protected AcademicService $academicService;

    public function __construct(AcademicService $academicService)
    {
        $this->academicService = $academicService;
    }

    /**
     * عرض قائمة الجامعات.
     */
    public function index()
    {
        $universities = $this->academicService->getAllUniversities();
        return view('admin.academic.universities.index', compact('universities'));
    }

    /**
     * تخزين جامعة جديدة.
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|unique:universities,name|max:255',
            'code' => 'nullable|string|unique:universities,code|max:50',
            'address' => 'nullable|string|max:500',
            'logo' => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);

        if ($request->hasFile('logo')) {
            $data['logo'] = $request->file('logo')->store('universities', 'public');
        }

        $this->academicService->createUniversity($data);

        return redirect()->route('admin.universities.index')
            ->with('success', 'تم إضافة الجامعة بنجاح.');
    }

    /**
     * تحديث بيانات الجامعة.
     */
    public function update(Request $request, University $university)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255|unique:universities,name,' . $university->id,
            'code' => 'nullable|string|max:50|unique:universities,code,' . $university->id,
            'address' => 'nullable|string|max:500',
            'logo' => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);

        if ($request->hasFile('logo')) {
            $data['logo'] = $request->file('logo')->store('universities', 'public');
        }

        $this->academicService->updateUniversity($university, $data);

        return redirect()->route('admin.universities.index')
            ->with('success', 'تم تحديث بيانات الجامعة بنجاح.');
    }

    /**
     * حذف جامعة.
     */
    public function destroy(University $university)
    {
        // التحقق من وجود كليات مرتبطة
        if ($university->colleges()->count() > 0) {
            return redirect()->route('admin.universities.index')
                ->with('error', 'لا يمكن حذف هذه الجامعة لأنها تحتوي على كليات. قم بحذفها أولاً.');
        }

        $this->academicService->deleteUniversity($university);

        return redirect()->route('admin.universities.index')
            ->with('success', 'تم حذف الجامعة بنجاح.');
    }
}
