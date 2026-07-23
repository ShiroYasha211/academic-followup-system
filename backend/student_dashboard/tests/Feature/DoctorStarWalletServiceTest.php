<?php

namespace Tests\Feature;

use App\Models\Academic\College;
use App\Models\User;
use App\Services\DoctorStarWalletService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class DoctorStarWalletServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('colleges', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('university_id')->nullable();
            $table->string('name');
            $table->unsignedInteger('doctor_initial_star_balance')->default(50);
            $table->timestamps();
        });

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('password');
            $table->string('role');
            $table->string('status')->default('active');
            $table->unsignedBigInteger('college_id')->nullable();
            $table->integer('stars_balance')->default(0);
            $table->integer('total_stars_earned')->default(0);
            $table->rememberToken();
            $table->softDeletes();
            $table->timestamps();
        });

        Schema::create('star_transactions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('granted_by')->nullable();
            $table->string('type');
            $table->integer('amount');
            $table->integer('balance_after');
            $table->string('description')->nullable();
            $table->string('reference_type')->nullable();
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->timestamps();
        });

        Schema::create('student_notifications', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id')->nullable();
            $table->unsignedBigInteger('college_id')->nullable();
            $table->unsignedBigInteger('sender_id')->nullable();
            $table->string('type');
            $table->string('title');
            $table->text('message');
            $table->json('data')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
        });

        Schema::create('doctor_star_wallets', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('doctor_id')->unique();
            $table->unsignedBigInteger('college_id');
            $table->unsignedInteger('balance')->default(0);
            $table->unsignedBigInteger('total_allocated')->default(0);
            $table->unsignedBigInteger('total_spent')->default(0);
            $table->timestamps();
        });

        Schema::create('doctor_star_wallet_transactions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('doctor_star_wallet_id');
            $table->unsignedBigInteger('performed_by')->nullable();
            $table->string('type');
            $table->integer('amount');
            $table->unsignedInteger('balance_after');
            $table->unsignedInteger('recipient_count')->nullable();
            $table->unsignedInteger('stars_per_recipient')->nullable();
            $table->string('description')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('doctor_star_wallet_transactions');
        Schema::dropIfExists('doctor_star_wallets');
        Schema::dropIfExists('student_notifications');
        Schema::dropIfExists('star_transactions');
        Schema::dropIfExists('users');
        Schema::dropIfExists('colleges');

        parent::tearDown();
    }

    public function test_it_deducts_the_total_cost_and_credits_all_students(): void
    {
        [$doctor, $students] = $this->users();
        $service = app(DoctorStarWalletService::class);
        $wallet = $service->initialize($doctor);
        $wallet->update([
            'balance' => 20,
            'total_allocated' => 20,
        ]);

        $result = $service->grant($doctor, $students, 5, 'تفوق أكاديمي');

        $this->assertSame(10, (int) $result['wallet']->balance);
        $this->assertSame(10, (int) $result['wallet']->total_spent);
        $this->assertSame(5, (int) $students[0]->fresh()->stars_balance);
        $this->assertSame(5, (int) $students[1]->fresh()->stars_balance);
        $this->assertDatabaseHas('doctor_star_wallet_transactions', [
            'doctor_star_wallet_id' => $wallet->id,
            'type' => 'grant',
            'amount' => -10,
            'recipient_count' => 2,
            'stars_per_recipient' => 5,
        ]);
    }

    public function test_it_rejects_an_insufficient_wallet_without_partial_credit(): void
    {
        [$doctor, $students] = $this->users();
        $service = app(DoctorStarWalletService::class);
        $wallet = $service->initialize($doctor);
        $wallet->update([
            'balance' => 10,
            'total_allocated' => 10,
        ]);

        try {
            $service->grant($doctor, $students, 6);
            $this->fail('The grant should have been rejected.');
        } catch (ValidationException) {
            $this->assertSame(10, (int) $wallet->fresh()->balance);
            $this->assertSame(0, (int) $students[0]->fresh()->stars_balance);
            $this->assertSame(0, (int) $students[1]->fresh()->stars_balance);
            $this->assertDatabaseMissing('doctor_star_wallet_transactions', [
                'doctor_star_wallet_id' => $wallet->id,
                'type' => 'grant',
            ]);
        }
    }

    public function test_an_administrative_user_can_top_up_a_doctor_wallet(): void
    {
        [$doctor] = $this->users();
        $administrative = User::factory()->create([
            'role' => 'administrative',
            'status' => 'active',
            'college_id' => $doctor->college_id,
        ]);

        $wallet = app(DoctorStarWalletService::class)->topUp(
            $administrative,
            $doctor,
            25,
            'تعزيز رصيد الفصل الحالي',
        );

        $this->assertSame(75, (int) $wallet->balance);
        $this->assertSame(75, (int) $wallet->total_allocated);
        $this->assertDatabaseHas('doctor_star_wallet_transactions', [
            'doctor_star_wallet_id' => $wallet->id,
            'performed_by' => $administrative->id,
            'type' => 'top_up',
            'amount' => 25,
            'balance_after' => 75,
        ]);
    }

    private function users(): array
    {
        $college = College::create([
            'name' => 'كلية الطب',
            'doctor_initial_star_balance' => 50,
        ]);
        $doctor = User::factory()->create([
            'role' => 'doctor',
            'status' => 'active',
            'college_id' => $college->id,
        ]);
        $students = collect([
            User::factory()->create([
                'role' => 'student',
                'status' => 'active',
                'college_id' => $college->id,
                'stars_balance' => 0,
                'total_stars_earned' => 0,
            ]),
            User::factory()->create([
                'role' => 'student',
                'status' => 'active',
                'college_id' => $college->id,
                'stars_balance' => 0,
                'total_stars_earned' => 0,
            ]),
        ]);

        return [$doctor, $students];
    }
}
