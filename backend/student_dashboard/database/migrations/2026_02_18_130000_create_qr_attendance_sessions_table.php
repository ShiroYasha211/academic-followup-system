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
        Schema::create('qr_attendance_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('subject_id')->constrained()->cascadeOnDelete();
            $table->foreignId('delegate_id')->constrained('users')->cascadeOnDelete();
            $table->date('date');
            $table->string('title');                          // Lecture title
            $table->string('lecture_number')->nullable();
            $table->string('current_token', 64)->unique();    // Active rotating token
            $table->timestamp('token_expires_at');             // Token expiry timestamp
            $table->enum('status', ['active', 'finalized'])->default('active');
            $table->timestamps();

            // One active session per subject per day
            $table->unique(['subject_id', 'date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('qr_attendance_sessions');
    }
};
