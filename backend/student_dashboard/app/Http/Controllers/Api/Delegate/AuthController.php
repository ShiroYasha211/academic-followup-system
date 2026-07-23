<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends DelegateApiController
{
    /**
     * Login delegate workspace users and issue a token.
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return $this->error('البريد الإلكتروني أو كلمة المرور غير صحيحة', 401);
        }

        if ($user->status !== 'active') {
            return $this->error('حسابك غير مفعل', 403);
        }

        if (! $user->canAccessDelegateWorkspace()) {
            return $this->error('غير مصرح لك بالدخول لتطبيق المندوب', 403);
        }

        $user->tokens()->where('name', 'delegate_app')->delete();
        $token = $user->createToken('delegate_app', ['delegate'])->plainTextToken;

        return $this->success([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'avatar' => $user->avatar,
                'role' => $user->role,
                'major_id' => $user->major_id,
                'level_id' => $user->level_id,
                'is_practical_delegate' => $user->isPracticalDelegate(),
                'is_clinical_delegate' => $user->isClinicalDelegate(),
                'permissions' => $user->all_delegate_permissions,
            ],
            'token' => $token,
        ], 'تم تسجيل الدخول بنجاح');
    }

    /**
     * Logout and revoke token.
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return $this->success(null, 'تم تسجيل الخروج بنجاح');
    }

    /**
     * Get the authenticated delegate profile.
     */
    public function me(Request $request)
    {
        $user = $request->user()->load(['major', 'level', 'clinicalDelegateAssignment']);

        return $this->success([
            'user' => array_merge(
                $user->toArray(),
                [
                    'is_practical_delegate' => $user->isPracticalDelegate(),
                    'is_clinical_delegate' => $user->isClinicalDelegate(),
                    'permissions' => $user->all_delegate_permissions,
                ]
            ),
        ], 'تم جلب البيانات بنجاح');
    }

    /**
     * Change user password.
     */
    public function changePassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'old_password' => 'required',
            'new_password' => 'required|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        $user = $request->user();

        if (! Hash::check($request->old_password, $user->password)) {
            return $this->error('كلمة المرور القديمة غير صحيحة', 422);
        }

        $user->update([
            'password' => Hash::make($request->new_password),
        ]);

        return $this->success(null, 'تم تغيير كلمة المرور بنجاح');
    }
}
