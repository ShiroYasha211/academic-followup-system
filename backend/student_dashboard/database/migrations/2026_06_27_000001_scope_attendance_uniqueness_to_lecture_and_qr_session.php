<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('qr_attendance_sessions', function (Blueprint $table) {
            if (!$this->indexExists('qr_attendance_sessions', 'qr_sessions_subject_id_index')) {
                $table->index('subject_id', 'qr_sessions_subject_id_index');
            }

            if ($this->indexExists('qr_attendance_sessions', 'qr_sessions_subject_date_title_unique')) {
                $table->dropUnique('qr_sessions_subject_date_title_unique');
            }

            if (!$this->indexExists('qr_attendance_sessions', 'qr_sessions_subject_date_title_number_unique')) {
                $table->unique(
                    ['subject_id', 'date', 'title', 'lecture_number'],
                    'qr_sessions_subject_date_title_number_unique'
                );
            }
        });

        Schema::table('attendances', function (Blueprint $table) {
            if (!$this->indexExists('attendances', 'attendances_student_id_index')) {
                $table->index('student_id', 'attendances_student_id_index');
            }

            if (!$this->indexExists('attendances', 'attendances_subject_id_index')) {
                $table->index('subject_id', 'attendances_subject_id_index');
            }

            if ($this->indexExists('attendances', 'attendances_student_id_subject_id_date_unique')) {
                $table->dropUnique('attendances_student_id_subject_id_date_unique');
            }

            if (!$this->indexExists('attendances', 'attendances_student_subject_date_lecture_unique')) {
                $table->unique(
                    ['student_id', 'subject_id', 'date', 'lecture_id'],
                    'attendances_student_subject_date_lecture_unique'
                );
            }

            if (
                Schema::hasColumn('attendances', 'qr_attendance_session_id')
                && !$this->indexExists('attendances', 'attendances_qr_session_student_unique')
            ) {
                $table->unique(
                    ['qr_attendance_session_id', 'student_id'],
                    'attendances_qr_session_student_unique'
                );
            }
        });
    }

    public function down(): void
    {
        Schema::table('qr_attendance_sessions', function (Blueprint $table) {
            if ($this->indexExists('qr_attendance_sessions', 'qr_sessions_subject_date_title_number_unique')) {
                $table->dropUnique('qr_sessions_subject_date_title_number_unique');
            }

            if (!$this->indexExists('qr_attendance_sessions', 'qr_sessions_subject_date_title_unique')) {
                $table->unique(['subject_id', 'date', 'title'], 'qr_sessions_subject_date_title_unique');
            }

            if ($this->indexExists('qr_attendance_sessions', 'qr_sessions_subject_id_index')) {
                $table->dropIndex('qr_sessions_subject_id_index');
            }
        });

        Schema::table('attendances', function (Blueprint $table) {
            if ($this->indexExists('attendances', 'attendances_qr_session_student_unique')) {
                $table->dropUnique('attendances_qr_session_student_unique');
            }

            if ($this->indexExists('attendances', 'attendances_student_subject_date_lecture_unique')) {
                $table->dropUnique('attendances_student_subject_date_lecture_unique');
            }

            if (!$this->indexExists('attendances', 'attendances_student_id_subject_id_date_unique')) {
                $table->unique(['student_id', 'subject_id', 'date']);
            }

            if ($this->indexExists('attendances', 'attendances_subject_id_index')) {
                $table->dropIndex('attendances_subject_id_index');
            }

            if ($this->indexExists('attendances', 'attendances_student_id_index')) {
                $table->dropIndex('attendances_student_id_index');
            }
        });
    }

    private function indexExists(string $table, string $index): bool
    {
        $database = DB::getDatabaseName();

        return !empty(DB::select(
            'select 1 from information_schema.statistics where table_schema = ? and table_name = ? and index_name = ? limit 1',
            [$database, $table, $index]
        ));
    }
};
