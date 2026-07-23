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
        Schema::table('student_schedule_items', function (Blueprint $table) {
            $table->string('priority', 10)->default('medium')->after('note'); // high, medium, low
            $table->string('status', 20)->default('pending')->after('priority'); // pending, in_progress, completed, overdue
            $table->string('item_type', 20)->default('study')->after('status'); // study, reminder, resource
            $table->string('category_tag')->nullable()->after('item_type'); // "قراءة لاحقاً", "مهم للاختبار", etc.
            $table->string('repeat_type', 10)->default('none')->after('category_tag'); // none, daily, weekly
            $table->timestamp('reminder_at')->nullable()->after('repeat_type');
            $table->boolean('reminder_sent')->default(false)->after('reminder_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('student_schedule_items', function (Blueprint $table) {
            $table->dropColumn([
                'priority',
                'status',
                'item_type',
                'category_tag',
                'repeat_type',
                'reminder_at',
                'reminder_sent',
            ]);
        });
    }
};
