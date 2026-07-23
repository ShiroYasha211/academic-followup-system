<?php

namespace App\Http\Controllers\Api\Administrative;

use App\Enums\UserRole;
use App\Models\Academic\Level;
use App\Models\Academic\Major;
use App\Models\Academic\Subject;
use App\Models\Attendance;
use App\Models\StudentNotification;
use App\Models\User;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ReportController extends AdministrativeApiController
{
    public function index()
    {
        $college = $this->college();

        $subjects = Subject::whereHas('major', fn ($q) => $q->where('college_id', $college->id))
            ->with(['level:id,name', 'major:id,name', 'doctor:id,name'])
            ->get(['id', 'name', 'level_id', 'major_id', 'doctor_id']);

        $totalStudents = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('college_id', $college->id)
            ->count();

        $totalDoctors = User::where('role', UserRole::DOCTOR)
            ->where('college_id', $college->id)
            ->count();

        $totalSubjects = Subject::whereHas('major', fn ($q) => $q->where('college_id', $college->id))->count();
        $totalAttendance = Attendance::whereHas('student', fn ($q) => $q->where('college_id', $college->id))->count();

        $statusCounts = Attendance::whereHas('student', fn ($q) => $q->where('college_id', $college->id))
            ->select('status', DB::raw('count(*) as count'))
            ->groupBy('status')
            ->pluck('count', 'status');

        $subjectsMaxAbsences = Subject::whereHas('major', fn ($q) => $q->where('college_id', $college->id))
            ->pluck('max_absences', 'id');

        $absences = Attendance::where('status', 'absent')
            ->whereHas('student', fn ($q) => $q->where('college_id', $college->id))
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
                'total_students' => $totalStudents,
                'total_doctors' => $totalDoctors,
                'total_subjects' => $totalSubjects,
                'total_attendance' => $totalAttendance,
                'present_count' => $statusCounts->get('present', 0),
                'absent_count' => $statusCounts->get('absent', 0),
                'late_count' => $statusCounts->get('late', 0),
                'excused_count' => $statusCounts->get('excused', 0),
                'deprived_count' => $deprivedCount,
            ],
            'subjects' => $subjects,
            'majors' => Major::where('college_id', $college->id)->with('levels:id,name,major_id')->get(['id', 'name']),
        ]);
    }

    public function subjectReport(Request $request)
    {
        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'date_start' => 'nullable|date',
            'date_end' => 'nullable|date|after_or_equal:date_start',
        ]);

        $subject = Subject::whereHas('major', fn ($q) => $q->where('college_id', $this->college()->id))
            ->with(['major:id,name', 'level:id,name', 'doctor:id,name'])
            ->findOrFail($request->subject_id);

        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->orderBy('name')
            ->get(['id', 'name', 'student_number']);

        $attendanceQuery = Attendance::where('subject_id', $subject->id);
        $this->applyDateRange($attendanceQuery, $request);
        $attendances = $attendanceQuery->get()->groupBy('student_id');

        $sessionsQuery = Attendance::where('subject_id', $subject->id);
        $this->applyDateRange($sessionsQuery, $request);
        $totalSessions = $sessionsQuery->distinct('date')->count('date');

        $reportData = $students->map(function ($student) use ($attendances, $totalSessions, $subject) {
            $records = $attendances->get($student->id, collect());
            $absent = $records->where('status', 'absent')->count();
            $percentage = $totalSessions > 0 ? round(($absent / $totalSessions) * 100, 1) : 0;
            $decision = $this->absenceDecision($absent, (int) ($subject->max_absences ?? 4));

            return [
                'student' => $student,
                'present' => $records->where('status', 'present')->count(),
                'late' => $records->where('status', 'late')->count(),
                'excused' => $records->where('status', 'excused')->count(),
                'absent' => $absent,
                'total_sessions' => $totalSessions,
                'absence_percentage' => $percentage,
                'decision' => $decision,
                'decision_color' => $this->decisionColor($decision),
            ];
        })->values();

        return $this->success([
            'subject' => $subject,
            'summary' => $this->subjectSummary($reportData),
            'date_range' => $this->dateRangePayload($request),
            'report' => $reportData,
        ]);
    }

    public function thresholdReport(Request $request)
    {
        $request->validate([
            'level_id' => 'required|exists:levels,id',
            'threshold' => 'required|numeric|min:0|max:100',
            'date_start' => 'nullable|date',
            'date_end' => 'nullable|date|after_or_equal:date_start',
        ]);

        $level = Level::whereHas('major', fn ($q) => $q->where('college_id', $this->college()->id))
            ->with('major:id,name')
            ->findOrFail($request->level_id);

        $subjects = Subject::whereHas('major', fn ($q) => $q->where('college_id', $this->college()->id))
            ->where('level_id', $level->id)
            ->get(['id', 'name', 'level_id', 'major_id']);

        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('level_id', $level->id)
            ->where('college_id', $this->college()->id)
            ->get(['id', 'name', 'student_number']);

        $subjectSessions = [];
        foreach ($subjects as $subject) {
            $sessionsQuery = Attendance::where('subject_id', $subject->id);
            $this->applyDateRange($sessionsQuery, $request);
            $subjectSessions[$subject->id] = $sessionsQuery->distinct('date')->count('date');
        }

        $absencesQuery = Attendance::whereIn('subject_id', $subjects->pluck('id'))
            ->whereIn('student_id', $students->pluck('id'))
            ->where('status', 'absent')
            ->select('student_id', 'subject_id', DB::raw('count(*) as count'))
            ->groupBy('student_id', 'subject_id');
        $this->applyDateRange($absencesQuery, $request);
        $absences = $absencesQuery->get()->groupBy('student_id');

        $alertData = [];
        $threshold = (float) $request->threshold;
        foreach ($students as $student) {
            $studentAbsences = $absences->get($student->id, collect())->keyBy('subject_id');
            foreach ($subjects as $subject) {
                $totalSessions = $subjectSessions[$subject->id] ?? 0;
                if ($totalSessions === 0) {
                    continue;
                }
                $absentCount = $studentAbsences->has($subject->id) ? $studentAbsences[$subject->id]->count : 0;
                $percentage = ($absentCount / $totalSessions) * 100;
                if ($percentage >= $threshold) {
                    $severity = $percentage >= 25 ? 'critical' : 'warning';
                    $alertData[] = [
                        'student' => $student,
                        'subject' => $subject,
                        'absence_percentage' => round($percentage, 1),
                        'absent_count' => $absentCount,
                        'total_sessions' => $totalSessions,
                        'severity' => $severity,
                        'action_label' => $severity === 'critical' ? 'حرمان' : 'إنذار',
                    ];
                }
            }
        }

        return $this->success([
            'level' => $level,
            'threshold' => $threshold,
            'summary' => [
                'alerts_count' => count($alertData),
                'students_count' => $students->count(),
                'subjects_count' => $subjects->count(),
                'critical_count' => collect($alertData)->where('severity', 'critical')->count(),
                'warning_count' => collect($alertData)->where('severity', 'warning')->count(),
                'highest_percentage' => collect($alertData)->max('absence_percentage') ?? 0,
            ],
            'date_range' => $this->dateRangePayload($request),
            'alerts' => $alertData,
        ]);
    }

    public function levelSummary(Request $request)
    {
        $request->validate([
            'level_id' => 'required|exists:levels,id',
            'date_start' => 'nullable|date',
            'date_end' => 'nullable|date|after_or_equal:date_start',
        ]);

        $level = Level::whereHas('major', fn ($q) => $q->where('college_id', $this->college()->id))
            ->with(['major:id,name', 'terms.subjects.doctor:id,name'])
            ->findOrFail($request->level_id);

        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('level_id', $level->id)
            ->where('college_id', $this->college()->id)
            ->get(['id', 'name', 'student_number']);

        $delegate = User::where('role', UserRole::DELEGATE)
            ->where('level_id', $level->id)
            ->where('college_id', $this->college()->id)
            ->first(['id', 'name', 'student_number']);

        $subjects = Subject::where('level_id', $level->id)
            ->whereHas('major', fn ($q) => $q->where('college_id', $this->college()->id))
            ->with('doctor:id,name')
            ->get(['id', 'name', 'doctor_id', 'level_id', 'major_id']);

        $subjectStats = $subjects->map(function ($subject) use ($request) {
            $totalQuery = Attendance::where('subject_id', $subject->id);
            $this->applyDateRange($totalQuery, $request);
            $totalRecords = $totalQuery->count();

            $presentQuery = Attendance::where('subject_id', $subject->id)->where('status', 'present');
            $this->applyDateRange($presentQuery, $request);
            $presentCount = $presentQuery->count();

            return [
                'subject' => $subject,
                'total_records' => $totalRecords,
                'attendance_rate' => $totalRecords > 0 ? round(($presentCount / $totalRecords) * 100, 1) : 0,
            ];
        })->values();

        return $this->success([
            'level' => $level,
            'students' => $students,
            'delegate' => $delegate,
            'summary' => [
                'students_count' => $students->count(),
                'subjects_count' => $subjects->count(),
                'average_attendance_rate' => round($subjectStats->avg('attendance_rate') ?? 0, 1),
                'lowest_subject_rate' => $subjectStats->min('attendance_rate') ?? 0,
                'best_subject' => $subjectStats->sortByDesc('attendance_rate')->first(),
                'weakest_subject' => $subjectStats->sortBy('attendance_rate')->first(),
            ],
            'date_range' => $this->dateRangePayload($request),
            'subject_stats' => $subjectStats,
        ]);
    }

    public function doctorPerformance(Request $request)
    {
        $request->validate([
            'date_start' => 'nullable|date',
            'date_end' => 'nullable|date|after_or_equal:date_start',
        ]);

        $doctors = User::where('college_id', $this->college()->id)
            ->where('role', UserRole::DOCTOR)
            ->withCount([
                'subjects',
                'qrSessions' => function ($q) use ($request) {
                    $q->where('status', 'finalized');
                    $this->applyDateRange($q, $request);
                },
            ])
            ->get(['id', 'name', 'email']);

        foreach ($doctors as $doctor) {
            $sessions = $doctor->qrSessions()->where('status', 'finalized');
            $this->applyDateRange($sessions, $request);
            $sessions = $sessions->with('subject')->get();

            $totalPossible = 0;
            $totalPresent = 0;

            foreach ($sessions as $session) {
                $subject = $session->subject;
                if (!$subject) {
                    continue;
                }

                $expectedCount = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
                    ->where('major_id', $subject->major_id)
                    ->where('level_id', $subject->level_id)
                    ->count();

                $totalPossible += $expectedCount;
                $presentQuery = Attendance::where('subject_id', $session->subject_id)
                    ->whereDate('date', $session->date)
                    ->where('status', 'present');
                $this->applyDateRange($presentQuery, $request);
                $totalPresent += $presentQuery->count();
            }

            $doctor->attendance_rate = $totalPossible > 0 ? round(($totalPresent / $totalPossible) * 100, 1) : 0;
        }

        return $this->success([
            'summary' => [
                'doctors_count' => $doctors->count(),
                'active_doctors_count' => $doctors->where('qr_sessions_count', '>', 0)->count(),
                'average_attendance_rate' => round($doctors->avg('attendance_rate') ?? 0, 1),
            ],
            'date_range' => $this->dateRangePayload($request),
            'doctors' => $doctors->values(),
        ]);
    }

    public function subjectPdf(Request $request)
    {
        $payload = $this->subjectReport($request)->getData(true);

        return $this->pdfResponse('كشف حضور وغياب الطلاب', 'subject', $payload['data'] ?? [], 'administrative_subject_report.pdf');
    }

    public function subjectExcel(Request $request)
    {
        $payload = $this->subjectReport($request)->getData(true)['data'] ?? [];
        $rows = [['الرقم الجامعي', 'اسم الطالب', 'حاضر', 'غائب', 'متأخر', 'أعذار', 'نسبة الغياب', 'الموقف']];
        foreach (($payload['report'] ?? []) as $row) {
            $rows[] = [
                $row['student']['student_number'] ?? '-',
                $row['student']['name'] ?? '-',
                $row['present'] ?? 0,
                $row['absent'] ?? 0,
                $row['late'] ?? 0,
                $row['excused'] ?? 0,
                ($row['absence_percentage'] ?? 0) . '%',
                $row['decision'] ?? '-',
            ];
        }

        return $this->csvResponse('administrative_subject_report.csv', $rows);
    }

    public function thresholdPdf(Request $request)
    {
        $payload = $this->thresholdReport($request)->getData(true);

        return $this->pdfResponse('كشف حالات تجاوز الغياب', 'threshold', $payload['data'] ?? [], 'administrative_threshold_report.pdf');
    }

    public function thresholdExcel(Request $request)
    {
        $payload = $this->thresholdReport($request)->getData(true)['data'] ?? [];
        $rows = [['الرقم الجامعي', 'اسم الطالب', 'المادة', 'الغيابات', 'الجلسات', 'النسبة', 'الإجراء']];
        foreach (($payload['alerts'] ?? []) as $row) {
            $percentage = (float) ($row['absence_percentage'] ?? 0);
            $rows[] = [
                $row['student']['student_number'] ?? '-',
                $row['student']['name'] ?? '-',
                $row['subject']['name'] ?? '-',
                $row['absent_count'] ?? 0,
                $row['total_sessions'] ?? 0,
                $percentage . '%',
                $row['action_label'] ?? ($percentage >= 25 ? 'حرمان' : 'إنذار'),
            ];
        }

        return $this->csvResponse('administrative_threshold_report.csv', $rows);
    }

    public function levelSummaryPdf(Request $request)
    {
        $payload = $this->levelSummary($request)->getData(true);

        return $this->pdfResponse('ملخص الدفعة الدراسية', 'level_summary', $payload['data'] ?? [], 'administrative_level_summary.pdf');
    }

    public function levelSummaryExcel(Request $request)
    {
        $payload = $this->levelSummary($request)->getData(true)['data'] ?? [];
        $rows = [['المادة', 'الدكتور', 'سجلات الرصد', 'نسبة الحضور']];
        foreach (($payload['subject_stats'] ?? []) as $row) {
            $rows[] = [
                $row['subject']['name'] ?? '-',
                $row['subject']['doctor']['name'] ?? '-',
                $row['total_records'] ?? 0,
                ($row['attendance_rate'] ?? 0) . '%',
            ];
        }

        return $this->csvResponse('administrative_level_summary.csv', $rows);
    }

    public function doctorPerformancePdf(Request $request)
    {
        $payload = $this->doctorPerformance($request)->getData(true);

        return $this->pdfResponse('أداء الكادر التعليمي', 'doctor_performance', $payload['data'] ?? [], 'administrative_doctor_performance.pdf');
    }

    public function doctorPerformanceExcel(Request $request)
    {
        $payload = $this->doctorPerformance($request)->getData(true)['data'] ?? [];
        $rows = [['الدكتور', 'البريد', 'جلسات QR', 'المواد', 'متوسط الحضور']];
        foreach (($payload['doctors'] ?? []) as $doctor) {
            $rows[] = [
                $doctor['name'] ?? '-',
                $doctor['email'] ?? '-',
                $doctor['qr_sessions_count'] ?? 0,
                $doctor['subjects_count'] ?? 0,
                ($doctor['attendance_rate'] ?? 0) . '%',
            ];
        }

        return $this->csvResponse('administrative_doctor_performance.csv', $rows);
    }

    public function comparison(Request $request)
    {
        $request->validate([
            'type' => 'nullable|in:subjects,levels',
            'date_start' => 'nullable|date',
            'date_end' => 'nullable|date|after_or_equal:date_start',
        ]);

        $type = $request->input('type', 'subjects');

        if ($type === 'levels') {
            $items = Level::whereHas('major', fn ($query) => $query->where('college_id', $this->college()->id))
                ->with('major:id,name')
                ->get(['id', 'name', 'major_id'])
                ->map(function ($level) use ($request) {
                    $subjectIds = Subject::where('level_id', $level->id)
                        ->whereHas('major', fn ($query) => $query->where('college_id', $this->college()->id))
                        ->pluck('id');

                    return $this->comparisonRow($level, $request, $subjectIds);
                })
                ->sortByDesc('attendance_rate')
                ->values();
        } else {
            $items = Subject::whereHas('major', fn ($query) => $query->where('college_id', $this->college()->id))
                ->with(['major:id,name', 'level:id,name', 'doctor:id,name'])
                ->get(['id', 'name', 'doctor_id', 'level_id', 'major_id'])
                ->map(fn ($subject) => $this->comparisonRow($subject, $request, collect([$subject->id])))
                ->sortByDesc('attendance_rate')
                ->values();
        }

        return $this->success([
            'type' => $type,
            'date_range' => $this->dateRangePayload($request),
            'summary' => [
                'items_count' => $items->count(),
                'best' => $items->first(),
                'weakest' => $items->last(),
                'average_attendance_rate' => round($items->avg('attendance_rate') ?? 0, 1),
            ],
            'items' => $items,
        ]);
    }

    public function comparisonExcel(Request $request)
    {
        $payload = $this->comparison($request)->getData(true)['data'] ?? [];
        $type = $payload['type'] ?? 'subjects';
        $rows = $type === 'levels'
            ? [['المستوى', 'التخصص', 'عدد المواد', 'سجلات الرصد', 'نسبة الحضور']]
            : [['المادة', 'التخصص', 'المستوى', 'الدكتور', 'سجلات الرصد', 'نسبة الحضور']];

        foreach (($payload['items'] ?? []) as $item) {
            $rows[] = $type === 'levels'
                ? [
                    $item['name'] ?? '-',
                    $item['major']['name'] ?? '-',
                    $item['subjects_count'] ?? 0,
                    $item['total_records'] ?? 0,
                    ($item['attendance_rate'] ?? 0) . '%',
                ]
                : [
                    $item['name'] ?? '-',
                    $item['major']['name'] ?? '-',
                    $item['level']['name'] ?? '-',
                    $item['doctor']['name'] ?? '-',
                    $item['total_records'] ?? 0,
                    ($item['attendance_rate'] ?? 0) . '%',
                ];
        }

        return $this->csvResponse('administrative_comparison_report.csv', $rows);
    }

    public function notifyThreshold(Request $request)
    {
        $payload = $this->thresholdReport($request)->getData(true)['data'] ?? [];
        $alerts = collect($payload['alerts'] ?? []);

        if ($alerts->isEmpty()) {
            return $this->error('لا توجد حالات لإرسال تنبيه لها.', 422);
        }

        $admin = $this->administrative();
        $college = $this->college();
        $batchId = (string) Str::uuid();
        $sentStudents = 0;

        $alerts->groupBy(fn ($row) => $row['student']['id'] ?? null)
            ->filter(fn ($rows, $studentId) => ! empty($studentId))
            ->each(function ($rows, $studentId) use ($admin, $college, $batchId, &$sentStudents) {
                $subjects = collect($rows)->pluck('subject.name')->filter()->unique()->values()->implode('، ');
                StudentNotification::create([
                    'user_id' => $studentId,
                    'college_id' => $college->id,
                    'sender_id' => $admin->id,
                    'batch_id' => $batchId,
                    'type' => 'absence_warning',
                    'title' => 'تنبيه بخصوص نسبة الغياب',
                    'message' => 'لديك نسبة غياب مرتفعة في المواد التالية: ' . ($subjects ?: 'مواد دراسية') . '. يرجى مراجعة شؤون الطلاب.',
                    'data' => [
                        'screen' => 'attendance',
                        'target_screen' => 'attendance',
                        'source' => 'administrative_threshold_report',
                    ],
                ]);
                $sentStudents++;
            });

        return $this->success([
            'batch_id' => $batchId,
            'recipients_count' => $sentStudents,
        ], 'تم إرسال تنبيهات الغياب للطلاب المحددين.');
    }

    protected function pdfResponse(string $title, string $type, array $data, string $filename)
    {
        $pdf = Pdf::loadView('administrative.reports.app_pdf', [
            'title' => $title,
            'type' => $type,
            'data' => $data,
            'college' => $this->college(),
            'generatedAt' => now()->format('Y-m-d'),
        ])->setPaper('a4');

        return $pdf->download($filename);
    }

    public function attendance(Request $request)
    {
        $college = $this->college();
        $query = Attendance::with(['student:id,name,student_number,major_id,level_id', 'subject:id,name'])
            ->whereHas('student', function ($q) use ($college, $request) {
                $q->where('college_id', $college->id);
                if ($request->filled('major_id')) {
                    $q->where('major_id', $request->integer('major_id'));
                }
                if ($request->filled('level_id')) {
                    $q->where('level_id', $request->integer('level_id'));
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
            $query->where(function ($q) use ($search) {
                $q->whereHas('student', fn ($sq) => $sq->where('name', 'like', "%{$search}%")->orWhere('student_number', 'like', "%{$search}%"))
                    ->orWhereHas('subject', fn ($sq) => $sq->where('name', 'like', "%{$search}%"));
            });
        }

        $records = $query->latest('date')->paginate($request->integer('per_page', 20));

        return $this->success([
            'records' => $records->items(),
            'pagination' => [
                'current_page' => $records->currentPage(),
                'last_page' => $records->lastPage(),
                'per_page' => $records->perPage(),
                'total' => $records->total(),
            ],
            'majors' => Major::where('college_id', $college->id)->with('levels:id,name,major_id')->get(['id', 'name']),
        ]);
    }

    protected function applyDateRange($query, Request $request)
    {
        if ($request->filled('date_start')) {
            $query->whereDate('date', '>=', $request->date_start);
        }
        if ($request->filled('date_end')) {
            $query->whereDate('date', '<=', $request->date_end);
        }

        return $query;
    }

    protected function dateRangePayload(Request $request): array
    {
        $start = $request->input('date_start');
        $end = $request->input('date_end');
        $label = 'كل الفترات';
        if ($start && $end) {
            $label = "{$start} إلى {$end}";
        } elseif ($start) {
            $label = "من {$start}";
        } elseif ($end) {
            $label = "حتى {$end}";
        }

        return [
            'date_start' => $start,
            'date_end' => $end,
            'label' => $label,
        ];
    }

    protected function absenceDecision(int $absent, int $maxAbsences): string
    {
        if ($absent >= $maxAbsences) {
            return 'محروم';
        }
        if ($maxAbsences > 2 && $absent >= $maxAbsences - 2) {
            return 'إنذار';
        }

        return '-';
    }

    protected function decisionColor(string $decision): string
    {
        return match ($decision) {
            'محروم' => 'danger',
            'إنذار' => 'warning',
            default => 'success',
        };
    }

    protected function subjectSummary($reportData): array
    {
        $collection = collect($reportData);

        return [
            'students_count' => $collection->count(),
            'present_total' => $collection->sum('present'),
            'absent_total' => $collection->sum('absent'),
            'late_total' => $collection->sum('late'),
            'excused_total' => $collection->sum('excused'),
            'warning_count' => $collection->where('decision', 'إنذار')->count(),
            'deprived_count' => $collection->where('decision', 'محروم')->count(),
            'average_absence_percentage' => round($collection->avg('absence_percentage') ?? 0, 1),
            'highest_absence_percentage' => $collection->max('absence_percentage') ?? 0,
        ];
    }

    protected function comparisonRow($model, Request $request, $subjectIds): array
    {
        $totalQuery = Attendance::whereIn('subject_id', $subjectIds);
        $this->applyDateRange($totalQuery, $request);
        $totalRecords = $totalQuery->count();

        $presentQuery = Attendance::whereIn('subject_id', $subjectIds)->where('status', 'present');
        $this->applyDateRange($presentQuery, $request);
        $presentCount = $presentQuery->count();

        $base = [
            'id' => $model->id,
            'name' => $model->name,
            'total_records' => $totalRecords,
            'present_count' => $presentCount,
            'absent_count' => max(0, $totalRecords - $presentCount),
            'attendance_rate' => $totalRecords > 0 ? round(($presentCount / $totalRecords) * 100, 1) : 0,
        ];

        if ($model instanceof Level) {
            return array_merge($base, [
                'major' => $model->major,
                'subjects_count' => $subjectIds->count(),
            ]);
        }

        return array_merge($base, [
            'major' => $model->major,
            'level' => $model->level,
            'doctor' => $model->doctor,
        ]);
    }

    protected function csvResponse(string $filename, array $rows)
    {
        return response()->streamDownload(function () use ($rows) {
            $handle = fopen('php://output', 'w');
            fwrite($handle, "\xEF\xBB\xBF");
            foreach ($rows as $row) {
                fputcsv($handle, $row);
            }
            fclose($handle);
        }, $filename, [
            'Content-Type' => 'text/csv; charset=UTF-8',
        ]);
    }
}
