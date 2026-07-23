<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('clinical_volunteers', function (Blueprint $table) {
            $table->string('follow_up_status')->default('not_contacted')->after('is_available');
            $table->string('preferred_contact_method')->nullable()->after('follow_up_status');
            $table->timestamp('last_contacted_at')->nullable()->after('preferred_contact_method');
            $table->text('internal_notes')->nullable()->after('last_contacted_at');
        });

        Schema::create('clinical_volunteer_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('clinical_volunteer_id')->constrained('clinical_volunteers')->onDelete('cascade');
            $table->foreignId('doctor_id')->constrained('users')->onDelete('cascade');
            $table->string('follow_up_status');
            $table->string('contact_method')->nullable();
            $table->timestamp('contacted_at')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('clinical_volunteer_logs');

        Schema::table('clinical_volunteers', function (Blueprint $table) {
            $table->dropColumn([
                'follow_up_status',
                'preferred_contact_method',
                'last_contacted_at',
                'internal_notes',
            ]);
        });
    }
};
