<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->foreignId('qr_attendance_session_id')
                ->nullable()
                ->after('attendance_method')
                ->constrained('qr_attendance_sessions')
                ->nullOnDelete();

            $table->index(['qr_attendance_session_id', 'student_id']);
        });
    }

    public function down(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->dropIndex(['qr_attendance_session_id', 'student_id']);
            $table->dropConstrainedForeignId('qr_attendance_session_id');
        });
    }
};
