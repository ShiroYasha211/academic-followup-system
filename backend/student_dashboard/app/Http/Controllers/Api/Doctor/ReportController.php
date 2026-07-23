<?php

namespace App\Http\Controllers\Api\Doctor;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Models\Academic\Subject;
use App\Models\User;
use App\Models\Attendance;
use App\Enums\UserRole;

class ReportController extends DoctorApiController
{
    /** GET /api/doctor/reports */
    public function index()
    {
        $subjects = Subject::where('doctor_id', Auth::id())->with(['major', 'level'])->get();

        $attendanceStats = Attendance::whereIn('subject_id', $subjects->pluck('id'))
            ->select(
                'subject_id',
                DB::raw('COUNT(*) as total'),
                DB::raw("SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present_count"),
                DB::raw("SUM(CASE WHEN status = 'absent' THEN 1 ELSE 0 END) as absent_count"),
                DB::raw("SUM(CASE WHEN status = 'excused' THEN 1 ELSE 0 END) as excused_count"),
                DB::raw('COUNT(DISTINCT date) as lectures_count')
            )->groupBy('subject_id')->get()->keyBy('subject_id');

        $studentsCountPerSubject = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->whereIn('major_id', $subjects->pluck('major_id')->unique())
            ->whereIn('level_id', $subjects->pluck('level_id')->unique())
            ->select('major_id', 'level_id', DB::raw('count(*) as count'))
            ->groupBy('major_id', 'level_id')->get()
            ->keyBy(fn($item) => $item->major_id . '_' . $item->level_id);

        $data = $subjects->map(function ($s) use ($attendanceStats, $studentsCountPerSubject) {
            $stats = $attendanceStats->get($s->id);
            $key = $s->major_id . '_' . $s->level_id;
            return [
                'id' => $s->id,
                'name' => $s->name,
                'major' => $s->major?->name,
                'level' => $s->level?->name,
                'students_count' => $studentsCountPerSubject->has($key) ? $studentsCountPerSubject->get($key)->count : 0,
                'lectures_count' => $stats?->lectures_count ?? 0,
                'present_count' => $stats?->present_count ?? 0,
                'absent_count' => $stats?->absent_count ?? 0,
                'excused_count' => $stats?->excused_count ?? 0,
                'attendance_rate' => $stats && $stats->total > 0 ? round(($stats->present_count / $stats->total) * 100) : 0,
            ];
        });

        return $this->success($data);
    }

    /** GET /api/doctor/reports/{subject} */
    public function show(Subject $subject)
    {
        if ($subject->doctor_id !== Auth::id()) {
            return $this->error('غير مصرح لك.', 403);
        }

        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->with(['attendances' => fn($q) => $q->where('subject_id', $subject->id)])
            ->get()
            ->map(function ($student) {
                $att = $student->attendances;
                $total = $att->count();
                $present = $att->where('status', 'present')->count();
                $absent = $att->where('status', 'absent')->count();
                $excused = $att->where('status', 'excused')->count();

                return [
                    'id' => $student->id,
                    'name' => $student->name,
                    'student_number' => $student->student_number,
                    'total' => $total,
                    'present' => $present,
                    'absent' => $absent,
                    'excused' => $excused,
                    'attendance_rate' => $total > 0 ? round(($present / $total) * 100) : 0,
                ];
            });

        return $this->success([
            'subject' => ['id' => $subject->id, 'name' => $subject->name],
            'students' => $students,
        ]);
    }
}
