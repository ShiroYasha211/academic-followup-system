<?php

namespace App\Http\Controllers\Api\Doctor;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class AuthController extends DoctorApiController
{
    /** POST /api/doctor/login */
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

        if (! $user->canAccessDoctorWorkspace()) {
            return $this->error('ليس لديك صلاحية الوصول كدكتور.', 403);
        }

        if ($user->status !== 'active') {
            return $this->error('حسابك غير مفعل. يرجى التواصل مع الإدارة.', 403);
        }

        $token = $user->createToken('doctor-api')->plainTextToken;

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

    /** POST /api/doctor/logout */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return $this->success(null, 'تم تسجيل الخروج بنجاح');
    }

    /** GET /api/doctor/me */
    public function me(Request $request)
    {
        $user = $request->user()->load(['university', 'college', 'major']);

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
            'major' => $user->major?->name,
        ]);
    }

    /** POST /api/doctor/change-password */
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

        return $this->success(null, 'تم تغيير كلمة المرور بنجاح');
    }

    /** PATCH /api/doctor/profile/email */
    public function updateEmail(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'email' => [
                'required',
                'string',
                'email',
                'max:255',
                Rule::unique('users', 'email')->ignore($user->id),
            ],
            'current_password' => ['required', 'string'],
        ], [
            'email.required' => 'البريد الإلكتروني مطلوب.',
            'email.email' => 'يرجى إدخال بريد إلكتروني صحيح.',
            'email.unique' => 'البريد الإلكتروني مستخدم مسبقًا.',
            'current_password.required' => 'كلمة المرور الحالية مطلوبة.',
        ]);

        if (! Hash::check($request->current_password, $user->password)) {
            return $this->error('كلمة المرور الحالية غير صحيحة.', 422);
        }

        $user->forceFill([
            'email' => $request->email,
        ])->save();

        return $this->success([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
        ], 'تم تحديث البريد الإلكتروني بنجاح.');
    }
}
