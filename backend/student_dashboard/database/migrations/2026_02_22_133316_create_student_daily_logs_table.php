<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('student_daily_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('training_center_id')->constrained('training_centers')->onDelete('cascade');
            $table->foreignId('department_id')->constrained('clinical_departments')->onDelete('cascade');
            $table->foreignId('doctor_id')->constrained('users')->onDelete('cascade');

            // Daily summary counts
            $table->integer('history_count')->default(0);       // عدد القصص المرضية
            $table->integer('exam_count')->default(0);          // عدد الفحوصات السريرية
            $table->boolean('did_round')->default(false);       // هل عمل مرور (Round)؟
            $table->text('round_notes')->nullable();            // ملاحظات المرور

            // QR Token for doctor scanning
            $table->string('qr_token', 64)->unique();
            $table->enum('status', ['pending', 'confirmed', 'rejected'])->default('pending');

            // Doctor confirmation
            $table->foreignId('confirmed_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamp('confirmed_at')->nullable();
            $table->text('doctor_notes')->nullable(); // ملاحظات الدكتور عند التأكيد

            // Date tracking
            $table->date('log_date');  // تاريخ اليوم
            $table->time('log_time'); // وقت التسليم

            $table->timestamps();

            $table->index(['student_id', 'log_date']);
            $table->index(['doctor_id', 'log_date']);
            $table->index('qr_token');
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('student_daily_logs');
    }
};
