<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('star_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('granted_by')->nullable()->constrained('users')->nullOnDelete();
            $table->enum('type', [
                'quiz_reward',       // مكافأة من كويز
                'doctor_gift',       // هدية من الدكتور
                'admin_grant',       // منحة من الأدمن
                'competition_prize', // جائزة مسابقة
                'attendance_bonus',  // مكافأة حضور
                'honor_board',       // لوحة الشرف
                'penalty',           // خصم / عقوبة
                'gifted',            // هدية لطالب آخر
                'received_gift',     // استلام هدية
            ]);
            $table->integer('amount');
            $table->integer('balance_after');
            $table->string('description')->nullable();
            $table->nullableMorphs('reference'); // reference to quiz_attempt, etc.
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('star_transactions');
    }
};
