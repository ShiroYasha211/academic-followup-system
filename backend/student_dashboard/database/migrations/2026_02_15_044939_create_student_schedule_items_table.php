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
        Schema::create('student_schedule_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->nullableMorphs('referenceable'); // Adds referenceable_type and referenceable_id
            $table->string('title')->nullable(); // detailed title if needed, or override
            $table->date('scheduled_date')->nullable();
            $table->boolean('is_completed')->default(false);
            $table->timestamp('completed_at')->nullable();
            $table->integer('sort_order')->default(0);
            $table->text('note')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'sort_order']);
            // $table->index(['referenceable_type', 'referenceable_id']); // Created automatically by nullableMorphs
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('student_schedule_items');
    }
};
