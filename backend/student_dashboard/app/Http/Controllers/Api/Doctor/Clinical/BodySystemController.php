<?php

namespace App\Http\Controllers\Api\Doctor\Clinical;

use App\Http\Controllers\Api\Doctor\DoctorApiController;
use Illuminate\Http\Request;
use App\Models\Clinical\BodySystem;
use Illuminate\Support\Facades\Auth;

class BodySystemController extends DoctorApiController
{
    /** GET /api/doctor/clinical/body-systems */
    public function index(Request $request)
    {
        $user = Auth::guard('sanctum')->user();
        $query = BodySystem::forDoctor($user)->latest();

        if ($request->filled('search')) {
            $query->where('name', 'like', "%{$request->search}%");
        }
        return $this->paginated($query->paginate(15));
    }

    /** POST /api/doctor/clinical/body-systems */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
        ]);

        $validated['doctor_id'] = Auth::guard('sanctum')->id();
        $system = BodySystem::create($validated);

        return $this->success($system, 'تم إضافة الجهاز المرضي المخصص بنجاح.', 201);
    }

    /** PUT /api/doctor/clinical/body-systems/{id} */
    public function update(Request $request, $id)
    {
        $user = Auth::guard('sanctum')->user();
        $system = BodySystem::forDoctor($user)->findOrFail($id);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
        ]);

        if (is_null($system->doctor_id)) {
            $user->hiddenBodySystems()->syncWithoutDetaching([$system->id]);
            $validated['doctor_id'] = $user->id;
            $newSystem = BodySystem::create($validated);
            return $this->success($newSystem, 'تم إنشاء نسخة مخصصة من الجهاز العام بنجاح.');
        } else {
            $system->update($validated);
            return $this->success($system, 'تم تحديث الجهاز المرضي بنجاح.');
        }
    }

    /** DELETE /api/doctor/clinical/body-systems/{id} */
    public function destroy($id)
    {
        $user = Auth::guard('sanctum')->user();
        $system = BodySystem::forDoctor($user)->findOrFail($id);

        if ($system->cases()->where('doctor_id', $user->id)->exists()) {
            return $this->error('لا يمكن حذف أو إخفاء هذا الجهاز لوجود حالات سريرية خاصة بك مرتبطة به.', 422);
        }

        if (is_null($system->doctor_id)) {
            $user->hiddenBodySystems()->syncWithoutDetaching([$system->id]);
            return $this->success(null, 'تم إخفاء الجهاز العام من قائمتك بنجاح.');
        } else {
            $system->delete();
            return $this->success(null, 'تم مسح الجهاز المرضي المخصص بنجاح.');
        }
    }

    public function restoreDefaults()
    {
        Auth::guard('sanctum')->user()->hiddenBodySystems()->detach();
        return $this->success(null, 'تم استرداد الأجهزة المرضية الأساسية بنجاح.');
    }
}
