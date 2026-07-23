<?php

namespace App\Http\Controllers\Doctor\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Clinical\ClinicalVolunteer;
use Illuminate\Support\Facades\Auth;

class VolunteerController extends Controller
{
    /**
     * Display a listing of volunteers for the authenticated doctor.
     */
    public function index()
    {
        $volunteers = ClinicalVolunteer::where('doctor_id', Auth::id())
            ->latest()
            ->paginate(12);

        return view('doctor.clinical.volunteers.index', compact('volunteers'));
    }

    /**
     * Show the form for creating a new volunteer.
     */
    public function create()
    {
        return view('doctor.clinical.volunteers.create');
    }

    /**
     * Store a newly created volunteer in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name'            => 'required|string|max:255',
            'contact_info'    => 'required|string|max:255',
            'phone_secondary' => 'nullable|string|max:255',
            'email'           => 'nullable|email|max:255',
            'diagnosis'       => 'required|string|max:255',
            'clinical_signs'  => 'nullable|string',
        ]);

        $validated['doctor_id'] = Auth::id();
        $validated['is_available'] = true;

        ClinicalVolunteer::create($validated);

        return redirect()->route('doctor.clinical.volunteers.index')
            ->with('success', 'تم إضافة المتطوع بنجاح إلى سجلك الخاص.');
    }

    /**
     * Show the form for editing the specified volunteer.
     */
    public function edit($id)
    {
        $volunteer = ClinicalVolunteer::where('doctor_id', Auth::id())->findOrFail($id);
        return view('doctor.clinical.volunteers.edit', compact('volunteer'));
    }

    /**
     * Update the specified volunteer in storage.
     */
    public function update(Request $request, $id)
    {
        $volunteer = ClinicalVolunteer::where('doctor_id', Auth::id())->findOrFail($id);

        $validated = $request->validate([
            'name'            => 'required|string|max:255',
            'contact_info'    => 'required|string|max:255',
            'phone_secondary' => 'nullable|string|max:255',
            'email'           => 'nullable|email|max:255',
            'diagnosis'       => 'required|string|max:255',
            'clinical_signs'  => 'nullable|string',
        ]);

        $volunteer->update($validated);

        return redirect()->route('doctor.clinical.volunteers.index')
            ->with('success', 'تم تحديث بيانات المتطوع بنجاح.');
    }

    /**
     * Toggle availability status of the volunteer.
     */
    public function toggleStatus($id)
    {
        $volunteer = ClinicalVolunteer::where('doctor_id', Auth::id())->findOrFail($id);
        $volunteer->update(['is_available' => !$volunteer->is_available]);

        return back()->with('success', 'تم تحديث حالة توفر المتطوع.');
    }

    /**
     * Remove the specified volunteer from storage.
     */
    public function destroy($id)
    {
        $volunteer = ClinicalVolunteer::where('doctor_id', Auth::id())->findOrFail($id);
        $volunteer->delete();

        return redirect()->route('doctor.clinical.volunteers.index')
            ->with('success', 'تم حذف المتطوع من السجل.');
    }
}
