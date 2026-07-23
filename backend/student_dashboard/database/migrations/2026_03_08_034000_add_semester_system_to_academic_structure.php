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
        // 1. Update majors table
        if (!Schema::hasColumn('majors', 'has_semesters')) {
            Schema::table('majors', function (Blueprint $blueprint) {
                $blueprint->boolean('has_semesters')->default(false)->after('has_clinical');
            });
        }

        // 2. Create semesters table
        if (!Schema::hasTable('semesters')) {
            Schema::create('semesters', function (Blueprint $table) {
                $table->id();
                $table->foreignId('term_id')->constrained()->onDelete('cascade');
                $table->string('name');
                $table->timestamps();
            });
        }

        // 3. Update subjects table
        if (!Schema::hasColumn('subjects', 'semester_id')) {
            Schema::table('subjects', function (Blueprint $table) {
                $table->foreignId('semester_id')->nullable()->after('term_id')->constrained()->onDelete('set null');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('subjects', function (Blueprint $table) {
            $table->dropForeign(['semester_id']);
            $table->dropColumn('semester_id');
        });

        Schema::dropIfExists('semesters');

        Schema::table('majors', function (Blueprint $table) {
            $table->dropColumn('has_semesters');
        });
    }
};
