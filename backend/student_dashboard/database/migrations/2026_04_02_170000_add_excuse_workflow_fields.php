<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('excuses', function (Blueprint $table) {
            $table->enum('receiver_type', ['administrative', 'doctor'])
                ->default('administrative')
                ->after('student_id');
            $table->foreignId('receiver_id')
                ->nullable()
                ->after('receiver_type')
                ->constrained('users')
                ->nullOnDelete();
            $table->enum('resolution', ['excused_permission', 'excused_exemption', 'keep_absent'])
                ->nullable()
                ->after('status');
            $table->foreignId('reviewed_by')
                ->nullable()
                ->after('resolution')
                ->constrained('users')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('excuses', function (Blueprint $table) {
            $table->dropConstrainedForeignId('reviewed_by');
            $table->dropColumn('resolution');
            $table->dropConstrainedForeignId('receiver_id');
            $table->dropColumn('receiver_type');
        });
    }
};
