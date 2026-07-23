<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('quiz_questions', function (Blueprint $table) {
            $table->unsignedInteger('time_limit_seconds')->nullable()->after('score');
        });

        Schema::table('quiz_answers', function (Blueprint $table) {
            $table->string('answer_status', 20)->default('answered')->after('is_correct');
            $table->index(['attempt_id', 'answer_status']);
        });
    }

    public function down(): void
    {
        Schema::table('quiz_answers', function (Blueprint $table) {
            $table->dropIndex(['attempt_id', 'answer_status']);
            $table->dropColumn('answer_status');
        });

        Schema::table('quiz_questions', function (Blueprint $table) {
            $table->dropColumn('time_limit_seconds');
        });
    }
};
