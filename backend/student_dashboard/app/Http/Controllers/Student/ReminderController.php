<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Reminder;
use Carbon\Carbon;

class ReminderController extends Controller
{
    public function index()
    {
        $student = Auth::user();

        // Fetch reminders relevant to the student's major and level
        // AND where the notify_at time has passed (should be shown now)
        // AND the event itself hasn't passed by too long (e.g., keep for 1 day after event) 
        // OR just show all future events that are past notify time.

        $reminders = Reminder::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->where('notify_at', '<=', now())
            ->where('event_date', '>=', now()) // only show upcoming events
            ->orderBy('event_date', 'asc')
            ->get();

        return view('student.reminders.index', compact('reminders'));
    }
}
