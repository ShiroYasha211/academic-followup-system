<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('student_daily_logs', 'qr_generated_at')) {
            Schema::table('student_daily_logs', function (Blueprint $table) {
                $table->timestamp('qr_generated_at')->nullable()->after('qr_token');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('student_daily_logs', 'qr_generated_at')) {
            Schema::table('student_daily_logs', function (Blueprint $table) {
                $table->dropColumn('qr_generated_at');
            });
        }
    }
};
