<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('desktop_pairing_codes', function (Blueprint $table) {
            $table->foreignId('subject_id')->nullable()->after('workspace')->constrained('subjects')->nullOnDelete();
            $table->date('attendance_date')->nullable()->after('subject_id');
            $table->string('session_title')->nullable()->after('attendance_date');
            $table->string('lecture_number', 50)->nullable()->after('session_title');
        });
    }

    public function down(): void
    {
        Schema::table('desktop_pairing_codes', function (Blueprint $table) {
            $table->dropConstrainedForeignId('subject_id');
            $table->dropColumn(['attendance_date', 'session_title', 'lecture_number']);
        });
    }
};
