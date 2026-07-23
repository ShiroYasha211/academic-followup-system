<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('quizzes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->enum('creator_type', ['doctor', 'admin'])->default('doctor');
            $table->foreignId('subject_id')->nullable()->constrained()->nullOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->integer('time_limit_minutes')->nullable();
            $table->boolean('shuffle_questions')->default(false);
            $table->boolean('shuffle_options')->default(false);
            $table->boolean('show_correct_answers')->default(false);
            $table->boolean('show_correction_notes')->default(true);
            $table->enum('results_visibility', ['hidden', 'individual', 'public'])->default('hidden');
            $table->boolean('is_competition')->default(false);
            $table->timestamp('scheduled_at')->nullable();
            $table->timestamp('closes_at')->nullable();
            $table->enum('status', ['draft', 'scheduled', 'published', 'closed'])->default('draft');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('quizzes');
    }
};
