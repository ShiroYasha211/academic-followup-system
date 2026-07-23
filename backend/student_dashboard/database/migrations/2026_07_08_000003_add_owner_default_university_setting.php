<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('settings')->updateOrInsert(
            ['key' => 'owner_default_university_id'],
            [
                'value' => null,
                'type' => 'number',
                'group' => 'owner',
                'label' => 'الجامعة الافتراضية للعرض',
                'description' => 'الجامعة التي تُستخدم تلقائيًا عند إنشاء كلية جديدة في وضع عرض مشروع التخرج.',
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );

        Cache::forget('setting.owner_default_university_id');
    }

    public function down(): void
    {
        DB::table('settings')
            ->where('key', 'owner_default_university_id')
            ->delete();

        Cache::forget('setting.owner_default_university_id');
    }
};
