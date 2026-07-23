<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Http\Controllers\Api\Delegate\DelegateApiController;
use App\Models\Academic\Subject;
use App\Models\Attendance;
use App\Models\QrAttendanceSession;
use App\Models\Setting;
use App\Models\StudentNotification;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class QrAttendanceController extends DelegateApiController
{
    public function startSession(Request $request)
    {
        try {
            $user = $request->user();

            if (!$user) {
                return response()->json(['message' => 'User not found. Please login.'], 401);
            }

            if (!in_array($user->role, [UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE, UserRole::DOCTOR], true)) {
                return response()->json(['message' => 'غير مصرح لك بهذا الإجراء.'], 403);
            }

            $validated = $request->validate([
                'subject_id' => 'required|exists:subjects,id',
                'date' => 'required|date',
                'title' => 'required|string|max:255',
                'lecture_number' => 'nullable|string|max:50',
            ]);
            $validated['date'] = $this->normalizeDateInput($validated['date']);

            $subject = Subject::findOrFail($validated['subject_id']);

            if (!in_array($user->role, [UserRole::DOCTOR], true) && !$subject->allow_delegate_attendance) {
                return response()->json(['message' => 'التحضير مغلق من قبل الدكتور المشرف على المادة.'], 403);
            }

            $existing = QrAttendanceSession::where('subject_id', $validated['subject_id'])
                ->whereDate('date', $validated['date'])
                ->where('title', $validated['title'])
                ->when(array_key_exists('lecture_number', $validated), function ($query) use ($validated) {
                    $lectureNumber = trim((string) ($validated['lecture_number'] ?? ''));

                    return $lectureNumber === ''
                        ? $query->whereNull('lecture_number')
                        : $query->where('lecture_number', $lectureNumber);
                })
                ->first();

            if ($existing) {
                if ((int) $existing->delegate_id !== (int) $user->id && $existing->status === 'active') {
                    return response()->json([
                        'message' => 'توجد جلسة QR نشطة لهذه المحاضرة بواسطة مستخدم آخر. أنهِ الجلسة الحالية أولًا ثم حاول مرة أخرى.',
                    ], 409);
                }

                if (in_array($existing->status, ['finalized', 'cancelled'], true)) {
                    Attendance::where('qr_attendance_session_id', $existing->id)->delete();
                    $existing->verifications()->delete();
                    $existing->status = 'active';
                }

                $existing->delegate_id = $user->id;
                $existing->lecture_number = $validated['lecture_number'] ?? null;
                $existing->save();
                $existing->rotateToken();

                return $this->success([
                    'session_id' => $existing->id,
                    'token' => $existing->current_token,
                    'expires_at' => $existing->token_expires_at->toIso8601String(),
                    'rotation_seconds' => $existing->rotationSeconds(),
                ], 'الجلسة موجودة مسبقًا، تم تحديث الكود وإعادة تفعيلها.');
            }

            $firstToken = Str::random(48) . bin2hex(random_bytes(8));

            try {
                $session = QrAttendanceSession::create([
                    'subject_id' => $validated['subject_id'],
                    'delegate_id' => $user->id,
                    'date' => $validated['date'],
                    'title' => $validated['title'],
                    'lecture_number' => $validated['lecture_number'] ?? null,
                    'current_token' => $firstToken,
                    'token_expires_at' => Carbon::now()->addSeconds(max(5, (int) ($subject->major?->college?->qr_rotation_seconds ?? 30))),
                    'status' => 'active',
                ]);
            } catch (\Illuminate\Database\QueryException $exception) {
                $session = QrAttendanceSession::where('subject_id', $validated['subject_id'])
                    ->whereDate('date', $validated['date'])
                    ->where('title', $validated['title'])
                    ->when(array_key_exists('lecture_number', $validated), function ($query) use ($validated) {
                        $lectureNumber = trim((string) ($validated['lecture_number'] ?? ''));

                        return $lectureNumber === ''
                            ? $query->whereNull('lecture_number')
                            : $query->where('lecture_number', $lectureNumber);
                    })
                    ->first();

                if (!$session) {
                    throw $exception;
                }

                if ((int) $session->delegate_id !== (int) $user->id && $session->status === 'active') {
                    return response()->json([
                        'message' => 'توجد جلسة QR نشطة لهذه المحاضرة بواسطة مستخدم آخر. أنهِ الجلسة الحالية أولًا ثم حاول مرة أخرى.',
                    ], 409);
                }

                $session->update([
                    'delegate_id' => $user->id,
                    'lecture_number' => $validated['lecture_number'] ?? null,
                    'current_token' => $firstToken,
                    'token_expires_at' => Carbon::now()->addSeconds(max(5, (int) ($subject->major?->college?->qr_rotation_seconds ?? 30))),
                    'status' => 'active',
                ]);
            }

            return $this->success([
                'session_id' => $session->id,
                'token' => $session->current_token,
                'expires_at' => $session->token_expires_at->toIso8601String(),
                'rotation_seconds' => $session->rotationSeconds(),
            ], 'تم بدء جلسة الحضور بنجاح.', 201);
        } catch (\Illuminate\Database\QueryException $exception) {
            return response()->json([
                'message' => 'تعذر بدء جلسة QR لهذه المحاضرة. توجد جلسة مطابقة محفوظة مسبقًا، حدّث الصفحة ثم حاول مرة أخرى.',
            ], 409);
        } catch (\Exception $exception) {
            return response()->json([
                'message' => 'حدث خطأ أثناء بدء جلسة QR. حاول مرة أخرى.',
            ], 500);
        }
    }

    public function rotateToken(Request $request, QrAttendanceSession $session)
    {
        $user = $request->user();

        if ((int) $session->delegate_id !== (int) $user->id) {
            return response()->json(['message' => 'غير مصرح لك.'], 403);
        }

        if (!$session->isActive()) {
            return response()->json(['message' => 'الجلسة منتهية.'], 410);
        }

        $newToken = $session->rotateToken();

        return $this->success([
            'token' => $newToken,
            'expires_at' => $session->token_expires_at->toIso8601String(),
            'rotation_seconds' => $session->rotationSeconds(),
        ], 'تم تحديث الكود.');
    }

    public function getStatus(Request $request, QrAttendanceSession $session)
    {
        $user = $request->user();

        if ((int) $session->delegate_id !== (int) $user->id) {
            return response()->json(['message' => 'غير مصرح لك.'], 403);
        }

        $subject = $session->subject;

        $allStudents = User::whereIn('role', QrAttendanceSession::PARTICIPANT_ROLES)
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->orderBy('name')
            ->get(['id', 'name', 'student_number', 'gender', 'role']);

        $attendanceRecords = Attendance::where('qr_attendance_session_id', $session->id)
            ->get()
            ->keyBy('student_id');

        if ($attendanceRecords->isEmpty()) {
            $attendanceRecords = Attendance::where('subject_id', $session->subject_id)
                ->whereDate('date', $session->date)
                ->where('attendance_method', 'qr')
                ->where('recorded_by', $session->delegate_id)
                ->get()
                ->keyBy('student_id');
        }

        $students = $allStudents->map(function (User $student) use ($attendanceRecords) {
            $record = $attendanceRecords->get($student->id);

            return [
                'id' => $student->id,
                'name' => $student->name,
                'student_number' => $student->student_number,
                'gender' => $student->gender,
                'role' => $student->role?->value,
                'status' => $record ? $record->status : 'pending',
                'scanned_at' => $record ? $record->updated_at->toIso8601String() : null,
            ];
        });

        $scannedCount = $attendanceRecords->where('status', Attendance::STATUS_PRESENT)->count();
        $recentScans = $students
            ->where('status', Attendance::STATUS_PRESENT)
            ->sortByDesc('scanned_at')
            ->take(12)
            ->values();

        return $this->success([
            'session_status' => $session->status,
            'session' => [
                'id' => $session->id,
                'title' => $session->title,
                'date' => $session->date?->format('Y-m-d'),
                'lecture_number' => $session->lecture_number,
                'expires_at' => $session->token_expires_at?->toIso8601String(),
                'rotation_seconds' => $session->rotationSeconds(),
                'status' => $session->status,
            ],
            'subject' => [
                'id' => $subject->id,
                'name' => $subject->name,
                'code' => $subject->code,
                'major' => $subject->major?->name,
                'level' => $subject->level?->name,
                'allow_delegate_attendance' => (bool) $subject->allow_delegate_attendance,
            ],
            'title' => $session->title,
            'expires_at' => $session->token_expires_at?->toIso8601String(),
            'rotation_seconds' => $session->rotationSeconds(),
            'total_students' => $allStudents->count(),
            'scanned_count' => $scannedCount,
            'students' => $students,
            'recent_scans' => $recentScans,
            'verification' => $session->buildVerificationPayload(),
        ], 'تم جلب حالة الجلسة.');
    }

    public function scan(Request $request)
    {
        $user = $request->user();

        if (!in_array($user->role->value, [
            UserRole::STUDENT->value,
            UserRole::DELEGATE->value,
            UserRole::PRACTICAL_DELEGATE->value,
        ], true)) {
            return response()->json(['message' => 'هذه الميزة متاحة للطلاب فقط.'], 403);
        }

        if (!Setting::get('student_qr_scan_free_enabled', true) && !$user->isSubscribed()) {
            return response()->json([
                'message' => 'تصوير QR الحضور يحتاج إلى اشتراك نشط حاليًا.',
                'code' => 'subscription_required',
            ], 403);
        }

        $validated = $request->validate([
            'token' => 'required|string|size:64',
        ]);

        $session = QrAttendanceSession::where('current_token', $validated['token'])
            ->active()
            ->first();

        if (!$session) {
            return response()->json([
                'message' => 'الكود غير صالح أو منتهي الصلاحية. اطلب من المحضر تحديث الكود.',
            ], 404);
        }

        if (!$session->isTokenValid($validated['token'])) {
            return response()->json([
                'message' => 'انتهت صلاحية الكود. انتظر الكود الجديد ثم أعد المسح.',
            ], 410);
        }

        $subject = $session->subject;
        if ($user->major_id !== $subject->major_id || $user->level_id !== $subject->level_id) {
            return response()->json([
                'message' => 'أنت لست ضمن هذه الدفعة.',
            ], 403);
        }

        $existingAttendance = Attendance::where('student_id', $user->id)
            ->where('qr_attendance_session_id', $session->id)
            ->first();

        if ($existingAttendance && $existingAttendance->status === Attendance::STATUS_PRESENT) {
            return response()->json([
                'message' => 'تم تسجيل حضورك مسبقًا.',
                'already_scanned' => true,
                'confirmed' => true,
                'attendance_id' => $existingAttendance->id,
            ]);
        }

        try {
            $attendance = DB::transaction(function () use ($user, $session) {
                Attendance::updateOrCreate(
                    [
                        'student_id' => $user->id,
                        'qr_attendance_session_id' => $session->id,
                    ],
                    [
                        'subject_id' => $session->subject_id,
                        'date' => $session->date,
                        'status' => Attendance::STATUS_PRESENT,
                        'recorded_by' => $session->delegate_id,
                        'attendance_method' => 'qr',
                    ]
                );

                $confirmedAttendance = Attendance::where('student_id', $user->id)
                    ->where('qr_attendance_session_id', $session->id)
                    ->where('status', Attendance::STATUS_PRESENT)
                    ->first();

                if (!$confirmedAttendance) {
                    throw new \RuntimeException('QR attendance was not persisted as present.');
                }

                $this->notifyQrAttendanceConfirmed($confirmedAttendance, $session);

                return $confirmedAttendance;
            });
        } catch (\Throwable $exception) {
            return response()->json([
                'message' => 'لم يتم تأكيد حضورك. حاول مسح الكود مرة أخرى أو راجع المحضر.',
                'confirmed' => false,
            ], 500);
        }

        return response()->json([
            'message' => 'تم تأكيد حضورك بنجاح.',
            'confirmed' => true,
            'attendance_id' => $attendance->id,
            'subject' => $session->subject->name ?? '',
            'date' => $session->date->format('Y-m-d'),
        ]);
    }

    protected function notifyQrAttendanceConfirmed(Attendance $attendance, QrAttendanceSession $session): void
    {
        StudentNotification::create([
            'user_id' => $attendance->student_id,
            'type' => 'attendance_confirmation',
            'title' => 'تم تأكيد حضورك',
            'message' => "تم تأكيد حضورك في مادة {$session->subject->name} بتاريخ {$session->date->format('Y-m-d')}.",
            'data' => [
                'event' => 'qr_attendance_confirmed',
                'attendance_id' => $attendance->id,
                'subject_id' => $session->subject_id,
                'subject_name' => $session->subject->name,
                'qr_attendance_session_id' => $session->id,
                'date' => $session->date->format('Y-m-d'),
            ],
        ]);
    }

    public function finalize(Request $request, QrAttendanceSession $session)
    {
        $user = $request->user();

        if ((int) $session->delegate_id !== (int) $user->id) {
            return response()->json(['message' => 'غير مصرح لك.'], 403);
        }

        if ($session->status === 'finalized') {
            return response()->json(['message' => 'الجلسة منتهية بالفعل.'], 410);
        }

        $session->update(['status' => 'finalized']);
        $session->createVerificationSnapshot();

        $redirectRoute = $user->role === UserRole::DOCTOR
            ? 'doctor.attendance.create'
            : 'delegate.attendance.create';

        $redirectUrl = route($redirectRoute, $session->subject_id) . '?qr_session_id=' . $session->id;

        return $this->success(
            [
                'session_id' => $session->id,
                'subject_id' => $session->subject_id,
                'redirect_url' => $redirectUrl,
                'verification' => $session->buildVerificationPayload(),
            ],
            'تم إنهاء المسح بنجاح. يمكنك الآن مراجعة غير الماسحين وعينة التحقق قبل الحفظ النهائي.'
        );
    }

    public function cancel(Request $request, QrAttendanceSession $session)
    {
        $user = $request->user();

        if ((int) $session->delegate_id !== (int) $user->id) {
            return response()->json(['message' => 'غير مصرح لك.'], 403);
        }

        if ($session->status === 'finalized') {
            return response()->json(['message' => 'الجلسة منتهية بالفعل.'], 410);
        }

        Attendance::where('qr_attendance_session_id', $session->id)->delete();
        $session->verifications()->delete();
        $session->update([
            'status' => 'cancelled',
            'current_token' => Str::random(48) . bin2hex(random_bytes(8)),
            'token_expires_at' => now(),
        ]);

        return $this->success([
            'session_id' => $session->id,
            'status' => $session->status,
        ], 'تم إلغاء جلسة QR.');
    }

    public function active(Request $request)
    {
        $user = $request->user();
        $validated = $request->validate([
            'subject_id' => 'required|integer|exists:subjects,id',
            'date' => 'required|date',
            'title' => 'required|string|max:255',
            'lecture_number' => 'nullable|string|max:50',
        ]);
        $validated['date'] = $this->normalizeDateInput($validated['date']);

        $session = QrAttendanceSession::where('delegate_id', $user->id)
            ->where('subject_id', $validated['subject_id'])
            ->whereDate('date', $validated['date'])
            ->where('title', $validated['title'])
            ->when(array_key_exists('lecture_number', $validated), function ($query) use ($validated) {
                $lectureNumber = trim((string) ($validated['lecture_number'] ?? ''));
                return $lectureNumber === ''
                    ? $query->whereNull('lecture_number')
                    : $query->where('lecture_number', $lectureNumber);
            })
            ->where('status', 'active')
            ->latest('id')
            ->first();

        if (!$session) {
            return $this->success(['session' => null], 'لا توجد جلسة مطابقة.');
        }

        return $this->success([
            'session' => [
                'id' => $session->id,
                'status' => $session->status,
                'subject_id' => $session->subject_id,
                'date' => $session->date?->format('Y-m-d'),
                'title' => $session->title,
                'lecture_number' => $session->lecture_number,
            ],
        ], 'تم جلب حالة الجلسة.');
    }

    protected function normalizeDateInput($value): string
    {
        $value = trim((string) $value);

        if (preg_match('/^\d{4}-\d{2}-\d{2}/', $value, $matches)) {
            return $matches[0];
        }

        foreach (['d-m-Y', 'd/m/Y'] as $format) {
            try {
                return Carbon::createFromFormat($format, $value)->format('Y-m-d');
            } catch (\Throwable) {
                //
            }
        }

        return Carbon::parse($value)->format('Y-m-d');
    }
}
