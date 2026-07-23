<?php

namespace App\Support;

use App\Models\Academic\University;
use App\Models\Setting;
use App\Models\User;

class OwnerPresentationMode
{
    public const ENABLED_SETTING = 'owner_graduation_presentation_mode';
    public const DEFAULT_UNIVERSITY_SETTING = 'owner_default_university_id';

    public static function enabledFor(?User $user): bool
    {
        return (bool) $user?->isSystemOwner()
            && (bool) Setting::get(self::ENABLED_SETTING, false);
    }

    public static function defaultUniversityId(): ?int
    {
        $id = (int) Setting::get(self::DEFAULT_UNIVERSITY_SETTING, 0);

        return $id > 0 ? $id : null;
    }

    public static function defaultUniversity(): ?University
    {
        $id = self::defaultUniversityId();

        return $id ? University::find($id) : null;
    }
}
