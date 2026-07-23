<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * تشغيل الهجرة – إنشاء جدول التخصصات (Majors).
     *
     * كل تخصص ينتمي إلى كلية (foreign key college_id).
     * الأعمدة:
     * - id          : المفتاح الأساسي
     * - college_id  : مرجع الكلية (cascade on delete)
     * - name        : اسم التخصص
     * - created_at / updated_at
     */
    public function up(): void
    {
        Schema::create('majors', function (Blueprint $table) {
            $table->id();
            $table->foreignId('college_id')
                ->constrained('colleges')
                ->onDelete('cascade');   // حذف الكلية يحذف تخصصاتها
            $table->string('name');
            $table->timestamps();

            // اسم التخصص يجب أن يكون فريدًا داخل الكلية
            $table->unique(['college_id', 'name']);
        });
    }

    /**
     * إلغاء الهجرة – حذف جدول التخصصات.
     */
    public function down(): void
    {
        Schema::dropIfExists('majors');
    }
};
