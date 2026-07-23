<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Academic\Subject;
use App\Models\Attendance;
use App\Models\User;
use App\Enums\UserRole;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    /**
     * لوحة تحكم التقارير (Reports Hub).
     */
    public function index()
    {
        // نحتاج بيانات للقوائم المنسدلة في فلاتر التقارير
        $universities = \App\Models\Academic\University::with('colleges.majors.levels')->get();
        // نحتاج قائمة المواد لتقرير المادة
        $subjects = Subject::with(['level', 'major'])->get();

        // إحصائيات سريعة — استعلام واحد مجمع بدلاً من N+1
        $totalStudents = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])->count();
        $totalDoctors = User::where('role', UserRole::DOCTOR)->count();
        $totalSubjects = Subject::count();
        $totalAttendance = Attendance::count();

        // توزيع الحضور
        $statusCounts = Attendance::select('status', DB::raw('count(*) as count'))
            ->groupBy('status')
            ->pluck('count', 'status');

        $presentCount = $statusCounts->get('present', 0);
        $absentCountAll = $statusCounts->get('absent', 0);
        $lateCount = $statusCounts->get('late', 0);
        $excusedCount = $statusCounts->get('excused', 0);

        // حساب المحرومين باستعلام واحد محسّن
        $subjectsMaxAbsences = Subject::pluck('max_absences', 'id');
        $absences = Attendance::where('status', 'absent')
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

        return view('admin.reports.index', compact(
            'universities',
            'subjects',
            'totalStudents',
            'totalDoctors',
            'totalSubjects',
            'totalAttendance',
            'presentCount',
            'absentCountAll',
            'lateCount',
            'excusedCount',
            'deprivedCount'
        ));
    }

    /**
     * تقرير الحضور التفصيلي لمادة (Subject Attendance Report).
     */
    public function subjectReport(Request $request)
    {
        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
        ]);

        $subject = Subject::with(['major', 'level', 'doctor'])->findOrFail($request->subject_id);

        // جلب جميع الطلاب المسجلين
        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->orderBy('name')
            ->get();

        // إحصائيات الحضور: جلب كل السجلات مرة واحدة لهذه المادة
        $attendances = Attendance::where('subject_id', $subject->id)
            ->get()
            ->groupBy('student_id');

        // إجمالي الجلسات (استعلام واحد)
        $totalSessions = Attendance::where('subject_id', $subject->id)
            ->distinct('date')
            ->count();

        $reportData = $students->map(function ($student) use ($attendances, $totalSessions) {
            // استرداد سجلات الطالب من المجموعة المحملة مسبقاً
            $records = $attendances->get($student->id, collect());

            $present = $records->where('status', 'present')->count();
            $late = $records->where('status', 'late')->count();
            $excused = $records->where('status', 'excused')->count();
            $absent = $records->where('status', 'absent')->count();

            $absencePercentage = 0;
            if ($totalSessions > 0) {
                $absencePercentage = round(($absent / $totalSessions) * 100, 1);
            }

            return [
                'student' => $student,
                'present' => $present,
                'late' => $late,
                'excused' => $excused,
                'absent' => $absent,
                'total_sessions' => $totalSessions,
                'absence_percentage' => $absencePercentage,
            ];
        });

        return view('admin.reports.subject_report', compact('subject', 'reportData'));
    }

    /**
     * تقرير الحرمان والإنذارات (Threshold Report).
     */
    public function thresholdReport(Request $request)
    {
        $request->validate([
            'level_id' => 'required|exists:levels,id',
            'threshold' => 'required|numeric|min:0|max:100', // نسبة الغياب المسموحة قبل التنبيه
        ]);

        $level = \App\Models\Academic\Level::with('major.college')->findOrFail($request->level_id);
        $threshold = $request->threshold;

        // 1. جلب مواد هذا المستوى
        $subjects = Subject::whereHas('term', function ($q) use ($level) {
            $q->where('level_id', $level->id);
        })->get();

        // 2. جلب طلاب هذا المستوى
        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('level_id', $level->id)
            ->get();

        $alertData = [];

        // أ. جلب إجمالي الجلسات لكل مادة مرة واحدة
        $subjectSessions = [];
        foreach ($subjects as $subject) {
            $subjectSessions[$subject->id] = Attendance::where('subject_id', $subject->id)
                ->distinct('date')
                ->count();
        }

        // ب. جلب إحصائيات الغياب لكل الطلاب في هذه المواد مرة واحدة
        $absences = Attendance::whereIn('subject_id', $subjects->pluck('id'))
            ->whereIn('student_id', $students->pluck('id'))
            ->where('status', 'absent')
            ->select('student_id', 'subject_id', DB::raw('count(*) as count'))
            ->groupBy('student_id', 'subject_id')
            ->get()
            ->groupBy('student_id');

        // ج. فحص كل طالب في كل مادة بدون استعلامات إضافية (N+1 Fixed)
        foreach ($students as $student) {
            $studentAbsences = $absences->get($student->id, collect())->keyBy('subject_id');

            foreach ($subjects as $subject) {
                $totalSessions = $subjectSessions[$subject->id] ?? 0;

                if ($totalSessions == 0) continue;

                $absentCount = $studentAbsences->has($subject->id) ? $studentAbsences[$subject->id]->count : 0;

                $percentage = ($absentCount / $totalSessions) * 100;

                if ($percentage >= $threshold) {
                    $alertData[] = [
                        'student' => $student,
                        'subject' => $subject,
                        'absence_percentage' => round($percentage, 1),
                        'absent_count' => $absentCount,
                        'total_sessions' => $totalSessions,
                    ];
                }
            }
        }

        return view('admin.reports.threshold_report', compact('level', 'threshold', 'alertData'));
    }

    /**
     * ملخص الدفعة الدراسية
     */
    public function levelSummary(Request $request)
    {
        $request->validate([
            'level_id' => 'required|exists:levels,id',
        ]);

        $level = \App\Models\Academic\Level::with(['major.college.university', 'terms.subjects.doctor'])->findOrFail($request->level_id);

        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('level_id', $level->id)
            ->get();

        $delegate = User::where('role', UserRole::DELEGATE)
            ->where('level_id', $level->id)
            ->first();

        $subjects = Subject::whereHas('term', function ($q) use ($level) {
            $q->where('level_id', $level->id);
        })->with('doctor')->get();

        // Calculate attendance stats per subject
        $subjectStats = $subjects->map(function ($subject) use ($students) {
            $totalRecords = Attendance::where('subject_id', $subject->id)->count();
            $presentCount = Attendance::where('subject_id', $subject->id)->where('status', 'present')->count();
            $attendanceRate = $totalRecords > 0 ? round(($presentCount / $totalRecords) * 100, 1) : 0;

            return [
                'subject' => $subject,
                'total_records' => $totalRecords,
                'attendance_rate' => $attendanceRate,
            ];
        });

        return view('admin.reports.level_summary', compact('level', 'students', 'delegate', 'subjectStats'));
    }

    /**
     * أداء أعضاء هيئة التدريس
     */
    public function doctorPerformance(Request $request)
    {
        $doctorId = $request->doctor_id;

        $query = User::where('role', UserRole::DOCTOR)->with('subjects');

        if ($doctorId) {
            $query->where('id', $doctorId);
        }

        $doctors = $query->get();

        $performanceData = $doctors->map(function ($doctor) {
            $subjects = $doctor->subjects;
            $totalSessions = 0;
            $totalPresent = 0;
            $totalRecords = 0;

            foreach ($subjects as $subject) {
                $sessions = Attendance::where('subject_id', $subject->id)->distinct('date')->count();
                $present = Attendance::where('subject_id', $subject->id)->where('status', 'present')->count();
                $records = Attendance::where('subject_id', $subject->id)->count();

                $totalSessions += $sessions;
                $totalPresent += $present;
                $totalRecords += $records;
            }

            $attendanceRate = $totalRecords > 0 ? round(($totalPresent / $totalRecords) * 100, 1) : 0;

            return [
                'doctor' => $doctor,
                'subjects_count' => $subjects->count(),
                'total_sessions' => $totalSessions,
                'attendance_rate' => $attendanceRate,
            ];
        });

        return view('admin.reports.doctor_performance', compact('performanceData'));
    }

    /**
     * تقرير التكاليف
     */
    public function assignmentsReport()
    {
        $assignments = \App\Models\Academic\Assignment::with(['subject.doctor', 'submissions'])->get();

        $stats = [
            'total' => $assignments->count(),
            'active' => $assignments->where('due_date', '>=', now())->count(),
            'expired' => $assignments->where('due_date', '<', now())->count(),
            'with_submissions' => $assignments->filter(fn($a) => $a->submissions->count() > 0)->count(),
        ];

        return view('admin.reports.assignments_report', compact('assignments', 'stats'));
    }

    /**
     * نظرة عامة على النظام
     */
    public function systemOverview()
    {
        $stats = [
            'students' => User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])->count(),
            'doctors' => User::where('role', UserRole::DOCTOR)->count(),
            'delegates' => User::where('role', UserRole::DELEGATE)->count(),
            'universities' => \App\Models\Academic\University::count(),
            'colleges' => \App\Models\Academic\College::count(),
            'majors' => \App\Models\Academic\Major::count(),
            'levels' => \App\Models\Academic\Level::count(),
            'subjects' => Subject::count(),
            'attendance_records' => Attendance::count(),
            'assignments' => \App\Models\Academic\Assignment::count(),
        ];

        // Attendance by status
        $attendanceByStatus = [
            'present' => Attendance::where('status', 'present')->count(),
            'absent' => Attendance::where('status', 'absent')->count(),
            'late' => Attendance::where('status', 'late')->count(),
            'excused' => Attendance::where('status', 'excused')->count(),
        ];

        // Recent activities
        $recentAttendance = Attendance::with(['student', 'subject'])
            ->latest()
            ->take(10)
            ->get();

        return view('admin.reports.system_overview', compact('stats', 'attendanceByStatus', 'recentAttendance'));
    }
}
