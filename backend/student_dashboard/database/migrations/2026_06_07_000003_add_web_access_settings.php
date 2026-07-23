<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $now = now();

        $settings = [
            [
                'key' => 'web_access_enabled',
                'value' => '1',
                'type' => 'boolean',
                'group' => 'access',
                'label' => 'السماح بدخول الموقع لغير الأدمن',
                'description' => 'عند تعطيله لا يستطيع الطلاب أو الدكاترة أو المندوبون أو مسؤولو الكليات تسجيل الدخول إلى الموقع، بينما يبقى دخول الأدمن الرئيسي متاحًا.',
            ],
            [
                'key' => 'web_access_closed_message',
                'value' => 'تم إيقاف دخول الموقع مؤقتًا. يرجى التواصل مع إدارة النظام.',
                'type' => 'text',
                'group' => 'access',
                'label' => 'رسالة إغلاق دخول الموقع',
                'description' => 'تظهر هذه الرسالة لأي مستخدم غير الأدمن عند محاولة دخول الموقع أثناء الإغلاق.',
            ],
        ];

        foreach ($settings as $setting) {
            DB::table('settings')->updateOrInsert(
                ['key' => $setting['key']],
                array_merge($setting, ['created_at' => $now, 'updated_at' => $now]),
            );
        }
    }

    public function down(): void
    {
        DB::table('settings')->whereIn('key', [
            'web_access_enabled',
            'web_access_closed_message',
        ])->delete();
    }
};
