<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('clinical_rare_cases', function (Blueprint $table) {
            $table->string('status')->default('published')->after('is_active');
            $table->timestamp('expires_at')->nullable()->after('status');
            $table->text('internal_notes')->nullable()->after('expires_at');
            $table->unsignedInteger('views_count')->default(0)->after('internal_notes');
        });
    }

    public function down(): void
    {
        Schema::table('clinical_rare_cases', function (Blueprint $table) {
            $table->dropColumn([
                'status',
                'expires_at',
                'internal_notes',
                'views_count',
            ]);
        });
    }
};
