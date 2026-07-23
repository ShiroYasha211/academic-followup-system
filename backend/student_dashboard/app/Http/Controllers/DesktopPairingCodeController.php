<?php

namespace App\Http\Controllers;

use App\Enums\UserRole;
use App\Models\Academic\Subject;
use App\Models\DesktopPairingCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DesktopPairingCodeController extends Controller
{
    public function issueForDoctor(Request $request): JsonResponse
    {
        $user = $request->user();

        abort_unless($user && $user->canAccessDoctorWorkspace(), 403);

        return $this->issue($request, 'doctor');
    }

    public function issueForDelegate(Request $request): JsonResponse
    {
        $user = $request->user();

        abort_unless($user, 403);

        $allowed = in_array($user->role, [UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE], true)
            || $user->hasClinicalDelegateAssignment();

        abort_unless($allowed, 403);

        return $this->issue($request, 'delegate');
    }

    protected function issue(Request $request, string $workspace): JsonResponse
    {
        $validated = $request->validate([
            'device_name' => 'nullable|string|max:120',
            'subject_id' => 'required|integer|exists:subjects,id',
            'date' => 'required|date',
            'title' => 'required|string|max:255',
            'lecture_number' => 'nullable|string|max:50',
        ]);

        $user = $request->user();
        $subject = Subject::with(['doctor:id,name', 'major:id,name', 'level:id,name'])
            ->findOrFail($validated['subject_id']);

        abort_unless($this->canStartAttendanceForSubject($user, $workspace, $subject), 403);

        DesktopPairingCode::query()
            ->where('user_id', $user->id)
            ->where('workspace', $workspace)
            ->whereNull('used_at')
            ->delete();

        $pairing = DesktopPairingCode::create([
            'user_id' => $user->id,
            'workspace' => $workspace,
            'subject_id' => $subject->id,
            'attendance_date' => $validated['date'],
            'session_title' => $validated['title'],
            'lecture_number' => $validated['lecture_number'] ?? null,
            'code' => DesktopPairingCode::generateUniqueCode(),
            'device_name' => $validated['device_name'] ?? null,
            'expires_at' => now()->addMinutes(10),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'تم إنشاء رمز الربط بنجاح.',
            'data' => [
                'code' => $pairing->code,
                'display_code' => $pairing->formattedCode(),
                'workspace' => $workspace,
                'session_context' => $this->sessionContextPayload($pairing->load('subject.doctor:id,name', 'subject.major:id,name', 'subject.level:id,name')),
                'expires_at' => $pairing->expires_at?->toIso8601String(),
                'expires_in_seconds' => max(0, now()->diffInSeconds($pairing->expires_at, false)),
            ],
        ]);
    }

    protected function canStartAttendanceForSubject($user, string $workspace, Subject $subject): bool
    {
        if ($workspace === 'doctor') {
            return (int) $subject->doctor_id === (int) $user->id;
        }

        return (int) $subject->major_id === (int) $user->major_id
            && (int) $subject->level_id === (int) $user->level_id
            && (bool) $subject->allow_delegate_attendance;
    }

    protected function sessionContextPayload(DesktopPairingCode $pairing): array
    {
        $subject = $pairing->subject;

        return [
            'subject' => $subject ? [
                'id' => $subject->id,
                'name' => $subject->name,
                'code' => $subject->code,
                'doctor' => $subject->doctor ? [
                    'id' => $subject->doctor->id,
                    'name' => $subject->doctor->name,
                ] : null,
                'major' => $subject->major ? [
                    'id' => $subject->major->id,
                    'name' => $subject->major->name,
                ] : null,
                'level' => $subject->level ? [
                    'id' => $subject->level->id,
                    'name' => $subject->level->name,
                ] : null,
                'allow_delegate_attendance' => (bool) $subject->allow_delegate_attendance,
            ] : null,
            'date' => $pairing->attendance_date?->format('Y-m-d'),
            'title' => $pairing->session_title,
            'lecture_number' => $pairing->lecture_number,
        ];
    }
}
