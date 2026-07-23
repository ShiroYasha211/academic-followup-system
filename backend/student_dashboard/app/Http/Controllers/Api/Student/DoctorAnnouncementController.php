<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use App\Models\DoctorAnnouncement;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DoctorAnnouncementController extends Controller
{
    public function index(Request $request)
    {
        $student = Auth::user();

        $subjectIds = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->pluck('id');

        $type = $request->get('type', 'all');

        $announcements = DoctorAnnouncement::published()
            ->whereIn('subject_id', $subjectIds)
            ->ofType($type)
            ->with(['doctor:id,name', 'subject:id,name'])
            ->latest()
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => [
                'module' => [
                    'name' => 'student_doctor_announcements',
                    'purpose' => 'Subject-level announcements published by doctors for the student subjects.',
                    'how_to_use' => 'Use this endpoint when you want doctor-only announcements. In the unified news-hub, these items appear under the doctor source.',
                    'filter' => [
                        'type' => 'Use type=all|announcement|warning|quiz_alert to narrow doctor announcements.',
                    ],
                ],
                'announcements' => $announcements,
            ],
        ]);
    }
}
