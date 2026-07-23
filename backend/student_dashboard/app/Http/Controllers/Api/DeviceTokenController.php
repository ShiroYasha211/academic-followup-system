<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\PushNotificationService;
use App\Models\UserDevice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class DeviceTokenController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'device_token' => 'required|string|max:2048',
            'platform' => 'required|in:android,ios,web',
            'device_name' => 'nullable|string|max:255',
            'app_version' => 'nullable|string|max:50',
        ]);

        $device = UserDevice::updateOrCreate(
            ['device_token' => $validated['device_token']],
            [
                'user_id' => $request->user()->id,
                'platform' => $validated['platform'],
                'device_name' => $validated['device_name'] ?? null,
                'app_version' => $validated['app_version'] ?? null,
                'last_used_at' => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Device token registered successfully.',
            'data' => [
                'id' => $device->id,
                'platform' => $device->platform,
                'last_used_at' => $device->last_used_at,
                'devices_count' => UserDevice::where('user_id', $request->user()->id)->count(),
            ],
        ]);
    }

    public function status(Request $request, PushNotificationService $pushNotificationService): JsonResponse
    {
        $devices = UserDevice::where('user_id', $request->user()->id)
            ->latest('last_used_at')
            ->get(['id', 'platform', 'device_name', 'app_version', 'last_used_at', 'created_at']);

        return response()->json([
            'success' => true,
            'message' => 'Device push status loaded successfully.',
            'data' => [
                'firebase_configured' => $pushNotificationService->isConfigured(),
                'devices_count' => $devices->count(),
                'devices' => $devices,
            ],
        ]);
    }

    public function test(Request $request, PushNotificationService $pushNotificationService): JsonResponse
    {
        $result = $pushNotificationService->sendToUser($request->user(), [
            'title' => 'اختبار إشعارات معين',
            'body' => 'إذا وصل هذا الإشعار فربط Firebase يعمل بنجاح.',
            'data' => [
                'type' => 'test',
                'screen' => 'notifications',
                'workspace' => $request->user()->role?->value ?? $request->user()->role ?? 'student',
                'request_id' => (string) Str::uuid(),
            ],
        ]);

        return response()->json([
            'success' => ($result['sent'] ?? 0) > 0,
            'message' => ($result['sent'] ?? 0) > 0
                ? 'Test push notification sent successfully.'
                : 'Test push notification was not sent.',
            'data' => $result,
        ], ($result['sent'] ?? 0) > 0 ? 200 : 422);
    }

    public function destroy(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'device_token' => 'required|string|max:2048',
        ]);

        UserDevice::where('user_id', $request->user()->id)
            ->where('device_token', $validated['device_token'])
            ->delete();

        return response()->json([
            'success' => true,
            'message' => 'Device token removed successfully.',
        ]);
    }
}
