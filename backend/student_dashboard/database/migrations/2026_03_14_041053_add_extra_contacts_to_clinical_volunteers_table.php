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
        Schema::table('clinical_volunteers', function (Blueprint $table) {
            $table->string('phone_secondary')->nullable()->after('contact_info');
            $table->string('email')->nullable()->after('phone_secondary');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('clinical_volunteers', function (Blueprint $table) {
            //
        });
    }
};
