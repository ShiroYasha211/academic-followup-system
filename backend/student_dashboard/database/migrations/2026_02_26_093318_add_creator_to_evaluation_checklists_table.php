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
            $table->string('creator_type')->nullable()->after('is_active');
            $table->unsignedBigInteger('creator_id')->nullable()->after('creator_type');

            $table->index(['creator_type', 'creator_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('evaluation_checklists', function (Blueprint $table) {
            $table->dropIndex(['creator_type', 'creator_id']);
            $table->dropColumn(['creator_type', 'creator_id']);
        });
    }
};
