<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('student_schedule_items', 'reminder_at')) {
            DB::statement('ALTER TABLE student_schedule_items MODIFY reminder_at DATETIME NULL');
        }
        if (Schema::hasColumn('student_schedule_items', 'next_reminder_at')) {
            DB::statement('ALTER TABLE student_schedule_items MODIFY next_reminder_at DATETIME NULL');
        }
        if (Schema::hasColumn('student_schedule_items', 'last_reminder_sent_at')) {
            DB::statement('ALTER TABLE student_schedule_items MODIFY last_reminder_sent_at DATETIME NULL');
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('student_schedule_items', 'reminder_at')) {
            DB::statement('ALTER TABLE student_schedule_items MODIFY reminder_at TIMESTAMP NULL');
        }
        if (Schema::hasColumn('student_schedule_items', 'next_reminder_at')) {
            DB::statement('ALTER TABLE student_schedule_items MODIFY next_reminder_at TIMESTAMP NULL');
        }
        if (Schema::hasColumn('student_schedule_items', 'last_reminder_sent_at')) {
            DB::statement('ALTER TABLE student_schedule_items MODIFY last_reminder_sent_at TIMESTAMP NULL');
        }
    }
};
