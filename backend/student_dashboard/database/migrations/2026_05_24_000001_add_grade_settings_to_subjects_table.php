<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('subjects', function (Blueprint $table) {
            $table->decimal('grade_total_max_score', 6, 2)->default(100)->after('inquiries_closed_reason');
            $table->decimal('grade_continuous_max_score', 6, 2)->default(40)->after('grade_total_max_score');
            $table->decimal('grade_final_max_score', 6, 2)->default(60)->after('grade_continuous_max_score');
            $table->decimal('grade_passing_score', 6, 2)->default(50)->after('grade_final_max_score');
        });
    }

    public function down(): void
    {
        Schema::table('subjects', function (Blueprint $table) {
            $table->dropColumn([
                'grade_total_max_score',
                'grade_continuous_max_score',
                'grade_final_max_score',
                'grade_passing_score',
            ]);
        });
    }
};
