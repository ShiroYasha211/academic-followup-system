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
        Schema::create('excuses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('attendance_id')->constrained('attendances')->cascadeOnDelete();
            $table->foreignId('student_id')->constrained('users')->cascadeOnDelete();

            $table->text('reason'); // Explanation from student
            $table->string('attachment')->nullable(); // File path

            // Status of the excuse
            $table->enum('status', ['pending', 'accepted', 'rejected'])->default('pending');

            $table->text('doctor_comment')->nullable(); // Reason for rejection or notes

            $table->timestamps();

            // Ensure one excuse per attendance record
            $table->unique('attendance_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('excuses');
    }
};
