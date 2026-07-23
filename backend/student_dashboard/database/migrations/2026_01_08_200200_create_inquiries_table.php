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
        Schema::create('inquiries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('subject_id')->constrained()->onDelete('cascade');
            $table->foreignId('delegate_id')->nullable()->constrained('users')->onDelete('set null');
            $table->string('title');
            $table->text('question');
            $table->text('answer')->nullable();
            $table->enum('status', ['pending', 'forwarded', 'answered', 'closed'])->default('pending');
            $table->timestamp('answered_at')->nullable();
            $table->timestamps();

            $table->index(['student_id', 'status']);
            $table->index('subject_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('inquiries');
    }
};
