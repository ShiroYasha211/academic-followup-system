<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('daily_log_activities', function (Blueprint $table) {
            $table->boolean('is_confirmed')->default(false)->after('notes');
            $table->text('diagnosis')->nullable()->after('is_confirmed');
            $table->foreignId('confirmed_by')->nullable()->after('diagnosis')->constrained('users')->nullOnDelete();
            $table->timestamp('confirmed_at')->nullable()->after('confirmed_by');
        });

        DB::statement("ALTER TABLE student_daily_logs MODIFY COLUMN status ENUM('pending', 'partially_confirmed', 'confirmed', 'rejected') DEFAULT 'pending'");
    }

    public function down(): void
    {
        DB::statement("UPDATE student_daily_logs SET status = 'pending' WHERE status = 'partially_confirmed'");
        DB::statement("ALTER TABLE student_daily_logs MODIFY COLUMN status ENUM('pending', 'confirmed', 'rejected') DEFAULT 'pending'");

        Schema::table('daily_log_activities', function (Blueprint $table) {
            $table->dropConstrainedForeignId('confirmed_by');
            $table->dropColumn(['is_confirmed', 'diagnosis', 'confirmed_at']);
        });
    }
};
