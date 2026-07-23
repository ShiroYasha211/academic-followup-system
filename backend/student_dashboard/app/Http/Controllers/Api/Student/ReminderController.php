<?php

namespace App\Http\Controllers\Api\Student;

use Illuminate\Http\Request;
use App\Models\Reminder;

class ReminderController extends StudentApiController
{
    /**
     * Get Student Reminders
     */
    public function index(Request $request)
    {
        $student = $request->user();

        $reminders = Reminder::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->where('notify_at', '<=', now())
            ->where('event_date', '>=', now())
            ->orderBy('event_date', 'asc')
            ->get();

        return $this->success([
            'reminders' => $reminders,
        ]);
    }
}
