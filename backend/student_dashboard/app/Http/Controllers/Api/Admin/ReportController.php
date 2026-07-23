<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Academic\Subject;
use App\Models\Attendance;
use App\Models\User;
use App\Enums\UserRole;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends AdminApiController
{
    /**
     * GET /api/admin/reports/overview — Overview stats
     */
    public function overview()
    {
        $statusCounts = Attendance::select('status', DB::raw('count(*) as count'))
            ->groupBy('status')->pluck('count', 'status');

        $totalAttendance = Attendance::count();

        return $this->success([
            'total_students' => User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])->count(),
            'total_doctors' => User::where('role', UserRole::DOCTOR)->count(),
            'total_subjects' => Subject::count(),
            'total_attendance' => $totalAttendance,
            'present' => $statusCounts->get('present', 0),
            'absent' => $statusCounts->get('absent', 0),
            'late' => $statusCounts->get('late', 0),
            'excused' => $statusCounts->get('excused', 0),
        ]);
    }

    /**
     * GET /api/admin/reports/subject?subject_id=
     */
    public function subject(Request $request)
    {
        $request->validate(['subject_id' => 'required|exists:subjects,id']);
        $subject = Subject::with('doctor', 'term.level.major')->findOrFail($request->subject_id);

        $students = DB::table('attendances')
            ->where('subject_id', $subject->id)
            ->select(
                'student_id',
                DB::raw('SUM(CASE WHEN status = "present" THEN 1 ELSE 0 END) as present'),
                DB::raw('SUM(CASE WHEN status = "absent" THEN 1 ELSE 0 END) as absent'),
                DB::raw('SUM(CASE WHEN status = "late" THEN 1 ELSE 0 END) as late'),
                DB::raw('SUM(CASE WHEN status = "excused" THEN 1 ELSE 0 END) as excused'),
                DB::raw('COUNT(*) as total')
            )
            ->groupBy('student_id')
            ->get()
            ->map(function ($row) {
                $student = User::find($row->student_id);
                return [
                    'student' => $student ? ['id' => $student->id, 'name' => $student->name, 'student_number' => $student->student_number] : null,
                    'present' => $row->present,
                    'absent' => $row->absent,
                    'late' => $row->late,
                    'excused' => $row->excused,
                    'total' => $row->total,
                    'absence_rate' => $row->total > 0 ? round(($row->absent / $row->total) * 100, 1) : 0,
                ];
            });

        return $this->success([
            'subject' => $subject,
            'records' => $students,
        ]);
    }

    /**
     * GET /api/admin/reports/threshold?level_id=&threshold=
     */
    public function threshold(Request $request)
    {
        $request->validate([
            'level_id' => 'required|exists:levels,id',
            'threshold' => 'integer|min:1|max:100',
        ]);

        $threshold = $request->threshold ?? 25;
        $level = \App\Models\Academic\Level::with('terms.subjects')->findOrFail($request->level_id);

        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('level_id', $level->id)->get();

        $subjectIds = $level->terms->flatMap->subjects->pluck('id');
        $maxAbsences = Subject::whereIn('id', $subjectIds)->pluck('max_absences', 'id');

        $results = [];
        foreach ($students as $student) {
            foreach ($subjectIds as $subjectId) {
                $absent = Attendance::where('student_id', $student->id)
                    ->where('subject_id', $subjectId)
                    ->where('status', 'absent')->count();
                $max = $maxAbsences->get($subjectId, 4);

                if ($max > 0 && ($absent / $max) * 100 >= $threshold) {
                    $results[] = [
                        'student' => ['id' => $student->id, 'name' => $student->name, 'student_number' => $student->student_number],
                        'subject_id' => $subjectId,
                        'absent_count' => $absent,
                        'max_absences' => $max,
                        'percentage' => round(($absent / $max) * 100, 1),
                    ];
                }
            }
        }

        return $this->success(['level' => $level->name, 'threshold' => $threshold, 'results' => $results]);
    }

    /**
     * GET /api/admin/reports/doctor-performance?doctor_id=
     */
    public function doctorPerformance(Request $request)
    {
        $query = User::where('role', UserRole::DOCTOR);
        if ($request->doctor_id) {
            $query->where('id', $request->doctor_id);
        }

        $doctors = $query->get()->map(function ($doctor) {
            $subjects = Subject::where('doctor_id', $doctor->id)->get();
            $subjectStats = $subjects->map(function ($subject) {
                $total = Attendance::where('subject_id', $subject->id)->count();
                $present = Attendance::where('subject_id', $subject->id)->where('status', 'present')->count();
                return [
                    'subject' => $subject->name,
                    'total_records' => $total,
                    'attendance_rate' => $total > 0 ? round(($present / $total) * 100, 1) : 0,
                ];
            });

            return [
                'doctor' => ['id' => $doctor->id, 'name' => $doctor->name, 'email' => $doctor->email],
                'subjects_count' => $subjects->count(),
                'subjects' => $subjectStats,
            ];
        });

        return $this->success($doctors);
    }

    /**
     * GET /api/admin/reports/system-overview
     */
    public function systemOverview()
    {
        return $this->success([
            'users' => [
                'total' => User::count(),
                'students' => User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])->count(),
                'doctors' => User::where('role', UserRole::DOCTOR)->count(),
                'delegates' => User::where('role', UserRole::DELEGATE)->count(),
                'active' => User::where('status', 'active')->count(),
                'inactive' => User::where('status', 'inactive')->count(),
            ],
            'academic' => [
                'universities' => \App\Models\Academic\University::count(),
                'colleges' => \App\Models\Academic\College::count(),
                'majors' => \App\Models\Academic\Major::count(),
                'subjects' => Subject::count(),
            ],
            'attendance' => [
                'total' => Attendance::count(),
                'today' => Attendance::whereDate('date', today())->count(),
            ],
        ]);
    }
}
