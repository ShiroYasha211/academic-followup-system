<?php

use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        // Only insert if the setting does not already exist
        if (!\DB::table('settings')->where('key', 'admin_whatsapp_number')->exists()) {
            \DB::table('settings')->insert([
                'key'         => 'admin_whatsapp_number',
                'value'       => '967773965086',
                'type'        => 'text',
                'group'       => 'general',
                'label'       => 'رقم واتساب الإدارة',
                'description' => 'رقم واتساب الإدارة الذي يظهر للطالب عند محاولة تسجيل الدخول من جهاز غير معتمد (مثال: 967773965086)',
                'created_at'  => now(),
                'updated_at'  => now(),
            ]);
        }
    }

    public function down(): void
    {
        \DB::table('settings')->where('key', 'admin_whatsapp_number')->delete();
    }
};
