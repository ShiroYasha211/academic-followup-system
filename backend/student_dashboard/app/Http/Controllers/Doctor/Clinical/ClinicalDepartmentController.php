<?php

namespace App\Http\Controllers\Doctor\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Clinical\ClinicalDepartment;
use Illuminate\Support\Facades\Auth;

class ClinicalDepartmentController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        $hiddenIds = $user->hiddenClinicalDepartments()->pluck('clinical_departments.id')->toArray();

        $query = ClinicalDepartment::where(function ($q) use ($user, $hiddenIds) {
            // Global constants not hidden by the doctor
            $q->whereNull('doctor_id');
            if (!empty($hiddenIds)) {
                $q->whereNotIn('id', $hiddenIds);
            }
        })->orWhere('doctor_id', $user->id)->latest();

        if ($request->filled('search')) {
            $query->where('name', 'like', '%' . $request->search . '%');
        }
        $departments = $query->paginate(10)->withQueryString();
        return view('doctor.clinical.departments.index', compact('departments'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        return view('doctor.clinical.departments.create');
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000'
        ]);

        $validated['doctor_id'] = Auth::id(); // Assign to current doctor

        ClinicalDepartment::create($validated);

        return redirect()->route('doctor.clinical.departments.index')->with('success', 'تم إضافة القسم الطبي بنجاح.');
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        $user = Auth::user();
        $department = ClinicalDepartment::where(function ($q) use ($user) {
            $q->whereNull('doctor_id')->orWhere('doctor_id', $user->id);
        })->findOrFail($id);

        return view('doctor.clinical.departments.edit', compact('department'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000'
        ]);

        $user = Auth::user();
        $department = ClinicalDepartment::where(function ($q) use ($user) {
            $q->whereNull('doctor_id')->orWhere('doctor_id', $user->id);
        })->findOrFail($id);

        if (is_null($department->doctor_id)) {
            // Editing a global constant -> hide the global one and create a personal one
            $user->hiddenClinicalDepartments()->syncWithoutDetaching([$department->id]);

            $validated['doctor_id'] = $user->id;
            ClinicalDepartment::create($validated);

            return redirect()->route('doctor.clinical.departments.index')->with('success', 'تم إنشاء نسخة مخصصة من القسم العام بنجاح.');
        } else {
            // Updating their own custom constant
            $department->update($validated);
            return redirect()->route('doctor.clinical.departments.index')->with('success', 'تم تعديل القسم الطبي بنجاح.');
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $user = Auth::user();
        $department = ClinicalDepartment::where(function ($q) use ($user) {
            $q->whereNull('doctor_id')->orWhere('doctor_id', $user->id);
        })->findOrFail($id);

        // Prevent deletion if it has cases attached by THIS doctor
        if ($department->cases()->where('doctor_id', $user->id)->exists()) {
            return back()->with('error', 'لا يمكن إخفاء/حذف هذا القسم لوجود حالات سريرية خاصة بك مرتبطة به.');
        }

        if (is_null($department->doctor_id)) {
            // Deleting a global constant -> simply hide it
            $user->hiddenClinicalDepartments()->syncWithoutDetaching([$department->id]);
            return redirect()->route('doctor.clinical.departments.index')->with('success', 'تم إخفاء القسم العام من قائمتك بنجاح.');
        } else {
            // Deleting their own constant -> actually delete
            $department->delete();
            return redirect()->route('doctor.clinical.departments.index')->with('success', 'تم مسح القسم الطبي المخصص بنجاح.');
        }
    }

    /**
     * Restore standard hidden departments.
     */
    public function restoreDefaults()
    {
        Auth::user()->hiddenClinicalDepartments()->detach();
        return redirect()->route('doctor.clinical.departments.index')->with('success', 'تم استرداد الأقسام الأساسية بنجاح.');
    }
}
