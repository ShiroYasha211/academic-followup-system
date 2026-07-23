<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Academic\Subject;
use App\Models\Academic\Assignment;
use App\Models\Announcement;
use App\Models\Reminder;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class DashboardController extends StudentApiController
{
    /**
     * Get Student Dashboard Overview
     */
    public function index(Request $request)
    {
        $student = $request->user();

        // 1. Fetch Subjects ID for queries
        $subjects = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->get();

        $subjectIds = $subjects->pluck('id');

        // 2. Overview Stats (Counts)
        $assignmentsCount = Assignment::whereIn('subject_id', $subjectIds)
            ->where('due_date', '>=', now())
            ->count();

        $totalAbsences = \App\Models\Attendance::where('student_id', $student->id)
            ->where('status', 'absent')
            ->count();

        // 3. Announcements & Reminders
        $announcements = Announcement::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->latest()
            ->take(5)
            ->get(['id', 'title', 'content', 'created_at']);

        $reminders = Reminder::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->where('notify_at', '<=', now())
            ->where('event_date', '>=', now())
            ->orderBy('event_date', 'asc')
            ->take(5)
            ->get(['id', 'title', 'description', 'event_date']);

        // 4. Deprivation Warnings (Horman)
        $warnings = [];
        $subjectAbsencesCount = \App\Models\Attendance::where('student_id', $student->id)
            ->whereIn('subject_id', $subjectIds)
            ->where('status', 'absent')
            ->select('subject_id', DB::raw('count(*) as absences'))
            ->groupBy('subject_id')
            ->pluck('absences', 'subject_id');

        foreach ($subjects as $subject) {
            $subjectAbsences = $subjectAbsencesCount->get($subject->id, 0);
            $threshold = $subject->max_absences ?? 5;
            $remaining = $threshold - $subjectAbsences;

            if ($remaining <= 1) { // 1 day left or already banned
                $warnings[] = [
                    'subject_name' => $subject->name,
                    'absences_count' => $subjectAbsences,
                    'max_allowed' => $threshold,
                    'status' => $remaining <= 0 ? 'banned' : 'warning',
                    'message' => $remaining <= 0
                        ? "لقد تجاوزت الحد الأقصى للغياب في مقرر {$subject->name}."
                        : "إنذار: غياب واحد إضافي وسيم حرمانك من مقرر {$subject->name}."
                ];
            }
        }

        // 5. Excuse Deadline Warnings
        $excuseWarnings = \App\Models\Attendance::where('student_id', $student->id)
            ->where('status', 'absent')
            ->doesntHave('excuse')
            ->whereBetween('date', [now()->subDays(7), now()->subDays(4)])
            ->with('subject:id,name')
            ->get()
            ->map(function ($attendance) {
                return [
                    'attendance_id' => $attendance->id,
                    'subject_id' => $attendance->subject_id,
                    'date' => $attendance->date,
                    'subject' => $attendance->subject->name ?? 'مجهول',
                    'message' => "لديك غياب بتاريخ {$attendance->date} اقترب من تجاوز مهلة تقديم العذر (أسبوع)."
                ];
            });

        // 6. Next Exam Countdown
        $nextExam = null;
        try {
            $examScheduleIds = \App\Models\ExamSchedule::where('major_id', $student->major_id)
                ->where('level_id', $student->level_id)
                ->pluck('id');

            if ($examScheduleIds->count() > 0) {
                $nextExamItem = \App\Models\ExamScheduleItem::whereIn('exam_schedule_id', $examScheduleIds)
                    ->where('exam_date', '>=', now()->startOfDay())
                    ->orderBy('exam_date', 'asc')
                    ->orderBy('start_time', 'asc')
                    ->with('subject:id,name')
                    ->first();

                if ($nextExamItem) {
                    $examDate = Carbon::parse($nextExamItem->exam_date);
                    $daysRemaining = (int) now()->startOfDay()->diffInDays($examDate, false);

                    $nextExam = [
                        'subject_name' => $nextExamItem->subject->name ?? 'اختبار',
                        'exam_date' => $examDate->format('Y-m-d'),
                        'start_time' => Carbon::parse($nextExamItem->start_time)->format('h:i A'),
                        'location' => $nextExamItem->location,
                        'days_remaining' => $daysRemaining,
                        'is_today' => $daysRemaining === 0
                    ];
                }
            }
        } catch (\Exception $e) {
            $nextExam = null;
        }

        // Assemble Final JSON Response
        return $this->success([
            'overview' => [
                'active_assignments_count' => $assignmentsCount,
                'total_absences_days' => $totalAbsences,
                'registered_subjects_count' => $subjects->count(),
                'has_clinical' => $student->major->has_clinical ?? false,
            ],
            'next_exam' => $nextExam,
            'alerts' => [
                'deprivation_warnings' => $warnings,
                'excuse_deadlines' => $excuseWarnings,
            ],
            'feed' => [
                'announcements' => $announcements,
                'reminders' => $reminders,
            ]
        ]);
    }
}
