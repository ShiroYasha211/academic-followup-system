<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('study_session_columns', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_schedule_item_id')->constrained('student_schedule_items')->cascadeOnDelete();
            $table->string('name', 80);
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();

            $table->index(['student_schedule_item_id', 'sort_order']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('study_session_columns');
    }
};
