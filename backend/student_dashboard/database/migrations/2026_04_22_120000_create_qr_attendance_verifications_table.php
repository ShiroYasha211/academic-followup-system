<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('qr_attendance_verifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('qr_attendance_session_id')->constrained()->cascadeOnDelete();
            $table->foreignId('student_id')->constrained('users')->cascadeOnDelete();
            $table->enum('verification_type', ['missing_scan', 'sample_check']);
            $table->enum('verification_status', ['pending', 'confirmed_present', 'confirmed_absent'])->default('pending');
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->unique(['qr_attendance_session_id', 'student_id', 'verification_type'], 'qr_verifications_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('qr_attendance_verifications');
    }
};
