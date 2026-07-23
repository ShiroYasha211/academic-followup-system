<?php

namespace App\Http\Controllers\Doctor\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Clinical\RareCase;
use App\Models\Academic\Major;
use App\Models\User;
use App\Notifications\Clinical\RareCaseAnnounced;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Notification;

class RareCaseController extends Controller
{
    /**
     * Display a listing of the rare cases for the logged-in doctor.
     */
    public function index()
    {
        $cases = RareCase::where('doctor_id', Auth::id())
            ->latest()
            ->paginate(15);

        return view('doctor.clinical.rare_cases.index', compact('cases'));
    }

    /**
     * Show the form for creating a new rare case.
     */
    public function create()
    {
        return view('doctor.clinical.rare_cases.create');
    }

    /**
     * Store a newly created rare case in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'patient_name' => 'nullable|string|max:255',
            'hospital'     => 'required|string|max:255',
            'department'   => 'required|string|max:255',
            'room_number'  => 'nullable|string|max:50',
            'diagnosis'    => 'required|string|max:255',
            'clinical_signs'=> 'nullable|string',
            'attachment'   => 'nullable|image|mimes:jpeg,png,jpg,gif|max:5120', // Max 5MB
        ]);

        $data = $validated;
        unset($data['attachment']);
        $data['doctor_id'] = Auth::id();

        if ($request->hasFile('attachment')) {
            $path = $request->file('attachment')->store('clinical/rare_cases', 'public');
            $data['attachment_path'] = $path;
        }

        $rareCase = RareCase::create($data);

        // Notify students in clinical majors
        $this->notifyClinicalStudents($rareCase);

        return redirect()->route('doctor.clinical.rare-cases.index')
            ->with('success', 'تم إعلان الحالة النادرة وإشعار الطلاب المعنيين بنجاح.');
    }

    /**
     * Toggle active status of a rare case.
     */
    public function toggleStatus(RareCase $rareCase)
    {
        $this->authorizeOwner($rareCase);
        $rareCase->update(['is_active' => !$rareCase->is_active]);

        return back()->with('success', 'تم تحديث حالة الإعلان بنجاح.');
    }

    /**
     * Remove the specified rare case from storage.
     */
    public function destroy(RareCase $rareCase)
    {
        $this->authorizeOwner($rareCase);
        $rareCase->delete();

        return redirect()->route('doctor.clinical.rare-cases.index')
            ->with('success', 'تم حذف الإعلان بنجاح.');
    }

    /**
     * Internal logic to notify relevant students.
     */
    protected function notifyClinicalStudents(RareCase $rareCase)
    {
        // Get all students whose major has clinical section
        $clinicalMajorIds = Major::where('has_clinical', true)->pluck('id');
        
        $students = User::whereIn('major_id', $clinicalMajorIds)
            ->where('status', 'active')
            ->get();

        if ($students->count() > 0) {
            Notification::send($students, new RareCaseAnnounced($rareCase));
        }
    }

    protected function authorizeOwner(RareCase $rareCase)
    {
        if ($rareCase->doctor_id !== Auth::id()) {
            abort(403, 'غير مصرح لك بالقيام بهذا الإجراء.');
        }
    }
}
