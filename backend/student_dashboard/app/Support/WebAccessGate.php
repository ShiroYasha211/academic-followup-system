<?php

namespace App\Support;

use App\Enums\UserRole;
use App\Models\Setting;
use App\Models\User;

class WebAccessGate
{
    public const ENABLED_SETTING = 'web_access_enabled';
    public const MESSAGE_SETTING = 'web_access_closed_message';

    public static function isEnabled(): bool
    {
        return (bool) Setting::get(self::ENABLED_SETTING, true);
    }

    public static function closedMessage(): string
    {
        $message = Setting::get(
            self::MESSAGE_SETTING,
            'تم إيقاف دخول الموقع مؤقتًا. يرجى التواصل مع إدارة النظام.',
        );

        return trim((string) $message) !== ''
            ? (string) $message
            : 'تم إيقاف دخول الموقع مؤقتًا. يرجى التواصل مع إدارة النظام.';
    }

    public static function canAccessWeb(?User $user): bool
    {
        if (! $user) {
            return true;
        }

        if ($user->role === UserRole::ADMIN) {
            return true;
        }

        return self::isEnabled();
    }
}
