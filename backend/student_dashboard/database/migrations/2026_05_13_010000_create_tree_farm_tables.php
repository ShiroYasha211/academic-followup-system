<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tree_farm_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnDelete();
            $table->string('public_name')->nullable();
            $table->boolean('is_public')->default(false);
            $table->boolean('use_alias')->default(false);
            $table->unsignedInteger('coins_balance')->default(0);
            $table->unsignedBigInteger('total_focus_seconds')->default(0);
            $table->unsignedBigInteger('total_public_focus_seconds')->default(0);
            $table->timestamps();
        });

        Schema::create('tree_farm_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('client_uuid')->nullable()->unique();
            $table->enum('farm_scope', ['private', 'public'])->default('private');
            $table->enum('source', ['online', 'offline'])->default('online');
            $table->enum('status', ['active', 'completed', 'interrupted', 'burned', 'pending_sync', 'synced', 'rejected'])->default('active');
            $table->timestamp('started_at');
            $table->timestamp('ended_at')->nullable();
            $table->unsignedInteger('planned_seconds')->default(0);
            $table->unsignedInteger('focused_seconds')->default(0);
            $table->unsignedInteger('heartbeat_count')->default(0);
            $table->timestamp('last_heartbeat_at')->nullable();
            $table->unsignedInteger('grace_seconds_used')->default(0);
            $table->string('awarded_plant_code')->nullable();
            $table->unsignedInteger('awarded_coins')->default(0);
            $table->text('rejection_reason')->nullable();
            $table->timestamp('synced_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });

        Schema::create('tree_farm_plants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('tree_farm_session_id')->nullable()->constrained('tree_farm_sessions')->nullOnDelete();
            $table->enum('farm_scope', ['private', 'public'])->default('private');
            $table->string('plant_code');
            $table->string('name');
            $table->string('rarity')->default('common');
            $table->unsignedInteger('required_seconds');
            $table->unsignedInteger('coins_awarded')->default(0);
            $table->enum('status', ['pending_sync', 'synced', 'rejected'])->default('synced');
            $table->timestamp('planted_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'farm_scope']);
        });

        Schema::create('tree_farm_reward_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedInteger('coins_amount');
            $table->unsignedInteger('stars_amount');
            $table->unsignedInteger('conversion_rate')->default(100);
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->timestamps();
        });

        Schema::create('tree_farm_thoughts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('tree_farm_session_id')->nullable()->constrained('tree_farm_sessions')->nullOnDelete();
            $table->string('client_uuid')->nullable()->unique();
            $table->text('body');
            $table->timestamp('reminder_at')->nullable();
            $table->timestamp('synced_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tree_farm_thoughts');
        Schema::dropIfExists('tree_farm_reward_requests');
        Schema::dropIfExists('tree_farm_plants');
        Schema::dropIfExists('tree_farm_sessions');
        Schema::dropIfExists('tree_farm_profiles');
    }
};
