<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('student_devices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('users')->cascadeOnDelete();
            $table->string('device_id');
            $table->string('device_name')->nullable();
            $table->string('platform', 50)->nullable();
            $table->string('app_version', 50)->nullable();
            $table->string('device_type', 20)->default('primary');
            $table->boolean('is_primary')->default(false);
            $table->boolean('is_active')->default(true);
            $table->foreignId('approved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('last_login_at')->nullable();
            $table->timestamps();

            $table->unique(['student_id', 'device_id'], 'student_devices_student_device_unique');
            $table->index(['student_id', 'is_active']);
            $table->index(['student_id', 'is_primary']);
            $table->index('device_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('student_devices');
    }
};
