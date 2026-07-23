<?php

namespace App\Services;

use App\Models\StudentNotification;
use App\Models\User;

class AdministrativeAccessNotificationService
{
    public function notify(User $doctor, bool $enabled, ?int $senderId = null): StudentNotification
    {
        return StudentNotification::create([
            'user_id' => $doctor->id,
            'college_id' => $doctor->college_id,
            'sender_id' => $senderId,
            'type' => 'administrative_access',
            'title' => $enabled
                ? 'تم منحك صلاحية المسؤول الإداري'
                : 'تم سحب صلاحية المسؤول الإداري',
            'message' => $enabled
                ? 'أصبح بإمكانك الآن الانتقال إلى لوحة المسؤول الإداري وإدارة الكلية من حسابك.'
                : 'تم سحب صلاحية الوصول إلى لوحة المسؤول الإداري من حسابك.',
            'data' => [
                'screen' => 'notifications',
                'target_screen' => 'notifications',
                'administrative_access' => $enabled,
                'refresh_session' => true,
            ],
        ]);
    }
}
