<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('delegate_grade_delegations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')->constrained('grade_categories')->cascadeOnDelete();
            $table->foreignId('delegated_by_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('helper_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('delegation_type')->default('full');
            $table->string('title');
            $table->text('notes')->nullable();
            $table->timestamp('due_at')->nullable();
            $table->boolean('is_revoked')->default(false);
            $table->timestamp('revoked_at')->nullable();
            $table->timestamps();
        });

        Schema::create('delegate_grade_delegation_students', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delegation_id')->constrained('delegate_grade_delegations')->cascadeOnDelete();
            $table->foreignId('student_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['delegation_id', 'student_id'], 'delegate_grade_delegation_students_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('delegate_grade_delegation_students');
        Schema::dropIfExists('delegate_grade_delegations');
    }
};
