<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('settings')->updateOrInsert(
            ['key' => 'owner_graduation_presentation_mode'],
            [
                'value' => '0',
                'type' => 'boolean',
                'group' => 'owner',
                'label' => 'عرض مشروع التخرج',
                'description' => 'إخفاء العناصر غير المطلوبة من القائمة الجانبية عند دخول مالك النظام فقط.',
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );

        Cache::forget('setting.owner_graduation_presentation_mode');
    }

    public function down(): void
    {
        DB::table('settings')
            ->where('key', 'owner_graduation_presentation_mode')
            ->delete();

        Cache::forget('setting.owner_graduation_presentation_mode');
    }
};
