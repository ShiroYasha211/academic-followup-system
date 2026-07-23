<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * تشغيل الهجرة – إنشاء جدول الفصول (Terms).
     *
     * كل Term ينتمي إلى مستوى (foreign key level_id).
     * الأعمدة:
     * - id          : المفتاح الأساسي
     * - level_id    : مرجع المستوى (cascade on delete)
     * - name        : اسم الفصل (مثلاً "Fall 2025" أو "Spring 2026")
     * - start_date  : تاريخ بداية الفصل (اختياري)
     * - end_date    : تاريخ نهاية الفصل (اختياري)
     * - created_at / updated_at
     */
    public function up(): void
    {
        Schema::create('terms', function (Blueprint $table) {
            $table->id();
            $table->foreignId('level_id')
                ->constrained('levels')
                ->onDelete('cascade');   // حذف المستوى يحذف فصوله
            $table->string('name');
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->timestamps();

            // اسم الفصل يجب أن يكون فريدًا داخل المستوى
            $table->unique(['level_id', 'name']);
        });
    }

    /**
     * إلغاء الهجرة – حذف جدول الفصول.
     */
    public function down(): void
    {
        Schema::dropIfExists('terms');
    }
};
