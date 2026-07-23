<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('assignment_delegate_permissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('doctor_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('delegate_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('subject_id')->constrained('subjects')->cascadeOnDelete();
            $table->boolean('can_create')->default(false);
            $table->boolean('can_edit_own')->default(false);
            $table->boolean('can_delete_own')->default(false);
            $table->boolean('can_edit_doctor_assignments')->default(false);
            $table->boolean('can_delete_doctor_assignments')->default(false);
            $table->timestamps();

            $table->unique(['doctor_id', 'delegate_id', 'subject_id'], 'assignment_delegate_permissions_unique');
            $table->index(['delegate_id', 'subject_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('assignment_delegate_permissions');
    }
};
