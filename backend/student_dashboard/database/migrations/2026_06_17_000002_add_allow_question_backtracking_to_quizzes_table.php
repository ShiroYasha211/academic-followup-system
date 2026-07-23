<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('quizzes', 'allow_question_backtracking')) {
            Schema::table('quizzes', function (Blueprint $table) {
                $table->boolean('allow_question_backtracking')
                    ->default(true)
                    ->after('timer_mode');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('quizzes', 'allow_question_backtracking')) {
            Schema::table('quizzes', function (Blueprint $table) {
                $table->dropColumn('allow_question_backtracking');
            });
        }
    }
};
