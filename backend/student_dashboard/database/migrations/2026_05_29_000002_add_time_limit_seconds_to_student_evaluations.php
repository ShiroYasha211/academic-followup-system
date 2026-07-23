<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('student_evaluations', function (Blueprint $table) {
            if (!Schema::hasColumn('student_evaluations', 'time_limit_seconds')) {
                $table->integer('time_limit_seconds')
                    ->nullable()
                    ->after('timer_type');
            }
        });
    }

    public function down(): void
    {
        Schema::table('student_evaluations', function (Blueprint $table) {
            if (Schema::hasColumn('student_evaluations', 'time_limit_seconds')) {
                $table->dropColumn('time_limit_seconds');
            }
        });
    }
};
