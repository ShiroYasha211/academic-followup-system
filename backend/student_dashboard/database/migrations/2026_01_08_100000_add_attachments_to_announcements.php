<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('announcements', function (Blueprint $table) {
            $table->string('attachment_path')->nullable()->after('content');
            $table->enum('attachment_type', ['image', 'document'])->nullable()->after('attachment_path');
            $table->boolean('is_pinned')->default(false)->after('category');
            $table->unsignedInteger('views_count')->default(0)->after('is_pinned');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('announcements', function (Blueprint $table) {
            $table->dropColumn(['attachment_path', 'attachment_type', 'is_pinned', 'views_count']);
        });
    }
};
