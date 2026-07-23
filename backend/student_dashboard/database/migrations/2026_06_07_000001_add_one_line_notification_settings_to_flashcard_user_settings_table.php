<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('flashcard_user_settings', function (Blueprint $table) {
            $table->boolean('one_line_notifications_enabled')->default(true)->after('prompt_mode');
            $table->unsignedTinyInteger('one_line_daily_limit')->default(5)->after('one_line_notifications_enabled');
            $table->unsignedSmallInteger('one_line_frequency_minutes')->default(30)->after('one_line_daily_limit');
            $table->time('one_line_active_from_time')->nullable()->after('one_line_frequency_minutes');
            $table->time('one_line_active_to_time')->nullable()->after('one_line_active_from_time');
            $table->time('one_line_quiet_start')->nullable()->after('one_line_active_to_time');
            $table->time('one_line_quiet_end')->nullable()->after('one_line_quiet_start');
        });
    }

    public function down(): void
    {
        Schema::table('flashcard_user_settings', function (Blueprint $table) {
            $table->dropColumn([
                'one_line_notifications_enabled',
                'one_line_daily_limit',
                'one_line_frequency_minutes',
                'one_line_active_from_time',
                'one_line_active_to_time',
                'one_line_quiet_start',
                'one_line_quiet_end',
            ]);
        });
    }
};
