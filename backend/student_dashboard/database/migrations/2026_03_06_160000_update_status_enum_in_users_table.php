<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Using DB statement for ENUM modification since Doctrine DBAL sometimes has issues with ENUMs in SQLite/MySQL
        // The previous statuses were 'active' and 'inactive'. We are adding 'pending'.
        DB::statement("ALTER TABLE users MODIFY COLUMN status ENUM('active', 'inactive', 'pending') DEFAULT 'pending'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // To rollback, we revert to the old ENUM. Note: Any user with 'pending' status might cause an error here
        // so it's safer to update them to 'inactive' before altering the column back.
        DB::statement("UPDATE users SET status = 'inactive' WHERE status = 'pending'");
        DB::statement("ALTER TABLE users MODIFY COLUMN status ENUM('active', 'inactive') DEFAULT 'active'");
    }
};
