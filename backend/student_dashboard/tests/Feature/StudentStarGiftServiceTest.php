<?php

namespace Tests\Feature;

use App\Exceptions\StarGiftException;
use App\Models\Setting;
use App\Models\User;
use App\Services\StudentStarGiftService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class StudentStarGiftServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

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

        Schema::create('settings', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->text('value')->nullable();
            $table->string('type')->default('text');
            $table->string('group')->default('general');
            $table->string('label')->nullable();
            $table->text('description')->nullable();
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
            $table->string('batch_id')->nullable();
            $table->string('type');
            $table->string('title');
            $table->text('message');
            $table->string('attachment_path')->nullable();
            $table->string('attachment_name')->nullable();
            $table->json('data')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
        });

        foreach ([
            ['student_star_gifting_enabled', '1', 'boolean'],
            ['student_star_gift_limit', '20', 'number'],
            ['student_star_gift_period', 'weekly', 'text'],
            ['student_star_gift_custom_days', '7', 'number'],
            ['student_star_gift_once_per_recipient', '0', 'boolean'],
        ] as [$key, $value, $type]) {
            Setting::create([
                'key' => $key,
                'value' => $value,
                'type' => $type,
                'group' => 'stars',
            ]);
        }
    }

    protected function tearDown(): void
    {
        Cache::flush();
        Schema::dropIfExists('student_notifications');
        Schema::dropIfExists('star_transactions');
        Schema::dropIfExists('settings');
        Schema::dropIfExists('users');

        parent::tearDown();
    }

    public function test_it_enforces_the_configured_period_limit_and_updates_both_balances(): void
    {
        Setting::set('student_star_gifting_enabled', true);
        Setting::set('student_star_gift_limit', 20);
        Setting::set('student_star_gift_period', 'weekly');

        $sender = User::factory()->create([
            'role' => 'student',
            'status' => 'active',
            'stars_balance' => 100,
            'total_stars_earned' => 100,
        ]);
        $recipient = User::factory()->create([
            'role' => 'student',
            'status' => 'active',
            'stars_balance' => 0,
            'total_stars_earned' => 0,
        ]);

        $service = app(StudentStarGiftService::class);
        $result = $service->gift($sender, $recipient, 15, 'بالتوفيق');

        $this->assertSame(85, (int) $result['sender']->stars_balance);
        $this->assertSame(15, (int) $result['recipient']->stars_balance);
        $this->assertSame(15, $result['limit']['used']);
        $this->assertSame(5, $result['limit']['remaining']);

        try {
            $service->gift($sender->fresh(), $recipient->fresh(), 6);
            $this->fail('The gift should have exceeded the configured limit.');
        } catch (StarGiftException $exception) {
            $this->assertSame('star_gift_limit_exceeded', $exception->errorCode);
        }

        $this->assertSame(85, (int) $sender->fresh()->stars_balance);
        $this->assertSame(15, (int) $recipient->fresh()->stars_balance);
    }

    public function test_it_rejects_non_student_recipients(): void
    {
        $sender = User::factory()->create([
            'role' => 'student',
            'status' => 'active',
            'stars_balance' => 10,
        ]);
        $doctor = User::factory()->create([
            'role' => 'doctor',
            'status' => 'active',
            'stars_balance' => 0,
        ]);

        $this->expectException(StarGiftException::class);

        app(StudentStarGiftService::class)->gift($sender, $doctor, 1);
    }

    public function test_it_can_limit_gifting_to_the_same_recipient_once_per_period(): void
    {
        Setting::set('student_star_gift_once_per_recipient', true);

        $sender = User::factory()->create([
            'role' => 'student',
            'status' => 'active',
            'stars_balance' => 10,
        ]);
        $recipient = User::factory()->create([
            'role' => 'delegate',
            'status' => 'active',
            'stars_balance' => 0,
        ]);

        $service = app(StudentStarGiftService::class);
        $service->gift($sender, $recipient, 1);

        try {
            $service->gift($sender->fresh(), $recipient->fresh(), 1);
            $this->fail('A second gift to the same recipient should be rejected.');
        } catch (StarGiftException $exception) {
            $this->assertSame('star_gift_recipient_limit_reached', $exception->errorCode);
        }
    }
}
