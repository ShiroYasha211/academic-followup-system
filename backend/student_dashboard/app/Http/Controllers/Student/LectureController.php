<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Academic\Subject;
use App\Models\Academic\Lecture;
use App\Models\Academic\StudentLectureStatus;

class LectureController extends Controller
{
    /**
     * Display a listing of lectures for a specific subject.
     */
    public function index($subjectId)
    {
        $student = Auth::user();

        $subject = Subject::where('id', $subjectId)
            ->where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->firstOrFail();

        // Fetch lectures for this subject, ordered by date descending
        $lectures = Lecture::where('subject_id', $subject->id)
            ->with(['statuses' => function ($query) use ($student) {
                $query->where('student_id', $student->id);
            }])
            ->ordered()
            ->get();

        // Calculate progress
        $totalLectures = $lectures->count();
        $studiedLectures = $lectures->filter(function ($lecture) {
            return $lecture->statuses->first() && $lecture->statuses->first()->is_studied;
        })->count();

        $progressPercentage = $totalLectures > 0 ? round(($studiedLectures / $totalLectures) * 100) : 0;

        // Fetch attendance records for this student and subject
        $attendances = \App\Models\Attendance::where('student_id', $student->id)
            ->where('subject_id', $subject->id)
            ->get()
            ->keyBy(function ($item) {
                return $item->date->format('Y-m-d');
            });

        // Fetch scheduled lectures for this student (key by lecture ID for easy access)
        $scheduledLectures = \App\Models\Student\StudentScheduleItem::where('user_id', $student->id)
            ->where('referenceable_type', Lecture::class)
            ->whereIn('referenceable_id', $lectures->pluck('id'))
            ->get()
            ->keyBy('referenceable_id');

        return view('student.lectures.index', compact('subject', 'lectures', 'progressPercentage', 'studiedLectures', 'totalLectures', 'attendances', 'scheduledLectures'));
    }

    /**
     * Toggle the study status of a lecture.
     */
    public function toggleStatus(Request $request, $lectureId)
    {
        $student = Auth::user();
        $lecture = Lecture::findOrFail($lectureId);

        // Ensure student has access to this lecture's subject
        if ($lecture->subject->major_id != $student->major_id || $lecture->subject->level_id != $student->level_id) {
            abort(403);
        }

        $status = StudentLectureStatus::firstOrCreate(
            ['lecture_id' => $lecture->id, 'student_id' => $student->id]
        );

        $status->is_studied = !$status->is_studied;
        $status->studied_at = $status->is_studied ? now() : null;
        $status->save();

        return response()->json([
            'success' => true,
            'is_studied' => $status->is_studied,
            'message' => $status->is_studied ? 'تم تحديد المحاضرة كـ "تمت المذاكرة"' : 'تم إلغاء تحديد المحاضرة',
        ]);
    }
}
