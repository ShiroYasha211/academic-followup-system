<?php

namespace App\Http\Controllers\Administrative;

use App\Enums\UserRole;
use App\Http\Controllers\Api\Administrative\AdministrativeApiController;
use App\Models\Academic\Major;
use App\Models\Academic\Subject;
use App\Models\Attendance;
use App\Models\QrAttendanceSession;
use App\Models\User;
use App\Support\ExcuseWorkflow;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ApiReportController extends AdministrativeApiController
{
    public function index()
    {
        $college = $this->college();

        $subjects = Subject::whereHas('major', fn ($query) => $query->where('college_id', $college->id))
            ->with(['level:id,name', 'major:id,name'])
            ->get(['id', 'name', 'level_id', 'major_id']);

        $statusCounts = Attendance::whereHas('student', fn ($query) => $query->where('college_id', $college->id))
            ->select('status', DB::raw('count(*) as count'))
            ->groupBy('status')
            ->pluck('count', 'status');

        $distribution = ExcuseWorkflow::statusDistribution($statusCounts);

        $subjectsMaxAbsences = Subject::whereHas('major', fn ($query) => $query->where('college_id', $college->id))
            ->pluck('max_absences', 'id');

        $absences = Attendance::where('status', 'absent')
            ->whereHas('student', fn ($query) => $query->where('college_id', $college->id))
            ->select('student_id', 'subject_id', DB::raw('count(*) as absent_count'))
            ->groupBy('student_id', 'subject_id')
            ->get();

        $deprivedCount = 0;
        foreach ($absences as $record) {
            $maxAbsences = $subjectsMaxAbsences->get($record->subject_id) ?? 4;
            if ($record->absent_count >= $maxAbsences) {
                $deprivedCount++;
            }
        }

        return $this->success([
            'summary' => [
                'total_students' => User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])->where('college_id', $college->id)->count(),
                'total_doctors' => User::where('role', UserRole::DOCTOR)->where('college_id', $college->id)->count(),
                'total_subjects' => Subject::whereHas('major', fn ($query) => $query->where('college_id', $college->id))->count(),
                'total_attendance' => Attendance::whereHas('student', fn ($query) => $query->where('college_id', $college->id))->count(),
                'present_count' => $distribution['present'],
                'absent_count' => $distribution['absent'],
                'late_count' => $distribution['late'],
                'excused_count' => $distribution['excused_total'],
                'permitted_count' => $distribution['permitted'],
                'exempted_count' => $distribution['exempted'],
                'deprived_count' => $deprivedCount,
            ],
            'subjects' => $subjects,
            'majors' => Major::where('college_id', $college->id)->with('levels:id,name,major_id')->get(['id', 'name']),
        ]);
    }

    public function attendance(Request $request)
    {
        $college = $this->college();
        $applyFilters = function ($query) use ($college, $request) {
            $query->whereHas('student', function ($query) use ($college, $request) {
                $query->where('college_id', $college->id);
                if ($request->filled('major_id')) {
                    $query->where('major_id', $request->integer('major_id'));
                }
                if ($request->filled('level_id')) {
                    $query->where('level_id', $request->integer('level_id'));
                }
            });

            if ($request->filled('date_start')) {
                $query->where('date', '>=', $request->date_start);
            }
            if ($request->filled('date_end')) {
                $query->where('date', '<=', $request->date_end);
            }
            if ($request->filled('search')) {
                $search = $request->search;
                $query->where(function ($query) use ($search) {
                    $query->whereHas('student', fn ($subQuery) => $subQuery->where('name', 'like', "%{$search}%")->orWhere('student_number', 'like', "%{$search}%"))
                        ->orWhereHas('subject', fn ($subQuery) => $subQuery->where('name', 'like', "%{$search}%"));
                });
            }
        };

        $today = now()->toDateString();
        $statsToday = [
            'present' => Attendance::whereDate('date', $today)->where('status', 'present')->whereHas('student', fn ($query) => $query->where('college_id', $college->id))->count(),
            'absent' => Attendance::whereDate('date', $today)->where('status', 'absent')->whereHas('student', fn ($query) => $query->where('college_id', $college->id))->count(),
            'excused' => Attendance::whereDate('date', $today)->whereIn('status', ExcuseWorkflow::countedAsExcusedStatuses())->whereHas('student', fn ($query) => $query->where('college_id', $college->id))->count(),
            'permitted' => Attendance::whereDate('date', $today)->where('status', ExcuseWorkflow::STATUS_PERMITTED)->whereHas('student', fn ($query) => $query->where('college_id', $college->id))->count(),
            'exempted' => Attendance::whereDate('date', $today)->where('status', ExcuseWorkflow::STATUS_EXEMPTED)->whereHas('student', fn ($query) => $query->where('college_id', $college->id))->count(),
            'active_sessions' => QrAttendanceSession::where('status', 'active')->whereHas('delegate', fn ($query) => $query->where('college_id', $college->id))->count(),
        ];

        $trendQuery = Attendance::query();
        $applyFilters($trendQuery);
        $trends = $trendQuery
            ->where('date', '>=', now()->subDays(6)->toDateString())
            ->select(
                'date',
                DB::raw('count(case when status = "present" then 1 end) as present'),
                DB::raw('count(case when status = "absent" then 1 end) as absent')
            )
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        $sessionQuery = Attendance::query();
        $applyFilters($sessionQuery);
        $dailySessions = $sessionQuery
            ->select(
                'subject_id',
                'date',
                'lecture_id',
                'recorded_by',
                DB::raw('count(*) as total_students'),
                DB::raw('count(case when status = "present" then 1 end) as present_count'),
                DB::raw('count(case when status = "absent" then 1 end) as absent_count')
            )
            ->with(['subject:id,name,doctor_id', 'subject.doctor:id,name', 'recorder:id,name'])
            ->groupBy('subject_id', 'date', 'lecture_id', 'recorded_by')
            ->latest('date')
            ->limit(12)
            ->get();

        $dangerQuery = Attendance::query();
        $applyFilters($dangerQuery);
        $dangerStudents = $dangerQuery
            ->select(
                'student_id',
                'subject_id',
                DB::raw('count(*) as total_lectures'),
                DB::raw('count(case when status = "absent" then 1 end) as absence_count')
            )
            ->groupBy('student_id', 'subject_id')
            ->with(['student:id,name,student_number,major_id,level_id', 'subject:id,name,max_absences'])
            ->get()
            ->filter(function ($row) {
                $limit = $row->subject->max_absences ?? 5;
                return $row->absence_count >= ($limit * 0.7);
            })
            ->values();

        $performance = User::where('college_id', $college->id)
            ->where('role', UserRole::DOCTOR)
            ->withCount(['subjects' => function ($query) use ($request) {
                if ($request->filled('major_id')) {
                    $query->where('major_id', $request->integer('major_id'));
                }
            }])
            ->get(['id', 'name'])
            ->map(function ($doctor) {
                $attendanceStats = Attendance::whereHas('subject', fn ($query) => $query->where('doctor_id', $doctor->id))
                    ->select(
                        DB::raw('count(*) as total'),
                        DB::raw('count(case when status = "present" then 1 end) as present')
                    )
                    ->first();

                $doctor->avg_attendance = $attendanceStats->total > 0
                    ? round(($attendanceStats->present / $attendanceStats->total) * 100, 1)
                    : 0;

                return $doctor;
            })
            ->sortByDesc('avg_attendance')
            ->values();

        $query = Attendance::with(['student:id,name,student_number,major_id,level_id', 'subject:id,name', 'excuse']);
        $applyFilters($query);
        $records = $query->latest('date')->paginate($request->integer('per_page', 20));

        return $this->success([
            'stats_today' => $statsToday,
            'trends' => $trends,
            'daily_sessions' => $dailySessions,
            'faculty_performance' => $performance,
            'danger_students' => $dangerStudents,
            'records' => collect($records->items())->map(function ($attendance) {
                return [
                    'id' => $attendance->id,
                    'date' => $attendance->date,
                    'status' => $attendance->status,
                    'status_label' => ExcuseWorkflow::attendanceStatusLabel($attendance->status),
                    'student' => $attendance->student,
                    'subject' => $attendance->subject,
                    'excuse' => $attendance->excuse ? [
                        'id' => $attendance->excuse->id,
                        'status' => $attendance->excuse->status,
                        'resolution' => $attendance->excuse->resolution,
                        'resolution_label' => ExcuseWorkflow::resolutionLabel($attendance->excuse->resolution),
                    ] : null,
                ];
            })->values(),
            'pagination' => [
                'current_page' => $records->currentPage(),
                'last_page' => $records->lastPage(),
                'per_page' => $records->perPage(),
                'total' => $records->total(),
            ],
            'majors' => Major::where('college_id', $college->id)->with('levels:id,name,major_id')->get(['id', 'name']),
        ]);
    }
}
