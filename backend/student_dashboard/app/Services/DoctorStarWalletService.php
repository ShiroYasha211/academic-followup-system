<?php

namespace App\Services;

use App\Enums\UserRole;
use App\Models\DoctorStarWallet;
use App\Models\StudentNotification;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class DoctorStarWalletService
{
    public function walletFor(User $doctor): DoctorStarWallet
    {
        $this->ensureDoctor($doctor);

        return DoctorStarWallet::firstOrCreate(
            ['doctor_id' => $doctor->id],
            [
                'college_id' => $doctor->college_id,
                'balance' => (int) ($doctor->college?->doctor_initial_star_balance ?? 50),
                'total_allocated' => (int) ($doctor->college?->doctor_initial_star_balance ?? 50),
                'total_spent' => 0,
            ],
        );
    }

    public function initialize(User $doctor, ?User $actor = null): DoctorStarWallet
    {
        $wallet = $this->walletFor($doctor);

        if (!$wallet->transactions()->exists()) {
            $wallet->transactions()->create([
                'performed_by' => $actor?->id,
                'type' => 'initial_allocation',
                'amount' => $wallet->balance,
                'balance_after' => $wallet->balance,
                'description' => 'الرصيد الابتدائي لمحفظة منح النجوم',
            ]);
        }

        return $wallet;
    }

    public function topUp(User $actor, User $doctor, int $amount, string $reason): DoctorStarWallet
    {
        $this->ensureDoctor($doctor);
        if (
            !$actor->canAccessAdministrativeWorkspace()
            || (int) $actor->college_id !== (int) $doctor->college_id
        ) {
            throw ValidationException::withMessages([
                'doctor' => ['لا يمكنك إدارة رصيد دكتور خارج نطاق كليتك.'],
            ]);
        }

        return DB::transaction(function () use ($actor, $doctor, $amount, $reason) {
            $this->walletFor($doctor);
            $wallet = DoctorStarWallet::where('doctor_id', $doctor->id)
                ->lockForUpdate()
                ->firstOrFail();

            $wallet->balance += $amount;
            $wallet->total_allocated += $amount;
            $wallet->save();

            $wallet->transactions()->create([
                'performed_by' => $actor->id,
                'type' => 'top_up',
                'amount' => $amount,
                'balance_after' => $wallet->balance,
                'description' => $reason,
            ]);

            return $wallet->fresh();
        });
    }

    public function grant(
        User $doctor,
        Collection $students,
        int $starsPerStudent,
        ?string $description = null,
    ): array {
        $students = $students->unique('id')->values();
        $recipientCount = $students->count();
        $totalCost = $recipientCount * $starsPerStudent;

        if ($recipientCount === 0) {
            throw ValidationException::withMessages([
                'student_ids' => ['يجب اختيار طالب واحد على الأقل.'],
            ]);
        }

        $result = DB::transaction(function () use (
            $doctor,
            $students,
            $starsPerStudent,
            $description,
            $recipientCount,
            $totalCost,
        ) {
            $this->walletFor($doctor);
            $wallet = DoctorStarWallet::where('doctor_id', $doctor->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($wallet->balance < $totalCost) {
                throw ValidationException::withMessages([
                    'amount' => [
                        "رصيد المنح غير كافٍ. المطلوب {$totalCost} نجمة، والمتاح {$wallet->balance} نجمة.",
                    ],
                ]);
            }

            $lockedStudents = User::whereIn('id', $students->pluck('id'))
                ->lockForUpdate()
                ->get()
                ->keyBy('id');

            foreach ($students as $student) {
                $lockedStudent = $lockedStudents->get($student->id);
                if (!$lockedStudent) {
                    throw ValidationException::withMessages([
                        'student_ids' => ['تعذر العثور على أحد الطلاب المحددين.'],
                    ]);
                }

                $lockedStudent->addStars(
                    $starsPerStudent,
                    'doctor_gift',
                    $doctor->id,
                    $description ?: "هدية نجوم من د. {$doctor->name}",
                );
            }

            $wallet->balance -= $totalCost;
            $wallet->total_spent += $totalCost;
            $wallet->save();

            $wallet->transactions()->create([
                'performed_by' => $doctor->id,
                'type' => 'grant',
                'amount' => -$totalCost,
                'balance_after' => $wallet->balance,
                'recipient_count' => $recipientCount,
                'stars_per_recipient' => $starsPerStudent,
                'description' => $description ?: 'منح نجوم للطلاب',
                'metadata' => [
                    'student_ids' => $students->pluck('id')->all(),
                ],
            ]);

            return [
                'wallet' => $wallet->fresh(),
                'students' => $lockedStudents->values(),
                'recipient_count' => $recipientCount,
                'stars_per_student' => $starsPerStudent,
                'total_cost' => $totalCost,
            ];
        });

        $this->notifyStudents(
            $doctor,
            $result['students'],
            $starsPerStudent,
        );

        return $result;
    }

    private function ensureDoctor(User $doctor): void
    {
        if ($doctor->role !== UserRole::DOCTOR || !$doctor->college_id) {
            throw ValidationException::withMessages([
                'doctor' => ['المستخدم المحدد ليس دكتورًا مرتبطًا بكلية.'],
            ]);
        }
    }

    private function notifyStudents(User $doctor, Collection $students, int $amount): void
    {
        foreach ($students as $student) {
            try {
                StudentNotification::create([
                    'user_id' => $student->id,
                    'college_id' => $student->college_id,
                    'sender_id' => $doctor->id,
                    'type' => 'stars',
                    'title' => 'تم منحك نجومًا جديدة',
                    'message' => "منحك د. {$doctor->name} {$amount} نجمة.",
                    'data' => [
                        'screen' => 'stars',
                        'target_screen' => 'stars',
                        'doctor_id' => $doctor->id,
                        'amount' => $amount,
                    ],
                ]);
            } catch (\Throwable $exception) {
                Log::warning('Doctor star grant completed but notification failed.', [
                    'doctor_id' => $doctor->id,
                    'student_id' => $student->id,
                    'error' => $exception->getMessage(),
                ]);
            }
        }
    }
}
