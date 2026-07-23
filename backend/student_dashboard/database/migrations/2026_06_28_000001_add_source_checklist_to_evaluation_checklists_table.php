<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('evaluation_checklists', function (Blueprint $table) {
            if (!Schema::hasColumn('evaluation_checklists', 'source_checklist_id')) {
                $table->foreignId('source_checklist_id')
                    ->nullable()
                    ->after('doctor_id')
                    ->constrained('evaluation_checklists')
                    ->nullOnDelete();
            }
        });
    }

    public function down(): void
    {
        Schema::table('evaluation_checklists', function (Blueprint $table) {
            if (Schema::hasColumn('evaluation_checklists', 'source_checklist_id')) {
                $table->dropConstrainedForeignId('source_checklist_id');
            }
        });
    }
};
