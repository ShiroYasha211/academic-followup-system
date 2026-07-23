<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('daily_log_activities', function (Blueprint $table) {
            if (! Schema::hasColumn('daily_log_activities', 'review_status')) {
                $table->string('review_status', 20)->default('pending')->after('is_confirmed');
            }

            if (! Schema::hasColumn('daily_log_activities', 'review_notes')) {
                $table->text('review_notes')->nullable()->after('diagnosis');
            }
        });
    }

    public function down(): void
    {
        Schema::table('daily_log_activities', function (Blueprint $table) {
            if (Schema::hasColumn('daily_log_activities', 'review_notes')) {
                $table->dropColumn('review_notes');
            }

            if (Schema::hasColumn('daily_log_activities', 'review_status')) {
                $table->dropColumn('review_status');
            }
        });
    }
};
