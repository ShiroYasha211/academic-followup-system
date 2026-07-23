<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Academic\University;
use Illuminate\Http\Request;

class UniversityController extends AdminApiController
{
    public function index()
    {
        $universities = University::withCount('colleges')->latest()->get();
        return $this->success($universities);
    }

    public function show(University $university)
    {
        return $this->success($university->load('colleges.majors'));
    }

    public function store(Request $request)
    {
        $request->validate(['name' => 'required|string|max:255|unique:universities']);
        $university = University::create($request->only('name'));
        return $this->success($university, 'تم إنشاء الجامعة بنجاح', 201);
    }

    public function update(Request $request, University $university)
    {
        $request->validate(['name' => 'required|string|max:255|unique:universities,name,' . $university->id]);
        $university->update($request->only('name'));
        return $this->success($university, 'تم تحديث الجامعة بنجاح');
    }

    public function destroy(University $university)
    {
        if ($university->colleges()->exists() || $university->users()->exists()) {
            return $this->error('لا يمكن حذف الجامعة لوجود كليات أو مستخدمين (طلاب/دكاترة) مرتبطين بها.', 422);
        }
        $university->delete();
        return $this->success(null, 'تم حذف الجامعة بنجاح');
    }
}
