<?php

namespace App\Http\Controllers\Api\Desktop;

use App\Models\DesktopPairingCode;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use App\Http\Controllers\Api\BaseController;

class AuthController extends BaseController
{
    public function exchange(Request $request)
    {
        $validated = $request->validate([
            'code' => 'required|string|max:20',
            'device_name' => 'nullable|string|max:120',
        ]);

        $code = DesktopPairingCode::normalizeCode($validated['code']);

        $pairing = DesktopPairingCode::query()
            ->usable()
            ->where('code', $code)
            ->with(['user', 'subject.doctor:id,name', 'subject.major:id,name', 'subject.level:id,name'])
            ->first();

        if (!$pairing || !$pairing->user) {
            return $this->error('رمز الربط غير صالح أو انتهت صلاحيته.', 404);
        }

        $user = $pairing->user;

        if ($user->status !== 'active') {
            return $this->error('الحساب غير مفعل.', 403);
        }

        if (!$this->canUseWorkspace($user, $pairing->workspace)) {
            return $this->error('المستخدم لا يملك صلاحية الربط لهذه المساحة.', 403);
        }

        $pairing->consume($validated['device_name'] ?? null);

        $workspace = $pairing->workspace;
        $tokenName = sprintf('desktop_%s_%s', $workspace, Str::lower(Str::random(8)));
        $abilities = ['desktop', 'qr-attendance', 'workspace:' . $workspace];
        $token = $user->createToken($tokenName, $abilities)->plainTextToken;

        return $this->success([
            'token' => $token,
            'workspace' => $workspace,
            'user' => $this->userPayload($user),
            'session_context' => $this->sessionContextPayload($pairing),
            'permissions' => [
                'can_start_qr' => true,
                'can_finalize_qr' => true,
            ],
        ], 'تم ربط تطبيق العرض بنجاح.');
    }

    public function me(Request $request)
    {
        return $this->success([
            'workspace' => $this->workspaceFromToken($request),
            'user' => $this->userPayload($request->user()),
        ], 'تم جلب بيانات الجهاز بنجاح.');
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return $this->success(null, 'تم إلغاء ربط الجهاز بنجاح.');
    }

    protected function canUseWorkspace($user, string $workspace): bool
    {
        return match ($workspace) {
            'doctor' => $user->canAccessDoctorWorkspace(),
            'delegate' => $user->canAccessDelegateWorkspace(),
            default => false,
        };
    }

    protected function workspaceFromToken(Request $request): ?string
    {
        $token = $request->user()?->currentAccessToken();

        if (!$token) {
            return null;
        }

        foreach ($token->abilities ?? [] as $ability) {
            if (str_starts_with($ability, 'workspace:')) {
                return Str::after($ability, 'workspace:');
            }
        }

        return null;
    }

    protected function userPayload($user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'preferred_workspace' => $user->preferredWorkspace(),
            'is_practical_delegate' => $user->isPracticalDelegate(),
        ];
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
