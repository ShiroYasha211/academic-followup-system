<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Clinical\ClinicalCase;
use App\Models\Clinical\TrainingCenter;
use App\Models\Subject;
use Illuminate\Support\Facades\Auth;

class ClinicalController extends Controller
{
    public function index()
    {
        $doctor = Auth::user();

        $totalCases = ClinicalCase::count();
        $activeCases = ClinicalCase::where('status', 'active')->count();

        return view('doctor.clinical.index', compact(
            'totalCases',
            'activeCases'
        ));
    }
}
