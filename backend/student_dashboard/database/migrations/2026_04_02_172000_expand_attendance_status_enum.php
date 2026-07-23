<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement(
            "ALTER TABLE attendances MODIFY status ENUM('present','absent','late','excused','permitted','exempted') NOT NULL DEFAULT 'absent'"
        );
    }

    public function down(): void
    {
        DB::statement("UPDATE attendances SET status = 'excused' WHERE status IN ('permitted', 'exempted')");
        DB::statement(
            "ALTER TABLE attendances MODIFY status ENUM('present','absent','late','excused') NOT NULL DEFAULT 'absent'"
        );
    }
};
