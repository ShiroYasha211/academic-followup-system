<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * تشغيل الهجرة – إنشاء جدول الجامعات.
     *
     * الأعمدة الأساسية:
     * - id          : المفتاح الأساسي (auto‑increment)
     * - name        : اسم الجامعة (فريد)
     * - code        : رمز مختصر للجامعة (اختياري، مفيد للبحث)
     * - address     : عنوان الجامعة (نص طويل)
     * - created_at / updated_at : timestamps تلقائية
     */
    public function up(): void
    {
        Schema::create('universities', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->string('code')->nullable()->unique();
            $table->text('address')->nullable();
            $table->timestamps();
        });
    }

    /**
     * إلغاء الهجرة – حذف جدول الجامعات.
     */
    public function down(): void
    {
        Schema::dropIfExists('universities');
    }
};
