<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('clinical_delegates', function (Blueprint $table) {
            if (! Schema::hasColumn('clinical_delegates', 'level_id')) {
                $table->foreignId('level_id')
                    ->nullable()
                    ->after('major_id')
                    ->constrained('levels')
                    ->nullOnDelete();
            }
        });

        DB::statement(
            'UPDATE clinical_delegates cd
             INNER JOIN users u ON u.id = cd.student_id
             SET cd.level_id = u.level_id
             WHERE cd.level_id IS NULL'
        );

        if (! $this->indexExists('clinical_delegates_major_level_index')) {
            Schema::table('clinical_delegates', function (Blueprint $table) {
                $table->index(['major_id', 'level_id'], 'clinical_delegates_major_level_index');
            });
        }

        if ($this->indexExists('clinical_delegates_major_id_unique')) {
            Schema::table('clinical_delegates', function (Blueprint $table) {
                try {
                    $table->dropUnique('clinical_delegates_major_id_unique');
                } catch (Throwable) {
                    // Older or manually migrated databases may not have this index.
                }
            });
        }
    }

    private function indexExists(string $indexName): bool
    {
        return (bool) DB::selectOne(
            'SELECT 1
             FROM information_schema.statistics
             WHERE table_schema = DATABASE()
               AND table_name = ?
               AND index_name = ?
             LIMIT 1',
            ['clinical_delegates', $indexName]
        );
    }

    private function dropIndexIfExists(string $indexName): void
    {
        if (! $this->indexExists($indexName)) {
            return;
        }

        Schema::table('clinical_delegates', function (Blueprint $table) use ($indexName) {
            try {
                $table->dropIndex($indexName);
            } catch (Throwable) {
                // Ignore when the index was already removed.
            }
        });
    }

    public function down(): void
    {
        $this->dropIndexIfExists('clinical_delegates_major_level_index');

        Schema::table('clinical_delegates', function (Blueprint $table) {
            if (Schema::hasColumn('clinical_delegates', 'level_id')) {
                $table->dropConstrainedForeignId('level_id');
            }

            try {
                $table->unique('major_id');
            } catch (Throwable) {
                // Rollback can fail if duplicate practical delegates exist for one major.
            }
        });
    }
};
