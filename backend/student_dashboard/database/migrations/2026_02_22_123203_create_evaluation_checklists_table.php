<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('evaluation_checklists', function (Blueprint $table) {
            $table->id();
            $table->string('title');                    // e.g. "أخذ القصة المرضية - الجهاز التنفسي"
            $table->text('description')->nullable();
            $table->foreignId('doctor_id')->constrained('users')->onDelete('cascade');
            $table->enum('skill_type', ['history_taking', 'clinical_examination', 'procedure', 'communication']);
            $table->integer('time_limit_minutes')->default(15); // OSCE timer
            $table->integer('total_marks')->default(100);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('evaluation_checklists');
    }
};
