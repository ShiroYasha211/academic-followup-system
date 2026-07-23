<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('quizzes', function (Blueprint $col) {
            $col->boolean('notify_students')->default(false)->after('status');
            $col->boolean('show_countdown')->default(false)->after('notify_students');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('quizzes', function (Blueprint $col) {
            $col->dropColumn(['notify_students', 'show_countdown']);
        });
    }
};
