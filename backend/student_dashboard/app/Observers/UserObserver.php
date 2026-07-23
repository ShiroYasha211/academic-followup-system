<?php

namespace App\Observers;

use App\Enums\UserRole;
use App\Models\User;
use App\Services\DoctorStarWalletService;

class UserObserver
{
    public function created(User $user): void
    {
        $this->initializeDoctorWallet($user);
    }

    public function updated(User $user): void
    {
        if ($user->wasChanged(['role', 'college_id'])) {
            $this->initializeDoctorWallet($user);
        }
    }

    private function initializeDoctorWallet(User $user): void
    {
        if ($user->role !== UserRole::DOCTOR || !$user->college_id) {
            return;
        }

        app(DoctorStarWalletService::class)->initialize($user);
    }
}
