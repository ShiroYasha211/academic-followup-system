<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Academic\College;
use Illuminate\Http\Request;

class CollegeController extends AdminApiController
{
    public function index(Request $request)
    {
        $query = College::with('university')->withCount('majors');
        if ($request->university_id) {
            $query->where('university_id', $request->university_id);
        }
        return $this->success($query->latest()->get());
    }

    public function show(College $college)
    {
        return $this->success($college->load('university', 'majors'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'university_id' => 'required|exists:universities,id',
        ]);
        $college = College::create($request->only('name', 'university_id'));
        return $this->success($college->load('university'), 'تم إنشاء الكلية بنجاح', 201);
    }

    public function update(Request $request, College $college)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'university_id' => 'required|exists:universities,id',
        ]);
        $college->update($request->only('name', 'university_id'));
        return $this->success($college->load('university'), 'تم تحديث الكلية بنجاح');
    }

    public function destroy(College $college)
    {
        if ($college->majors()->exists() || $college->users()->exists()) {
            return $this->error('لا يمكن حذف الكلية لوجود تخصصات أو مستخدمين (طلاب/دكاترة) مرتبطين بها.', 422);
        }
        $college->delete();
        return $this->success(null, 'تم حذف الكلية بنجاح');
    }
}
