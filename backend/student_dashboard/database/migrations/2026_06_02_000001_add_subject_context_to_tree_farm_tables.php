<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tree_farm_sessions', function (Blueprint $table) {
            if (!Schema::hasColumn('tree_farm_sessions', 'subject_id')) {
                $table->foreignId('subject_id')
                    ->nullable()
                    ->after('user_id')
                    ->constrained('subjects')
                    ->nullOnDelete();
            }

            if (!Schema::hasColumn('tree_farm_sessions', 'subject_name')) {
                $table->string('subject_name')->nullable()->after('subject_id');
            }
        });

        Schema::table('tree_farm_plants', function (Blueprint $table) {
            if (!Schema::hasColumn('tree_farm_plants', 'subject_id')) {
                $table->foreignId('subject_id')
                    ->nullable()
                    ->after('user_id')
                    ->constrained('subjects')
                    ->nullOnDelete();
            }

            if (!Schema::hasColumn('tree_farm_plants', 'subject_name')) {
                $table->string('subject_name')->nullable()->after('subject_id');
            }
        });
    }

    public function down(): void
    {
        Schema::table('tree_farm_plants', function (Blueprint $table) {
            if (Schema::hasColumn('tree_farm_plants', 'subject_id')) {
                $table->dropConstrainedForeignId('subject_id');
            }

            if (Schema::hasColumn('tree_farm_plants', 'subject_name')) {
                $table->dropColumn('subject_name');
            }
        });

        Schema::table('tree_farm_sessions', function (Blueprint $table) {
            if (Schema::hasColumn('tree_farm_sessions', 'subject_id')) {
                $table->dropConstrainedForeignId('subject_id');
            }

            if (Schema::hasColumn('tree_farm_sessions', 'subject_name')) {
                $table->dropColumn('subject_name');
            }
        });
    }
};
