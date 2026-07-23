<?php

namespace App\Http\Controllers\Api\Admin\Clinical;

use App\Http\Controllers\Api\Admin\AdminApiController;
use App\Models\Clinical\ClinicalDepartment;
use Illuminate\Http\Request;

class ClinicalDepartmentController extends AdminApiController
{
    public function index(Request $request)
    {
        $query = ClinicalDepartment::whereNull('doctor_id')->latest();
        
        if ($request->filled('search')) {
            $query->where('name', 'like', '%' . $request->search . '%');
        }
        
        return $this->paginated($query->paginate($request->per_page ?? 15));
    }

    public function show(ClinicalDepartment $clinicalDepartment)
    {
        if ($clinicalDepartment->doctor_id !== null) {
            return $this->error('غير مصرح بالوصول لهذا القسم الجانبي.', 403);
        }
        return $this->success($clinicalDepartment);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000'
        ]);

        $validated['doctor_id'] = null;
        $department = ClinicalDepartment::create($validated);

        return $this->success($department, 'تم إضافة القسم الطبي العام بنجاح.', 201);
    }

    public function update(Request $request, ClinicalDepartment $clinicalDepartment)
    {
        if ($clinicalDepartment->doctor_id !== null) {
            return $this->error('لا يمكن تعديل الأقسام غير العامة.', 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000'
        ]);

        $clinicalDepartment->update($validated);

        return $this->success($clinicalDepartment, 'تم تعديل القسم الطبي العام بنجاح.');
    }

    public function destroy(ClinicalDepartment $clinicalDepartment)
    {
        if ($clinicalDepartment->doctor_id !== null) {
            return $this->error('لا يمكن حذف الأقسام غير العامة.', 403);
        }

        if ($clinicalDepartment->cases()->exists()) {
            return $this->error('لا يمكن حذف هذا القسم العام لوجود حالات سريرية مرتبطة به.', 422);
        }

        $clinicalDepartment->delete();
        return $this->success(null, 'تم مسح القسم الطبي العام بنجاح.');
    }
}
