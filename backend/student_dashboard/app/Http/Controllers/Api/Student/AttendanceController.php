<?php

namespace App\Http\Controllers\Api\Student;

use App\Models\Attendance;
use App\Models\Setting;
use App\Support\ExcuseWorkflow;
use Illuminate\Http\Request;

class AttendanceController extends StudentApiController
{
    /**
     * Get student attendance stats and history.
     */
    public function index(Request $request)
    {
        $student = $request->user();
        $student->loadMissing('college');

        $attendances = Attendance::where('student_id', $student->id)
            ->with(['subject:id,name,max_absences', 'excuse'])
            ->orderBy('date', 'desc')
            ->get();

        $totalLectures = $attendances->count();
        $presentCount = $attendances->where('status', 'present')->count();
        $absentCount = $attendances->where('status', 'absent')->count();
        $lateCount = $attendances->where('status', 'late')->count();
        $excusedCount = $attendances->whereIn('status', ExcuseWorkflow::countedAsExcusedStatuses())->count();

        $presencePercentage = $totalLectures > 0
            ? round((($presentCount + $lateCount + $excusedCount) / $totalLectures) * 100, 1)
            : 0;

        $attendanceBySubject = $attendances->groupBy('subject_id');
        $defaultMaxAbsences = (int) Setting::get('default_max_absences', 3);
        $deprivationThreshold = (int) ($student->college?->absence_deprivation_percentage ?: Setting::get('deprivation_threshold', 25));

        $subjectWarnings = [];
        $history = [];

        foreach ($attendanceBySubject as $subjectId => $records) {
            $subject = $records->first()->subject;
            $subjectName = $subject?->name ?? 'Unknown';
            $maxAbsences = (int) (($subject?->max_absences) ?: $defaultMaxAbsences);
            $subjectAbsent = $records->where('status', 'absent')->count();
            $subjectTotal = $records->count();
            $absencePercent = $subjectTotal > 0 ? round(($subjectAbsent / $subjectTotal) * 100) : 0;
            $remainingAbsences = max($maxAbsences - $subjectAbsent, 0);

            $warningLevel = null;
            if ($absencePercent >= $deprivationThreshold) {
                $warningLevel = 'danger';
            } elseif ($subjectAbsent >= $maxAbsences) {
                $warningLevel = 'danger';
            } elseif ($subjectAbsent >= ($maxAbsences - 1)) {
                $warningLevel = 'warning';
            }

            $subjectWarnings[] = [
                'subject_id' => $subjectId,
                'subject_name' => $subjectName,
                'absent_count' => $subjectAbsent,
                'total_lectures' => $subjectTotal,
                'absence_percent' => $absencePercent,
                'warning_level' => $warningLevel,
                'max_absences_allowed' => $maxAbsences,
                'remaining_absences' => $remainingAbsences,
                'deprivation_threshold_percent' => $deprivationThreshold,
                'is_banned' => $warningLevel === 'danger',
            ];

            foreach ($records as $rec) {
                $history[] = [
                    'id' => $rec->id,
                    'subject_name' => $subjectName,
                    'date' => $rec->date,
                    'status' => $rec->status,
                    'is_excused' => in_array($rec->status, ExcuseWorkflow::countedAsExcusedStatuses(), true) || $rec->excuse !== null,
                    'excuse_status' => $rec->excuse?->status,
                    'excuse_resolution' => $rec->excuse?->resolution,
                ];
            }
        }

        usort($history, static function ($a, $b) {
            return strtotime($b['date']) - strtotime($a['date']);
        });

        return $this->success([
            'overview' => [
                'total_lectures' => $totalLectures,
                'present_count' => $presentCount,
                'absent_count' => $absentCount,
                'late_count' => $lateCount,
                'excused_count' => $excusedCount,
                'presence_percentage' => $presencePercentage,
            ],
            'subjects_status' => $subjectWarnings,
            'history' => $history,
        ]);
    }
}
