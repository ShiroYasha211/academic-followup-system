<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('settings')->updateOrInsert(
            ['key' => 'student_qr_scan_free_enabled'],
            [
                'value' => '1',
                'type' => 'boolean',
                'group' => 'attendance',
                'label' => 'فتح تصوير QR للطلاب مجانًا',
                'description' => 'عند تفعيله يستطيع الطالب تصوير QR الحضور بدون اشتراك. عند تعطيله يحتاج الطالب إلى اشتراك نشط لاستخدام تصوير QR.',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        );
    }

    public function down(): void
    {
        DB::table('settings')
            ->where('key', 'student_qr_scan_free_enabled')
            ->delete();
    }
};
