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
        Schema::create('case_assignments', function (Blueprint $table) {
            $table->id();

            // العلاقات
            $table->foreignId('student_id')->constrained('users')->onDelete('cascade'); // الطالب المعني
            $table->foreignId('clinical_case_id')->constrained('clinical_cases')->onDelete('cascade'); // المستند له
            $table->foreignId('assigned_by')->constrained('users')->onDelete('cascade'); // من وزع الحالة (الدكتور/المندوب)

            // تفاصيل المهمة
            $table->enum('task_type', ['history_taking', 'clinical_examination', 'follow_up']); // نوع المهمة المطلوبة
            $table->text('instructions')->nullable(); // تعليمات إضافية من الدكتور للطالب

            // حالة الإنجاز المبدئية
            $table->boolean('is_completed')->default(false); // هل أتم المهمة (سيتم تأكيده بمسح الباركود لاحقاً)
            $table->timestamp('completed_at')->nullable();

            $table->timestamps();

            // لمنع التكرار (نفس الطالب ونفس الحالة لنفس المهمة لا يجب تكرارهما)
            $table->unique(['student_id', 'clinical_case_id', 'task_type'], 'student_case_task_unique');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('case_assignments');
    }
};
