<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('quiz_models', function (Blueprint $table) {
            $table->dropUnique('quiz_models_access_code_unique');
            $table->unique(['quiz_id', 'access_code'], 'quiz_models_quiz_id_access_code_unique');
        });
    }

    public function down(): void
    {
        Schema::table('quiz_models', function (Blueprint $table) {
            $table->dropUnique('quiz_models_quiz_id_access_code_unique');
            $table->unique('access_code', 'quiz_models_access_code_unique');
        });
    }
};
