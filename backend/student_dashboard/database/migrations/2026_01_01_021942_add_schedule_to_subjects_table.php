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
        Schema::table('subjects', function (Blueprint $table) {
            $table->string('hall')->nullable()->after('doctor_id');
            $table->string('time')->nullable()->after('hall');
            $table->string('day')->nullable()->after('time'); // e.g., Sunday, Monday
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('subjects', function (Blueprint $table) {
            $table->dropColumn(['hall', 'time', 'day']);
        });
    }
};
