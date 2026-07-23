<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('flashcard_packs', function (Blueprint $table) {
            $table->string('schedule_mode', 20)->default('daily')->after('repeat_cycle');
            $table->json('schedule_weekdays')->nullable()->after('schedule_mode');
            $table->time('active_from_time')->nullable()->after('schedule_weekdays');
            $table->time('active_to_time')->nullable()->after('active_from_time');
            $table->unsignedTinyInteger('daily_card_limit')->default(5)->after('active_to_time');
            $table->string('pack_priority', 20)->default('medium')->after('daily_card_limit');
            $table->boolean('smart_review_enabled')->default(true)->after('pack_priority');
            $table->unsignedSmallInteger('smart_review_frequency_minutes')->default(30)->after('smart_review_enabled');
            $table->string('restart_mode', 20)->default('none')->after('smart_review_frequency_minutes');
        });

        DB::table('flashcard_packs')->update([
            'schedule_mode' => DB::raw("CASE repeat_cycle WHEN 'weekly' THEN 'weekly' WHEN 'monthly' THEN 'monthly' ELSE 'daily' END"),
            'daily_card_limit' => DB::raw('daily_notification_count'),
            'smart_review_enabled' => DB::raw('notifications_enabled'),
        ]);
    }

    public function down(): void
    {
        Schema::table('flashcard_packs', function (Blueprint $table) {
            $table->dropColumn([
                'schedule_mode',
                'schedule_weekdays',
                'active_from_time',
                'active_to_time',
                'daily_card_limit',
                'pack_priority',
                'smart_review_enabled',
                'smart_review_frequency_minutes',
                'restart_mode',
            ]);
        });
    }
};
