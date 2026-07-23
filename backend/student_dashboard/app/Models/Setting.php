<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class Setting extends Model
{
    protected $fillable = [
        'key',
        'value',
        'type',
        'group',
        'label',
        'description',
    ];

    /**
     * Get a setting value by key
     */
    public static function get(string $key, mixed $default = null): mixed
    {
        $setting = Cache::rememberForever("setting.{$key}", function () use ($key) {
            return self::where('key', $key)->first();
        });

        if (!$setting) {
            return $default;
        }

        return match ($setting->type) {
            'boolean' => (bool) $setting->value,
            'number' => (int) $setting->value,
            'json' => json_decode($setting->value, true),
            default => $setting->value
        };
    }

    /**
     * Set a setting value
     */
    public static function set(string $key, mixed $value): bool
    {
        $setting = self::where('key', $key)->first();

        if (!$setting) {
            return false;
        }

        // Convert value based on type
        if (is_array($value)) {
            $value = json_encode($value);
        } elseif (is_bool($value)) {
            $value = $value ? '1' : '0';
        }

        $setting->update(['value' => $value]);

        // Clear cache
        Cache::forget("setting.{$key}");

        return true;
    }

    /**
     * Get all settings grouped
     */
    public static function allGrouped(): array
    {
        return self::all()->groupBy('group')->toArray();
    }

    /**
     * Get settings by group
     */
    public static function byGroup(string $group)
    {
        return self::where('group', $group)->get();
    }

    /**
     * Get group label in Arabic
     */
    public static function getGroupLabel(string $group): string
    {
        return match ($group) {
            'general' => 'الإعدادات العامة',
            'academic' => 'الإعدادات الأكاديمية',
            'attendance' => 'إعدادات الحضور',
            'support' => 'إعدادات الدعم والمساعدة',
            'stars' => 'إعدادات تحويل النجوم',
            'access' => 'إعدادات دخول الموقع',
            'owner' => 'إعدادات المالك',
            default => $group
        };
    }
}
