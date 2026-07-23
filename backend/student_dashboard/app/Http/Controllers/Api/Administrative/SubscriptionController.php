<?php

namespace App\Http\Controllers\Api\Administrative;

use App\Enums\UserRole;
use App\Models\Card;
use App\Models\Package;
use App\Models\Subscription;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SubscriptionController extends AdministrativeApiController
{
    public function index(Request $request)
    {
        $user = $request->user();
        $roleValue = $user->role instanceof UserRole ? $user->role->value : $user->role;
        $packages = Package::where('is_active', true)
            ->get()
            ->map(function (Package $package) use ($roleValue) {
                $package->effective_price = $package->getPriceForRole($roleValue);
                $package->effective_role = $roleValue;

                return $package;
            });

        return $this->success([
            'user_balance' => $user->balance,
            'is_subscribed' => $user->isSubscribed(),
            'subscribed_until' => $user->subscribed_until?->format('Y-m-d H:i:s'),
            'auto_renew' => (bool) $user->auto_renew,
            'packages' => $packages,
        ]);
    }

    public function redeem(Request $request)
    {
        $validated = $request->validate([
            'code' => 'required|string|size:12',
        ]);

        $card = Card::where('code', strtoupper($validated['code']))
            ->where('is_used', false)
            ->first();

        if (!$card) {
            return $this->error('كود البطاقة غير صحيح أو مستخدم مسبقًا.', 422);
        }

        $user = $request->user();

        DB::transaction(function () use ($card, $user) {
            $user->recordTransaction(
                $card->amount,
                'deposit',
                'voucher_redeem',
                "شحن رصيد عبر بطاقة {$card->code}",
                $card
            );

            $card->update([
                'is_used' => true,
                'used_by_id' => $user->id,
                'used_at' => now(),
            ]);
        });

        return $this->success([
            'balance' => $user->fresh()->balance,
            'amount_added' => $card->amount,
        ], 'تم شحن الرصيد بنجاح');
    }

    public function subscribe(Request $request)
    {
        $validated = $request->validate([
            'package_id' => 'required|exists:packages,id',
        ]);

        $package = Package::findOrFail($validated['package_id']);
        $user = $request->user();

        if ($user->isSubscribed()) {
            return $this->error('لديك اشتراك فعال بالفعل.', 422);
        }

        $roleValue = $user->role?->value ?? $user->role;
        $price = $package->getPriceForRole($roleValue);

        if ($user->balance < $price) {
            return $this->error('الرصيد غير كافٍ للاشتراك في هذه الباقة.', 422);
        }

        DB::transaction(function () use ($user, $package, $price) {
            $user->recordTransaction(
                -$price,
                'payment',
                'package_subscription',
                "اشتراك في باقة {$package->name}",
                $package
            );

            $currentExpiry = ($user->subscribed_until && $user->subscribed_until->isFuture())
                ? $user->subscribed_until
                : now();

            $newExpiry = (clone $currentExpiry)->addDays($package->duration_days);

            $user->update([
                'subscribed_until' => $newExpiry,
            ]);

            Subscription::create([
                'user_id' => $user->id,
                'package_id' => $package->id,
                'price_paid' => $price,
                'started_at' => $currentExpiry,
                'ends_at' => $newExpiry,
                'status' => 'active',
            ]);
        });

        return $this->success([
            'balance' => $user->fresh()->balance,
            'subscribed_until' => $user->fresh()->subscribed_until?->format('Y-m-d H:i:s'),
        ], 'تم تفعيل الاشتراك بنجاح');
    }

    public function toggleAutoRenew(Request $request)
    {
        $validated = $request->validate([
            'auto_renew' => 'required|boolean',
        ]);

        $request->user()->update([
            'auto_renew' => $validated['auto_renew'],
        ]);

        return $this->success([
            'auto_renew' => (bool) $request->user()->fresh()->auto_renew,
        ], 'تم تحديث حالة التجديد التلقائي بنجاح');
    }
}
