<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\StudentDevice;
use App\Enums\UserRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeviceValidationTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test student login binds device_id to token ability and middleware works.
     */
    public function test_device_binding_middleware_and_login()
    {
        // 1. Create a student user
        $student = User::create([
            'name' => 'Test Student',
            'email' => 'student@test.com',
            'student_number' => '12345678',
            'password' => bcrypt('password123'),
            'role' => UserRole::STUDENT,
            'status' => 'active',
        ]);

        // 2. Mock login request to student login API
        $response = $this->postJson('/api/student/login', [
            'login' => 'student@test.com',
            'password' => 'password123',
            'device' => [
                'device_id' => 'my-unique-device-id',
                'device_name' => 'iPhone 15 Pro',
                'platform' => 'ios',
                'app_version' => '1.0.0',
            ]
        ]);

        $response->assertStatus(200);
        $token = $response->json('data.token');
        $this->assertNotNull($token);

        // 3. Verify device was registered as primary and active
        $device = StudentDevice::where('student_id', $student->id)->where('device_id', 'my-unique-device-id')->first();
        $this->assertNotNull($device);
        $this->assertTrue($device->is_active);
        $this->assertTrue($device->is_primary);

        // 4. Request authenticated endpoint and verify it passes (200 or 403/other if no sub, but not 401 device error)
        $meResponse = $this->getJson('/api/student/me', [
            'Authorization' => 'Bearer ' + $token,
        ]);
        // Because of CheckSubscription middleware, it might return 403 subscription error, which is fine since it's not a 401 device error
        $this->assertNotEquals(401, $meResponse->status());

        // 5. Deactivate the device
        $device->update(['is_active' => false]);

        // 6. Request again and verify it is kicked out (401 Unauthorized)
        $meResponse2 = $this->getJson('/api/student/me', [
            'Authorization' => 'Bearer ' . $token,
        ]);
        $meResponse2->assertStatus(401);
        $meResponse2->assertJson([
            'success' => false,
            'message' => 'تم إلغاء تنشيط هذا الجهاز أو انتهت صلاحية استخدامه. يرجى التواصل مع الإدارة.',
            'error_code' => 'device_not_authorized'
        ]);
    }
}
