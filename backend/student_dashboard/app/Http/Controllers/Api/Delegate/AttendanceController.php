<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Enums\UserRole;
use App\Exceptions\AttendanceEditLockedException;
use App\Models\Academic\Lecture;
use App\Models\Academic\Subject;
use App\Models\Attendance;
use App\Models\QrAttendanceSession;
use App\Models\Student\StudentScheduleItem;
use App\Models\User;
use App\Services\AttendanceEditGate;
use App\Support\ExcuseWorkflow;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\ViewErrorBag;

class AttendanceController extends DelegateApiController
{
    public function index(Request $request)
    {
        $delegate = $request->user();
        $search = $request->input('search');
        $dateFilter = $request->input('date');

        $subjects = Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->with('doctor:id,name')
            ->orderBy('name')
            ->get();

        $subjectIds = $subjects->pluck('id')->filter();

        $query = Attendance::with(['subject:id,name,code', 'recorder:id,name,role', 'lecture:id,title,lecture_number,start_time,end_time,lecture_type'])
            ->where(function ($q) use ($subjectIds, $delegate) {
                $q->whereIn('subject_id', $subjectIds)
                    ->orWhere(function ($unofficialQuery) use ($delegate) {
                        $unofficialQuery->whereNull('subject_id')
                            ->whereHas('student', function ($studentQuery) use ($delegate) {
                                $studentQuery->whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
                                    ->where('major_id', $delegate->major_id)
                                    ->where('level_id', $delegate->level_id);
                            });
                    });
            });

        if ($dateFilter) {
            $query->whereDate('date', $dateFilter);
        }

        if ($search) {
            $query->whereHas('lecture', function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%");
            });
        }

        $records = $query->orderByDesc('date')->orderByDesc('id')->get();

        $sessions = $records->groupBy(function ($attendance) {
            return implode('|', [
                $attendance->subject_id ?? 0,
                $attendance->date->format('Y-m-d'),
                $attendance->lecture_id ?? 0,
                $attendance->recorded_by ?? 0,
                $attendance->attendance_method ?? 'manual',
            ]);
        })->map(function ($group) {
            $first = $group->first();
            return [
                'subject_id' => $first->subject_id,
                'subject' => $first->subject,
                'date' => $first->date->format('Y-m-d'),
                'lecture_id' => $first->lecture_id,
                'lecture' => $first->lecture,
                'recorded_by' => $first->recorded_by,
                'recorder' => $first->recorder,
                'attendance_method' => $first->attendance_method,
                'total_records' => $group->count(),
                'is_unofficial' => is_null($first->subject_id),
                'display_name' => $first->subject?->name ?? $first->lecture?->title ?? 'محاضرة غير رسمية',
            ];
        })->values();

        return $this->success([
            'subjects' => $subjects,
            'sessions' => $sessions,
        ], 'تم جلب بيانات الحضور بنجاح.');
    }

    public function store(Request $request)
    {
        $delegate = $request->user();
        $request->merge([
            'date' => $request->input('date', $request->input('lecture_date')),
        ]);

        $validator = Validator::make($request->all(), [
            'date' => 'required|date',
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:2000',
            'lecture_type' => 'nullable|in:official,special',
            'lecture_number' => 'nullable|string|max:50',
            'start_time' => 'nullable',
            'end_time' => 'nullable',
            'gender_filter' => 'nullable|in:all,male,female',
            'students' => 'nullable|array|min:1',
            'students.*.id' => 'required_with:students|exists:users,id',
            'students.*.status' => 'required_with:students|in:' . implode(',', ExcuseWorkflow::editableAttendanceStatuses()),
            'attendance' => 'nullable|array|min:1',
            'attendance.*' => 'required_with:attendance|in:' . implode(',', ExcuseWorkflow::editableAttendanceStatuses()),
            'qr_session_id' => 'nullable|integer|exists:qr_attendance_sessions,id',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة.', 422, $validator->errors());
        }

        $subject = Subject::where('id', $request->subject_id)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->first();

        if (!$subject) {
            return $this->error('المادة غير موجودة أو ليست ضمن نطاق المندوب.', 403);
        }

        if (!$subject->allow_delegate_attendance) {
            return $this->error('التحضير مغلق من قبل الدكتور المشرف على المادة.', 403);
        }

        $students = collect($request->input('students', []));
        if ($students->isEmpty()) {
            $students = collect($request->input('attendance', []))
                ->map(fn ($status, $studentId) => ['id' => (int) $studentId, 'status' => $status])
                ->values();
        }

        if ($students->isEmpty()) {
            return $this->error('Attendance payload is required.', 422);
        }

        $genderFilter = in_array($request->input('gender_filter'), ['male', 'female'], true)
            ? $request->input('gender_filter')
            : 'all';

        $allowedStudentIds = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->when($genderFilter !== 'all', fn ($query) => $query->where('gender', $genderFilter))
            ->pluck('id');

        if ($students->pluck('id')->diff($allowedStudentIds)->isNotEmpty()) {
            return $this->error('One or more students are outside the delegate scope or current gender filter.', 422);
        }

        $lectureKey = [
            'subject_id' => $subject->id,
            'date' => $request->date,
            'title' => $request->title,
            'lecture_type' => $request->input('lecture_type', 'official'),
        ];

        if (!empty($request->lecture_number)) {
            $lectureKey['lecture_number'] = $request->lecture_number;
        }

        try {
            DB::beginTransaction();

            $lecture = Lecture::updateOrCreate(
                $lectureKey,
                [
                    'title' => $request->title,
                    'lecture_type' => $request->input('lecture_type', 'official'),
                    'lecture_number' => $request->lecture_number,
                    'description' => $request->description,
                    'start_time' => $request->start_time,
                    'end_time' => $request->end_time,
                ]
            );

            $qrSessionId = $request->filled('qr_session_id') ? (int) $request->input('qr_session_id') : null;
            $attendanceMethod = $qrSessionId ? 'qr' : 'manual';
            $editGate = app(AttendanceEditGate::class);

            foreach ($students as $student) {
                $values = [
                    'subject_id' => $subject->id,
                    'date' => $request->date,
                    'lecture_id' => $lecture->id,
                    'status' => $student['status'],
                    'recorded_by' => $delegate->id,
                    'attendance_method' => $attendanceMethod,
                ];

                if ($qrSessionId) {
                    $values['qr_attendance_session_id'] = $qrSessionId;

                    $editGate->upsertAttendance(
                        [
                            'student_id' => $student['id'],
                            'qr_attendance_session_id' => $qrSessionId,
                        ],
                        $values,
                        $delegate
                    );
                } else {
                    $editGate->upsertAttendance(
                        [
                            'student_id' => $student['id'],
                            'subject_id' => $subject->id,
                            'date' => $request->date,
                            'lecture_id' => $lecture->id,
                        ],
                        $values,
                        $delegate
                    );
                }

                StudentScheduleItem::firstOrCreate(
                    [
                        'user_id' => $student['id'],
                        'referenceable_type' => Lecture::class,
                        'referenceable_id' => $lecture->id,
                    ],
                    [
                        'title' => $request->title,
                        'scheduled_date' => $request->date,
                        'item_type' => 'study',
                        'priority' => 'medium',
                        'status' => 'pending',
                    ]
                );
            }

            if ($request->filled('qr_session_id')) {
                $this->syncQrVerificationResults((int) $request->input('qr_session_id'), $students, $delegate->id);
            }

            if ($subject->doctor_id) {
                $presentCount = $students->where('status', Attendance::STATUS_PRESENT)->count();
                $absentCount = $students->where('status', Attendance::STATUS_ABSENT)->count();
                $lateCount = $students->where('status', Attendance::STATUS_LATE)->count();
                $totalStudents = $students->count();

                \App\Models\StudentNotification::create([
                    'user_id' => $subject->doctor_id,
                    'type' => 'lecture_report',
                    'title' => "تقرير محاضرة: {$subject->name}",
                    'message' => "تم تسجيل الحضور لمحاضرة \"{$request->title}\" بتاريخ {$request->date}.\n"
                        . "إجمالي الطلاب: {$totalStudents} | حضور: {$presentCount} | غياب: {$absentCount} | تأخر: {$lateCount}",
                    'data' => [
                        'subject_id' => $subject->id,
                        'lecture_id' => $lecture->id,
                        'date' => $request->date,
                    ],
                ]);
            }

            DB::commit();

            return $this->success([
                'lecture_id' => $lecture->id,
                'lecture_type' => $lecture->lecture_type,
                'merge_mode' => true,
                'gender_filter' => $genderFilter,
                'updated_students_count' => $students->count(),
            ], 'تم حفظ سجل الحضور بنجاح.', 201);
        } catch (AttendanceEditLockedException $exception) {
            DB::rollBack();

            return $this->error($exception->getMessage(), 403, $exception->context());
        } catch (\Throwable $exception) {
            DB::rollBack();

            return $this->error('حدث خطأ أثناء حفظ الحضور: ' . $exception->getMessage(), 500);
        }
    }

    public function create(Request $request, Subject $subject)
    {
        $delegate = $request->user();

        $subject = Subject::where('id', $subject->id)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->with('doctor:id,name')
            ->first();

        if (!$subject) {
            return $this->error('المادة غير موجودة أو ليست ضمن نطاق المندوب.', 403);
        }

        if (!$subject->allow_delegate_attendance) {
            return $this->error('التحضير مغلق من قبل الدكتور المشرف على المادة.', 403);
        }

        $date = $request->input('date') ?? now()->format('Y-m-d');
        $lectureId = $request->input('lecture_id');
        $qrSessionId = $request->input('qr_session_id');
        $genderFilter = in_array($request->input('gender_filter'), ['male', 'female'], true)
            ? $request->input('gender_filter')
            : 'all';

        $students = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->when($genderFilter !== 'all', fn ($query) => $query->where('gender', $genderFilter))
            ->orderBy('name')
            ->get(['id', 'name', 'student_number', 'gender']);

        $prefill = ['date' => $date];
        $verification = null;

        if ($qrSessionId) {
            $qrSession = QrAttendanceSession::where('id', $qrSessionId)
                ->where('delegate_id', $delegate->id)
                ->firstOrFail();

            $date = $qrSession->date->format('Y-m-d');
            $prefill['date'] = $date;
            $prefill['title'] = $qrSession->title;
            $prefill['lecture_number'] = $qrSession->lecture_number;
            $prefill['from_qr'] = true;
            $verification = $qrSession->buildVerificationPayload();
        }

        $lecture = null;
        if (!$qrSessionId) {
            if ($lectureId) {
                $lecture = Lecture::where('id', $lectureId)
                    ->where('subject_id', $subject->id)
                    ->first();
            }
            if (!$lecture) {
                $lecture = Lecture::where('subject_id', $subject->id)
                    ->where('date', $date)
                    ->latest()
                    ->first();
            }

            $attendanceQuery = Attendance::where('subject_id', $subject->id)
                ->where('date', $date);

            if ($lecture) {
                $attendanceQuery->where('lecture_id', $lecture->id);
                $prefill['title'] = $prefill['title'] ?? $lecture->title;
                $prefill['lecture_number'] = $prefill['lecture_number'] ?? $lecture->lecture_number;
                $prefill['description'] = $lecture->description;
                $prefill['lecture_type'] = $lecture->lecture_type;
                $prefill['start_time'] = $lecture->start_time;
                $prefill['end_time'] = $lecture->end_time;
            }
        } else {
            $attendanceQuery = Attendance::where('qr_attendance_session_id', $qrSessionId);
        }

        return $this->success([
            'subject' => $subject->only(['id', 'name', 'allow_delegate_attendance']),
            'students' => $students,
            'attendance_records' => $attendanceQuery->get()->keyBy('student_id'),
            'prefill' => $prefill,
            'verification' => $verification,
            'filters' => [
                'gender_filter' => $genderFilter,
                'available_gender_filters' => ['all', 'male', 'female'],
            ],
            'workflow' => [
                'merge_mode' => true,
                'description' => 'Re-saving the same lecture updates only submitted students and keeps previously recorded students unchanged.',
            ],
        ], 'تم جلب نموذج الحضور بنجاح.');
    }

    public function show(Request $request, $lectureId)
    {
        $delegate = $request->user();

        $lecture = Lecture::with('subject')->findOrFail($lectureId);

        $subject = Subject::where('id', $lecture->subject_id)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->first();

        if (!$subject) {
            return $this->error('المادة غير موجودة أو ليست ضمن نطاق المندوب.', 403);
        }

        $records = Attendance::where('lecture_id', $lectureId)
            ->with(['student:id,name,university_id,student_number,gender'])
            ->get();

        if ($records->isEmpty()) {
            return $this->error('لا توجد سجلات لهذه الجلسة.', 404);
        }

        return $this->success([
            'subject' => $subject->only('id', 'name'),
            'lecture' => [
                'id' => $lecture->id,
                'title' => $lecture->title,
                'lecture_number' => $lecture->lecture_number,
                'date' => $lecture->date,
                'start_time' => $lecture->start_time,
                'end_time' => $lecture->end_time,
            ],
            'records' => $records,
        ], 'تم جلب تفاصيل جلسة الحضور بنجاح.');
    }

    public function report(Request $request, int $subject_id, string $date)
    {
        $delegate = $request->user();

        $subject = null;
        if ($subject_id > 0) {
            $subject = Subject::where('id', $subject_id)
                ->where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)
                ->with('doctor:id,name')
                ->firstOrFail();
        }

        $genderFilter = in_array($request->input('gender_filter'), ['male', 'female'], true)
            ? $request->input('gender_filter')
            : 'all';

        $students = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->when($genderFilter !== 'all', fn ($query) => $query->where('gender', $genderFilter))
            ->orderBy('name')
            ->get(['id', 'name', 'student_number', 'gender']);

        $lecture = null;
        if ($request->filled('lecture_id')) {
            $lecture = Lecture::where('id', $request->input('lecture_id'))
                ->when($subject, fn ($q) => $q->where('subject_id', $subject->id), fn ($q) => $q->whereNull('subject_id'))
                ->first();
        }
        if (!$lecture) {
            $lecture = Lecture::where('date', $date)
                ->when($subject, fn ($q) => $q->where('subject_id', $subject->id), fn ($q) => $q->whereNull('subject_id'))
                ->latest()
                ->first();
        }

        $attendanceQuery = Attendance::where('date', $date);
        
        if ($subject) {
            $attendanceQuery->where('subject_id', $subject->id);
        } else {
            $attendanceQuery->whereNull('subject_id');
        }

        if ($lecture) {
            $attendanceQuery->where('lecture_id', $lecture->id);
        }

        $attendanceRecords = $attendanceQuery
            ->with('recorder:id,name')
            ->get()
            ->keyBy('student_id');

        $appStudents = $students->map(function ($student) use ($attendanceRecords) {
            $record = $attendanceRecords->get($student->id);

            return [
                'id' => $student->id,
                'name' => $student->name,
                'student_number' => $student->student_number,
                'gender' => $student->gender,
                'status' => $record?->status,
                'attendance_method' => $record?->attendance_method,
                'recorder_name' => $record?->recorder?->name,
                'recorded_at' => $record?->created_at,
            ];
        });

        $summary = [
            'total' => $appStudents->count(),
            'present' => $attendanceRecords->where('status', Attendance::STATUS_PRESENT)->count(),
            'absent' => $attendanceRecords->where('status', Attendance::STATUS_ABSENT)->count(),
            'late' => $attendanceRecords->where('status', Attendance::STATUS_LATE)->count(),
            'excused' => $attendanceRecords->where('status', Attendance::STATUS_EXCUSED)->count(),
            'unrecorded' => $appStudents->whereNull('status')->count(),
        ];

        $data = [
            'subject' => $subject,
            'students' => $students,
            'app_students' => $appStudents,
            'attendanceRecords' => $attendanceRecords,
            'summary' => $summary,
            'date' => $date,
            'genderFilter' => $genderFilter,
            'lecture' => $lecture,
            'delegate' => $delegate,
            'isUnofficial' => is_null($subject),
            'is_unofficial' => is_null($subject),
            'errors' => new ViewErrorBag(),
            'pdfMode' => true,
        ];

        if ($request->input('export') === 'pdf') {
            Auth::setUser($delegate);
            $pdf = Pdf::loadView('delegate.attendance.report-app-pdf', $data);
            $pdf->getDomPDF()->set_option('isRemoteEnabled', true);
            $pdf->getDomPDF()->set_option('isHtml5ParserEnabled', true);
            $pdf->getDomPDF()->set_option('defaultFont', 'DejaVu Sans');
            return $pdf->setPaper('a4', 'portrait')->download("تقرير_حضور_{$date}.pdf");
        }

        return $this->success($data, 'تم جلب تقرير الحضور بنجاح.');
    }

    public function reportPdf(Request $request, int $subject_id, string $date)
    {
        $delegate = $request->user();

        $subject = null;
        if ($subject_id > 0) {
            $subject = Subject::where('id', $subject_id)
                ->where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)
                ->with('doctor:id,name')
                ->firstOrFail();
        }

        $students = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->orderBy('name')
            ->get(['id', 'name', 'student_number', 'gender']);

        $lecture = null;
        if ($request->filled('lecture_id')) {
            $lecture = Lecture::where('id', $request->input('lecture_id'))
                ->when($subject, fn ($q) => $q->where('subject_id', $subject->id), fn ($q) => $q->whereNull('subject_id'))
                ->first();
        }
        if (!$lecture) {
            $lecture = Lecture::where('date', $date)
                ->when($subject, fn ($q) => $q->where('subject_id', $subject->id), fn ($q) => $q->whereNull('subject_id'))
                ->latest()
                ->first();
        }

        $attendanceQuery = Attendance::where('date', $date);

        if ($subject) {
            $attendanceQuery->where('subject_id', $subject->id);
        } else {
            $attendanceQuery->whereNull('subject_id');
        }

        if ($lecture) {
            $attendanceQuery->where('lecture_id', $lecture->id);
        }

        $attendanceRecords = $attendanceQuery
            ->with('recorder:id,name')
            ->get()
            ->keyBy('student_id');

        $data = [
            'subject' => $subject,
            'students' => $students,
            'attendanceRecords' => $attendanceRecords,
            'date' => $date,
            'genderFilter' => 'all',
            'lecture' => $lecture,
            'delegate' => $delegate,
            'isUnofficial' => is_null($subject),
            'errors' => new ViewErrorBag(),
            'pdfMode' => true,
        ];

        Auth::setUser($delegate);
        $pdf = Pdf::loadView('delegate.attendance.report-app-pdf', $data);
        $pdf->getDomPDF()->set_option('isRemoteEnabled', true);
        $pdf->getDomPDF()->set_option('isHtml5ParserEnabled', true);
        $pdf->getDomPDF()->set_option('defaultFont', 'DejaVu Sans');

        return response($pdf->output(), 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename="attendance_report.pdf"',
        ]);
    }

    public function alerts(Request $request)
    {
        $delegate = $request->user();

        $absentToday = Attendance::where('date', date('Y-m-d'))
            ->where('status', Attendance::STATUS_ABSENT)
            ->whereHas('student', function ($query) use ($delegate) {
                $query->where('major_id', $delegate->major_id)
                    ->where('level_id', $delegate->level_id);
            })
            ->with(['student:id,name,student_number', 'subject:id,name', 'lecture:id,title'])
            ->latest()
            ->get();

        $atRiskStudents = collect();

        $subjects = Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->get();

        $allStudents = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->get(['id', 'name', 'student_number']);

        $totalSessionsQuery = Attendance::whereIn('student_id', $allStudents->pluck('id'))
            ->whereIn('subject_id', $subjects->pluck('id'))
            ->select('student_id', 'subject_id', DB::raw('count(*) as total'))
            ->groupBy('student_id', 'subject_id')
            ->get();

        $absencesQuery = Attendance::whereIn('student_id', $allStudents->pluck('id'))
            ->whereIn('subject_id', $subjects->pluck('id'))
            ->where('status', Attendance::STATUS_ABSENT)
            ->select('student_id', 'subject_id', DB::raw('count(*) as absences'))
            ->groupBy('student_id', 'subject_id')
            ->get()
            ->keyBy(fn ($item) => $item->student_id . '_' . $item->subject_id);

        foreach ($totalSessionsQuery as $sessionStat) {
            $studentId = $sessionStat->student_id;
            $subjectId = $sessionStat->subject_id;
            $totalSessions = $sessionStat->total;

            if ($totalSessions < 3) {
                continue;
            }

            $absenceKey = $studentId . '_' . $subjectId;
            $absences = $absencesQuery->has($absenceKey) ? $absencesQuery->get($absenceKey)->absences : 0;
            $absenceRate = ($absences / $totalSessions) * 100;

            if ($absenceRate >= 20) {
                $student = $allStudents->firstWhere('id', $studentId);
                $subject = $subjects->firstWhere('id', $subjectId);

                if ($student && $subject) {
                    $atRiskStudents->push([
                        'student' => $student,
                        'subject' => $subject->only('id', 'name'),
                        'absence_rate' => round($absenceRate, 1),
                        'absences' => $absences,
                        'total_sessions' => $totalSessions,
                    ]);
                }
            }
        }

        return $this->success([
            'absent_today' => $absentToday,
            'at_risk_students' => $atRiskStudents->sortByDesc('absence_rate')->values(),
        ], 'تم جلب تنبيهات الغياب بنجاح.');
    }

    protected function syncQrVerificationResults(int $qrSessionId, Collection $students, int $reviewerId): void
    {
        $session = QrAttendanceSession::with('verifications')->find($qrSessionId);

        if (!$session) {
            return;
        }

        $statusMap = $students->pluck('status', 'id');

        foreach ($session->verifications as $verification) {
            $finalStatus = $statusMap->get($verification->student_id);

            if (!$finalStatus) {
                continue;
            }

            $verification->update([
                'verification_status' => $finalStatus === Attendance::STATUS_ABSENT ? 'confirmed_absent' : 'confirmed_present',
                'reviewed_by' => $reviewerId,
                'reviewed_at' => now(),
            ]);
        }
    }
}
