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
        Schema::create('clinical_cases', function (Blueprint $table) {
            $table->id();
            $table->string('patient_name'); // اسم الحالة / المريض
            $table->integer('age')->nullable(); // عمر المريض
            $table->enum('gender', ['male', 'female'])->nullable(); // جنس المريض

            // العلاقات
            $table->foreignId('training_center_id')->constrained('training_centers')->onDelete('cascade');
            $table->foreignId('clinical_department_id')->constrained('clinical_departments')->onDelete('cascade');
            $table->foreignId('body_system_id')->constrained('body_systems')->onDelete('cascade');
            $table->foreignId('doctor_id')->constrained('users')->onDelete('cascade'); // الدكتور المسؤول عن الحالة

            $table->text('diagnosis_or_description')->nullable(); // التشخيص أو الوصف
            $table->enum('status', ['active', 'discharged', 'transferred'])->default('active'); // حالة المريض

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('clinical_cases');
    }
};
