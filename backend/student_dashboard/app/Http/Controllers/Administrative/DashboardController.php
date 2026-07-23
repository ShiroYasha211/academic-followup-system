<?php

namespace App\Http\Controllers\Administrative;

use App\Http\Controllers\Controller;
use App\Models\Academic\College;
use App\Models\User;
use App\Enums\UserRole;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    /**
     * Display the administrative dashboard.
     */
    public function index()
    {
        $college = auth()->user()->college;
        
        if (!$college) {
            abort(403, 'لم يتم ربط حسابك بكلية محددة. يرجى التواصل مع مدير النظام.');
        }

        // Stats for the college
        $stats = [
            'doctors_count' => User::where('college_id', $college->id)->where('role', UserRole::DOCTOR)->count(),
            'delegates_count' => User::where('college_id', $college->id)->where('role', UserRole::DELEGATE)->count(),
            'students_count' => User::where('college_id', $college->id)->whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])->count(),
            // We can add more stats later like pending excuses, etc.
        ];

        return view('administrative.dashboard', compact('college', 'stats'));
    }

    /**
     * Show the college settings form.
     */
    public function settings()
    {
        $college = auth()->user()->college;
        return view('administrative.settings', compact('college'));
    }

    /**
     * Update the college settings.
     */
    public function updateSettings(Request $request)
    {
        $college = auth()->user()->college;

        $request->validate([
            'absence_deprivation_percentage' => 'required|integer|min:1|max:100',
            'excuses_deadline_days' => 'required|integer|min:1|max:30',
        ]);

        $college->update([
            'absence_deprivation_percentage' => $request->absence_deprivation_percentage,
            'excuses_deadline_days' => $request->excuses_deadline_days,
        ]);

        return back()->with('success', 'تم تحديث إعدادات الكلية بنجاح.');
    }
}
