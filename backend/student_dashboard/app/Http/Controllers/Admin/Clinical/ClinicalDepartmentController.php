<?php

namespace App\Http\Controllers\Admin\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Clinical\ClinicalDepartment;

class ClinicalDepartmentController extends Controller
{
    public function index(Request $request)
    {
        // Admin only manages global constants (where doctor_id is null)
        $query = ClinicalDepartment::whereNull('doctor_id')->latest();
        
        if ($request->filled('search')) {
            $query->where('name', 'like', '%' . $request->search . '%');
        }
        
        $departments = $query->paginate(10)->withQueryString();
        return view('admin.clinical.departments.index', compact('departments'));
    }

    public function create()
    {
        return view('admin.clinical.departments.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000'
        ]);

        $validated['doctor_id'] = null; // Explicitly null for global constants
        ClinicalDepartment::create($validated);

        return redirect()->route('admin.clinical.departments.index')->with('success', 'تم إضافة القسم الطبي العام بنجاح.');
    }

    public function edit(string $id)
    {
        $department = ClinicalDepartment::whereNull('doctor_id')->findOrFail($id);
        return view('admin.clinical.departments.edit', compact('department'));
    }

    public function update(Request $request, string $id)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000'
        ]);

        $department = ClinicalDepartment::whereNull('doctor_id')->findOrFail($id);
        $department->update($validated);

        return redirect()->route('admin.clinical.departments.index')->with('success', 'تم تعديل القسم الطبي العام بنجاح.');
    }

    public function destroy(string $id)
    {
        $department = ClinicalDepartment::whereNull('doctor_id')->findOrFail($id);

        if ($department->cases()->exists()) {
            return back()->with('error', 'لا يمكن حذف هذا القسم العام لوجود حالات سريرية مرتبطة به.');
        }

        $department->delete();
        return redirect()->route('admin.clinical.departments.index')->with('success', 'تم مسح القسم الطبي العام بنجاح.');
    }
}
