<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Academic\Lecture;
use App\Models\Academic\Subject;
use App\Models\Attendance;
use App\Models\AttendanceEditPermission;
use App\Models\AttendanceEditRequest;
use App\Models\QrAttendanceSession;
use Illuminate\Http\Request;

class AttendanceEditRequestController extends Controller
{
    public function index(Request $request)
    {
        $requests = AttendanceEditRequest::where('requester_id', $request->user()->id)
            ->with(['subject:id,name,code', 'lecture:id,title,lecture_number,date', 'qrSession:id,title,lecture_number,date', 'permission'])
            ->latest()
            ->limit(30)
            ->get();

        $permissions = AttendanceEditPermission::active()
            ->where('user_id', $request->user()->id)
            ->with(['subject:id,name,code', 'lecture:id,title,lecture_number,date', 'qrSession:id,title,lecture_number,date'])
            ->latest('expires_at')
            ->get();

        return response()->json([
            'requests' => $requests,
            'active_permissions' => $permissions,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'attendance_id' => 'nullable|integer|exists:attendances,id',
            'subject_id' => 'nullable|integer|exists:subjects,id',
            'lecture_id' => 'nullable|integer|exists:lectures,id',
            'qr_attendance_session_id' => 'nullable|integer|exists:qr_attendance_sessions,id',
            'date' => 'nullable|date',
            'title' => 'nullable|string|max:255',
            'reason' => 'required|string|min:5|max:2000',
        ]);

        $scope = $this->resolveScope($validated);
        $this->authorizeScope($request, $scope);

        if (empty($scope['date']) && empty($scope['lecture_id']) && empty($scope['qr_attendance_session_id'])) {
            return response()->json([
                'message' => 'يجب تحديد تاريخ أو محاضرة لطلب فتح تعديل الحضور.',
            ], 422);
        }

        $existingQuery = AttendanceEditRequest::pending()
            ->where('requester_id', $request->user()->id)
            ->where('subject_id', $scope['subject_id'])
            ->where('lecture_id', $scope['lecture_id'])
            ->where('qr_attendance_session_id', $scope['qr_attendance_session_id']);

        if ($scope['date']) {
            $existingQuery->whereDate('date', $scope['date']);
        } else {
            $existingQuery->whereNull('date');
        }

        $existing = $existingQuery->first();

        if ($existing) {
            return response()->json([
                'message' => 'يوجد طلب فتح تعديل معلق لنفس سجل الحضور.',
                'request' => $existing,
            ], 200);
        }

        $editRequest = AttendanceEditRequest::create([
            'requester_id' => $request->user()->id,
            'subject_id' => $scope['subject_id'],
            'lecture_id' => $scope['lecture_id'],
            'qr_attendance_session_id' => $scope['qr_attendance_session_id'],
            'date' => $scope['date'],
            'title' => $scope['title'],
            'reason' => $validated['reason'],
        ]);

        return response()->json([
            'message' => 'تم إرسال طلب فتح تعديل الحضور إلى الأدمن الرئيسي.',
            'request' => $editRequest,
        ], 201);
    }

    protected function resolveScope(array $validated): array
    {
        $attendance = !empty($validated['attendance_id'])
            ? Attendance::with(['lecture', 'qrSession'])->findOrFail($validated['attendance_id'])
            : null;

        $lecture = null;
        if (!empty($validated['lecture_id'])) {
            $lecture = Lecture::findOrFail($validated['lecture_id']);
        } elseif ($attendance?->lecture_id) {
            $lecture = $attendance->lecture;
        }

        $qrSession = null;
        if (!empty($validated['qr_attendance_session_id'])) {
            $qrSession = QrAttendanceSession::findOrFail($validated['qr_attendance_session_id']);
        } elseif ($attendance?->qr_attendance_session_id) {
            $qrSession = $attendance->qrSession;
        }

        return [
            'subject_id' => $lecture?->subject_id ?? $qrSession?->subject_id ?? $attendance?->subject_id ?? ($validated['subject_id'] ?? null),
            'lecture_id' => $lecture?->id,
            'qr_attendance_session_id' => $qrSession?->id,
            'date' => $lecture?->date?->format('Y-m-d')
                ?? $qrSession?->date?->format('Y-m-d')
                ?? $attendance?->date?->format('Y-m-d')
                ?? ($validated['date'] ?? null),
            'title' => $lecture?->title ?? $qrSession?->title ?? ($validated['title'] ?? null),
        ];
    }

    protected function authorizeScope(Request $request, array $scope): void
    {
        $user = $request->user();
        $role = $user->role instanceof UserRole ? $user->role : UserRole::from($user->role);

        if (!in_array($role, [UserRole::DOCTOR, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE], true)) {
            abort(403, 'غير مصرح لك بإرسال طلب تعديل الحضور.');
        }

        if ($scope['qr_attendance_session_id']) {
            $qrSession = QrAttendanceSession::findOrFail($scope['qr_attendance_session_id']);

            if ((int) $qrSession->delegate_id !== (int) $user->id) {
                abort(403, 'غير مصرح لك بهذا النطاق.');
            }

            return;
        }

        if ($scope['lecture_id']) {
            $lecture = Lecture::with('subject')->findOrFail($scope['lecture_id']);
            $subject = $lecture->subject;

            if ($subject) {
                $this->authorizeSubject($user, $role, $subject);
            } elseif (!in_array($role, [UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE], true)) {
                abort(403, 'غير مصرح لك بهذا النطاق.');
            }

            return;
        }

        if ($scope['subject_id']) {
            $this->authorizeSubject($user, $role, Subject::findOrFail($scope['subject_id']));
            return;
        }

        if (!in_array($role, [UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE], true)) {
            abort(403, 'يجب تحديد مادة أو محاضرة لطلب تعديل الحضور.');
        }
    }

    protected function authorizeSubject($user, UserRole $role, Subject $subject): void
    {
        if ($role === UserRole::DOCTOR && (int) $subject->doctor_id === (int) $user->id) {
            return;
        }

        if (in_array($role, [UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE], true)
            && (int) $subject->major_id === (int) $user->major_id
            && (int) $subject->level_id === (int) $user->level_id) {
            return;
        }

        abort(403, 'غير مصرح لك بهذا النطاق.');
    }
}
