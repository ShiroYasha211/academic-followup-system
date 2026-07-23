<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use App\Models\ActivityLog;
use Illuminate\Http\Request;

class SettingController extends Controller
{
    /**
     * عرض صفحة الإعدادات
     */
    public function index(Request $request)
    {
        $settings = Setting::query()
            ->when(!$request->user()?->isSystemOwner(), fn ($query) => $query->where('group', '!=', 'owner'))
            ->get()
            ->groupBy('group');

        return view('admin.settings.index', compact('settings'));
    }

    /**
     * تحديث الإعدادات
     */
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
                'student_star_gifting_enabled' => ['required', 'boolean'],
                'student_star_gift_limit' => ['required', 'integer', 'min:1', 'max:1000000'],
                'student_star_gift_period' => ['required', 'in:daily,weekly,monthly,custom'],
                'student_star_gift_custom_days' => [
                    'required_if:student_star_gift_period,custom',
                    'nullable',
                    'integer',
                    'min:1',
                    'max:365',
                ],
                'student_star_gift_once_per_recipient' => ['required', 'boolean'],
            ]);
        }

        if ($request->hasAny([
            'web_access_enabled',
            'web_access_closed_message',
        ])) {
            $request->validate([
                'web_access_enabled' => ['required', 'boolean'],
                'web_access_closed_message' => ['required', 'string', 'max:500'],
            ]);
        }

        $updated = 0;

        foreach ($request->all() as $key => $value) {
            // Handle file uploads
            if ($request->hasFile($key)) {
                $setting = Setting::where('key', $key)->first();
                if ($setting) {
                    $oldValue = $setting->value;
                    $path = $request->file($key)->store('settings', 'public');
                    $setting->update(['value' => $path]);
                    
                    // Clear cache
                    \Cache::forget("setting.{$key}");
                    $updated++;
                    continue;
                }
            }

            $setting = Setting::where('key', $key)->first();

            if ($setting) {
                $oldValue = $setting->value;

                // Handle checkbox (boolean) values
                if ($setting->type === 'boolean') {
                    $value = $request->boolean($key) ? '1' : '0';
                }

                if ($oldValue !== $value) {
                    $setting->update(['value' => $value]);

                    // Clear cache
                    \Cache::forget("setting.{$key}");

                    $updated++;
                }
            }
        }

        // Log activity
        if ($updated > 0) {
            ActivityLog::log(
                'update',
                'Settings',
                null,
                null,
                "تحديث {$updated} إعداد في النظام"
            );
        }

        return back()->with(
            'success',
            $updated > 0
                ? "تم تحديث {$updated} إعداد بنجاح."
                : 'لم يتم تغيير أي إعدادات.'
        );
    }
}
