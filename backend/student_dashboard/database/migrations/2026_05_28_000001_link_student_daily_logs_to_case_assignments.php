<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('student_daily_logs', function (Blueprint $table) {
            if (! Schema::hasColumn('student_daily_logs', 'case_assignment_id')) {
                $table->foreignId('case_assignment_id')
                    ->nullable()
                    ->after('student_id')
                    ->constrained('case_assignments')
                    ->nullOnDelete();
            }
        });
    }

    public function down(): void
    {
        Schema::table('student_daily_logs', function (Blueprint $table) {
            if (Schema::hasColumn('student_daily_logs', 'case_assignment_id')) {
                $table->dropConstrainedForeignId('case_assignment_id');
            }
        });
    }
};
