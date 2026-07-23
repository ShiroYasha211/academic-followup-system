<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('student_schedule_items', function (Blueprint $table) {
            if (! Schema::hasColumn('student_schedule_items', 'reminder_schedule_type')) {
                $table->string('reminder_schedule_type', 20)->default('none')->after('reminder_sent');
            }
            if (! Schema::hasColumn('student_schedule_items', 'reminder_time')) {
                $table->time('reminder_time')->nullable()->after('reminder_schedule_type');
            }
            if (! Schema::hasColumn('student_schedule_items', 'reminder_weekdays')) {
                $table->json('reminder_weekdays')->nullable()->after('reminder_time');
            }
            if (! Schema::hasColumn('student_schedule_items', 'reminder_dates')) {
                $table->json('reminder_dates')->nullable()->after('reminder_weekdays');
            }
            if (! Schema::hasColumn('student_schedule_items', 'next_reminder_at')) {
                $table->timestamp('next_reminder_at')->nullable()->after('reminder_dates');
            }
            if (! Schema::hasColumn('student_schedule_items', 'last_reminder_sent_at')) {
                $table->timestamp('last_reminder_sent_at')->nullable()->after('next_reminder_at');
            }
        });

        if (! $this->indexExists('student_schedule_items', 'student_schedule_next_reminder_idx')) {
            Schema::table('student_schedule_items', function (Blueprint $table) {
                $table->index('next_reminder_at', 'student_schedule_next_reminder_idx');
            });
        }
    }

    public function down(): void
    {
        Schema::table('student_schedule_items', function (Blueprint $table) {
            if ($this->indexExists('student_schedule_items', 'student_schedule_next_reminder_idx')) {
                $table->dropIndex('student_schedule_next_reminder_idx');
            }
            $table->dropColumn([
                'reminder_schedule_type',
                'reminder_time',
                'reminder_weekdays',
                'reminder_dates',
                'next_reminder_at',
                'last_reminder_sent_at',
            ]);
        });
    }

    private function indexExists(string $tableName, string $indexName): bool
    {
        return DB::table('information_schema.statistics')
            ->where('table_schema', DB::getDatabaseName())
            ->where('table_name', $tableName)
            ->where('index_name', $indexName)
            ->exists();
    }
};
