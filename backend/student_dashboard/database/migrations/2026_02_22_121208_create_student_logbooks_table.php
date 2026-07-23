<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('student_logbooks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('clinical_case_id')->constrained('clinical_cases')->onDelete('cascade');
            $table->foreignId('case_assignment_id')->nullable()->constrained('case_assignments')->onDelete('set null');
            $table->foreignId('confirmed_by')->nullable()->constrained('users')->onDelete('set null');
            $table->enum('task_type', ['history_taking', 'clinical_examination', 'follow_up']);
            $table->text('notes')->nullable();
            $table->string('qr_token', 64)->unique();
            $table->enum('status', ['pending', 'confirmed', 'rejected'])->default('pending');
            $table->timestamp('confirmed_at')->nullable();
            $table->timestamps();

            $table->index(['student_id', 'status']);
            $table->index('qr_token');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('student_logbooks');
    }
};
