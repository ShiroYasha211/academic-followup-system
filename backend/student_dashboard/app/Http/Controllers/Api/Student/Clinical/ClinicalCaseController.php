<?php

namespace App\Http\Controllers\Api\Student\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Clinical\ClinicalCase;
use Illuminate\Support\Facades\Auth;

class ClinicalCaseController extends Controller
{
    /**
     * List current student's pending or rejected clinical cases.
     * Accessible by students with "Sub-Delegate" permissions.
     */
    public function pending()
    {
        $student = Auth::user();

        $cases = ClinicalCase::with(['trainingCenter', 'clinicalDepartment', 'bodySystem'])
            ->where('doctor_id', $student->id)
            ->whereIn('approval_status', ['pending', 'rejected'])
            ->latest()
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $cases
        ]);
    }
}
