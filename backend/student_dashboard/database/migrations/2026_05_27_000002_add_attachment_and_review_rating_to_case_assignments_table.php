<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('case_assignments', function (Blueprint $table) {
            $table->string('attachment_path')->nullable()->after('due_at');
            $table->string('attachment_name')->nullable()->after('attachment_path');
            $table->string('attachment_type')->nullable()->after('attachment_name');
            $table->string('review_rating', 30)->nullable()->after('review_notes');
        });
    }

    public function down(): void
    {
        Schema::table('case_assignments', function (Blueprint $table) {
            $table->dropColumn([
                'attachment_path',
                'attachment_name',
                'attachment_type',
                'review_rating',
            ]);
        });
    }
};
