<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("ALTER TABLE qr_attendance_sessions MODIFY status ENUM('active', 'finalized', 'cancelled') NOT NULL DEFAULT 'active'");
    }

    public function down(): void
    {
        DB::table('qr_attendance_sessions')
            ->where('status', 'cancelled')
            ->update(['status' => 'active']);

        DB::statement("ALTER TABLE qr_attendance_sessions MODIFY status ENUM('active', 'finalized') NOT NULL DEFAULT 'active'");
    }
};
