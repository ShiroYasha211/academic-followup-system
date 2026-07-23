<?php

namespace App\Http\Controllers\Student\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Clinical\RareCase;
use Illuminate\Support\Facades\Auth;

class RareCaseController extends Controller
{
    /**
     * Display a listing of active rare cases for students.
     */
    public function index()
    {
        // Students can see all active cases
        $cases = RareCase::with('doctor')
            ->where('is_active', true)
            ->latest()
            ->paginate(10);

        return view('student.clinical.rare_cases.index', compact('cases'));
    }

    /**
     * Display the specified rare case (for deep links/notifications).
     */
    public function show($id)
    {
        $case = RareCase::with('doctor')->findOrFail($id);
        
        if (!$case->is_active) {
            return redirect()->route('student.clinical.rare-cases.index')
                ->with('error', 'هذا الإعلان غير متاح حالياً.');
        }

        return view('student.clinical.rare_cases.show', compact('case'));
    }
}
