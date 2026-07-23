<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Setting;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class SettingController extends AdminApiController
{
    public function index(Request $request)
    {
        $settings = Setting::query()
            ->when(!$request->user()?->isSystemOwner(), fn ($query) => $query->where('group', '!=', 'owner'))
            ->get()
            ->groupBy('group');

        return $this->success($settings);
    }

    public function update(Request $request)
    {
        if ($request->has('owner_graduation_presentation_mode') && !$request->user()?->isSystemOwner()) {
            abort(403);
        }

        if ($request->has('owner_default_university_id') && !$request->user()?->isSystemOwner()) {
            abort(403);
        }

        if ($request->has('owner_default_university_id')) {
            $request->validate([
                'owner_default_university_id' => ['nullable', 'integer', 'exists:universities,id'],
            ]);
        }

        if ($request->hasAny([
            'student_star_gifting_enabled',
            'student_star_gift_limit',
            'student_star_gift_period',
            'student_star_gift_custom_days',
            'student_star_gift_once_per_recipient',
        ])) {
            $request->validate([
                'student_star_gifting_enabled' => ['sometimes', 'boolean'],
                'student_star_gift_limit' => ['sometimes', 'integer', 'min:1', 'max:1000000'],
                'student_star_gift_period' => ['sometimes', 'in:daily,weekly,monthly,custom'],
                'student_star_gift_custom_days' => ['sometimes', 'integer', 'min:1', 'max:365'],
                'student_star_gift_once_per_recipient' => ['sometimes', 'boolean'],
            ]);
        }

        $settings = Setting::query()
            ->when(!$request->user()?->isSystemOwner(), fn ($query) => $query->where('group', '!=', 'owner'))
            ->get();
        $updated = 0;

        foreach ($settings as $setting) {
            $key = $setting->key;

            // Handle file uploads (Logo/Favicon)
            if ($request->hasFile($key)) {
                $path = $request->file($key)->store('settings', 'public');
                $setting->update(['value' => $path]);
                Cache::forget("setting.{$key}");
                $updated++;
                continue;
            }

            if ($request->has($key)) {
                $value = $setting->type === 'boolean'
                    ? ($request->boolean($key) ? '1' : '0')
                    : $request->input($key);

                if ($setting->value !== $value) {
                    $setting->update(['value' => $value]);
                    Cache::forget("setting.{$key}");
                    $updated++;
                }
            }
        }

        if ($updated > 0) {
            ActivityLog::log('update', 'Setting', null, null, "تحديث {$updated} إعداد عبر الـ API");
        }

        return $this->success(
            Setting::query()
                ->when(!$request->user()?->isSystemOwner(), fn ($query) => $query->where('group', '!=', 'owner'))
                ->get()
                ->groupBy('group'),
            "تم تحديث {$updated} إعداد بنجاح"
        );
    }
}
