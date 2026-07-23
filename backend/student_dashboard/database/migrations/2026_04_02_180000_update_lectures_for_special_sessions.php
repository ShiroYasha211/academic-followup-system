<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('lectures', 'lecture_type')) {
            try {
                Schema::table('lectures', function (Blueprint $table) {
                    $table->dropUnique('lectures_subject_id_date_unique');
                });
            } catch (Throwable $e) {
                // Unique may already be replaced during a previous partial run.
            }

            Schema::table('lectures', function (Blueprint $table) {
                $table->unique(['subject_id', 'date', 'title', 'lecture_number', 'lecture_type'], 'lectures_subject_date_title_number_type_unique');
            });

            try {
                Schema::table('lectures', function (Blueprint $table) {
                    $table->foreign('subject_id')->references('id')->on('subjects')->cascadeOnDelete();
                });
            } catch (Throwable $e) {
                // FK may already exist from a previous run.
            }

            return;
        }

        Schema::table('lectures', function (Blueprint $table) {
            $table->dropForeign(['subject_id']);
        });

        Schema::table('lectures', function (Blueprint $table) {
            $table->string('lecture_type')->default('official')->after('lecture_number');
            $table->dropUnique('lectures_subject_id_date_unique');
            $table->unique(['subject_id', 'date', 'title', 'lecture_number', 'lecture_type'], 'lectures_subject_date_title_number_type_unique');
            $table->foreign('subject_id')->references('id')->on('subjects')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('lectures', function (Blueprint $table) {
            $table->dropUnique('lectures_subject_date_title_number_type_unique');
        });

        if (Schema::hasColumn('lectures', 'lecture_type')) {
            Schema::table('lectures', function (Blueprint $table) {
                $table->dropColumn('lecture_type');
            });
        }

        Schema::table('lectures', function (Blueprint $table) {
            try {
                $table->dropForeign(['subject_id']);
            } catch (Throwable $e) {
                // FK may already be absent in a partially reverted database.
            }
            $table->unique(['subject_id', 'date'], 'lectures_subject_id_date_unique');
            $table->foreign('subject_id')->references('id')->on('subjects')->cascadeOnDelete();
        });
    }
};
