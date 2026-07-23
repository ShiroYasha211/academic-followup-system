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
        Schema::table('clinical_cases', function (Blueprint $table) {
            $table->enum('approval_status', ['approved', 'pending', 'rejected'])->default('approved')->after('status');
            $table->foreignId('approved_by_id')->nullable()->constrained('users')->nullOnDelete()->after('approval_status');
            $table->text('rejection_reason')->nullable()->after('approved_by_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('clinical_cases', function (Blueprint $table) {
            $table->dropForeign(['approved_by_id']);
            $table->dropColumn(['approval_status', 'approved_by_id', 'rejection_reason']);
        });
    }
};
