<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $now = now();
        $settings = [
            [
                'key' => 'student_star_gifting_enabled',
                'value' => '1',
                'type' => 'boolean',
                'group' => 'stars',
                'label' => 'السماح بتحويل النجوم بين الطلاب',
                'description' => 'إيقاف هذا الخيار يمنع جميع تحويلات النجوم بين الطلاب.',
            ],
            [
                'key' => 'student_star_gift_limit',
                'value' => '20',
                'type' => 'number',
                'group' => 'stars',
                'label' => 'الحد الأقصى للتحويل',
                'description' => 'إجمالي عدد النجوم التي يستطيع الطالب تحويلها خلال الفترة المحددة.',
            ],
            [
                'key' => 'student_star_gift_period',
                'value' => 'weekly',
                'type' => 'text',
                'group' => 'stars',
                'label' => 'فترة احتساب الحد',
                'description' => 'تحدد متى يتجدد الحد المسموح للطالب.',
            ],
            [
                'key' => 'student_star_gift_custom_days',
                'value' => '7',
                'type' => 'number',
                'group' => 'stars',
                'label' => 'عدد أيام الفترة المخصصة',
                'description' => 'يستخدم فقط عند اختيار فترة مخصصة.',
            ],
            [
                'key' => 'student_star_gift_once_per_recipient',
                'value' => '0',
                'type' => 'boolean',
                'group' => 'stars',
                'label' => 'تحويل واحد لنفس الطالب خلال الفترة',
                'description' => 'عند تفعيله لا يستطيع الطالب الإرسال إلى نفس المستلم أكثر من مرة خلال الفترة.',
            ],
        ];

        foreach ($settings as $setting) {
            DB::table('settings')->updateOrInsert(
                ['key' => $setting['key']],
                array_merge($setting, ['created_at' => $now, 'updated_at' => $now]),
            );
        }

        Schema::table('star_transactions', function (Blueprint $table) {
            $table->index(
                ['user_id', 'type', 'created_at'],
                'star_transactions_user_type_created_index',
            );
        });
    }

    public function down(): void
    {
        Schema::table('star_transactions', function (Blueprint $table) {
            $table->dropIndex('star_transactions_user_type_created_index');
        });

        DB::table('settings')->whereIn('key', [
            'student_star_gifting_enabled',
            'student_star_gift_limit',
            'student_star_gift_period',
            'student_star_gift_custom_days',
            'student_star_gift_once_per_recipient',
        ])->delete();
    }
};
