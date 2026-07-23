<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('colleges', function (Blueprint $table) {
            $table->unsignedInteger('doctor_initial_star_balance')
                ->default(50)
                ->after('qr_rotation_seconds');
        });

        Schema::create('doctor_star_wallets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('doctor_id')->unique()->constrained('users')->cascadeOnDelete();
            $table->foreignId('college_id')->constrained('colleges')->cascadeOnDelete();
            $table->unsignedInteger('balance')->default(0);
            $table->unsignedBigInteger('total_allocated')->default(0);
            $table->unsignedBigInteger('total_spent')->default(0);
            $table->timestamps();

            $table->index(['college_id', 'balance']);
        });

        Schema::create('doctor_star_wallet_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('doctor_star_wallet_id')
                ->constrained('doctor_star_wallets')
                ->cascadeOnDelete();
            $table->foreignId('performed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('type', 40);
            $table->integer('amount');
            $table->unsignedInteger('balance_after');
            $table->unsignedInteger('recipient_count')->nullable();
            $table->unsignedInteger('stars_per_recipient')->nullable();
            $table->string('description')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index(['doctor_star_wallet_id', 'created_at'], 'doctor_star_wallet_tx_wallet_created_idx');
        });

        $now = now();
        $doctors = DB::table('users')
            ->join('colleges', 'colleges.id', '=', 'users.college_id')
            ->where('users.role', 'doctor')
            ->whereNull('users.deleted_at')
            ->select([
                'users.id as doctor_id',
                'users.college_id',
                'colleges.doctor_initial_star_balance',
            ])
            ->get();

        foreach ($doctors as $doctor) {
            $initialBalance = (int) ($doctor->doctor_initial_star_balance ?? 50);
            $walletId = DB::table('doctor_star_wallets')->insertGetId([
                'doctor_id' => $doctor->doctor_id,
                'college_id' => $doctor->college_id,
                'balance' => $initialBalance,
                'total_allocated' => $initialBalance,
                'total_spent' => 0,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            DB::table('doctor_star_wallet_transactions')->insert([
                'doctor_star_wallet_id' => $walletId,
                'performed_by' => null,
                'type' => 'initial_allocation',
                'amount' => $initialBalance,
                'balance_after' => $initialBalance,
                'description' => 'الرصيد الابتدائي لمحفظة منح النجوم',
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('doctor_star_wallet_transactions');
        Schema::dropIfExists('doctor_star_wallets');

        Schema::table('colleges', function (Blueprint $table) {
            $table->dropColumn('doctor_initial_star_balance');
        });
    }
};
