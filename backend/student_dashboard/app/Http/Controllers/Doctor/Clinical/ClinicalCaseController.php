<?php

namespace App\Http\Controllers\Doctor\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Clinical\ClinicalCase;
use App\Models\Clinical\TrainingCenter;
use App\Models\Clinical\ClinicalDepartment;
use App\Models\Clinical\BodySystem;
use Illuminate\Support\Facades\Auth;

class ClinicalCaseController extends Controller
{
    public function index(Request $request)
    {
        $query = ClinicalCase::with(['trainingCenter', 'clinicalDepartment', 'bodySystem', 'doctor', 'assignments'])
            ->withCount('assignments')
            ->where('approval_status', 'approved')
            ->where('doctor_id', Auth::id());

        // Filters
        if ($request->filled('patient_name')) {
            $query->where('patient_name', 'like', '%' . $request->patient_name . '%');
        }
        if ($request->filled('training_center_id')) {
            $query->where('training_center_id', $request->training_center_id);
        }
        if ($request->filled('clinical_department_id')) {
            $query->where('clinical_department_id', $request->clinical_department_id);
        }
        if ($request->filled('body_system_id')) {
            $query->where('body_system_id', $request->body_system_id);
        }

        $cases = $query->latest()->paginate(15)->withQueryString();

        $centers = TrainingCenter::all();
        $departments = ClinicalDepartment::all();
        $systems = BodySystem::all();

        return view('doctor.clinical.cases.index', compact('cases', 'centers', 'departments', 'systems'));
    }

    public function create()
    {
        $centers = TrainingCenter::all();
        $departments = ClinicalDepartment::all();
        $systems = BodySystem::all();

        return view('doctor.clinical.cases.create', compact('centers', 'departments', 'systems'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'patient_name' => 'required|string|max:255',
            'age' => 'nullable|integer|min:0|max:150',
            'gender' => 'nullable|in:male,female',
            'training_center_id' => 'required|exists:training_centers,id',
            'clinical_department_id' => 'required|exists:clinical_departments,id',
            'body_system_id' => 'required|exists:body_systems,id',
            'diagnosis_or_description' => 'nullable|string',
            'status' => 'required|in:active,discharged,transferred',
        ]);

        $validated['doctor_id'] = Auth::id();
        $validated['approval_status'] = 'approved';

        ClinicalCase::create($validated);

        return redirect()->route('doctor.clinical.cases.index')
            ->with('success', 'تم إدراج الحالة المرضية بنجاح.');
    }

    public function show(string $id)
    {
        $case = ClinicalCase::with(['trainingCenter', 'clinicalDepartment', 'bodySystem', 'doctor'])
            ->withCount('assignments')
            ->where('doctor_id', Auth::id())
            ->findOrFail($id);

        return view('doctor.clinical.cases.show', compact('case'));
    }

    public function edit(string $id)
    {
        $case = ClinicalCase::where('doctor_id', Auth::id())->findOrFail($id);
        $centers = TrainingCenter::all();
        $departments = ClinicalDepartment::all();
        $systems = BodySystem::all();

        return view('doctor.clinical.cases.edit', compact('case', 'centers', 'departments', 'systems'));
    }

    public function update(Request $request, string $id)
    {
        $case = ClinicalCase::where('doctor_id', Auth::id())->findOrFail($id);
        $validated = $request->validate([
            'patient_name' => 'required|string|max:255',
            'age' => 'nullable|integer|min:0|max:150',
            'gender' => 'nullable|in:male,female',
            'training_center_id' => 'required|exists:training_centers,id',
            'clinical_department_id' => 'required|exists:clinical_departments,id',
            'body_system_id' => 'required|exists:body_systems,id',
            'diagnosis_or_description' => 'nullable|string',
            'status' => 'required|in:active,discharged,transferred',
        ]);

        $case->update($validated);

        return redirect()->route('doctor.clinical.cases.index')
            ->with('success', 'تم تحديث بيانات الحالة بنجاح.');
    }

    public function destroy(string $id)
    {
        $case = ClinicalCase::where('doctor_id', Auth::id())->findOrFail($id);
        $case->delete();

        return redirect()->route('doctor.clinical.cases.index')
            ->with('success', 'تم المسح بنجاح.');
    }
}
