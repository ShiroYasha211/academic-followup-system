<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Academic\Schedule;
use Illuminate\Support\Facades\Auth;

class ScheduleController extends StudentApiController
{
    /**
     * Display a read-only listing of schedules for the student's major and level.
     * 
     * @response 200 {
     *  "success": true,
     *  "message": "Study schedule retrieved successfully",
     *  "data": {
     *      "1": [ ...monday schedules... ],
     *      "2": [ ...tuesday schedules... ]
     *  }
     * }
     */
    public function index()
    {
        $student = Auth::user();

        // Get schedules for subjects in the student's major/level
        $schedules = Schedule::whereHas('subject', function ($q) use ($student) {
            $q->where('major_id', $student->major_id)
                ->where('level_id', $student->level_id);
        })
            ->with([
                'doctor:id,name',
                'subject:id,name,doctor_id',
                'subject.doctor:id,name',
            ])
            ->orderBy('day_of_week')
            ->orderBy('start_time')
            ->get();

        $schedules->transform(function (Schedule $schedule) {
            $doctor = $schedule->doctor ?: $schedule->subject?->doctor;

            $schedule->setRelation('doctor', $doctor);
            $schedule->doctor_id = $doctor?->id;
            $schedule->doctor_name = $doctor?->name;

            return $schedule;
        });

        // Group schedules by day_of_week for easier consumption by mobile apps
        $groupedSchedules = $schedules->groupBy('day_of_week');

        return $this->success($groupedSchedules, 'Study schedule retrieved successfully');
    }
}
