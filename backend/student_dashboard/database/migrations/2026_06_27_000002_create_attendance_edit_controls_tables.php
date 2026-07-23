<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('attendance_edit_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('requester_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('subject_id')->nullable()->constrained('subjects')->nullOnDelete();
            $table->foreignId('lecture_id')->nullable()->constrained('lectures')->nullOnDelete();
            $table->foreignId('qr_attendance_session_id')->nullable()->constrained('qr_attendance_sessions')->nullOnDelete();
            $table->date('date')->nullable();
            $table->string('title')->nullable();
            $table->text('reason');
            $table->enum('status', ['pending', 'approved', 'rejected', 'cancelled'])->default('pending');
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->text('admin_note')->nullable();
            $table->timestamp('granted_until')->nullable();
            $table->timestamps();

            $table->index(['status', 'created_at']);
            $table->index(['requester_id', 'status']);
            $table->index(['subject_id', 'date']);
            $table->index('lecture_id');
            $table->index('qr_attendance_session_id');
        });

        Schema::create('attendance_edit_permissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('granted_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('attendance_edit_request_id')->nullable()->constrained('attendance_edit_requests')->nullOnDelete();
            $table->foreignId('subject_id')->nullable()->constrained('subjects')->nullOnDelete();
            $table->foreignId('lecture_id')->nullable()->constrained('lectures')->nullOnDelete();
            $table->foreignId('qr_attendance_session_id')->nullable()->constrained('qr_attendance_sessions')->nullOnDelete();
            $table->date('date')->nullable();
            $table->text('reason')->nullable();
            $table->timestamp('expires_at');
            $table->timestamp('revoked_at')->nullable();
            $table->foreignId('revoked_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['user_id', 'expires_at']);
            $table->index(['user_id', 'revoked_at']);
            $table->index(['subject_id', 'date']);
            $table->index('lecture_id');
            $table->index('qr_attendance_session_id');
        });

        Schema::create('attendance_change_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('attendance_id')->constrained('attendances')->cascadeOnDelete();
            $table->foreignId('changed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('attendance_edit_permission_id')->nullable()->constrained('attendance_edit_permissions')->nullOnDelete();
            $table->foreignId('attendance_edit_request_id')->nullable()->constrained('attendance_edit_requests')->nullOnDelete();
            $table->foreignId('student_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('subject_id')->nullable()->constrained('subjects')->nullOnDelete();
            $table->foreignId('lecture_id')->nullable()->constrained('lectures')->nullOnDelete();
            $table->foreignId('qr_attendance_session_id')->nullable()->constrained('qr_attendance_sessions')->nullOnDelete();
            $table->date('date')->nullable();
            $table->string('old_status')->nullable();
            $table->string('new_status')->nullable();
            $table->json('changes')->nullable();
            $table->timestamps();

            $table->index(['attendance_id', 'created_at']);
            $table->index(['changed_by', 'created_at']);
            $table->index(['subject_id', 'date']);
            $table->index('lecture_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('attendance_change_logs');
        Schema::dropIfExists('attendance_edit_permissions');
        Schema::dropIfExists('attendance_edit_requests');
    }
};
