<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * تشغيل الهجرة – إنشاء جدول الكليات.
     *
     * كل كلية تنتمي إلى جامعة (foreign key university_id).
     * الأعمدة:
     * - id            : المفتاح الأساسي
     * - university_id : مرجع الجامعة (cascade on delete)
     * - name          : اسم الكلية (فريد داخل الجامعة)
     * - created_at / updated_at
     */
    public function up(): void
    {
        Schema::create('colleges', function (Blueprint $table) {
            $table->id();
            $table->foreignId('university_id')
                ->constrained('universities')
                ->onDelete('cascade');   // حذف الجامعة يحذف كلياتها
            $table->string('name');
            $table->timestamps();

            // اسم الكلية يجب أن يكون فريدًا داخل الجامعة
            $table->unique(['university_id', 'name']);
        });
    }

    /**
     * إلغاء الهجرة – حذف جدول الكليات.
     */
    public function down(): void
    {
        Schema::dropIfExists('colleges');
    }
};
