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
        Schema::create('mock_evaluations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('checklist_id')->constrained('evaluation_checklists')->cascadeOnDelete();
            $table->decimal('percentage', 5, 2)->default(0);
            $table->string('grade')->nullable(); // excellent, vgood, good, pass, fail
            $table->integer('time_taken')->default(0); // Time taken in seconds
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('mock_evaluations');
    }
};
