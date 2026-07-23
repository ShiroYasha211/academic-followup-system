<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\ExamSchedule;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ExamScheduleController extends Controller
{
    public function index()
    {
        $user = Auth::user();

        $schedules = ExamSchedule::where('major_id', $user->major_id)
            ->where('level_id', $user->level_id)
            ->where('is_published', true)
            ->with(['items.subject', 'term', 'creator'])
            ->latest()
            ->get();

        return view('student.exams.index', compact('schedules'));
    }
}
