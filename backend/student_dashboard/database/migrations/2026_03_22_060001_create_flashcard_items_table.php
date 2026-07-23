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
        Schema::create('flashcard_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pack_id')->constrained('flashcard_packs')->cascadeOnDelete();

            // Core content (Column A & Column B from Excel)
            $table->text('front_content');
            $table->text('back_content')->nullable();

            // MCQ options
            $table->json('options')->nullable();
            $table->unsignedTinyInteger('correct_option')->nullable();

            // Priority & ordering
            $table->enum('priority', ['normal', 'high', 'critical'])->default('normal');
            $table->unsignedInteger('sort_order')->default(0);

            $table->timestamps();

            $table->index(['pack_id', 'priority']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('flashcard_items');
    }
};
