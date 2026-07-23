<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Models\StudentDevice;
use App\Enums\UserRole;
use Symfony\Component\HttpFoundation\Response;

class ValidateDeviceBinding
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && in_array($user->role, [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE], true)) {
            $token = $user->currentAccessToken();

            if ($token) {
                $abilities = $token->abilities ?? [];
                $deviceId = null;

                foreach ($abilities as $ability) {
                    if (strpos($ability, 'device_id:') === 0) {
                        $deviceId = substr($ability, 10);
                        break;
                    }
                }

                if ($deviceId) {
                    $device = StudentDevice::where('student_id', $user->id)
                        ->where('device_id', $deviceId)
                        ->first();

                    if (!$device || !$device->isValid()) {
                        // Revoke the token
                        $token->delete();

                        return response()->json([
                            'success' => false,
                            'message' => 'تم إلغاء تنشيط هذا الجهاز أو انتهت صلاحية استخدامه. يرجى التواصل مع الإدارة.',
                            'error_code' => 'device_not_authorized'
                        ], 401);
                    }
                }
            }
        }

        return $next($request);
    }
}
