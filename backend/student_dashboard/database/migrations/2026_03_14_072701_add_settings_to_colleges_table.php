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
        Schema::table('colleges', function (Blueprint $table) {
            $table->integer('absence_deprivation_percentage')->default(25);
            $table->integer('excuses_deadline_days')->default(3);
            $table->enum('excuse_receiver', ['administrative', 'doctor', 'delegate'])->default('administrative');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('colleges', function (Blueprint $table) {
            $table->dropColumn(['absence_deprivation_percentage', 'excuses_deadline_days', 'excuse_receiver']);
        });
    }
};
