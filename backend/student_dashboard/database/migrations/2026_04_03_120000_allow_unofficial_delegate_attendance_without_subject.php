<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('lectures') && Schema::hasColumn('lectures', 'subject_id')) {
            try {
                DB::statement('ALTER TABLE lectures DROP FOREIGN KEY lectures_subject_id_foreign');
            } catch (Throwable $e) {
                // Foreign key may already be absent.
            }

            try {
                DB::statement('ALTER TABLE lectures DROP INDEX lectures_subject_date_title_number_type_unique');
            } catch (Throwable $e) {
                // Index may already be absent.
            }

            DB::statement('ALTER TABLE lectures MODIFY subject_id BIGINT UNSIGNED NULL');

            try {
                DB::statement('ALTER TABLE lectures ADD CONSTRAINT lectures_subject_id_foreign FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE');
            } catch (Throwable $e) {
                // Foreign key may already exist.
            }

            try {
                DB::statement('ALTER TABLE lectures ADD UNIQUE KEY lectures_subject_date_title_number_type_unique (subject_id, date, title, lecture_number, lecture_type)');
            } catch (Throwable $e) {
                // Unique index may already exist.
            }
        }

        if (Schema::hasTable('attendances') && Schema::hasColumn('attendances', 'subject_id')) {
            try {
                DB::statement('ALTER TABLE attendances DROP FOREIGN KEY attendances_subject_id_foreign');
            } catch (Throwable $e) {
                // Foreign key may already be absent.
            }

            try {
                DB::statement('ALTER TABLE attendances DROP INDEX attendances_student_id_subject_id_date_unique');
            } catch (Throwable $e) {
                // Index may already be absent.
            }

            DB::statement('ALTER TABLE attendances MODIFY subject_id BIGINT UNSIGNED NULL');

            try {
                DB::statement('ALTER TABLE attendances ADD CONSTRAINT attendances_subject_id_foreign FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE');
            } catch (Throwable $e) {
                // Foreign key may already exist.
            }

            try {
                DB::statement('ALTER TABLE attendances ADD UNIQUE KEY attendances_student_id_subject_id_date_unique (student_id, subject_id, date)');
            } catch (Throwable $e) {
                // Unique index may already exist.
            }
        }
    }

    public function down(): void
    {
        DB::statement('DELETE FROM attendances WHERE subject_id IS NULL');
        DB::statement('DELETE FROM lectures WHERE subject_id IS NULL');

        if (Schema::hasTable('attendances') && Schema::hasColumn('attendances', 'subject_id')) {
            try {
                DB::statement('ALTER TABLE attendances DROP FOREIGN KEY attendances_subject_id_foreign');
            } catch (Throwable $e) {
                // Foreign key may already be absent.
            }

            try {
                DB::statement('ALTER TABLE attendances DROP INDEX attendances_student_id_subject_id_date_unique');
            } catch (Throwable $e) {
                // Index may already be absent.
            }

            DB::statement('ALTER TABLE attendances MODIFY subject_id BIGINT UNSIGNED NOT NULL');

            try {
                DB::statement('ALTER TABLE attendances ADD CONSTRAINT attendances_subject_id_foreign FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE');
            } catch (Throwable $e) {
                // Foreign key may already exist.
            }

            try {
                DB::statement('ALTER TABLE attendances ADD UNIQUE KEY attendances_student_id_subject_id_date_unique (student_id, subject_id, date)');
            } catch (Throwable $e) {
                // Unique index may already exist.
            }
        }

        if (Schema::hasTable('lectures') && Schema::hasColumn('lectures', 'subject_id')) {
            try {
                DB::statement('ALTER TABLE lectures DROP FOREIGN KEY lectures_subject_id_foreign');
            } catch (Throwable $e) {
                // Foreign key may already be absent.
            }

            try {
                DB::statement('ALTER TABLE lectures DROP INDEX lectures_subject_date_title_number_type_unique');
            } catch (Throwable $e) {
                // Index may already be absent.
            }

            DB::statement('ALTER TABLE lectures MODIFY subject_id BIGINT UNSIGNED NOT NULL');

            try {
                DB::statement('ALTER TABLE lectures ADD CONSTRAINT lectures_subject_id_foreign FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE');
            } catch (Throwable $e) {
                // Foreign key may already exist.
            }

            try {
                DB::statement('ALTER TABLE lectures ADD UNIQUE KEY lectures_subject_date_title_number_type_unique (subject_id, date, title, lecture_number, lecture_type)');
            } catch (Throwable $e) {
                // Unique index may already exist.
            }
        }
    }
};
