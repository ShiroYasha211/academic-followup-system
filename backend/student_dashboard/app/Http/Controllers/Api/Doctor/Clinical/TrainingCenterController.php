<?php

namespace App\Http\Controllers\Api\Doctor\Clinical;

use App\Http\Controllers\Api\Doctor\DoctorApiController;
use Illuminate\Http\Request;
use App\Models\Clinical\TrainingCenter;

class TrainingCenterController extends DoctorApiController
{
    /** GET /api/doctor/clinical/training-centers */
    public function index(Request $request)
    {
        $query = TrainingCenter::withCount('cases')
            ->with([
                'cases:id,training_center_id,patient_name,diagnosis_or_description,status',
            ])
            ->latest();
        if ($request->filled('search')) {
            $query->where('name', 'like', "%{$request->search}%");
        }
        $centers = $query->paginate(15);
        return $this->paginated($centers);
    }

    /** POST /api/doctor/clinical/training-centers */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'location' => 'nullable|string|max:255',
            'description' => 'nullable|string|max:1000',
        ]);
        $center = TrainingCenter::create($validated);
        $center->loadCount('cases')->load([
            'cases:id,training_center_id,patient_name,diagnosis_or_description,status',
        ]);
        return $this->success($center, 'تم إضافة المركز التدريبي بنجاح.', 201);
    }

    /** PUT /api/doctor/clinical/training-centers/{id} */
    public function update(Request $request, $id)
    {
        $center = TrainingCenter::findOrFail($id);
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'location' => 'nullable|string|max:255',
            'description' => 'nullable|string|max:1000',
        ]);
        $center->update($validated);
        $center->loadCount('cases')->load([
            'cases:id,training_center_id,patient_name,diagnosis_or_description,status',
        ]);
        return $this->success($center, 'تم تحديث المركز التدريبي بنجاح.');
    }

    /** DELETE /api/doctor/clinical/training-centers/{id} */
    public function destroy($id)
    {
        $center = TrainingCenter::findOrFail($id);
        if ($center->cases()->exists()) {
            return $this->error('لا يمكن حذف هذا المركز لوجود حالات سريرية مرتبطة به.', 422);
        }
        $center->delete();
        return $this->success(null, 'تم مسح المركز التدريبي بنجاح.');
    }
}
