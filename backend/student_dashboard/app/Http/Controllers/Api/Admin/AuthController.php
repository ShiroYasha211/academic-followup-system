<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\User;
use App\Enums\UserRole;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends AdminApiController
{
    /**
     * POST /api/admin/login
     */
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

        if (! in_array($user->role, [UserRole::ADMIN]) && ! $user->canAccessAdministrativeWorkspace()) {
            return $this->error('ليس لديك صلاحية الوصول إلى لوحة الإدارة.', 403);
        }

        if ($user->status !== 'active') {
            return $this->error('حسابك غير مفعّل. يرجى التواصل مع الإدارة.', 403);
        }

        $user->tokens()->where('name', 'admin-api')->delete();
        $token = $user->createToken('admin-api')->plainTextToken;

        return $this->success([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'available_workspaces' => $user->availableWorkspaces(),
                'administrative_access' => $user->canAccessAdministrativeWorkspace(),
            ],
            'token' => $token,
        ], 'تم تسجيل الدخول بنجاح');
    }

    /**
     * POST /api/admin/logout
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return $this->success(null, 'تم تسجيل الخروج بنجاح');
    }

    /**
     * GET /api/admin/me
     */
    public function me(Request $request)
    {
        $user = $request->user()->load(['university', 'college', 'major']);

        return $this->success([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'available_workspaces' => $user->availableWorkspaces(),
            'administrative_access' => $user->canAccessAdministrativeWorkspace(),
            'status' => $user->status,
            'university' => $user->university?->name,
            'college' => $user->college?->name,
            'major' => $user->major?->name,
        ]);
    }
    /**
     * POST /api/admin/change-password
     */
    public function changePassword(Request $request)
    {
        $request->validate([
            'old_password' => 'required',
            'new_password' => 'required|min:8|confirmed',
        ]);

        $user = $request->user();

        if (!Hash::check($request->old_password, $user->password)) {
            return $this->error('كلمة المرور القديمة غير صحيحة.', 422);
        }

        $user->update([
            'password' => Hash::make($request->new_password)
        ]);

        \App\Models\ActivityLog::log('update', 'User', $user->id, $user->name, "قام الأدمن بتغيير كلمة مروره الشخصية عبر الـ API");

        return $this->success(null, 'تم تغيير كلمة المرور بنجاح.');
    }
}
