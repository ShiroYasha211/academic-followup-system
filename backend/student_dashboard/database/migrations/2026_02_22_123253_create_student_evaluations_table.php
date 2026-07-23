<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('student_evaluations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('doctor_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('checklist_id')->constrained('evaluation_checklists')->onDelete('cascade');
            $table->foreignId('clinical_case_id')->nullable()->constrained('clinical_cases')->onDelete('set null');
            $table->integer('total_score')->default(0);
            $table->integer('max_score')->default(100);
            $table->decimal('percentage', 5, 2)->default(0);
            $table->enum('grade', ['excellent', 'good', 'acceptable', 'weak', 'fail'])->nullable();
            $table->integer('time_taken_seconds')->nullable();  // actual time the student took
            $table->text('doctor_feedback')->nullable();
            $table->timestamps();

            $table->index(['student_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('student_evaluations');
    }
};
