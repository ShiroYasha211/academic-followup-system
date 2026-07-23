<?php

namespace App\Services;

use App\Enums\UserRole;
use App\Exceptions\StarGiftException;
use App\Models\Setting;
use App\Models\StarTransaction;
use App\Models\StudentNotification;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class StudentStarGiftService
{
    private const STUDENT_ROLES = [
        UserRole::STUDENT->value,
        UserRole::DELEGATE->value,
        UserRole::PRACTICAL_DELEGATE->value,
    ];

    public function limitStatus(User $student): array
    {
        $enabled = (bool) Setting::get('student_star_gifting_enabled', true);
        $maximum = max(1, (int) Setting::get('student_star_gift_limit', 20));
        $period = (string) Setting::get('student_star_gift_period', 'weekly');
        $customDays = max(1, (int) Setting::get('student_star_gift_custom_days', 7));
        [$startsAt, $resetsAt] = $this->periodBounds($period, $customDays);

        $used = abs((int) StarTransaction::query()
            ->where('user_id', $student->id)
            ->where('type', 'gifted')
            ->where('created_at', '>=', $startsAt)
            ->where('created_at', '<', $resetsAt)
            ->sum('amount'));

        $remaining = $enabled ? max(0, $maximum - $used) : 0;

        return [
            'enabled' => $enabled,
            'maximum' => $maximum,
            'used' => $used,
            'remaining' => $remaining,
            'period' => $period,
            'period_label' => $this->periodLabel($period, $customDays),
            'starts_at' => $startsAt->toIso8601String(),
            'resets_at' => $resetsAt->toIso8601String(),
            'once_per_recipient' => (bool) Setting::get('student_star_gift_once_per_recipient', false),
            'can_gift' => $enabled && $remaining > 0 && (int) $student->stars_balance > 0,
        ];
    }

    public function gift(User $sender, User $recipient, int $amount, ?string $message = null): array
    {
        if ($amount < 1) {
            throw new StarGiftException(
                'يجب أن يكون عدد النجوم نجمة واحدة على الأقل.',
                'invalid_star_gift_amount',
            );
        }

        if ((int) $sender->id === (int) $recipient->id) {
            throw new StarGiftException(
                'لا يمكنك تحويل النجوم إلى حسابك نفسه.',
                'cannot_gift_stars_to_self',
            );
        }

        $result = DB::transaction(function () use ($sender, $recipient, $amount, $message) {
            $users = User::query()
                ->whereIn('id', [$sender->id, $recipient->id])
                ->orderBy('id')
                ->lockForUpdate()
                ->get()
                ->keyBy('id');

            /** @var User|null $lockedSender */
            $lockedSender = $users->get($sender->id);
            /** @var User|null $lockedRecipient */
            $lockedRecipient = $users->get($recipient->id);

            if (! $lockedSender || ! $lockedRecipient) {
                throw new StarGiftException(
                    'تعذر العثور على أحد الحسابين.',
                    'star_gift_user_not_found',
                    404,
                );
            }

            $this->assertEligibleStudent($lockedSender, 'حسابك غير مؤهل لتحويل النجوم.');
            $this->assertEligibleStudent($lockedRecipient, 'يمكن تحويل النجوم إلى حساب طالب فعال فقط.');

            $limit = $this->limitStatus($lockedSender);
            if (! $limit['enabled']) {
                throw new StarGiftException(
                    'تحويل النجوم بين الطلاب متوقف حاليًا من إدارة النظام.',
                    'student_star_gifting_disabled',
                    403,
                );
            }

            if ($amount > (int) $lockedSender->stars_balance) {
                throw new StarGiftException(
                    'رصيدك الحالي لا يكفي لإتمام التحويل.',
                    'insufficient_star_balance',
                );
            }

            if ($amount > $limit['remaining']) {
                throw new StarGiftException(
                    "المتبقي المسموح لك خلال {$limit['period_label']} هو {$limit['remaining']} نجمة.",
                    'star_gift_limit_exceeded',
                );
            }

            if ($limit['once_per_recipient'] && $this->hasGiftedRecipientDuringPeriod(
                $lockedSender,
                $lockedRecipient,
                CarbonImmutable::parse($limit['starts_at']),
                CarbonImmutable::parse($limit['resets_at']),
            )) {
                throw new StarGiftException(
                    'سبق أن حولت نجومًا لهذا الطالب خلال الفترة الحالية.',
                    'star_gift_recipient_limit_reached',
                );
            }

            $description = trim((string) $message);
            $lockedSender->deductStars(
                $amount,
                'gifted',
                null,
                $description !== '' ? $description : 'هدية لـ ' . $lockedRecipient->name,
            );
            $lockedRecipient->addStars(
                $amount,
                'received_gift',
                $lockedSender->id,
                $description !== '' ? $description : 'هدية من ' . $lockedSender->name,
            );

            return [
                'sender' => $lockedSender->fresh(),
                'recipient' => $lockedRecipient->fresh(),
                'limit' => $this->limitStatus($lockedSender->fresh()),
            ];
        }, 3);

        $this->notifyRecipient(
            $result['sender'],
            $result['recipient'],
            $amount,
        );

        return $result;
    }

    private function assertEligibleStudent(User $user, string $message): void
    {
        $role = $user->role instanceof UserRole ? $user->role->value : (string) $user->role;

        if (! in_array($role, self::STUDENT_ROLES, true) || $user->status !== 'active') {
            throw new StarGiftException($message, 'ineligible_star_gift_account', 403);
        }
    }

    private function hasGiftedRecipientDuringPeriod(
        User $sender,
        User $recipient,
        CarbonImmutable $startsAt,
        CarbonImmutable $resetsAt,
    ): bool {
        return StarTransaction::query()
            ->where('user_id', $recipient->id)
            ->where('granted_by', $sender->id)
            ->where('type', 'received_gift')
            ->where('created_at', '>=', $startsAt)
            ->where('created_at', '<', $resetsAt)
            ->exists();
    }

    private function periodBounds(string $period, int $customDays): array
    {
        $now = CarbonImmutable::now();

        return match ($period) {
            'daily' => [$now->startOfDay(), $now->startOfDay()->addDay()],
            'monthly' => [$now->startOfMonth(), $now->startOfMonth()->addMonth()],
            'custom' => $this->customPeriodBounds($now, $customDays),
            default => [$now->startOfWeek(), $now->startOfWeek()->addWeek()],
        };
    }

    private function customPeriodBounds(CarbonImmutable $now, int $days): array
    {
        $anchor = CarbonImmutable::create(2020, 1, 1, 0, 0, 0, config('app.timezone'));
        $elapsedDays = (int) $anchor->diffInDays($now->startOfDay());
        $cycle = intdiv($elapsedDays, $days);
        $startsAt = $anchor->addDays($cycle * $days);

        return [$startsAt, $startsAt->addDays($days)];
    }

    private function periodLabel(string $period, int $customDays): string
    {
        return match ($period) {
            'daily' => 'اليوم',
            'monthly' => 'هذا الشهر',
            'custom' => "فترة {$customDays} أيام",
            default => 'هذا الأسبوع',
        };
    }

    private function notifyRecipient(User $sender, User $recipient, int $amount): void
    {
        try {
            StudentNotification::create([
                'user_id' => $recipient->id,
                'college_id' => $recipient->college_id,
                'sender_id' => $sender->id,
                'type' => 'stars',
                'title' => 'هدية نجوم جديدة',
                'message' => "أهدى لك {$sender->name} {$amount} نجمة.",
                'data' => [
                    'screen' => 'stars',
                    'target_screen' => 'stars',
                    'sender_id' => $sender->id,
                    'amount' => $amount,
                ],
            ]);
        } catch (\Throwable $exception) {
            Log::warning('Star gift completed but recipient notification failed.', [
                'sender_id' => $sender->id,
                'recipient_id' => $recipient->id,
                'error' => $exception->getMessage(),
            ]);
        }
    }
}
