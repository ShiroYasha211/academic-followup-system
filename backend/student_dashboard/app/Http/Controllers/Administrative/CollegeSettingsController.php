<?php

namespace App\Http\Controllers\Administrative;

use App\Http\Controllers\Controller;
use App\Support\ExcuseWorkflow;
use Illuminate\Http\Request;

class CollegeSettingsController extends Controller
{
    public function edit()
    {
        $college = auth()->user()->college;

        return view('administrative.settings-clean', compact('college'));
    }

    public function update(Request $request)
    {
        $college = auth()->user()->college;

        $validated = $request->validate([
            'absence_deprivation_percentage' => 'required|integer|min:1|max:100',
            'excuses_deadline_days' => 'required|integer|min:1|max:30',
            'excuse_receiver' => 'required|in:administrative,doctor',
            'qr_rotation_seconds' => 'required|integer|min:5|max:300',
            'doctor_initial_star_balance' => 'required|integer|min:0|max:1000000',
        ]);

        $college->update($validated);
        $transferredExcuses = 0;

        if (ExcuseWorkflow::normalizeReceiver($college->excuse_receiver) === ExcuseWorkflow::RECEIVER_DOCTOR) {
            $transferredExcuses = ExcuseWorkflow::transferPendingAdministrativeExcusesToDoctors($college);
        }

        $message = 'College settings updated successfully.';
        if ($transferredExcuses > 0) {
            $message .= " {$transferredExcuses} pending excuses were routed to subject doctors.";
        }

        return back()->with('success', $message);
    }
}
