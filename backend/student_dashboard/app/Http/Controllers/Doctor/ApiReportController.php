<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Api\Doctor\DoctorApiController;
use App\Models\Academic\Subject;
use App\Models\Attendance;
use App\Models\QrAttendanceSession;
use App\Models\User;
use App\Support\ExcuseWorkflow;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class ApiReportController extends DoctorApiController
{
    public function index()
    {
        $subjects = Subject::where('doctor_id', Auth::id())->with(['major', 'level'])->get();

        $attendanceStats = Attendance::whereIn('subject_id', $subjects->pluck('id'))
            ->select(
                'subject_id',
                DB::raw('COUNT(*) as total'),
                DB::raw("SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present_count"),
                DB::raw("SUM(CASE WHEN status = 'absent' THEN 1 ELSE 0 END) as absent_count"),
                DB::raw("SUM(CASE WHEN status IN ('excused','permitted','exempted') THEN 1 ELSE 0 END) as excused_count"),
                DB::raw("SUM(CASE WHEN status = 'permitted' THEN 1 ELSE 0 END) as permitted_count"),
                DB::raw("SUM(CASE WHEN status = 'exempted' THEN 1 ELSE 0 END) as exempted_count"),
                DB::raw('COUNT(DISTINCT date) as lectures_count')
            )->groupBy('subject_id')->get()->keyBy('subject_id');

        $studentsCountPerSubject = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->whereIn('major_id', $subjects->pluck('major_id')->unique())
            ->whereIn('level_id', $subjects->pluck('level_id')->unique())
            ->select('major_id', 'level_id', DB::raw('count(*) as count'))
            ->groupBy('major_id', 'level_id')->get()
            ->keyBy(fn ($item) => $item->major_id . '_' . $item->level_id);

        $data = $subjects->map(function ($subject) use ($attendanceStats, $studentsCountPerSubject) {
            $stats = $attendanceStats->get($subject->id);
            $key = $subject->major_id . '_' . $subject->level_id;

            return [
                'id' => $subject->id,
                'name' => $subject->name,
                'major' => $subject->major?->name,
                'level' => $subject->level?->name,
                'students_count' => $studentsCountPerSubject->has($key) ? $studentsCountPerSubject->get($key)->count : 0,
                'lectures_count' => $stats?->lectures_count ?? 0,
                'present_count' => $stats?->present_count ?? 0,
                'absent_count' => $stats?->absent_count ?? 0,
                'excused_count' => $stats?->excused_count ?? 0,
                'permitted_count' => $stats?->permitted_count ?? 0,
                'exempted_count' => $stats?->exempted_count ?? 0,
                'attendance_rate' => $stats && $stats->total > 0
                    ? round((($stats->present_count + $stats->excused_count) / $stats->total) * 100)
                    : 0,
            ];
        });

        return $this->success($data);
    }

    public function show(Subject $subject)
    {
        if ($subject->doctor_id !== Auth::id()) {
            return $this->error('Unauthorized.', 403);
        }

        $students = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->with(['attendances' => fn ($query) => $query->where('subject_id', $subject->id)])
            ->get()
            ->map(function ($student) {
                $att = $student->attendances;
                $total = $att->count();
                $present = $att->where('status', 'present')->count();
                $absent = $att->where('status', 'absent')->count();
                $excused = $att->whereIn('status', ExcuseWorkflow::countedAsExcusedStatuses())->count();
                $permitted = $att->where('status', ExcuseWorkflow::STATUS_PERMITTED)->count();
                $exempted = $att->where('status', ExcuseWorkflow::STATUS_EXEMPTED)->count();

                return [
                    'id' => $student->id,
                    'name' => $student->name,
                    'student_number' => $student->student_number,
                    'total' => $total,
                    'present' => $present,
                    'absent' => $absent,
                    'excused' => $excused,
                    'permitted' => $permitted,
                    'exempted' => $exempted,
                    'attendance_rate' => $total > 0 ? round((($present + $excused) / $total) * 100) : 0,
                ];
            });

        return $this->success([
            'subject' => ['id' => $subject->id, 'name' => $subject->name],
            'students' => $students,
        ]);
    }

    public function pdf(Subject $subject)
    {
        if ($subject->doctor_id !== Auth::id()) {
            return $this->error('Unauthorized.', 403);
        }

        $subject->loadMissing(['major.college.university', 'level', 'term']);

        $students = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->with(['attendances' => fn ($query) => $query->where('subject_id', $subject->id)])
            ->orderBy('name')
            ->get()
            ->map(function ($student) {
                $attendances = $student->attendances;
                $total = $attendances->count();
                $present = $attendances->where('status', 'present')->count();
                $absent = $attendances->where('status', 'absent')->count();
                $excused = $attendances->whereIn('status', ExcuseWorkflow::countedAsExcusedStatuses())->count();

                return [
                    'name' => $student->name,
                    'student_number' => $student->student_number,
                    'total' => $total,
                    'present' => $present,
                    'absent' => $absent,
                    'excused' => $excused,
                    'attendance_rate' => $total > 0 ? round((($present + $excused) / $total) * 100) : 0,
                ];
            });

        $pdf = Pdf::loadView('doctor.reports.subject_report_app_pdf', [
            'subject' => $subject,
            'students' => $students,
            'generatedAt' => now()->format('Y-m-d H:i'),
        ]);
        $pdf->getDomPDF()->set_option('isRemoteEnabled', true);
        $pdf->getDomPDF()->set_option('isHtml5ParserEnabled', true);
        $pdf->getDomPDF()->set_option('defaultFont', 'DejaVu Sans');

        return response($pdf->setPaper('a4', 'portrait')->output(), 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename="doctor_subject_report_' . $subject->id . '_' . now()->format('Y-m-d_His') . '.pdf"',
        ]);
    }
}
