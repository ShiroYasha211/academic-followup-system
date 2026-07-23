<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('majors', 'has_clinical')) {
            Schema::table('majors', function (Blueprint $table) {
                $table->boolean('has_clinical')->default(false)->after('name');
            });
        }
    }

    public function down(): void
    {
        Schema::table('majors', function (Blueprint $table) {
            $table->dropColumn('has_clinical');
        });
    }
};
