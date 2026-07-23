<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('student_device_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('users')->cascadeOnDelete();
            $table->string('current_device_id')->nullable();
            $table->string('requested_device_id')->nullable();
            $table->string('requested_device_name')->nullable();
            $table->string('platform', 50)->nullable();
            $table->string('app_version', 50)->nullable();
            $table->text('reason');
            $table->string('status', 20)->default('pending');
            $table->text('admin_note')->nullable();
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();

            $table->index(['student_id', 'status']);
            $table->index('status');
            $table->index('requested_device_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('student_device_requests');
    }
};
