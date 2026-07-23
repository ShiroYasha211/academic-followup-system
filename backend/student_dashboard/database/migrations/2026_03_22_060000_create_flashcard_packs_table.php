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
        Schema::create('flashcard_packs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('color', 7)->default('#4f46e5');
            $table->string('icon')->nullable();

            // Display settings
            $table->enum('display_mode', ['flash_card', 'one_line', 'qa', 'mcq'])->default('flash_card');

            // Notification settings
            $table->boolean('notifications_enabled')->default(true);
            $table->unsignedTinyInteger('daily_notification_count')->default(5);
            $table->enum('repeat_cycle', ['daily', 'weekly', 'monthly'])->default('daily');
            $table->time('quiet_start')->nullable();
            $table->time('quiet_end')->nullable();

            // Status
            $table->boolean('is_active')->default(true);
            $table->boolean('is_public')->default(false);
            $table->foreignId('source_pack_id')->nullable()->constrained('flashcard_packs')->nullOnDelete();

            $table->timestamps();

            $table->index(['user_id', 'is_active']);
            $table->index('is_public');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('flashcard_packs');
    }
};
