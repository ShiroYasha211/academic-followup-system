<?php

namespace App\Http\Controllers\Api\Doctor\Clinical;

use App\Http\Controllers\Api\Doctor\DoctorApiController;
use Illuminate\Support\Facades\Auth;
use App\Models\Clinical\ClinicalCase;
use App\Models\Clinical\ClinicalVolunteer;
use App\Models\Clinical\RareCase;

class ClinicalController extends DoctorApiController
{
    /** GET /api/doctor/clinical/overview */
    public function index()
    {
        $doctorId = Auth::id();

        return $this->success([
            'total_cases' => ClinicalCase::where('doctor_id', $doctorId)->count(),
            'active_cases' => ClinicalCase::where('doctor_id', $doctorId)->where('status', 'active')->count(),
            'discharged_cases' => ClinicalCase::where('doctor_id', $doctorId)->where('status', 'discharged')->count(),
            'rare_cases' => RareCase::where('doctor_id', $doctorId)->count(),
            'active_rare_cases' => RareCase::where('doctor_id', $doctorId)->where('is_active', true)->count(),
            'volunteers' => ClinicalVolunteer::where('doctor_id', $doctorId)->count(),
            'available_volunteers' => ClinicalVolunteer::where('doctor_id', $doctorId)->where('is_available', true)->count(),
        ]);
    }
}
