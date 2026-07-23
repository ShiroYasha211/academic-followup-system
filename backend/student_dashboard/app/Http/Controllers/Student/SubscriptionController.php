<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Package;
use App\Models\Card;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Enums\UserRole;

class SubscriptionController extends Controller
{
    /**
     * Show subscription status and available packages.
     */
    public function index()
    {
        $user = auth()->user();
        $packages = Package::where('is_active', true)->get();
        
        return view('student.subscription.index', compact('user', 'packages'));
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
            return back()->with('error', 'كود الكرت غير صحيح أو تم استخدامه مسبقاً.');
        }

        DB::transaction(function () use ($card) {
            $user = auth()->user();
            
            // 1. Update User Balance & Record Transaction
            $user->recordTransaction(
                $card->amount, 
                'deposit', 
                'voucher_redeem', 
                "شحن رصيد عبر كرت (كود: {$card->code})",
                $card
            );

            // 2. Mark card as used (already handled by balance increment in some logic, but recordTransaction handles it now)
            $card->update([
                'is_used' => true,
                'used_by_id' => $user->id,
                'used_at' => now(),
            ]);
        });

        return back()->with('success', "تم شحن رصيدك بنجاح بمبلغ {$card->amount} ريال.");
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
        $user = auth()->user();

        // Guard: Prevent stacking subscriptions if already active
        if ($user->isSubscribed()) {
            return back()->with('error', 'أنت مشترك بالفعل في باقة أخرى. يرجى الانتظار حتى انتهاء اشتراكك الحالي لتتمكن من التجديد أو تغيير الباقة.');
        }
        
        // Determine price based on role
        $roleValue = $user->role instanceof UserRole ? $user->role->value : $user->role;
        $price = $package->getPriceForRole($roleValue);

        if ($user->balance < $price) {
            return back()->with('error', 'رصيدك غير كافٍ للاشتراك في هذه الباقة. يرجى شحن رصيدك أولاً.');
        }

        DB::transaction(function () use ($user, $package, $price) {
            // 1. Deduct Balance & Record Transaction
            $transaction = $user->recordTransaction(
                -$price, 
                'payment', 
                'package_subscription', 
                "اشتراك في باقة: [{$package->name}]",
                $package
            );

            // 2. Update Subscription Date
            $currentExpiry = ($user->subscribed_until && $user->subscribed_until->isFuture()) 
                ? $user->subscribed_until 
                : now();
            
            $newExpiry = (clone $currentExpiry)->addDays($package->duration_days);

            $user->update([
                'subscribed_until' => $newExpiry,
            ]);

            // 3. Record History (Old subscription model, keep for backward compatibility or linking)
            \App\Models\Subscription::create([
                'user_id' => $user->id,
                'package_id' => $package->id,
                'price_paid' => $price,
                'started_at' => $currentExpiry,
                'ends_at' => $newExpiry,
                'status' => 'active',
            ]);

            // Optional: Link transaction to subscription if needed later
        });

        return back()->with('success', "تهانينا! تم تفعيل اشتراكك في [{$package->name}] بنجاح.");
    }

    /**
     * Toggle auto-renewal setting.
     */
    public function toggleAutoRenew(Request $request)
    {
        auth()->user()->update([
            'auto_renew' => $request->has('auto_renew')
        ]);

        return back()->with('success', 'تم تحديث إعدادات التجديد التلقائي.');
    }
}
