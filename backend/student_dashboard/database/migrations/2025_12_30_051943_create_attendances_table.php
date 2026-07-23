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
        Schema::create('attendances', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('subject_id')->constrained()->cascadeOnDelete();
            // حالة الحضور: present (حاضر), absent (غائب), late (متأخر), excused (معذور)
            $table->enum('status', ['present', 'absent', 'late', 'excused'])->default('absent');
            $table->date('date');

            // من قام بتسجيل الحضور (المندوب أو الدكتور)
            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();

            // منع تكرار تسجيل الحضور لنفس الطالب في نفس المادة في نفس اليوم
            $table->unique(['student_id', 'subject_id', 'date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('attendances');
    }
};
