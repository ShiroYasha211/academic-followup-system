<?php

namespace App\Http\Controllers\Api\Student;

use Illuminate\Http\Request;
use App\Models\ExamSchedule;

class ExamScheduleController extends StudentApiController
{
    /**
     * Get Student Exam Schedules
     */
    public function index(Request $request)
    {
        $student = $request->user();

        $schedules = ExamSchedule::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->where('is_published', true)
            ->with(['items.subject:id,name', 'term:id,name'])
            ->latest()
            ->get();

        return $this->success([
            'schedules' => $schedules,
        ]);
    }
}
