<?php

namespace App\Http\Controllers\Delegate\Clinical;

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
        $user = Auth::user();
        $query = ClinicalCase::with(['trainingCenter', 'clinicalDepartment', 'bodySystem', 'doctor', 'assignments'])
            ->withCount('assignments');

        // In the main index, we ONLY show approved cases to keep it clean.
        $query->where('approval_status', 'approved');

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
        if ($request->filled('approval_status')) {
            $query->where('approval_status', $request->approval_status);
        }

        $cases = $query->latest()->paginate(15)->withQueryString();

        $centers = TrainingCenter::all();
        $departments = ClinicalDepartment::all();
        $systems = BodySystem::all();

        return view('doctor.clinical.cases.index', compact('cases', 'centers', 'departments', 'systems'));
    }

    public function pending(Request $request)
    {
        $user = Auth::user();
        $query = ClinicalCase::with(['trainingCenter', 'clinicalDepartment', 'bodySystem', 'doctor'])
            ->withCount('assignments');

        if ($user->isClinicalDelegate()) {
            $query->where('approval_status', 'pending');
        } else {
            $query->where('doctor_id', $user->id)
                  ->whereIn('approval_status', ['pending', 'rejected']);
        }

        if ($request->filled('patient_name')) {
            $query->where('patient_name', 'like', '%' . $request->patient_name . '%');
        }

        $cases = $query->latest()->paginate(15)->withQueryString();
        $centers = TrainingCenter::all();
        $departments = ClinicalDepartment::all();
        $systems = BodySystem::all();

        return view('doctor.clinical.cases.pending', compact('cases', 'centers', 'departments', 'systems'));
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

        $user = Auth::user();
        $validated['doctor_id'] = $user->id;

        // Determine approval status
        if ($user->role->value === 'doctor' || $user->isClinicalDelegate()) {
            $validated['approval_status'] = 'approved';
        } else {
            $validated['approval_status'] = 'pending';
        }

        ClinicalCase::create($validated);

        $role = $user->role->value;
        $routePrefix = ($role === 'student') ? 'student' : 'delegate';

        $msg = $validated['approval_status'] === 'pending' 
            ? 'تم إرسال الحالة بنجاح وهي قيد المراجعة من المندوب.' 
            : 'تم إدراج الحالة المرضية بنجاح.';

        return redirect()->route($routePrefix . '.clinical.cases.index')
            ->with('success', $msg);
    }

    public function approve(ClinicalCase $case)
    {
        if (!Auth::user()->isClinicalDelegate()) {
            abort(403);
        }

        $case->update([
            'approval_status' => 'approved',
            'approved_by_id' => Auth::id(),
            'rejection_reason' => null
        ]);

        return redirect()->back()->with('success', 'تم اعتماد الحالة ونشرها للجميع بنجاح.');
    }

    public function reject(Request $request, ClinicalCase $case)
    {
        if (!Auth::user()->isClinicalDelegate()) {
            abort(403);
        }

        $request->validate([
            'rejection_reason' => 'required|string|max:500'
        ]);

        $case->update([
            'approval_status' => 'rejected',
            'rejection_reason' => $request->rejection_reason
        ]);

        return redirect()->back()->with('success', 'تم رفض الحالة وإعادتها للطالب مع الملاحظات.');
    }

    public function show(string $id)
    {
        $case = ClinicalCase::with(['trainingCenter', 'clinicalDepartment', 'bodySystem', 'doctor'])
            ->withCount('assignments')
            ->findOrFail($id);

        return view('doctor.clinical.cases.show', compact('case'));
    }

    public function edit(string $id)
    {
        $case = ClinicalCase::findOrFail($id);
        $centers = TrainingCenter::all();
        $departments = ClinicalDepartment::all();
        $systems = BodySystem::all();

        return view('doctor.clinical.cases.edit', compact('case', 'centers', 'departments', 'systems'));
    }

    public function update(Request $request, string $id)
    {
        $case = ClinicalCase::findOrFail($id);
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

        // If a sub-delegate edits a rejected/pending case, maybe it should stay pending?
        // For now, simple update.

        $role = Auth::user()->role->value;
        $routePrefix = ($role === 'student') ? 'student' : 'delegate';

        return redirect()->route($routePrefix . '.clinical.cases.index')
            ->with('success', 'تم تحديث بيانات الحالة بنجاح.');
    }

    public function destroy(string $id)
    {
        $case = ClinicalCase::findOrFail($id);
        $case->delete();

        $role = Auth::user()->role->value;
        $routePrefix = ($role === 'student') ? 'student' : 'delegate';

        return redirect()->route($routePrefix . '.clinical.cases.index')
            ->with('success', 'تم المسح بنجاح.');
    }
}
