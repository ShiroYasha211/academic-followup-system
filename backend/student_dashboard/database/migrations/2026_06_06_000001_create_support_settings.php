<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $settings = [
            [
                'key'         => 'support_phone',
                'value'       => '+967 777 000 111',
                'type'        => 'text',
                'group'       => 'support',
                'label'       => 'رقم الهاتف المباشر',
                'description' => 'رقم الهاتف المباشر للدعم الفني المعروض في صفحة المساعدة',
            ],
            [
                'key'         => 'support_whatsapp',
                'value'       => '+967 777 000 222',
                'type'        => 'text',
                'group'       => 'support',
                'label'       => 'رقم واتساب الدعم',
                'description' => 'رقم واتساب الدعم الفني المعروض في صفحة المساعدة',
            ],
            [
                'key'         => 'support_email',
                'value'       => 'support@moeen.tech',
                'type'        => 'text',
                'group'       => 'support',
                'label'       => 'البريد الإلكتروني للدعم',
                'description' => 'البريد الإلكتروني المخصص لاستقبال استفسارات الطلاب',
            ],
            [
                'key'         => 'support_website',
                'value'       => 'moeen.tech',
                'type'        => 'text',
                'group'       => 'support',
                'label'       => 'الموقع الإلكتروني',
                'description' => 'موقع الويب المعروض للطلاب في صفحة المساعدة',
            ],
            [
                'key'         => 'support_instagram',
                'value'       => '@moeen.app',
                'type'        => 'text',
                'group'       => 'support',
                'label'       => 'حساب إنستغرام',
                'description' => 'حساب الإنستغرام المعروض للطلاب في صفحة المساعدة',
            ],
            [
                'key'         => 'support_work_hours',
                'value'       => 'السبت - الخميس | 8:00 ص - 2:00 م',
                'type'        => 'text',
                'group'       => 'support',
                'label'       => 'أوقات العمل',
                'description' => 'أوقات العمل الخاصة بالدعم الفني المعروضة في صفحة المساعدة',
            ],
            [
                'key'         => 'support_notice',
                'value'       => 'عند وجود مشكلة في الحضور أو رفع الملفات، يرجى إرسال اسمك، رقم القيد، وصف دقيق للمشكلة، مع لقطة شاشة توضيحية لضمان سرعة المعالجة.',
                'type'        => 'text',
                'group'       => 'support',
                'label'       => 'ملاحظات هامة للطلاب',
                'description' => 'نص التنبيه أو الملاحظة الهامة التي تظهر للطلاب في أسفل مركز المساعدة',
            ],
        ];

        foreach ($settings as $setting) {
            if (!DB::table('settings')->where('key', $setting['key'])->exists()) {
                DB::table('settings')->insert(array_merge($setting, [
                    'created_at' => now(),
                    'updated_at' => now(),
                ]));
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('settings')->whereIn('key', [
            'support_phone',
            'support_whatsapp',
            'support_email',
            'support_website',
            'support_instagram',
            'support_work_hours',
            'support_notice',
        ])->delete();
    }
};
