<?php

namespace App\Http\Controllers\Api\Student;

use App\Models\Setting;
use App\Models\StudentDevice;
use App\Models\User;
use App\Models\StudentDeviceRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AuthController extends StudentApiController
{
    /**
     * Student login.
     */
    public function login(Request $request)
    {
        $request->validate([
            'login' => 'required',
            'password' => 'required',
            'device' => 'nullable|array',
            'device.device_id' => 'nullable|string|max:255',
            'device.device_name' => 'nullable|string|max:255',
            'device.platform' => 'nullable|string|max:50',
            'device.app_version' => 'nullable|string|max:50',
        ]);

        $login = $request->login;

        $user = User::where(function ($query) use ($login) {
            $query->where('email', $login)
                ->orWhere('student_number', $login);
        })->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return $this->error('بيانات الدخول غير صحيحة.', 401);
        }

        if (! $user->canAccessStudentWorkspace()) {
            return $this->error('غير مصرح لك بالدخول إلى تطبيق الطالب.', 403);
        }

        if ($user->status !== 'active') {
            return $this->error('حسابك غير مفعل حاليًا. يرجى مراجعة الإدارة.', 403);
        }

        $deviceId = trim((string) ($request->input('device.device_id') ?? ''));
        if ($deviceId) {
            $existingDevice = $user->studentDevices()->where('device_id', $deviceId)->first();
            $hasPrimaryDevice = $user->studentDevices()->where('is_primary', true)->exists();
            
            if ($hasPrimaryDevice) {
                // If it doesn't exist, try to consume an available secondary slot
                if (!$existingDevice) {
                    $secondaryCount = $user->studentDevices()->where('device_type', StudentDevice::TYPE_SECONDARY)->count();
                    
                    if ($secondaryCount < ($user->allowed_secondary_devices ?? 0)) {
                        // Slot is available! Auto-register as active secondary device
                        $existingDevice = $user->studentDevices()->create([
                            'device_id' => $deviceId,
                            'device_name' => $request->input('device.device_name') ?? 'جهاز فرعي تلقائي',
                            'platform' => $request->input('device.platform'),
                            'app_version' => $request->input('device.app_version'),
                            'device_type' => StudentDevice::TYPE_SECONDARY,
                            'is_primary' => false,
                            'is_active' => true,
                            'is_temporary' => false,
                            'approved_at' => now(),
                        ]);
                    } else {
                        // No slots available
                        $whatsappNumber = Setting::get('support_whatsapp', Setting::get('admin_whatsapp_number', ''));
                        return $this->error(
                            'هذا الحساب مرتبط بجهاز آخر. يرجى التواصل مع الإدارة لفتح مساحة وتسجيل جهازك الجديد.',
                            403,
                            [
                                'error_code'      => 'device_not_authorized',
                                'whatsapp_number' => $whatsappNumber,
                            ]
                        );
                    }
                }

                // If it exists, verify it is valid (active and not expired)
                if (!$existingDevice->isValid()) {
                    $whatsappNumber = Setting::get('support_whatsapp', Setting::get('admin_whatsapp_number', ''));
                    
                    $message = $existingDevice->isExpired()
                        ? 'انتهت صلاحية الفترة المحددة لهذا الجهاز الفرعي. يرجى التواصل مع الإدارة لتمديد الصلاحية.'
                        : 'هذا الجهاز الفرعي غير نشط حالياً. يرجى التواصل مع الإدارة لتفعيله.';

                    return $this->error(
                        $message,
                        403,
                        [
                            'error_code'      => 'device_not_authorized',
                            'whatsapp_number' => $whatsappNumber,
                        ]
                    );
                }
            }
        }

        $user->load(['major', 'level', 'clinicalDelegateAssignment']);
        $device = $this->recordLoginDevice($user, $request->input('device', []));
        
        $abilities = [];
        if ($deviceId) {
            $abilities[] = 'device_id:' . $deviceId;
        }
        $token = $user->createToken('student_api_token', $abilities)->plainTextToken;

        return $this->success([
            'token' => $token,
            'device' => $device ? [
                'id' => $device->id,
                'device_type' => $device->device_type,
                'is_primary' => $device->is_primary,
                'is_active' => $device->is_active,
            ] : null,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'is_practical_delegate' => $user->isPracticalDelegate(),
                'avatar' => $user->avatar ? asset('storage/' . $user->avatar) : null,
                'major' => $user->major ? [
                    'id' => $user->major->id,
                    'name' => $user->major->name,
                    'has_clinical' => $user->major->has_clinical,
                ] : null,
                'level' => $user->level ? [
                    'id' => $user->level->id,
                    'name' => $user->level->name,
                ] : null,
                'academic_year' => $user->academic_year,
                'permissions' => $this->resolvedPermissions($user),
            ],
        ], 'تم تسجيل الدخول بنجاح');
    }

    private function recordLoginDevice(User $user, array $deviceData): ?StudentDevice
    {
        $deviceId = trim((string) ($deviceData['device_id'] ?? ''));

        if ($deviceId === '') {
            return null;
        }

        $hasPrimary = $user->studentDevices()->where('is_primary', true)->exists();
        $device = $user->studentDevices()->where('device_id', $deviceId)->first();

        $payload = [
            'device_name' => $deviceData['device_name'] ?? null,
            'platform' => $deviceData['platform'] ?? null,
            'app_version' => $deviceData['app_version'] ?? null,
            'last_login_at' => now(),
        ];

        if ($device) {
            if (! $hasPrimary) {
                $payload['device_type'] = StudentDevice::TYPE_PRIMARY;
                $payload['is_primary'] = true;
                $payload['is_active'] = true;
                $payload['approved_at'] = $device->approved_at ?? now();
            }

            $device->update($payload);

            return $device->refresh();
        }

        return $user->studentDevices()->create($payload + [
            'device_id' => $deviceId,
            'device_type' => $hasPrimary
                ? StudentDevice::TYPE_SECONDARY
                : StudentDevice::TYPE_PRIMARY,
            'is_primary' => ! $hasPrimary,
            'is_active' => ! $hasPrimary,
            'approved_at' => $hasPrimary ? null : now(),
        ]);
    }

    /**
     * Get current student profile.
     */
    public function me(Request $request)
    {
        $user = $request->user()->load([
            'major', 'university', 'college', 'level', 'clinicalDelegateAssignment',
            'studentDevices', 'studentDeviceRequests' => fn($q) => $q->latest()
        ]);

        return $this->success([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'student_number' => $user->student_number,
            'phone' => $user->phone,
            'gender' => $user->gender,
            'avatar' => $user->avatar ? asset('storage/' . $user->avatar) : null,
            'role' => $user->role,
            'status' => $user->status,
            'is_practical_delegate' => $user->isPracticalDelegate(),
            'academic_year' => $user->academic_year,
            'permissions' => $this->resolvedPermissions($user),
            'university' => $user->university->name ?? null,
            'college' => $user->college->name ?? null,
            'clinical_delegate_assignment' => $user->clinicalDelegateAssignment ? [
                'id' => $user->clinicalDelegateAssignment->id,
                'status' => $user->clinicalDelegateAssignment->status,
            ] : null,
            'major' => $user->major ? [
                'id' => $user->major->id,
                'name' => $user->major->name,
                'has_clinical' => $user->major->has_clinical,
            ] : null,
            'level' => $user->level ? [
                'id' => $user->level->id,
                'name' => $user->level->name,
            ] : null,
            'devices' => $user->studentDevices->map(fn($d) => [
                'id' => $d->id,
                'device_name' => $d->device_name,
                'platform' => $d->platform,
                'app_version' => $d->app_version,
                'device_type' => $d->device_type,
                'is_active' => $d->is_active,
                'is_temporary' => $d->is_temporary,
                'expires_at' => $d->expires_at ? $d->expires_at->toIso8601String() : null,
                'is_primary' => $d->is_primary,
            ]),
            'device_requests' => $user->studentDeviceRequests->map(fn($r) => [
                'id' => $r->id,
                'requested_device_name' => $r->requested_device_name,
                'platform' => $r->platform,
                'reason' => $r->reason,
                'status' => $r->status,
                'admin_note' => $r->admin_note,
                'created_at' => $r->created_at ? $r->created_at->toIso8601String() : null,
            ]),
        ]);
    }

    /**
     * Store student secondary device request.
     */
    public function storeDeviceRequest(Request $request)
    {
        $request->validate([
            'requested_device_name' => 'required|string|max:255',
            'platform' => 'nullable|string|max:50',
            'reason' => 'required|string',
        ]);

        $user = $request->user();

        // Check if there is already a pending request to prevent spamming
        $hasPending = $user->studentDeviceRequests()->where('status', StudentDeviceRequest::STATUS_PENDING)->exists();
        if ($hasPending) {
            return $this->error('لديك طلب معلق بالفعل. يرجى انتظار مراجعة الإدارة.', 400);
        }

        $deviceRequest = $user->studentDeviceRequests()->create([
            'requested_device_name' => $request->requested_device_name,
            'platform' => $request->platform,
            'reason' => $request->reason,
            'status' => StudentDeviceRequest::STATUS_PENDING,
        ]);

        return $this->success([
            'message' => 'تم تقديم طلب استخدام جهاز فرعي بنجاح.',
            'request' => [
                'id' => $deviceRequest->id,
                'requested_device_name' => $deviceRequest->requested_device_name,
                'platform' => $deviceRequest->platform,
                'reason' => $deviceRequest->reason,
                'status' => $deviceRequest->status,
                'created_at' => $deviceRequest->created_at->toIso8601String(),
            ]
        ]);
    }

    /**
     * Get dynamic support settings.
     */
    public function supportSettings()
    {
        return $this->success([
            'support_phone'      => Setting::get('support_phone', '+967 777 000 111'),
            'support_whatsapp'   => Setting::get('support_whatsapp', '+967 777 000 222'),
            'support_email'      => Setting::get('support_email', 'support@moeen.tech'),
            'support_website'    => Setting::get('support_website', 'moeen.tech'),
            'support_instagram'  => Setting::get('support_instagram', '@moeen.app'),
            'student_qr_scan_free_enabled' => Setting::get('student_qr_scan_free_enabled', true),
            'support_work_hours' => Setting::get('support_work_hours', 'السبت - الخميس | 8:00 ص - 2:00 م'),
            'support_notice'     => Setting::get('support_notice', 'عند وجود مشكلة في الحضور أو رفع الملفات، يرجى إرسال اسمك، رقم القيد، وصف دقيق للمشكلة، مع لقطة شاشة توضيحية لضمان سرعة المعالجة.'),
        ]);
    }

    /**
     * Student logout.
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return $this->success(null, 'تم تسجيل الخروج بنجاح.');
    }

    /**
     * Change student password.
     */
    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required_without:old_password',
            'old_password' => 'required_without:current_password',
            'new_password' => 'required|min:8|confirmed',
        ]);

        $user = $request->user();
        $currentPassword = $request->input('current_password', $request->input('old_password'));

        if (! Hash::check($currentPassword, $user->password)) {
            return $this->error('كلمة المرور القديمة غير صحيحة.', 422);
        }

        $user->update([
            'password' => Hash::make($request->new_password),
        ]);

        return $this->success(null, 'تم تغيير كلمة المرور بنجاح.');
    }

    /**
     * Update student email address.
     */
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

    private function resolvedPermissions(User $user): array
    {
        $permissions = $user->permissions()
            ->pluck('slug')
            ->map(fn ($slug) => (string) $slug);

        if ($user->canAccessDelegateWorkspace()) {
            $permissions = $permissions->merge($user->all_delegate_permissions);
        }

        return $permissions->filter()->unique()->values()->all();
    }
}
