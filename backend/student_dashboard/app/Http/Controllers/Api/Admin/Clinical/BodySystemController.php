<?php

namespace App\Http\Controllers\Api\Admin\Clinical;

use App\Http\Controllers\Api\Admin\AdminApiController;
use App\Models\Clinical\BodySystem;
use Illuminate\Http\Request;

class BodySystemController extends AdminApiController
{
    public function index(Request $request)
    {
        $query = BodySystem::whereNull('doctor_id')->latest();
        
        if ($request->filled('search')) {
            $query->where('name', 'like', '%' . $request->search . '%');
        }
        
        return $this->paginated($query->paginate($request->per_page ?? 15));
    }

    public function show(BodySystem $bodySystem)
    {
        if ($bodySystem->doctor_id !== null) {
            return $this->error('غير مصرح بالوصول لهذا الجهاز الجانبي.', 403);
        }
        return $this->success($bodySystem);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000'
        ]);

        $validated['doctor_id'] = null;
        $system = BodySystem::create($validated);

        return $this->success($system, 'تم إضافة الجهاز المرضي العام بنجاح.', 201);
    }

    public function update(Request $request, BodySystem $bodySystem)
    {
        if ($bodySystem->doctor_id !== null) {
            return $this->error('لا يمكن تعديل الأجهزة غير العامة.', 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000'
        ]);

        $bodySystem->update($validated);

        return $this->success($bodySystem, 'تم تعديل الجهاز المرضي العام بنجاح.');
    }

    public function destroy(BodySystem $bodySystem)
    {
        if ($bodySystem->doctor_id !== null) {
            return $this->error('لا يمكن حذف الأجهزة غير العامة.', 403);
        }

        if ($bodySystem->cases()->exists()) {
            return $this->error('لا يمكن حذف هذا الجهاز العام لوجود حالات سريرية مرتبطة به.', 422);
        }

        $bodySystem->delete();
        return $this->success(null, 'تم مسح الجهاز المرضي العام بنجاح.');
    }
}
