<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('student_evaluations', function (Blueprint $table) {
            if (!Schema::hasColumn('student_evaluations', 'body_system_id')) {
                $table->foreignId('body_system_id')
                    ->nullable()
                    ->after('clinical_case_id')
                    ->constrained('body_systems')
                    ->nullOnDelete();
            }

            if (!Schema::hasColumn('student_evaluations', 'procedure_type')) {
                $table->string('procedure_type')->nullable()->after('body_system_id');
            }

            if (!Schema::hasColumn('student_evaluations', 'timer_type')) {
                $table->string('timer_type')->default('fixed')->after('procedure_type');
            }
        });
    }

    public function down(): void
    {
        Schema::table('student_evaluations', function (Blueprint $table) {
            if (Schema::hasColumn('student_evaluations', 'body_system_id')) {
                $table->dropConstrainedForeignId('body_system_id');
            }

            if (Schema::hasColumn('student_evaluations', 'procedure_type')) {
                $table->dropColumn('procedure_type');
            }

            if (Schema::hasColumn('student_evaluations', 'timer_type')) {
                $table->dropColumn('timer_type');
            }
        });
    }
};
