<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * تشغيل الهجرة – إنشاء جدول المستويات (Levels).
     *
     * كل مستوى ينتمي إلى تخصص (foreign key major_id).
     * الأعمدة:
     * - id          : المفتاح الأساسي
     * - major_id    : مرجع التخصص (cascade on delete)
     * - name        : اسم المستوى (مثلاً "Year 1" أو "Level 1")
     * - created_at / updated_at
     */
    public function up(): void
    {
        Schema::create('levels', function (Blueprint $table) {
            $table->id();
            $table->foreignId('major_id')
                ->constrained('majors')
                ->onDelete('cascade');   // حذف التخصص يحذف مستوياته
            $table->string('name');
            $table->timestamps();

            // اسم المستوى يجب أن يكون فريدًا داخل التخصص
            $table->unique(['major_id', 'name']);
        });
    }

    /**
     * إلغاء الهجرة – حذف جدول المستويات.
     */
    public function down(): void
    {
        Schema::dropIfExists('levels');
    }
};
