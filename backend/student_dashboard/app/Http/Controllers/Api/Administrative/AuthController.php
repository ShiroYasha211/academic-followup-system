<?php

namespace App\Http\Controllers\Api\Administrative;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AuthController extends AdministrativeApiController
{
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return $this->error('بيانات الدخول غير صحيحة.', 401);
        }

        if (! $user->canAccessAdministrativeWorkspace()) {
            return $this->error('ليس لديك صلاحية الوصول إلى لوحة الإدارة.', 403);
        }

        if ($user->status !== 'active') {
            return $this->error('حسابك غير مفعل. يرجى التواصل مع الإدارة.', 403);
        }

        $user->tokens()->where('name', 'administrative-api')->delete();
        $token = $user->createToken('administrative-api')->plainTextToken;

        return $this->success([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'administrative_access' => $user->canAccessAdministrativeWorkspace(),
                'available_workspaces' => $user->availableWorkspaces(),
            ],
            'token' => $token,
        ], 'تم تسجيل الدخول بنجاح');
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return $this->success(null, 'تم تسجيل الخروج بنجاح');
    }

    public function me(Request $request)
    {
        $user = $request->user()->load(['university', 'college']);

        return $this->success([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'administrative_access' => $user->canAccessAdministrativeWorkspace(),
            'available_workspaces' => $user->availableWorkspaces(),
            'status' => $user->status,
            'university' => $user->university?->name,
            'college' => $user->college?->name,
            'balance' => $user->balance,
            'subscribed_until' => $user->subscribed_until?->format('Y-m-d H:i:s'),
        ]);
    }

    public function changePassword(Request $request)
    {
        $validated = $request->validate([
            'current_password' => ['required_without:old_password', 'nullable', 'current_password'],
            'old_password' => ['required_without:current_password', 'nullable', 'current_password'],
            'password' => ['required', 'confirmed', Password::defaults()],
        ]);

        $request->user()->update([
            'password' => Hash::make($validated['password']),
        ]);

        return $this->success(null, 'تم تغيير كلمة المرور بنجاح.');
    }
}
