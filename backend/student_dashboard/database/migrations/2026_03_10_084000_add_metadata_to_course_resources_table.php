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
        Schema::table('course_resources', function (Blueprint $table) {
            $table->string('sub_category')->nullable()->after('category');
            $table->string('custom_category_type')->nullable()->after('sub_category');
            $table->string('unit_coordinator')->nullable()->after('description');
            $table->string('lecturer_name')->nullable()->after('unit_coordinator');
            $table->string('clinical_unit')->nullable()->after('lecturer_name');
            $table->string('semester_info')->nullable()->after('clinical_unit');
            $table->string('visibility')->default('everyone')->after('semester_info'); // batch, college, everyone
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('course_resources', function (Blueprint $table) {
            $table->dropColumn([
                'sub_category',
                'custom_category_type',
                'unit_coordinator',
                'lecturer_name',
                'clinical_unit',
                'semester_info',
                'visibility'
            ]);
        });
    }
};
