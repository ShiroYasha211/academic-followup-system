<?php

namespace App\Http\Controllers\Administrative;

use App\Http\Controllers\Api\Administrative\AdministrativeApiController;
use App\Support\ExcuseWorkflow;
use Illuminate\Http\Request;

class ApiCollegeSettingsController extends AdministrativeApiController
{
    public function show()
    {
        $college = $this->college();

        return $this->success([
            'id' => $college->id,
            'name' => $college->name,
            'absence_deprivation_percentage' => $college->absence_deprivation_percentage,
            'excuses_deadline_days' => $college->excuses_deadline_days,
            'excuse_receiver' => $college->excuse_receiver,
            'qr_rotation_seconds' => $college->qr_rotation_seconds,
            'doctor_initial_star_balance' => $college->doctor_initial_star_balance,
        ]);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'absence_deprivation_percentage' => 'required|integer|min:1|max:100',
            'excuses_deadline_days' => 'required|integer|min:1|max:30',
            'excuse_receiver' => 'required|in:administrative,doctor',
            'qr_rotation_seconds' => 'required|integer|min:5|max:300',
            'doctor_initial_star_balance' => 'required|integer|min:0|max:1000000',
        ]);

        $college = $this->college();
        $college->update($validated);
        $transferredExcuses = 0;

        if (ExcuseWorkflow::normalizeReceiver($college->excuse_receiver) === ExcuseWorkflow::RECEIVER_DOCTOR) {
            $transferredExcuses = ExcuseWorkflow::transferPendingAdministrativeExcusesToDoctors($college);
        }

        return $this->success([
            'id' => $college->id,
            'absence_deprivation_percentage' => $college->absence_deprivation_percentage,
            'excuses_deadline_days' => $college->excuses_deadline_days,
            'excuse_receiver' => $college->excuse_receiver,
            'qr_rotation_seconds' => $college->qr_rotation_seconds,
            'doctor_initial_star_balance' => $college->doctor_initial_star_balance,
            'transferred_pending_excuses' => $transferredExcuses,
        ], 'College settings updated successfully.');
    }
}
