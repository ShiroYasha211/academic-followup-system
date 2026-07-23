<?php

namespace App\Http\Controllers\Administrative;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\User;
use App\Enums\UserRole;
use App\Models\Academic\Major;
use App\Models\Academic\Level;
use App\Models\QrAttendanceSession;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Support\ExcuseWorkflow;

class ReportController extends Controller
{
    /**
     * لوحة تحكم التقارير (Reports Hub).
     */
    public function index()
    {
        $college = auth()->user()->college;
        
        // نحتاج قائمة المواد لتقرير المادة (مقصورة على الكلية)
        $subjects = \App\Models\Academic\Subject::whereHas('major', function($q) use ($college) {
                $q->where('college_id', $college->id);
            })
            ->with(['level', 'major'])
            ->get();

        // إحصائيات سريعة (مقصورة على الكلية)
        $totalStudents = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('college_id', $college->id)
            ->count();
        
        $totalDoctors = User::where('role', UserRole::DOCTOR)
            ->where('college_id', $college->id)
            ->count();
        
        $totalSubjects = \App\Models\Academic\Subject::whereHas('major', function($q) use ($college) {
            $q->where('college_id', $college->id);
        })->count();
        
        $totalAttendance = Attendance::whereHas('student', function($q) use ($college) {
            $q->where('college_id', $college->id);
        })->count();

        // توزيع الحضور (مقصور على الكلية)
        $statusCounts = Attendance::whereHas('student', function($q) use ($college) {
            $q->where('college_id', $college->id);
        })
            ->select('status', DB::raw('count(*) as count'))
            ->groupBy('status')
            ->pluck('count', 'status');

        $distribution = ExcuseWorkflow::statusDistribution($statusCounts);
        $presentCount = $distribution['present'];
        $absentCountAll = $distribution['absent'];
        $lateCount = $distribution['late'];
        $excusedCount = $distribution['excused_total'];
        $permittedCount = $distribution['permitted'];
        $exemptedCount = $distribution['exempted'];

        // حساب المحرومين (مقصور على الكلية)
        $subjectsMaxAbsences = \App\Models\Academic\Subject::whereHas('major', function($q) use ($college) {
            $q->where('college_id', $college->id);
        })->pluck('max_absences', 'id');
        $absences = Attendance::where('status', 'absent')
            ->whereHas('student', function($q) use ($college) {
                $q->where('college_id', $college->id);
            })
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

        $majors = Major::where('college_id', $college->id)->get();

        return view('administrative.reports.index', compact(
            'subjects',
            'totalStudents',
            'totalDoctors',
            'totalSubjects',
            'totalAttendance',
            'presentCount',
            'absentCountAll',
            'lateCount',
            'excusedCount',
            'permittedCount',
            'exemptedCount',
            'deprivedCount',
            'majors'
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

        $college = auth()->user()->college;
        $subject = \App\Models\Academic\Subject::whereHas('major', function($q) use ($college) {
                $q->where('college_id', $college->id);
            })
            ->with(['major', 'level', 'doctor'])
            ->findOrFail($request->subject_id);

        // جلب جميع الطلاب المسجلين في هذا التخصص والمستوى (التابعين للكلية تلقائياً)
        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->orderBy('name')
            ->get();

        // إحصائيات الحضور: جلب كل السجلات مرة واحدة لهذه المادة
        $attendances = Attendance::where('subject_id', $subject->id)
            ->get()
            ->groupBy('student_id');

        // إجمالي الجلسات
        $totalSessions = Attendance::where('subject_id', $subject->id)
            ->distinct('date')
            ->count();

        $reportData = $students->map(function ($student) use ($attendances, $totalSessions) {
            $records = $attendances->get($student->id, collect());

            $present = $records->where('status', 'present')->count();
            $late = $records->where('status', 'late')->count();
            $excused = $records->whereIn('status', ExcuseWorkflow::countedAsExcusedStatuses())->count();
            $permitted = $records->where('status', ExcuseWorkflow::STATUS_PERMITTED)->count();
            $exempted = $records->where('status', ExcuseWorkflow::STATUS_EXEMPTED)->count();
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
                'permitted' => $permitted,
                'exempted' => $exempted,
                'absent' => $absent,
                'total_sessions' => $totalSessions,
                'absence_percentage' => $absencePercentage,
            ];
        });

        return view('administrative.reports.subject_report', compact('subject', 'reportData'));
    }

    /**
     * تقرير الحرمان والإنذارات (Threshold Report).
     */
    public function thresholdReport(Request $request)
    {
        $request->validate([
            'level_id' => 'required|exists:levels,id',
            'threshold' => 'required|numeric|min:0|max:100',
        ]);

        $college = auth()->user()->college;
        $level = \App\Models\Academic\Level::whereHas('major', function($q) use ($college) {
            $q->where('college_id', $college->id);
        })->with('major.college')->findOrFail($request->level_id);
        
        $threshold = $request->threshold;

        // 1. جلب مواد هذا المستوى في هذه الكلية
        $subjects = \App\Models\Academic\Subject::whereHas('major', function($q) use ($college) {
                $q->where('college_id', $college->id);
            })
            ->whereHas('term', function ($q) use ($level) {
                $q->where('level_id', $level->id);
            })->get();

        // 2. جلب طلاب هذا المستوى في الكلية
        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('level_id', $level->id)
            ->where('college_id', $college->id)
            ->get();

        $alertData = [];

        // أ. جلب إجمالي الجلسات لكل مادة
        $subjectSessions = [];
        foreach ($subjects as $subject) {
            $subjectSessions[$subject->id] = Attendance::where('subject_id', $subject->id)
                ->distinct('date')
                ->count();
        }

        // ب. جلب إحصائيات الغياب
        $absences = Attendance::whereIn('subject_id', $subjects->pluck('id'))
            ->whereIn('student_id', $students->pluck('id'))
            ->where('status', 'absent')
            ->select('student_id', 'subject_id', DB::raw('count(*) as count'))
            ->groupBy('student_id', 'subject_id')
            ->get()
            ->groupBy('student_id');

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

        return view('administrative.reports.threshold_report', compact('level', 'threshold', 'alertData'));
    }

    /**
     * ملخص الدفعة الدراسية
     */
    public function levelSummary(Request $request)
    {
        $request->validate([
            'level_id' => 'required|exists:levels,id',
        ]);

        $college = auth()->user()->college;
        $level = \App\Models\Academic\Level::whereHas('major', function($q) use ($college) {
            $q->where('college_id', $college->id);
        })->with(['major.college.university', 'terms.subjects.doctor'])->findOrFail($request->level_id);

        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('level_id', $level->id)
            ->where('college_id', $college->id)
            ->get();

        $delegate = User::where('role', UserRole::DELEGATE)
            ->where('level_id', $level->id)
            ->where('college_id', $college->id)
            ->first();

        $subjects = \App\Models\Academic\Subject::whereHas('major', function($q) use ($college) {
                $q->where('college_id', $college->id);
            })
            ->whereHas('term', function ($q) use ($level) {
                $q->where('level_id', $level->id);
            })->with('doctor')->get();

        $subjectStats = $subjects->map(function ($subject) {
            $totalRecords = Attendance::where('subject_id', $subject->id)->count();
            $presentCount = Attendance::where('subject_id', $subject->id)->where('status', 'present')->count();
            $attendanceRate = $totalRecords > 0 ? round(($presentCount / $totalRecords) * 100, 1) : 0;

            return [
                'subject' => $subject,
                'total_records' => $totalRecords,
                'attendance_rate' => $attendanceRate,
            ];
        });

        return view('administrative.reports.level_summary', compact('level', 'students', 'delegate', 'subjectStats'));
    }

    /**
     * Doctor Performance Report.
     */
    public function doctorPerformance(Request $request)
    {
        $college = auth()->user()->college;
        
        $doctors = User::where('college_id', $college->id)
            ->where('role', UserRole::DOCTOR)
            ->withCount(['qrSessions' => function($q) {
                $q->where('status', 'finalized');
            }])
            ->get();

        foreach ($doctors as $doctor) {
            $sessions = $doctor->qrSessions()
                ->where('status', 'finalized')
                ->with('subject')
                ->get();
            
            if ($sessions->count() > 0) {
                $totalPossible = 0;
                $totalPresent = 0;

                foreach ($sessions as $session) {
                    $subject = $session->subject;
                    if (!$subject) continue;

                    // The expected number of students is all students in the major/level of that subject
                    $expectedCount = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
                        ->where('major_id', $subject->major_id)
                        ->where('level_id', $subject->level_id)
                        ->count();
                    
                    $totalPossible += $expectedCount;

                    // Actual present students for this specific session
                    $totalPresent += Attendance::where('subject_id', $session->subject_id)
                        ->whereDate('date', $session->date)
                        ->where('status', 'present')
                        ->count();
                }

                $doctor->attendance_rate = $totalPossible > 0 ? round(($totalPresent / $totalPossible) * 100, 1) : 0;
            } else {
                $doctor->attendance_rate = 0;
            }
        }

        return view('administrative.reports.doctors', compact('doctors'));
    }

    /**
     * Detailed Attendance Report.
     */
    public function attendance(Request $request)
    {
        $college = auth()->user()->college;
        $today = now()->startOfDay();
        
        // --- 1. Filter Initialization ---
        $majorId = $request->major_id;
        $levelId = $request->level_id;
        $dateStart = $request->date_start;
        $dateEnd = $request->date_end;
        $search = $request->search;

        // --- 2. Base Query Closure for Re-use ---
        $applyFilters = function($query) use ($college, $majorId, $levelId, $dateStart, $dateEnd, $search) {
            $query->whereHas('student', function($q) use ($college, $majorId, $levelId) {
                $q->where('college_id', $college->id);
                if ($majorId) $q->where('major_id', $majorId);
                if ($levelId) $q->where('level_id', $levelId);
            });
            
            if ($dateStart) $query->where('date', '>=', $dateStart);
            if ($dateEnd) $query->where('date', '<=', $dateEnd);
            
            if ($search) {
                $query->where(function($q) use ($search) {
                    $q->whereHas('student', fn($sq) => $sq->where('name', 'like', "%$search%")->orWhere('student_number', 'like', "%$search%"))
                      ->orWhereHas('subject', fn($sq) => $sq->where('name', 'like', "%$search%"));
                });
            }
        };

        // --- 3. Dashboard Metrics (Cards) ---
        $statsToday = [
            'present' => Attendance::where('date', $today)->where('status', 'present')->whereHas('student', fn($q) => $q->where('college_id', $college->id))->count(),
            'absent' => Attendance::where('date', $today)->where('status', 'absent')->whereHas('student', fn($q) => $q->where('college_id', $college->id))->count(),
            'excused' => Attendance::where('date', $today)->whereIn('status', ExcuseWorkflow::countedAsExcusedStatuses())->whereHas('student', fn($q) => $q->where('college_id', $college->id))->count(),
            'permitted' => Attendance::where('date', $today)->where('status', ExcuseWorkflow::STATUS_PERMITTED)->whereHas('student', fn($q) => $q->where('college_id', $college->id))->count(),
            'exempted' => Attendance::where('date', $today)->where('status', ExcuseWorkflow::STATUS_EXEMPTED)->whereHas('student', fn($q) => $q->where('college_id', $college->id))->count(),
            'active_sessions' => QrAttendanceSession::where('status', 'active')->whereHas('delegate', fn($q) => $q->where('college_id', $college->id))->count(),
        ];

        // --- 4. Trend Analysis (Last 7 Days) ---
        $sevenDaysAgo = now()->subDays(6)->startOfDay();
        $trends = Attendance::tap($applyFilters)
            ->where('date', '>=', $sevenDaysAgo)
            ->select('date', 
                DB::raw('count(case when status = "present" then 1 end) as present'),
                DB::raw('count(case when status = "absent" then 1 end) as absent')
            )
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        // --- 5. Daily Session Reports ---
        // We group by subject, date, and lecture_id to represent specific "Classes"
        $dailySessions = Attendance::tap($applyFilters)
            ->select(
                'subject_id', 'date', 'lecture_id', 'recorded_by',
                DB::raw('count(*) as total_students'),
                DB::raw('count(case when status = "present" then 1 end) as present_count'),
                DB::raw('count(case when status = "absent" then 1 end) as absent_count')
            )
            ->with(['subject.doctor', 'recorder'])
            ->groupBy('subject_id', 'date', 'lecture_id', 'recorded_by')
            ->latest('date')
            ->get();

        // --- 6. Faculty Engagement (merged doctorPerformance logic) ---
        $facultyPerformance = User::where('college_id', $college->id)
            ->where('role', UserRole::DOCTOR)
            ->withCount(['subjects' => function($q) use ($majorId) {
                if ($majorId) $q->where('major_id', $majorId);
            }])
            ->get()
            ->map(function($doctor) use ($college) {
                // Get sessions for this specific doctor in this college
                $sessions = Attendance::whereHas('subject', fn($q) => $q->where('doctor_id', $doctor->id))
                    ->select('subject_id', 'date', 'lecture_id')
                    ->groupBy('subject_id', 'date', 'lecture_id')
                    ->get();
                
                $doctor->session_count = $sessions->count();
                
                // Average attendance rate across all his subjects
                $attendanceStats = Attendance::whereHas('subject', fn($q) => $q->where('doctor_id', $doctor->id))
                    ->select(DB::raw('count(*) as total'), DB::raw('count(case when status = "present" then 1 end) as present'))
                    ->first();
                
                $doctor->avg_attendance = $attendanceStats->total > 0 
                    ? round(($attendanceStats->present / $attendanceStats->total) * 100, 1) 
                    : 0;
                
                return $doctor;
            })->sortByDesc('avg_attendance')->values();

        // --- 7. Danger Zone (Student Absences Monitoring) ---
        $dangerStudents = Attendance::tap($applyFilters)
            ->select('student_id', 'subject_id', 
                DB::raw('count(*) as total_lectures'),
                DB::raw('count(case when status = "absent" then 1 end) as absence_count')
            )
            ->groupBy('student_id', 'subject_id')
            ->with(['student.major', 'subject'])
            ->get()
            ->filter(function($row) {
                $limit = $row->subject->max_absences ?? 5;
                return $row->absence_count >= ($limit * 0.7); // Start alerting at 70% risk
            })->values();

        // --- 8. Raw Audit Logs (Current view logic) ---
        $auditLogs = Attendance::tap($applyFilters)
            ->with(['student.major', 'student.level', 'subject.doctor', 'excuse'])
            ->latest()
            ->paginate(20)
            ->withQueryString();

        $majors = Major::where('college_id', $college->id)->get();

        return view('administrative.reports.attendance-clean', [
            'auditLogs' => $auditLogs,
            'stats' => $statsToday,
            'trends' => $trends,
            'dailySessions' => $dailySessions,
            'facultyPerformance' => $facultyPerformance,
            'dangerStudents' => $dangerStudents,
            'majors' => $majors
        ]);
    }
}
