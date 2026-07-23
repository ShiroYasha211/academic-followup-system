<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('quizzes', 'timer_mode')) {
            Schema::table('quizzes', function (Blueprint $table) {
                $table->enum('timer_mode', ['quiz', 'per_question'])->default('quiz')->after('time_limit_minutes');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('quizzes', 'timer_mode')) {
            Schema::table('quizzes', function (Blueprint $table) {
                $table->dropColumn('timer_mode');
            });
        }
    }
};
