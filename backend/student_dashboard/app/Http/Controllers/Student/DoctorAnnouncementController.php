<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\DoctorAnnouncement;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DoctorAnnouncementController extends Controller
{
    /**
     * Display doctor announcements as a chronological feed for the student.
     */
    public function index(Request $request)
    {
        $student = Auth::user();

        // Get subjects the student is enrolled in (same major + level)
        $subjectIds = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->pluck('id');

        $type = $request->get('type', 'all');

        // Feed items: ordered by latest publication/creation
        $announcements = DoctorAnnouncement::published()
            ->whereIn('subject_id', $subjectIds)
            ->ofType($type)
            ->with(['doctor', 'subject'])
            ->latest()
            ->paginate(15);

        return view('student.doctor-announcements.index', compact('announcements', 'type'));
    }
}
