<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('flashcard_packs', function (Blueprint $table) {
            $table->foreignId('parent_pack_id')
                ->nullable()
                ->after('source_pack_id')
                ->constrained('flashcard_packs')
                ->nullOnDelete();
        });

        Schema::table('flashcard_items', function (Blueprint $table) {
            $table->string('item_type', 20)->nullable()->after('pack_id');
            $table->string('item_color', 7)->nullable()->after('correct_option');
        });

        Schema::table('flashcard_progress', function (Blueprint $table) {
            $table->string('last_response', 20)->nullable()->after('times_correct');
            $table->unsignedTinyInteger('review_weight')->default(2)->after('last_response');
        });
    }

    public function down(): void
    {
        Schema::table('flashcard_progress', function (Blueprint $table) {
            $table->dropColumn(['last_response', 'review_weight']);
        });

        Schema::table('flashcard_items', function (Blueprint $table) {
            $table->dropColumn(['item_type', 'item_color']);
        });

        Schema::table('flashcard_packs', function (Blueprint $table) {
            $table->dropConstrainedForeignId('parent_pack_id');
        });
    }
};
