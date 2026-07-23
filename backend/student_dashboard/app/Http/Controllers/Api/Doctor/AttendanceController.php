<?php

namespace App\Http\Controllers\Api\Doctor;

use App\Enums\UserRole;
use App\Exceptions\AttendanceEditLockedException;
use App\Models\Academic\Lecture;
use App\Models\Academic\Subject;
use App\Models\Attendance;
use App\Models\QrAttendanceSession;
use App\Models\Student\StudentScheduleItem;
use App\Models\User;
use App\Services\AttendanceEditGate;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use App\Support\ExcuseWorkflow;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\ViewErrorBag;

class AttendanceController extends DoctorApiController
{
    public function index(Request $request)
    {
        $subjects = Subject::where('doctor_id', $request->user()->id)
            ->with(['major:id,name', 'level:id,name'])
            ->orderBy('name')
            ->get();
        $subjectIds = $subjects->pluck('id');

        $sessions = Attendance::selectRaw('subject_id, date, lecture_id, recorded_by, attendance_method, count(*) as total_records')
            ->whereIn('subject_id', $subjectIds)
            ->with(['subject:id,name,code', 'recorder:id,name,role', 'lecture:id,title,lecture_number,start_time,end_time,lecture_type'])
            ->groupBy('subject_id', 'date', 'lecture_id', 'recorded_by', 'attendance_method')
            ->orderByDesc('date')
            ->get()
            ->map(function ($session) {
                $date = $this->normalizeReportDate($session->date);
                $session->date = $date;
                $session->display_date = $this->displayReportDate($date);
                return $session;
            });

        return $this->success([
            'subjects' => $subjects,
            'sessions' => $sessions,
        ], 'تم جلب جلسات الحضور بنجاح');
    }

    public function create(Request $request, Subject $subject)
    {
        if ($subject->doctor_id !== $request->user()->id) {
            return $this->error('غير مصرح لك بالوصول لهذا المقرر.', 403);
        }

        $date = $request->input('date') ?? now()->format('Y-m-d');
        $lectureId = $request->input('lecture_id');
        $qrSessionId = $request->input('qr_session_id');
        $genderFilter = in_array($request->input('gender_filter'), ['male', 'female'], true)
            ? $request->input('gender_filter')
            : 'all';

        $students = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->when($genderFilter !== 'all', fn ($query) => $query->where('gender', $genderFilter))
            ->orderBy('name')
            ->get(['id', 'name', 'student_number', 'gender']);

        $prefill = ['date' => $date];
        $verification = null;

        if ($qrSessionId) {
            $qrSession = QrAttendanceSession::where('id', $qrSessionId)
                ->where('delegate_id', $request->user()->id)
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
                $lecture = Lecture::where('id', $lectureId)->where('subject_id', $subject->id)->first();
            }
            if (!$lecture) {
                $lecture = Lecture::where('subject_id', $subject->id)->where('date', $date)->latest()->first();
            }

            $attendanceQuery = Attendance::where('subject_id', $subject->id)->where('date', $date);
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
        ]);
    }

    public function store(Request $request)
    {
        $subject = Subject::where('id', $request->subject_id)
            ->where('doctor_id', $request->user()->id)
            ->first();

        if (!$subject) {
            return $this->error('المادة غير موجودة أو غير مصرح لك.', 403);
        }

        return $this->persist($request, $subject);
    }

    public function storeForSubject(Request $request, Subject $subject)
    {
        if ($subject->doctor_id !== $request->user()->id) {
            return $this->error('غير مصرح لك بالوصول لهذا المقرر.', 403);
        }

        return $this->persist($request, $subject);
    }

    public function show(Request $request, $lectureId)
    {
        $lecture = Lecture::with('subject')->findOrFail($lectureId);
        $subject = Subject::where('id', $lecture->subject_id)
            ->where('doctor_id', $request->user()->id)
            ->first();

        if (!$subject) {
            return $this->error('المادة غير موجودة أو غير مصرح لك', 403);
        }

        $records = Attendance::where('lecture_id', $lectureId)
            ->with(['student:id,name,student_number,gender'])
            ->get();

        if ($records->isEmpty()) {
            return $this->error('لا توجد سجلات لهذه الجلسة', 404);
        }

        return $this->success([
            'subject' => $subject->only(['id', 'name']),
            'lecture' => [
                'id' => $lecture->id,
                'title' => $lecture->title,
                'lecture_number' => $lecture->lecture_number,
                'date' => $lecture->date,
                'start_time' => $lecture->start_time,
                'end_time' => $lecture->end_time,
            ],
            'records' => $records,
        ], 'تم جلب تفاصيل جلسة الحضور بنجاح');
    }

    public function toggleDelegate(Request $request, Subject $subject)
    {
        if ($subject->doctor_id !== $request->user()->id) {
            return $this->error('غير مصرح لك بالوصول لهذا المقرر.', 403);
        }

        $subject->allow_delegate_attendance = !$subject->allow_delegate_attendance;
        $subject->save();

        return $this->success([
            'subject_id' => $subject->id,
            'allow_delegate_attendance' => (bool) $subject->allow_delegate_attendance,
        ], $subject->allow_delegate_attendance ? 'تم تفعيل صلاحية تحضير المندوب.' : 'تم إيقاف صلاحية تحضير المندوب.');
    }

    public function report(Request $request, int $subjectId, string $date)
    {
        $date = $this->normalizeReportDate($date);
        $subject = Subject::where('id', $subjectId)
            ->where('doctor_id', $request->user()->id)
            ->firstOrFail();

        $genderFilter = in_array($request->input('gender_filter'), ['male', 'female'], true)
            ? $request->input('gender_filter')
            : 'all';

        $students = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->when($genderFilter !== 'all', fn ($query) => $query->where('gender', $genderFilter))
            ->orderBy('name')
            ->get(['id', 'name', 'student_number', 'gender']);

        $lecture = null;
        if ($request->filled('lecture_id')) {
            $lecture = Lecture::where('id', $request->input('lecture_id'))
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
            ->where('date', $date)
            ->with('recorder');
        if ($lecture) {
            $attendanceQuery->where('lecture_id', $lecture->id);
        }

        $attendanceRecords = $attendanceQuery->get()->keyBy('student_id');

        $appStudents = $students->map(function ($student) use ($attendanceRecords) {
            $record = $attendanceRecords->get($student->id);
            $status = $record?->status;

            return [
                'id' => $student->id,
                'name' => $student->name,
                'student_number' => $student->student_number,
                'gender' => $student->gender,
                'status' => $status,
                'status_label' => $status ? ExcuseWorkflow::attendanceStatusLabel($status) : null,
                'attendance_method' => $record?->attendance_method,
                'recorder_name' => $record?->recorder?->name,
                'recorded_at' => $record?->created_at,
                'record' => $record ? [
                    'id' => $record->id,
                    'status' => $record->status,
                    'attendance_method' => $record->attendance_method,
                    'recorded_by' => $record->recorded_by,
                    'recorded_by_name' => $record->recorder?->name,
                    'recorded_by_role' => $record->recorder?->role,
                ] : null,
            ];
        });

        return $this->success([
            'subject' => $subject->only(['id', 'name']),
            'date' => $date,
            'date_display' => $this->displayReportDate($date),
            'lecture' => $lecture ? [
                'id' => $lecture->id,
                'title' => $lecture->title,
                'lecture_number' => $lecture->lecture_number,
                'lecture_type' => $lecture->lecture_type,
                'start_time' => $lecture->start_time,
                'end_time' => $lecture->end_time,
            ] : null,
            'students' => $appStudents,
            'summary' => [
                'total' => $appStudents->count(),
                'present' => $attendanceRecords->where('status', Attendance::STATUS_PRESENT)->count(),
                'absent' => $attendanceRecords->where('status', Attendance::STATUS_ABSENT)->count(),
                'late' => $attendanceRecords->where('status', Attendance::STATUS_LATE)->count(),
                'excused' => $attendanceRecords->where('status', Attendance::STATUS_EXCUSED)->count(),
                'permitted' => $attendanceRecords->where('status', Attendance::STATUS_PERMITTED)->count(),
                'exempted' => $attendanceRecords->where('status', Attendance::STATUS_EXEMPTED)->count(),
                'unrecorded' => $appStudents->whereNull('status')->count(),
            ],
            'filters' => [
                'gender_filter' => $genderFilter,
                'available_gender_filters' => ['all', 'male', 'female'],
            ],
        ]);
    }

    public function reportPdf(Request $request, int $subjectId, string $date)
    {
        $date = $this->normalizeReportDate($date);
        $subject = Subject::where('id', $subjectId)
            ->where('doctor_id', $request->user()->id)
            ->firstOrFail();

        $students = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->orderBy('name')
            ->get(['id', 'name', 'student_number', 'gender']);

        $lecture = null;
        if ($request->filled('lecture_id')) {
            $lecture = Lecture::where('id', $request->input('lecture_id'))
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
            'dateDisplay' => $this->displayReportDate($date),
            'genderFilter' => 'all',
            'lecture' => $lecture,
            'delegate' => $request->user(),
            'isUnofficial' => false,
            'errors' => new ViewErrorBag(),
            'pdfMode' => true,
        ];

        Auth::setUser($request->user());
        $pdf = Pdf::loadView('delegate.attendance.report-app-pdf', $data);
        $pdf->getDomPDF()->set_option('isRemoteEnabled', true);
        $pdf->getDomPDF()->set_option('isHtml5ParserEnabled', true);
        $pdf->getDomPDF()->set_option('defaultFont', 'DejaVu Sans');

        return response($pdf->output(), 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename="attendance_report.pdf"',
        ]);
    }

    protected function normalizeReportDate($value): string
    {
        if ($value instanceof \DateTimeInterface) {
            return Carbon::instance($value)->format('Y-m-d');
        }

        $value = (string) $value;
        if (preg_match('/^\d{4}-\d{2}-\d{2}/', $value, $matches)) {
            return $matches[0];
        }

        try {
            return Carbon::parse($value)->format('Y-m-d');
        } catch (\Throwable) {
            return $value;
        }
    }

    protected function displayReportDate($value): string
    {
        try {
            return Carbon::parse($value)->locale('ar')->translatedFormat('d M Y');
        } catch (\Throwable) {
            return (string) $value;
        }
    }

    protected function persist(Request $request, Subject $subject)
    {
        $validator = Validator::make($request->all(), [
            'date' => 'required|date',
            'title' => 'required|string|max:255',
            'lecture_type' => 'nullable|in:official,special',
            'lecture_number' => 'nullable|string|max:50',
            'description' => 'nullable|string|max:2000',
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
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        $students = collect($request->input('students', []));
        if ($students->isEmpty()) {
            $students = collect($request->input('attendance', []))
                ->map(fn ($status, $studentId) => ['id' => (int) $studentId, 'status' => $status])
                ->values();
        }

        if ($students->isEmpty()) {
            return $this->error('يجب إرسال بيانات الحضور للطلاب.', 422);
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

        $genderFilter = in_array($request->input('gender_filter'), ['male', 'female'], true)
            ? $request->input('gender_filter')
            : 'all';

        $allowedStudentIds = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->when($genderFilter !== 'all', fn ($query) => $query->where('gender', $genderFilter))
            ->pluck('id');

        if ($students->pluck('id')->diff($allowedStudentIds)->isNotEmpty()) {
            return $this->error('One or more students are outside the subject scope or current gender filter.', 422);
        }

        DB::beginTransaction();

        try {
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
                    'recorded_by' => $request->user()->id,
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
                        $request->user()
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
                        $request->user()
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
                $this->syncQrVerificationResults((int) $request->input('qr_session_id'), $students, $request->user()->id);
            }

            DB::commit();

            return $this->success([
                'lecture_id' => $lecture->id,
                'lecture_type' => $lecture->lecture_type,
                'merge_mode' => true,
                'gender_filter' => $genderFilter,
                'updated_students_count' => $students->count(),
            ], 'تم حفظ سجل الحضور والغياب بنجاح', 201);
        } catch (AttendanceEditLockedException $exception) {
            DB::rollBack();

            return $this->error($exception->getMessage(), 403, $exception->context());
        } catch (\Throwable $exception) {
            DB::rollBack();
            return $this->error('حدث خطأ أثناء رصد الحضور: ' . $exception->getMessage(), 500);
        }
    }

    protected function syncQrVerificationResults(int $qrSessionId, \Illuminate\Support\Collection $students, int $reviewerId): void
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
