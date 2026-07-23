<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('daily_log_activities', function (Blueprint $table) {
            $table->id();
            $table->foreignId('daily_log_id')->constrained('student_daily_logs')->onDelete('cascade');
            $table->enum('activity_type', ['history_taking', 'clinical_examination', 'round']);
            $table->foreignId('body_system_id')->nullable()->constrained('body_systems')->onDelete('set null');
            $table->string('case_name')->nullable(); // اسم الحالة في المرور
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index('daily_log_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('daily_log_activities');
    }
};
