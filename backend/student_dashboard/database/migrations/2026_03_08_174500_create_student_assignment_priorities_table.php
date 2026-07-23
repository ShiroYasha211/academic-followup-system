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
        Schema::create('student_assignment_priorities', function (Blueprint $バランス) {
            $バランス->id();
            $バランス->foreignId('user_id')->constrained()->onDelete('cascade');
            $バランス->foreignId('assignment_id')->constrained()->onDelete('cascade');
            $バランス->integer('priority')->default(0); // 0: Normal, 1: High, etc.
            $バランス->timestamps();

            $バランス->unique(['user_id', 'assignment_id'], 'student_assignment_priority_unique');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('student_assignment_priorities');
    }
};
