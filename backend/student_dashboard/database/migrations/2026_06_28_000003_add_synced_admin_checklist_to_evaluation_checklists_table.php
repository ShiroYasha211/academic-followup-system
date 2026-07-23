<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('evaluation_checklists', function (Blueprint $table) {
            if (!Schema::hasColumn('evaluation_checklists', 'synced_admin_checklist_id')) {
                $table->foreignId('synced_admin_checklist_id')
                    ->nullable()
                    ->after('source_checklist_id')
                    ->constrained('evaluation_checklists')
                    ->nullOnDelete();
            }
        });
    }

    public function down(): void
    {
        Schema::table('evaluation_checklists', function (Blueprint $table) {
            if (Schema::hasColumn('evaluation_checklists', 'synced_admin_checklist_id')) {
                $table->dropConstrainedForeignId('synced_admin_checklist_id');
            }
        });
    }
};
