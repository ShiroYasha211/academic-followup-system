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
        Schema::table('evaluation_checklists', function (Blueprint $table) {
            // First check if column does not exist before adding it to avoid duplication errors
            if (!Schema::hasColumn('evaluation_checklists', 'is_practice_allowed')) {
                $table->boolean('is_practice_allowed')->default(false)->after('time_limit_minutes');
            }

            // Alter the time limit column
            $table->integer('time_limit_minutes')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('evaluation_checklists', function (Blueprint $table) {
            if (Schema::hasColumn('evaluation_checklists', 'is_practice_allowed')) {
                $table->dropColumn('is_practice_allowed');
            }
            $table->integer('time_limit_minutes')->nullable(false)->default(15)->change();
        });
    }
};
