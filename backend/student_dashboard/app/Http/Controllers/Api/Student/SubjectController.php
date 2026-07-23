<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Academic\Subject;
use App\Models\Academic\Term;
use App\Models\Academic\Lecture;
use App\Models\Academic\Assignment;
use App\Models\Academic\StudentLectureStatus;
use App\Models\Attendance;
use App\Models\Grade;
use App\Models\GradeCategory;
use App\Models\Setting;
use App\Support\ExcuseWorkflow;
use Illuminate\Support\Facades\Auth;

class SubjectController extends StudentApiController
{
    /**
     * Get Student's Subjects
     */
    public function index(Request $request)
    {
        $student = $request->user();

        $subjects = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->with(['doctor:id,name,avatar', 'term:id,name', 'semester:id,name']);

        if ($request->term_id) {
            $subjects->where('term_id', $request->term_id);
        }

        if ($request->semester_id) {
            $subjects->where('semester_id', $request->semester_id);
        }

        $terms = Term::where('level_id', $student->level_id)
            ->with('semesters:id,term_id,name')
            ->get(['id', 'level_id', 'name']);

        return $this->success([
            'subjects' => $subjects->get(),
            'terms' => $terms,
            'major' => $student->major ? [
                'id' => $student->major->id,
                'name' => $student->major->name,
                'has_semesters' => (bool) $student->major->has_semesters,
            ] : null,
            'filters' => [
                'term_id' => $request->term_id,
                'semester_id' => $request->semester_id,
            ],
        ]);
    }

    /**
     * Get Subject Details (Lectures, Stats, Assignments)
     */
    public function show($id, Request $request)
    {
        $student = $request->user();

        $subject = Subject::where('id', $id)
            ->where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->with(['doctor:id,name,avatar', 'resources', 'term:id,name', 'semester:id,name'])
            ->firstOrFail();

        // 1. Fetch Lectures with Study Status
        $lectures = Lecture::where('subject_id', $subject->id)
            ->with(['statuses' => function ($query) use ($student) {
                $query->where('student_id', $student->id);
            }])
            ->ordered()
            ->get()
            ->map(function ($lecture) {
                $status = $lecture->statuses->first();
                return [
                    'id' => $lecture->id,
                    'title' => $lecture->title,
                    'description' => $lecture->description,
                    'date' => $lecture->date,
                    'is_studied' => $status ? (bool) $status->is_studied : false,
                    'studied_at' => $status ? $status->studied_at : null,
                ];
            });

        // 2. Fetch Assignments
        $assignments = Assignment::where('subject_id', $subject->id)
            ->latest()
            ->get()
            ->map(function ($assignment) use ($student) {
                $isSubmitted = $assignment->submissions()->where('student_id', $student->id)->exists();
                $isLate = now()->greaterThan($assignment->due_date);

                $status = 'available';
                if ($isSubmitted) $status = 'submitted';
                elseif ($isLate) $status = 'missing';

                return [
                    'id' => $assignment->id,
                    'title' => $assignment->title,
                    'description' => $assignment->description,
                    'due_date' => $assignment->due_date,
                    'marks' => $assignment->marks,
                    'requires_submission' => (bool) $assignment->requires_submission,
                    'requires_file' => (bool) $assignment->requires_submission,
                    'status' => $status,
                ];
            });

        // 3. Attendance Stats & History
        $attendanceRecords = Attendance::where('student_id', $student->id)
            ->where('subject_id', $subject->id)
            ->with('excuse')
            ->orderBy('date', 'desc')
            ->get();

        $presentCount = $attendanceRecords->where('status', 'present')->count();
        $absentCount = $attendanceRecords->where('status', 'absent')->count();
        $lateCount = $attendanceRecords->where('status', 'late')->count();
        $excusedCount = $attendanceRecords->whereIn('status', ExcuseWorkflow::countedAsExcusedStatuses())->count();
        $totalLecturesHeld = $attendanceRecords->count();
        
        $attendancePercentage = $totalLecturesHeld > 0 
            ? round((($presentCount + $lateCount + $excusedCount) / $totalLecturesHeld) * 100) 
            : 0;

        // 4. Deprivation Warning Logic
        $student->loadMissing('college');
        $maxAbsences = (int) ($subject->max_absences ?: Setting::get('default_max_absences', 3));
        $deprivationThreshold = (int) ($student->college?->absence_deprivation_percentage ?: Setting::get('deprivation_threshold', 25));
        $excuseDeadlineDays = (int) ($student->college?->excuses_deadline_days ?? 3);

        $absencePercent = $totalLecturesHeld > 0 ? round(($absentCount / $totalLecturesHeld) * 100) : 0;
        $warningLevel = null;
        $remainingAbsences = max($maxAbsences - $absentCount, 0);

        if ($absencePercent >= $deprivationThreshold) {
            $warningLevel = 'danger'; // Deprivation zone
        } elseif ($absentCount >= $maxAbsences) {
            $warningLevel = 'danger'; // Exceeded max allowed
        } elseif ($absentCount >= ($maxAbsences - 1)) {
            $warningLevel = 'warning'; // One absence away from max
        }

        $history = $attendanceRecords->map(function ($rec) use ($excuseDeadlineDays) {
            $canSubmit = false;
            $daysSince = 0;
            $isExpired = false;
            
            if ($rec->status == 'absent' && !$rec->excuse) {
                $deadline = \Carbon\Carbon::parse($rec->date)->addDays($excuseDeadlineDays)->endOfDay();
                $canSubmit = now()->lte($deadline);
                $isExpired = now()->gt($deadline);
                $daysSince = (int) now()->diffInDays(\Carbon\Carbon::parse($rec->date), false);
                $daysSince = abs($daysSince);
            }

            return [
                'id' => $rec->id,
                'date' => $rec->date,
                'status' => $rec->status,
                'is_excused' => in_array($rec->status, ExcuseWorkflow::countedAsExcusedStatuses(), true) || ($rec->excuse && $rec->excuse->status == 'accepted'),
                'excuse' => $rec->excuse ? [
                    'id' => $rec->excuse->id,
                    'reason' => $rec->excuse->reason,
                    'status' => $rec->excuse->status,
                    'receiver_type' => $rec->excuse->receiver_type,
                    'resolution' => $rec->excuse->resolution,
                    'resolution_label' => ExcuseWorkflow::resolutionLabel($rec->excuse->resolution),
                    'attachment_url' => $rec->excuse->attachment ? asset('storage/' . $rec->excuse->attachment) : null,
                    'doctor_comment' => $rec->excuse->doctor_comment,
                    'created_at' => $rec->excuse->created_at->format('Y-m-d H:i'),
                ] : null,
                'can_submit_excuse' => $canSubmit,
                'deadline_info' => [
                    'days_since_absence' => $daysSince,
                    'max_deadline_days' => $excuseDeadlineDays,
                    'is_expired' => $isExpired
                ]
            ];
        });

        // 4. Fetch Grades with the same category-based structure used by doctors.
        $gradesData = $this->formatSubjectGrades($student->id, $subject->id);

        return $this->success([
            'subject' => $subject,
            'grades' => $gradesData,
            'progress' => [
                'attendance_percentage' => $attendancePercentage,
                'total_lectures_held' => $totalLecturesHeld,
                'absences' => $absentCount,
                'presents' => $presentCount,
                'lates' => $lateCount,
                'excused' => $excusedCount,
            ],
            'deprivation_info' => [
                'warning_level' => $warningLevel,
                'absence_percent' => $absencePercent,
                'max_absences_allowed' => $maxAbsences,
                'remaining_absences' => $remainingAbsences,
                'deprivation_threshold_percent' => $deprivationThreshold,
                'is_banned' => $warningLevel === 'danger',
            ],
            'lectures' => $lectures,
            'assignments' => $assignments,
            'attendance_history' => $history,
        ]);
    }

    private function formatSubjectGrades(int $studentId, int $subjectId): array
    {
        $categories = GradeCategory::where('subject_id', $subjectId)
            ->orderBy('created_at')
            ->get();

        $grades = Grade::where('student_id', $studentId)
            ->where('subject_id', $subjectId)
            ->with(['gradeCategory:id,name,max_score', 'creator:id,name'])
            ->get();

        $categoryItems = $categories->map(function ($category) use ($grades) {
            $grade = $grades->firstWhere('category_id', $category->id);

            return [
                'id' => $category->id,
                'name' => $category->name,
                'type' => 'category',
                'score' => $grade?->score !== null ? (float) $grade->score : null,
                'max_score' => (float) $category->max_score,
                'percentage' => ($grade && $category->max_score > 0)
                    ? round(((float) $grade->score / (float) $category->max_score) * 100, 1)
                    : null,
                'status' => $grade?->status ?? 'not_entered',
                'entered_at' => $grade?->updated_at?->format('Y-m-d H:i'),
                'created_by' => $grade?->creator?->name,
            ];
        })->values();

        $generalContinuous = $grades->where('type', 'continuous')->whereNull('category_id')->values();
        $generalItems = $generalContinuous->map(function ($grade) {
            return [
                'id' => $grade->id,
                'name' => $grade->category ?: 'أعمال السنة',
                'type' => 'general_continuous',
                'score' => $grade->score !== null ? (float) $grade->score : null,
                'max_score' => (float) $grade->max_score,
                'percentage' => $grade->max_score > 0
                    ? round(((float) $grade->score / (float) $grade->max_score) * 100, 1)
                    : null,
                'status' => $grade->status,
                'entered_at' => $grade->updated_at?->format('Y-m-d H:i'),
                'created_by' => $grade->creator?->name,
            ];
        });

        $finalGrades = $grades->where('type', 'final')->values();
        $finalItems = $finalGrades->map(function ($grade) {
            return [
                'id' => $grade->id,
                'name' => 'الاختبار النهائي',
                'type' => 'final',
                'score' => $grade->score !== null ? (float) $grade->score : null,
                'max_score' => (float) $grade->max_score,
                'percentage' => $grade->max_score > 0
                    ? round(((float) $grade->score / (float) $grade->max_score) * 100, 1)
                    : null,
                'status' => $grade->status,
                'entered_at' => $grade->updated_at?->format('Y-m-d H:i'),
                'created_by' => $grade->creator?->name,
            ];
        });

        $hasCategories = $categoryItems->isNotEmpty();
        $visibleContinuousItems = $hasCategories ? $categoryItems : $generalItems;
        $allItems = $visibleContinuousItems->concat($finalItems)->values();
        $approvedItems = $allItems->where('status', 'approved');
        $earned = round($approvedItems->sum(fn ($item) => (float) ($item['score'] ?? 0)), 2);
        $max = round($allItems->sum(fn ($item) => (float) ($item['max_score'] ?? 0)), 2);

        $approvedGrades = $grades->where('status', 'approved');
        $continuousScore = round($visibleContinuousItems
            ->where('status', 'approved')
            ->sum(fn ($item) => (float) ($item['score'] ?? 0)), 2);
        $continuousMax = round($visibleContinuousItems
            ->sum(fn ($item) => (float) ($item['max_score'] ?? 0)), 2);
        $finalScore = round((float) $approvedGrades->where('type', 'final')->sum('score'), 2);
        $finalMax = round((float) $finalGrades->sum('max_score'), 2);

        return [
            'continuous' => $continuousMax > 0 ? [
                'score' => $continuousScore,
                'max_score' => $continuousMax,
            ] : null,
            'final' => $finalMax > 0 ? [
                'score' => $finalScore,
                'max_score' => $finalMax,
            ] : null,
            'total_score' => $earned,
            'max_possible' => $max,
            'total_percentage' => $max > 0 ? round(($earned / $max) * 100, 1) : null,
            'items' => $allItems,
            'summary' => [
                'entered_count' => $allItems->whereNotNull('score')->count(),
                'approved_count' => $allItems->where('status', 'approved')->count(),
                'pending_count' => $allItems->where('status', 'pending')->count(),
                'not_entered_count' => $allItems->where('status', 'not_entered')->count(),
            ],
        ];
    }

    /**
     * Toggle the study status of a lecture
     */
    public function toggleListen($lecture_id, Request $request)
    {
        $student = $request->user();
        $lecture = Lecture::with('subject')->findOrFail($lecture_id);

        // Security check
        if ($lecture->subject->major_id != $student->major_id || $lecture->subject->level_id != $student->level_id) {
            return $this->error('Unauthorized', 403);
        }

        $status = StudentLectureStatus::firstOrCreate(
            ['lecture_id' => $lecture->id, 'student_id' => $student->id]
        );

        $status->is_studied = !$status->is_studied;
        $status->studied_at = $status->is_studied ? now() : null;
        $status->save();

        return $this->success([
            'is_studied' => $status->is_studied,
        ], $status->is_studied ? 'تم تحديد المحاضرة كـ "تمت المذاكرة"' : 'تم إلغاء تحديد المحاضرة');
    }
}
