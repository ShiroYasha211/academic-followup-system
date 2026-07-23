<?php

namespace App\Http\Controllers\Api\Doctor\Clinical;

use App\Http\Controllers\Api\Doctor\DoctorApiController;
use Illuminate\Http\Request;
use App\Models\Clinical\ClinicalDepartment;
use Illuminate\Support\Facades\Auth;

class DepartmentController extends DoctorApiController
{
    /** GET /api/doctor/clinical/departments */
    public function index(Request $request)
    {
        $user = Auth::guard('sanctum')->user();
        $query = ClinicalDepartment::forDoctor($user)->latest();

        if ($request->filled('search')) {
            $query->where('name', 'like', "%{$request->search}%");
        }
        return $this->paginated($query->paginate(15));
    }

    /** POST /api/doctor/clinical/departments */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
        ]);
        
        $validated['doctor_id'] = Auth::guard('sanctum')->id();
        $dept = ClinicalDepartment::create($validated);
        
        return $this->success($dept, 'تم إضافة القسم السريري المخصص بنجاح.', 201);
    }

    /** PUT /api/doctor/clinical/departments/{id} */
    public function update(Request $request, $id)
    {
        $user = Auth::guard('sanctum')->user();
        $dept = ClinicalDepartment::forDoctor($user)->findOrFail($id);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
        ]);

        if (is_null($dept->doctor_id)) {
            // Hide global, create personal
            $user->hiddenClinicalDepartments()->syncWithoutDetaching([$dept->id]);
            $validated['doctor_id'] = $user->id;
            $newDept = ClinicalDepartment::create($validated);
            return $this->success($newDept, 'تم إنشاء نسخة مخصصة من القسم العام بنجاح.');
        } else {
            // Update personal
            $dept->update($validated);
            return $this->success($dept, 'تم تحديث القسم السريري بنجاح.');
        }
    }

    /** DELETE /api/doctor/clinical/departments/{id} */
    public function destroy($id)
    {
        $user = Auth::guard('sanctum')->user();
        $dept = ClinicalDepartment::forDoctor($user)->findOrFail($id);

        if ($dept->cases()->where('doctor_id', $user->id)->exists()) {
            return $this->error('لا يمكن حذف أو إخفاء هذا القسم لوجود حالات سريرية خاصة بك مرتبطة به.', 422);
        }

        if (is_null($dept->doctor_id)) {
            $user->hiddenClinicalDepartments()->syncWithoutDetaching([$dept->id]);
            return $this->success(null, 'تم إخفاء القسم العام من قائمتك بنجاح.');
        } else {
            $dept->delete();
            return $this->success(null, 'تم مسح القسم السريري المخصص بنجاح.');
        }
    }

    public function restoreDefaults()
    {
        Auth::guard('sanctum')->user()->hiddenClinicalDepartments()->detach();
        return $this->success(null, 'تم استرداد الأقسام الأساسية بنجاح.');
    }
}
