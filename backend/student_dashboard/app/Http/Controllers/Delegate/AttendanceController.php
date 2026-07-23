<?php

namespace App\Http\Controllers\Delegate;

use App\Enums\UserRole;
use App\Exceptions\AttendanceEditLockedException;
use App\Http\Controllers\Controller;
use App\Models\Academic\Lecture;
use App\Models\Academic\Subject;
use App\Models\Attendance;
use App\Models\QrAttendanceSession;
use App\Models\Student\StudentScheduleItem;
use App\Models\StudentNotification;
use App\Models\User;
use App\Services\AttendanceEditGate;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class AttendanceController extends Controller
{
    public function index()
    {
        $delegate = Auth::user();

        $subjects = Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->with('doctor')
            ->orderBy('name')
            ->get();

        $subjectIds = $subjects->pluck('id')->filter();

        $sessionRecords = Attendance::with(['subject', 'lecture', 'recorder', 'student'])
            ->where(function ($query) use ($subjectIds, $delegate) {
                $query->whereIn('subject_id', $subjectIds)
                    ->orWhere(function ($unofficialQuery) use ($delegate) {
                        $unofficialQuery->whereNull('subject_id')
                            ->whereHas('student', function ($studentQuery) use ($delegate) {
                                $studentQuery->whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
                                    ->where('major_id', $delegate->major_id)
                                    ->where('level_id', $delegate->level_id);
                            });
                    });
            })
            ->orderByDesc('date')
            ->orderByDesc('lecture_id')
            ->get();

        $sessionItems = $sessionRecords
            ->groupBy(function (Attendance $attendance) {
                return implode('|', [
                    $attendance->subject_id ?? 'unofficial',
                    optional($attendance->date)->format('Y-m-d') ?? $attendance->date,
                    $attendance->lecture_id ?? 'none',
                    $attendance->recorded_by ?? 'none',
                    $attendance->attendance_method ?? 'manual',
                ]);
            })
            ->map(function ($records) {
                $first = $records->first();

                return (object) [
                    'subject_id' => $first->subject_id,
                    'lecture_id' => $first->lecture_id,
                    'date' => $first->date,
                    'attendance_method' => $first->attendance_method,
                    'recorded_by' => $first->recorded_by,
                    'recorder' => $first->recorder,
                    'lecture' => $first->lecture,
                    'subject' => $first->subject,
                    'is_unofficial' => is_null($first->subject_id),
                    'display_subject_name' => $first->subject?->name ?? 'محاضرة غير رسمية',
                    'display_subject_code' => $first->subject?->code ?? 'بدون مادة مسجلة',
                    'total_records' => $records->count(),
                ];
            })
            ->sortByDesc(fn ($session) => optional($session->date)->timestamp ?? 0)
            ->values();

        $page = LengthAwarePaginator::resolveCurrentPage();
        $perPage = 10;

        $sessions = new LengthAwarePaginator(
            $sessionItems->forPage($page, $perPage)->values(),
            $sessionItems->count(),
            $perPage,
            $page,
            [
                'path' => request()->url(),
                'query' => request()->query(),
            ]
        );

        return view('delegate.attendance.index', compact('sessions', 'subjects'));
    }

    public function create(Request $request, $subjectId)
    {
        $delegate = Auth::user();
        $date = $request->input('date');
        $requestedLectureType = in_array($request->input('lecture_type'), ['official', 'special'], true)
            ? $request->input('lecture_type')
            : 'official';
        $genderFilter = in_array($request->input('gender_filter'), ['male', 'female'], true)
            ? $request->input('gender_filter')
            : 'all';
        $qrSessionId = $request->input('qr_session_id');

        $subject = Subject::where('id', $subjectId)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->firstOrFail();

        if (!$subject->allow_delegate_attendance) {
            abort(403, 'التحضير مغلق من قبل الدكتور المشرف على المادة.');
        }

        $students = $this->getScopedStudents($delegate, $genderFilter);
        $attendanceRecords = null;
        $prefill = [
            'lecture_type' => $requestedLectureType,
        ];
        $qrVerification = null;

        if ($qrSessionId) {
            $qrSession = QrAttendanceSession::where('id', $qrSessionId)
                ->where('delegate_id', $delegate->id)
                ->firstOrFail();

            $date = $qrSession->date->format('Y-m-d');
            $prefill['title'] = $qrSession->title;
            $prefill['lecture_number'] = $qrSession->lecture_number;
            $prefill['date'] = $date;
            $prefill['from_qr'] = true;
            $qrVerification = $qrSession->buildVerificationPayload();
        }

        if ($qrSessionId) {
            $attendanceRecords = Attendance::where('qr_attendance_session_id', $qrSessionId)
                ->get()
                ->keyBy('student_id');
        } elseif ($date) {
            $lecture = null;

            if ($request->filled('lecture_id')) {
                $lecture = Lecture::where('id', $request->input('lecture_id'))
                    ->where('subject_id', $subjectId)
                    ->first();
            }

            if (!$lecture) {
                $lecture = Lecture::where('subject_id', $subjectId)
                    ->where('date', $date)
                    ->latest()
                    ->first();
            }

            $attendanceQuery = Attendance::where('subject_id', $subjectId)
                ->where('date', $date);

            if ($lecture) {
                $attendanceQuery->where('lecture_id', $lecture->id);
            }

            $attendanceRecords = $attendanceQuery->get()->keyBy('student_id');

            if ($lecture && empty($prefill['from_qr'])) {
                $prefill['title'] = $prefill['title'] ?? $lecture->title;
                $prefill['lecture_number'] = $prefill['lecture_number'] ?? $lecture->lecture_number;
                $prefill['description'] = $lecture->description;
                $prefill['lecture_type'] = $lecture->lecture_type;
                $prefill['start_time'] = $lecture->start_time ? Carbon::parse($lecture->start_time)->format('H:i') : null;
                $prefill['end_time'] = $lecture->end_time ? Carbon::parse($lecture->end_time)->format('H:i') : null;
                $prefill['date'] = $date;
            }
        }

        return view('delegate.attendance.create', [
            'subject' => $subject,
            'students' => $students,
            'attendanceRecords' => $attendanceRecords,
            'prefill' => $prefill,
            'genderFilter' => $genderFilter,
            'isUnofficial' => false,
            'formAction' => route('delegate.attendance.store', $subject->id),
            'qrVerification' => $qrVerification,
        ]);
    }

    public function createUnofficial(Request $request)
    {
        $delegate = Auth::user();
        $date = $request->input('date');
        $genderFilter = in_array($request->input('gender_filter'), ['male', 'female'], true)
            ? $request->input('gender_filter')
            : 'all';

        $students = $this->getScopedStudents($delegate, $genderFilter);
        $attendanceRecords = null;
        $prefill = [
            'lecture_type' => 'special',
            'title' => 'محاضرة غير رسمية',
            'date' => $date ?: date('Y-m-d'),
        ];

        if ($date || $request->filled('lecture_id')) {
            $lecture = null;

            if ($request->filled('lecture_id')) {
                $lecture = Lecture::where('id', $request->input('lecture_id'))
                    ->whereNull('subject_id')
                    ->first();
            }

            if (!$lecture && $date) {
                $lecture = Lecture::whereNull('subject_id')
                    ->where('date', $date)
                    ->latest()
                    ->first();
            }

            if ($lecture) {
                $attendanceRecords = Attendance::whereNull('subject_id')
                    ->where('lecture_id', $lecture->id)
                    ->whereHas('student', function ($query) use ($delegate) {
                        $query->whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
                            ->where('major_id', $delegate->major_id)
                            ->where('level_id', $delegate->level_id);
                    })
                    ->get()
                    ->keyBy('student_id');

                $prefill['title'] = $lecture->title;
                $prefill['lecture_number'] = $lecture->lecture_number;
                $prefill['description'] = $lecture->description;
                $prefill['start_time'] = $lecture->start_time ? Carbon::parse($lecture->start_time)->format('H:i') : null;
                $prefill['end_time'] = $lecture->end_time ? Carbon::parse($lecture->end_time)->format('H:i') : null;
                $prefill['date'] = $lecture->date->format('Y-m-d');
            }
        }

        return view('delegate.attendance.create', [
            'subject' => null,
            'students' => $students,
            'attendanceRecords' => $attendanceRecords,
            'prefill' => $prefill,
            'genderFilter' => $genderFilter,
            'isUnofficial' => true,
            'formAction' => route('delegate.attendance.unofficial.store'),
            'qrVerification' => null,
        ]);
    }

    public function store(Request $request, $subjectId)
    {
        $delegate = Auth::user();

        $subject = Subject::findOrFail($subjectId);

        if ($subject->major_id != $delegate->major_id || $subject->level_id != $delegate->level_id) {
            abort(403);
        }

        if (!$subject->allow_delegate_attendance) {
            abort(403, 'التحضير مغلق من قبل الدكتور المشرف على المادة.');
        }

        $validated = $request->validate([
            'date' => 'required|date',
            'title' => 'required|string|max:255',
            'lecture_type' => 'nullable|in:official,special',
            'lecture_number' => 'nullable|string|max:50',
            'description' => 'nullable|string|max:2000',
            'start_time' => 'nullable',
            'end_time' => 'nullable',
            'gender_filter' => 'nullable|in:all,male,female',
            'attendance' => 'required|array',
            'attendance.*' => 'required|in:present,absent,late',
            'qr_session_id' => 'nullable|integer|exists:qr_attendance_sessions,id',
        ]);

        $qrSessionId = !empty($validated['qr_session_id']) ? (int) $validated['qr_session_id'] : null;
        $attendanceMethod = $qrSessionId ? 'qr' : 'manual';

        $lectureKey = [
            'subject_id' => $subject->id,
            'date' => $validated['date'],
            'title' => $validated['title'],
            'lecture_type' => $validated['lecture_type'] ?? 'official',
        ];

        if (!empty($validated['lecture_number'])) {
            $lectureKey['lecture_number'] = $validated['lecture_number'];
        }

        try {
            DB::beginTransaction();

            $lecture = Lecture::updateOrCreate(
                $lectureKey,
                [
                    'title' => $validated['title'],
                    'lecture_type' => $validated['lecture_type'] ?? 'official',
                    'lecture_number' => $validated['lecture_number'] ?? null,
                    'description' => $validated['description'] ?? null,
                    'start_time' => $validated['start_time'] ?? null,
                    'end_time' => $validated['end_time'] ?? null,
                ]
            );

            $editGate = app(AttendanceEditGate::class);

            foreach ($validated['attendance'] as $studentId => $status) {
                $values = [
                    'subject_id' => $subject->id,
                    'date' => $validated['date'],
                    'lecture_id' => $lecture->id,
                    'status' => $status,
                    'recorded_by' => $delegate->id,
                    'attendance_method' => $attendanceMethod,
                ];

                if ($qrSessionId) {
                    $values['qr_attendance_session_id'] = $qrSessionId;

                    $editGate->upsertAttendance(
                        [
                            'student_id' => $studentId,
                            'qr_attendance_session_id' => $qrSessionId,
                        ],
                        $values,
                        $delegate
                    );
                } else {
                    $editGate->upsertAttendance(
                        [
                            'student_id' => $studentId,
                            'subject_id' => $subject->id,
                            'date' => $validated['date'],
                            'lecture_id' => $lecture->id,
                        ],
                        $values,
                        $delegate
                    );
                }

                StudentScheduleItem::firstOrCreate(
                    [
                        'user_id' => $studentId,
                        'referenceable_type' => Lecture::class,
                        'referenceable_id' => $lecture->id,
                    ],
                    [
                        'title' => $validated['title'],
                        'scheduled_date' => $validated['date'],
                        'item_type' => 'study',
                        'priority' => 'medium',
                        'status' => 'pending',
                    ]
                );
            }

            if (!empty($validated['qr_session_id'])) {
                $this->syncQrVerificationResults((int) $validated['qr_session_id'], $validated['attendance'], $delegate->id);
            }

            if ($subject->doctor_id) {
                $presentCount = collect($validated['attendance'])->filter(fn ($status) => $status === 'present')->count();
                $absentCount = collect($validated['attendance'])->filter(fn ($status) => $status === 'absent')->count();
                $lateCount = collect($validated['attendance'])->filter(fn ($status) => $status === 'late')->count();
                $totalStudents = count($validated['attendance']);

                StudentNotification::create([
                    'user_id' => $subject->doctor_id,
                    'type' => 'lecture_report',
                    'title' => "تقرير محاضرة: {$subject->name}",
                    'message' => "تم تسجيل الحضور لمحاضرة \"{$validated['title']}\" بتاريخ {$validated['date']}.\n"
                        . "إجمالي الطلاب: {$totalStudents} | حضور: {$presentCount} | غياب: {$absentCount} | تأخر: {$lateCount}",
                    'data' => [
                        'subject_id' => $subject->id,
                        'lecture_id' => $lecture->id,
                        'date' => $validated['date'],
                    ],
                ]);
            }

            DB::commit();
        } catch (AttendanceEditLockedException $exception) {
            DB::rollBack();

            return back()
                ->withInput()
                ->with('error', $exception->getMessage());
        } catch (\Throwable $exception) {
            DB::rollBack();

            throw $exception;
        }

        return redirect()
            ->route('delegate.attendance.index')
            ->with('success', 'تم حفظ سجل الحضور وتحديث قائمة التحقق بنجاح.');
    }

    public function storeUnofficial(Request $request)
    {
        $delegate = Auth::user();

        $validated = $request->validate([
            'date' => 'required|date',
            'title' => 'required|string|max:255',
            'lecture_number' => 'nullable|string|max:50',
            'description' => 'nullable|string|max:2000',
            'start_time' => 'nullable',
            'end_time' => 'nullable',
            'gender_filter' => 'nullable|in:all,male,female',
            'attendance' => 'required|array',
            'attendance.*' => 'required|in:present,absent,late',
        ]);

        $lectureKey = [
            'subject_id' => null,
            'date' => $validated['date'],
            'title' => $validated['title'],
            'lecture_type' => 'special',
        ];

        if (!empty($validated['lecture_number'])) {
            $lectureKey['lecture_number'] = $validated['lecture_number'];
        }

        try {
            DB::beginTransaction();

            $lecture = Lecture::updateOrCreate(
                $lectureKey,
                [
                    'title' => $validated['title'],
                    'lecture_type' => 'special',
                    'lecture_number' => $validated['lecture_number'] ?? null,
                    'description' => $validated['description'] ?? null,
                    'start_time' => $validated['start_time'] ?? null,
                    'end_time' => $validated['end_time'] ?? null,
                ]
            );

            $editGate = app(AttendanceEditGate::class);

            foreach ($validated['attendance'] as $studentId => $status) {
                $editGate->upsertAttendance(
                    [
                        'student_id' => $studentId,
                        'subject_id' => null,
                        'date' => $validated['date'],
                        'lecture_id' => $lecture->id,
                    ],
                    [
                        'status' => $status,
                        'recorded_by' => $delegate->id,
                        'attendance_method' => 'manual',
                    ],
                    $delegate
                );

                StudentScheduleItem::firstOrCreate(
                    [
                        'user_id' => $studentId,
                        'referenceable_type' => Lecture::class,
                        'referenceable_id' => $lecture->id,
                    ],
                    [
                        'title' => $validated['title'],
                        'scheduled_date' => $validated['date'],
                        'item_type' => 'study',
                        'priority' => 'medium',
                        'status' => 'pending',
                    ]
                );
            }

            DB::commit();
        } catch (AttendanceEditLockedException $exception) {
            DB::rollBack();

            return back()
                ->withInput()
                ->with('error', $exception->getMessage());
        } catch (\Throwable $exception) {
            DB::rollBack();

            throw $exception;
        }

        return redirect()
            ->route('delegate.attendance.index')
            ->with('success', 'تم حفظ جلسة الحضور غير الرسمية بنجاح.');
    }

    public function showReport(Request $request, $subjectId, $date)
    {
        $delegate = Auth::user();

        $subject = Subject::where('id', $subjectId)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->with('doctor')
            ->firstOrFail();

        $genderFilter = in_array($request->input('gender_filter'), ['male', 'female'], true)
            ? $request->input('gender_filter')
            : 'all';

        $students = $this->getScopedStudents($delegate, $genderFilter);

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

        $data = [
            'subject' => $subject,
            'students' => $students,
            'attendanceRecords' => $attendanceRecords,
            'date' => $date,
            'genderFilter' => $genderFilter,
            'lecture' => $lecture,
            'delegate' => $delegate,
            'isUnofficial' => false,
        ];

        if ($request->input('export') === 'pdf') {
            $pdf = Pdf::loadView('delegate.attendance.report', $data);
            $pdf->getDomPDF()->set_option('isRemoteEnabled', true);
            $pdf->getDomPDF()->set_option('isHtml5ParserEnabled', true);
            $pdf->getDomPDF()->set_option('defaultFont', 'DejaVu Sans');
            return $pdf->setPaper('a4', 'portrait')->download("تقرير_حضور_{$date}.pdf");
        }

        return view('delegate.attendance.report', $data);
    }

    public function showUnofficialReport(Request $request, Lecture $lecture)
    {
        $delegate = Auth::user();

        abort_if($lecture->subject_id !== null, 404);

        $genderFilter = in_array($request->input('gender_filter'), ['male', 'female'], true)
            ? $request->input('gender_filter')
            : 'all';

        $students = $this->getScopedStudents($delegate, $genderFilter);

        $attendanceRecords = Attendance::whereNull('subject_id')
            ->where('lecture_id', $lecture->id)
            ->whereHas('student', function ($query) use ($delegate) {
                $query->whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
                    ->where('major_id', $delegate->major_id)
                    ->where('level_id', $delegate->level_id);
            })
            ->with('recorder')
            ->get()
            ->keyBy('student_id');

        $data = [
            'subject' => null,
            'students' => $students,
            'attendanceRecords' => $attendanceRecords,
            'date' => $lecture->date->format('Y-m-d'),
            'genderFilter' => $genderFilter,
            'lecture' => $lecture,
            'delegate' => $delegate,
            'isUnofficial' => true,
        ];

        if ($request->input('export') === 'pdf') {
            $pdf = Pdf::loadView('delegate.attendance.report', $data);
            $pdf->getDomPDF()->set_option('isRemoteEnabled', true);
            $pdf->getDomPDF()->set_option('isHtml5ParserEnabled', true);
            $pdf->getDomPDF()->set_option('defaultFont', 'DejaVu Sans');
            return $pdf->setPaper('a4', 'portrait')->download("تقرير_حضور_غير_رسمي.pdf");
        }

        return view('delegate.attendance.report', $data);
    }

    public function check(Request $request, $subjectId)
    {
        $date = $request->input('date');
        $title = $request->input('title');
        $lectureNumber = $request->input('lecture_number');

        $lecture = Lecture::where('subject_id', $subjectId)
            ->where('date', $date)
            ->when($title, fn ($query) => $query->where('title', $title))
            ->when($lectureNumber, fn ($query) => $query->where('lecture_number', $lectureNumber))
            ->first();

        $exists = $lecture
            ? Attendance::where('subject_id', $subjectId)
                ->where('date', $date)
                ->where('lecture_id', $lecture->id)
                ->exists()
            : false;

        return response()->json([
            'exists' => $exists,
            'title' => $lecture?->title ?? '',
            'lecture_number' => $lecture?->lecture_number ?? '',
        ]);
    }

    protected function getScopedStudents(User $delegate, string $genderFilter = 'all')
    {
        return User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->when($genderFilter !== 'all', fn ($query) => $query->where('gender', $genderFilter))
            ->orderBy('name')
            ->get();
    }

    protected function syncQrVerificationResults(int $qrSessionId, array $attendance, int $reviewerId): void
    {
        $session = QrAttendanceSession::with('verifications')->find($qrSessionId);

        if (!$session) {
            return;
        }

        foreach ($session->verifications as $verification) {
            $finalStatus = $attendance[$verification->student_id] ?? null;

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
