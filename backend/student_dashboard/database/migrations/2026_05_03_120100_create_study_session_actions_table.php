<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('study_session_actions')) {
            $this->addIndexIfMissing(
                'study_session_actions',
                'study_actions_item_user_time_idx',
                ['student_schedule_item_id', 'user_id', 'occurred_at']
            );
            $this->addIndexIfMissing(
                'study_session_actions',
                'study_actions_column_time_idx',
                ['study_session_column_id', 'occurred_at']
            );

            return;
        }

        Schema::create('study_session_actions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_schedule_item_id')->constrained('student_schedule_items')->cascadeOnDelete();
            $table->foreignId('study_session_column_id')->constrained('study_session_columns')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('action_type', 20)->default('increment');
            $table->timestamp('occurred_at')->useCurrent();
            $table->timestamps();

            $table->index(['student_schedule_item_id', 'user_id', 'occurred_at'], 'study_actions_item_user_time_idx');
            $table->index(['study_session_column_id', 'occurred_at'], 'study_actions_column_time_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('study_session_actions');
    }

    private function addIndexIfMissing(string $tableName, string $indexName, array $columns): void
    {
        if ($this->indexExists($tableName, $indexName)) {
            return;
        }

        Schema::table($tableName, function (Blueprint $table) use ($columns, $indexName) {
            $table->index($columns, $indexName);
        });
    }

    private function indexExists(string $tableName, string $indexName): bool
    {
        return DB::table('information_schema.statistics')
            ->where('table_schema', DB::getDatabaseName())
            ->where('table_name', $tableName)
            ->where('index_name', $indexName)
            ->exists();
    }
};
