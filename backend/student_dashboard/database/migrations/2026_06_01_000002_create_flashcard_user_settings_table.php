<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('flashcard_user_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->boolean('smart_review_enabled')->default(true);
            $table->time('active_from_time')->nullable();
            $table->time('active_to_time')->nullable();
            $table->time('quiet_start')->nullable();
            $table->time('quiet_end')->nullable();
            $table->unsignedTinyInteger('daily_card_limit')->default(5);
            $table->unsignedSmallInteger('smart_review_frequency_minutes')->default(30);
            $table->boolean('auto_restart_enabled')->default(false);
            $table->string('prompt_mode', 20)->default('app_and_notification');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('flashcard_user_settings');
    }
};
