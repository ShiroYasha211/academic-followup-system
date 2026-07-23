<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('evaluation_checklists', function (Blueprint $table) {
            if (!Schema::hasColumn('evaluation_checklists', 'tracks_admin_updates')) {
                $table->boolean('tracks_admin_updates')
                    ->default(true)
                    ->after('source_checklist_id');
            }
        });
    }

    public function down(): void
    {
        Schema::table('evaluation_checklists', function (Blueprint $table) {
            if (Schema::hasColumn('evaluation_checklists', 'tracks_admin_updates')) {
                $table->dropColumn('tracks_admin_updates');
            }
        });
    }
};
