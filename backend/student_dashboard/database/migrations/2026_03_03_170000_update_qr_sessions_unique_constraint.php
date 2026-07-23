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
        Schema::table('qr_attendance_sessions', function (Blueprint $table) {
            // First drop the foreign key that depends on the index
            $table->dropForeign(['subject_id']);
        });

        Schema::table('qr_attendance_sessions', function (Blueprint $table) {
            // Now drop the old unique constraint
            $table->dropUnique('qr_attendance_sessions_subject_id_date_unique');

            // Add new unique constraint (subject_id + date + title)
            $table->unique(['subject_id', 'date', 'title'], 'qr_sessions_subject_date_title_unique');

            // Re-add the foreign key
            $table->foreign('subject_id')->references('id')->on('subjects')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('qr_attendance_sessions', function (Blueprint $table) {
            $table->dropForeign(['subject_id']);
        });

        Schema::table('qr_attendance_sessions', function (Blueprint $table) {
            $table->dropUnique('qr_sessions_subject_date_title_unique');
            $table->unique(['subject_id', 'date'], 'qr_attendance_sessions_subject_id_date_unique');
            $table->foreign('subject_id')->references('id')->on('subjects')->onDelete('cascade');
        });
    }
};
