<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Http\Controllers\Api\Delegate\DelegateApiController;
use Illuminate\Http\Request;
use App\Models\Package;
use App\Models\Card;
use Illuminate\Support\Facades\DB;
use App\Enums\UserRole;

class SubscriptionController extends DelegateApiController
{
    /**
     * Show subscription status and available packages.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $packages = Package::where('is_active', true)
            ->get()
            ->map(function (Package $package) {
                $package->effective_price = $package->getPriceForRole(UserRole::DELEGATE->value);
                $package->effective_role = UserRole::DELEGATE->value;

                return $package;
            });
        
        return $this->success([
            'user_balance' => $user->balance,
            'is_subscribed' => $user->isSubscribed(),
            'subscribed_until' => $user->subscribed_until ? $user->subscribed_until->format('Y-m-d H:i:s') : null,
            'auto_renew' => (bool)$user->auto_renew,
            'packages' => $packages,
        ]);
    }

    /**
     * Redeem a voucher card to add balance.
     */
    public function redeem(Request $request)
    {
        $request->validate([
            'code' => 'required|string|size:12',
        ]);

        $card = Card::where('code', strtoupper($request->code))
            ->where('is_used', false)
            ->first();

        if (!$card) {
            return $this->error('كود الكرت غير صحيح أو تم استخدامه مسبقاً.');
        }

        $user = $request->user();

        DB::transaction(function () use ($card, $user) {
            $user->recordTransaction(
                $card->amount, 
                'deposit', 
                'voucher_redeem', 
                "شحن رصيد عبر كرت (كود: {$card->code})",
                $card
            );

            $card->update([
                'is_used' => true,
                'used_by_id' => $user->id,
                'used_at' => now(),
            ]);
        });

        return $this->success([
            'balance' => $user->balance,
            'amount_added' => $card->amount,
        ], "تم شحن رصيدك بنجاح بمبلغ {$card->amount} ريال.");
    }

    /**
     * Subscribe to a chosen package.
     */
    public function subscribe(Request $request)
    {
        $request->validate([
            'package_id' => 'required|exists:packages,id',
        ]);

        $package = Package::findOrFail($request->package_id);
        $user = $request->user();

        if ($user->isSubscribed()) {
            return $this->error('أنت مشترك بالفعل في باقة أخرى. يرجى الانتظار حتى انتهاء اشتراكك الحالي لتتمكن من التجديد أو تغيير الباقة.');
        }
        
        $price = $package->getPriceForRole(UserRole::DELEGATE->value);

        if ($user->balance < $price) {
            return $this->error('رصيدك غير كافٍ للاشتراك في هذه الباقة. يرجى شحن رصيدك أولاً.');
        }

        DB::transaction(function () use ($user, $package, $price) {
            $user->recordTransaction(
                -$price, 
                'payment', 
                'package_subscription', 
                "اشتراك في باقة: [{$package->name}]",
                $package
            );

            $currentExpiry = ($user->subscribed_until && $user->subscribed_until->isFuture()) 
                ? $user->subscribed_until 
                : now();
            
            $newExpiry = (clone $currentExpiry)->addDays($package->duration_days);

            $user->update([
                'subscribed_until' => $newExpiry,
            ]);

            \App\Models\Subscription::create([
                'user_id' => $user->id,
                'package_id' => $package->id,
                'price_paid' => $price,
                'started_at' => $currentExpiry,
                'ends_at' => $newExpiry,
                'status' => 'active',
            ]);
        });

        return $this->success([
            'balance' => $user->balance,
            'subscribed_until' => $user->subscribed_until->format('Y-m-d H:i:s'),
        ], "تهانينا! تم تفعيل اشتراكك في [{$package->name}] بنجاح.");
    }

    /**
     * Toggle auto-renewal setting.
     */
    public function toggleAutoRenew(Request $request)
    {
        $request->validate([
            'auto_renew' => 'required|boolean',
        ]);

        $user = $request->user();
        $user->update([
            'auto_renew' => $request->auto_renew
        ]);

        $status = $request->auto_renew ? 'مفعل' : 'معطل';
        return $this->success([
            'auto_renew' => (bool)$user->auto_renew,
        ], "تم {$status} التجديد التلقائي بنجاح.");
    }
}
