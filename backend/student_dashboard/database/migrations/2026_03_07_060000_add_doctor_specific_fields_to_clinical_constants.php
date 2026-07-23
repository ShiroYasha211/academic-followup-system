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
        // Add doctor_id to clinical_departments
        Schema::table('clinical_departments', function (Blueprint $table) {
            $table->foreignId('doctor_id')->nullable()->after('id')->constrained('users')->onDelete('cascade');
        });

        // Add doctor_id to body_systems
        Schema::table('body_systems', function (Blueprint $table) {
            $table->foreignId('doctor_id')->nullable()->after('id')->constrained('users')->onDelete('cascade');
        });

        // Create pivot table for hidden departments
        Schema::create('doctor_hidden_departments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('doctor_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('department_id')->constrained('clinical_departments')->onDelete('cascade');
            $table->timestamps();

            $table->unique(['doctor_id', 'department_id']);
        });

        // Create pivot table for hidden body systems
        Schema::create('doctor_hidden_body_systems', function (Blueprint $table) {
            $table->id();
            $table->foreignId('doctor_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('body_system_id')->constrained('body_systems')->onDelete('cascade');
            $table->timestamps();

            $table->unique(['doctor_id', 'body_system_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('doctor_hidden_body_systems');
        Schema::dropIfExists('doctor_hidden_departments');

        Schema::table('body_systems', function (Blueprint $table) {
            $table->dropForeign(['doctor_id']);
            $table->dropColumn('doctor_id');
        });

        Schema::table('clinical_departments', function (Blueprint $table) {
            $table->dropForeign(['doctor_id']);
            $table->dropColumn('doctor_id');
        });
    }
};
