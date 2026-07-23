<?php

namespace App\Http\Controllers\Doctor;

use App\Enums\UserRole;
use App\Exceptions\AttendanceEditLockedException;
use App\Http\Controllers\Controller;
use App\Models\Academic\Lecture;
use App\Models\Academic\Subject;
use App\Models\Attendance;
use App\Models\QrAttendanceSession;
use App\Models\Student\StudentScheduleItem;
use App\Models\User;
use App\Services\AttendanceEditGate;
use App\Support\ExcuseWorkflow;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class AttendanceController extends Controller
{
    public function index()
    {
        $doctor = Auth::user();

        $subjects = Subject::where('doctor_id', $doctor->id)
            ->with(['major', 'level'])
            ->get();

        $subjectIds = $subjects->pluck('id');

        $sessions = Attendance::selectRaw('subject_id, date, lecture_id, recorded_by, attendance_method, count(*) as total_records')
            ->whereIn('subject_id', $subjectIds)
            ->groupBy('subject_id', 'date', 'lecture_id', 'recorded_by', 'attendance_method')
            ->with(['subject', 'lecture', 'recorder'])
            ->latest('date')
            ->paginate(10);

        return view('doctor.attendance.index', compact('sessions', 'subjects'));
    }

    public function create(Request $request, Subject $subject)
    {
        $doctor = Auth::user();

        if ($subject->doctor_id !== $doctor->id) {
            abort(403, 'غير مصرح لك بالوصول لهذا المقرر.');
        }

        $date = $request->input('date') ?? date('Y-m-d');
        $genderFilter = in_array($request->input('gender_filter'), ['male', 'female'], true)
            ? $request->input('gender_filter')
            : 'all';
        $qrSessionId = $request->input('qr_session_id');

        $students = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->orderBy('name')
            ->get();

        $attendanceRecords = null;
        $prefill = [];
        $qrVerification = null;

        if ($qrSessionId) {
            $qrSession = QrAttendanceSession::where('id', $qrSessionId)
                ->where('delegate_id', $doctor->id)
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
            $lectureId = $request->input('lecture_id');
            $lecture = null;

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

        return view('doctor.attendance.create', compact(
            'subject',
            'students',
            'attendanceRecords',
            'prefill',
            'genderFilter',
            'qrVerification'
        ));
    }

    public function store(Request $request, Subject $subject)
    {
        $doctor = Auth::user();

        if ($subject->doctor_id !== $doctor->id) {
            abort(403, 'غير مصرح لك بالوصول لهذا المقرر.');
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
            'attendance.*' => 'required|in:' . implode(',', ExcuseWorkflow::editableAttendanceStatuses()),
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
                    'recorded_by' => $doctor->id,
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
                        $doctor
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
                        $doctor
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
                $this->syncQrVerificationResults((int) $validated['qr_session_id'], $validated['attendance'], $doctor->id);
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
            ->route('doctor.attendance.index')
            ->with('success', 'تم رصد الحضور وتحديث قائمة التحقق بنجاح.');
    }

    public function showReport(Request $request, $subjectId, $date)
    {
        $doctor = Auth::user();

        $subject = Subject::where('id', $subjectId)
            ->where('doctor_id', $doctor->id)
            ->firstOrFail();

        $genderFilter = in_array($request->input('gender_filter'), ['male', 'female'], true)
            ? $request->input('gender_filter')
            : 'all';

        $students = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->when($genderFilter !== 'all', fn ($query) => $query->where('gender', $genderFilter))
            ->orderBy('name')
            ->get();

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

        return view('doctor.attendance.report-clean', compact('subject', 'students', 'attendanceRecords', 'date', 'genderFilter', 'lecture'));
    }

    public function toggleDelegateAttendance(Request $request, Subject $subject)
    {
        $doctor = Auth::user();

        if ($subject->doctor_id !== $doctor->id) {
            abort(403, 'غير مصرح لك بالوصول لهذا المقرر.');
        }

        $subject->allow_delegate_attendance = !$subject->allow_delegate_attendance;
        $subject->save();

        $status = $subject->allow_delegate_attendance ? 'تم تفعيل' : 'تم إيقاف';

        return redirect()
            ->back()
            ->with('success', "{$status} صلاحية تحضير المندوب للمقرر بنجاح.");
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
