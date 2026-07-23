<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('case_assignments', function (Blueprint $table) {
            $table->string('status', 30)->default('assigned')->after('instructions');
            $table->text('student_completion_message')->nullable()->after('status');
            $table->timestamp('submitted_at')->nullable()->after('student_completion_message');
            $table->timestamp('reviewed_at')->nullable()->after('submitted_at');
            $table->foreignId('reviewed_by')->nullable()->after('reviewed_at')->constrained('users')->nullOnDelete();
            $table->text('review_notes')->nullable()->after('reviewed_by');
        });

        DB::table('case_assignments')
            ->where('is_completed', true)
            ->update([
                'status' => 'approved',
                'reviewed_at' => DB::raw('COALESCE(completed_at, updated_at)'),
            ]);

        DB::table('case_assignments')
            ->where('is_completed', false)
            ->update([
                'status' => 'assigned',
            ]);
    }

    public function down(): void
    {
        Schema::table('case_assignments', function (Blueprint $table) {
            $table->dropConstrainedForeignId('reviewed_by');
            $table->dropColumn([
                'status',
                'student_completion_message',
                'submitted_at',
                'reviewed_at',
                'review_notes',
            ]);
        });
    }
};
