<?php

namespace App\Http\Middleware;

use App\Enums\UserRole;
use App\Models\StudentDevice;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsurePrimaryStudentDevice
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user || ! in_array($user->role, [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE], true)) {
            return $next($request);
        }

        $token = $user->currentAccessToken();
        $deviceId = $this->deviceIdFromToken($token?->abilities ?? []);

        if (! $deviceId) {
            return $this->primaryDeviceRequired();
        }

        $device = StudentDevice::where('student_id', $user->id)
            ->where('device_id', $deviceId)
            ->first();

        if (! $device || ! $device->isValid()) {
            return response()->json([
                'success' => false,
                'message' => 'تم إلغاء تنشيط هذا الجهاز أو انتهت صلاحية استخدامه. يرجى التواصل مع الإدارة.',
                'error_code' => 'device_not_authorized',
            ], 401);
        }

        if (! $device->is_primary || $device->device_type !== StudentDevice::TYPE_PRIMARY) {
            return $this->primaryDeviceRequired();
        }

        return $next($request);
    }

    private function deviceIdFromToken(array $abilities): ?string
    {
        foreach ($abilities as $ability) {
            if (is_string($ability) && str_starts_with($ability, 'device_id:')) {
                return substr($ability, 10);
            }
        }

        return null;
    }

    private function primaryDeviceRequired(): Response
    {
        return response()->json([
            'success' => false,
            'message' => 'هذه الميزة متاحة من الجهاز الأساسي فقط.',
            'error_code' => 'primary_device_required',
        ], 403);
    }
}
