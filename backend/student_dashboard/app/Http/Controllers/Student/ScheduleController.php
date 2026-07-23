<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Academic\Schedule;
use Illuminate\Support\Facades\Auth;

class ScheduleController extends Controller
{
    /**
     * Display a read-only listing of schedules for the student's major and level.
     */
    public function index()
    {
        $student = Auth::user();

        // Get schedules for subjects in the student's major/level
        $schedules = Schedule::whereHas('subject', function ($q) use ($student) {
            $q->where('major_id', $student->major_id)
                ->where('level_id', $student->level_id);
        })
            ->with('subject')
            ->orderBy('day_of_week')
            ->orderBy('start_time')
            ->get();

        return view('student.schedules.index', compact('schedules'));
    }
}
