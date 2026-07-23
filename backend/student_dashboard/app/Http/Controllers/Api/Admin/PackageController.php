<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\Package;
use App\Models\Subscription;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;

class PackageController extends AdminApiController
{
    public function index()
    {
        return $this->success(Package::latest()->get());
    }

    public function show(Package $package)
    {
        return $this->success($package);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'price_student' => 'required|numeric|min:0',
            'price_doctor' => 'required|numeric|min:0',
            'price_delegate' => 'required|numeric|min:0',
            'price_administrative' => 'required|numeric|min:0',
            'duration_days' => 'required|integer|min:1',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $package = new Package($validated);
        $slug = Str::slug($request->name);
        if (empty($slug)) $slug = bin2hex(random_bytes(5));
        if (Package::where('slug', $slug)->exists()) $slug .= '-' . time();
        
        $package->slug = $slug;
        $package->is_active = $request->input('is_active', true);
        $package->save();

        ActivityLog::log('create', 'Package', $package->id, $package->name, "إنشاء باقة اشتراك جديدة عبر الـ API: {$package->name}");

        return $this->success($package, 'تم إنشاء الباقة بنجاح', 201);
    }

    public function update(Request $request, Package $package)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'price_student' => 'required|numeric|min:0',
            'price_doctor' => 'required|numeric|min:0',
            'price_delegate' => 'required|numeric|min:0',
            'price_administrative' => 'required|numeric|min:0',
            'duration_days' => 'required|integer|min:1',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $package->update($validated);
        $package->is_active = $request->input('is_active', $package->is_active);
        $package->save();

        ActivityLog::log('update', 'Package', $package->id, $package->name, "تحديث باقة عبر الـ API: {$package->name}");

        return $this->success($package, 'تم تحديث الباقة بنجاح');
    }

    public function toggleStatus(Package $package)
    {
        $package->is_active = !$package->is_active;
        $package->save();

        return $this->success($package, $package->is_active ? 'تم تفعيل الباقة' : 'تم إلغاء تفعيل الباقة');
    }

    public function subscribers(Package $package)
    {
        $subscribers = Subscription::with('user')
            ->where('package_id', $package->id)
            ->get()
            ->groupBy('user_id')
            ->map(function ($subs) {
                return [
                    'user' => $subs->first()->user,
                    'count' => $subs->count(),
                    'total_paid' => $subs->sum('price_paid'),
                    'current_subscription' => $subs->where('status', 'active')->where('ends_at', '>', now())->first(),
                ];
            })
            ->values();

        return $this->success($subscribers);
    }

    public function cancelSubscription(Request $request, Subscription $subscription)
    {
        $user = $subscription->user;

        DB::transaction(function () use ($subscription, $user, $request) {
            $subscription->update([
                'status' => 'cancelled',
                'canceled_at' => now(),
                'refunded' => $request->has('refund')
            ]);

            $user->update(['subscribed_until' => now()]);

            if ($request->has('refund')) {
                $user->recordTransaction(
                    $subscription->price_paid,
                    'refund',
                    'admin_refund',
                    "استرداد مبلغ اشتراك عبر الـ API (باقة: [{$subscription->package->name}])",
                    $subscription
                );
            }
        });

        return $this->success(null, 'تم إلغاء الاشتراك بنجاح.');
    }

    public function destroy(Package $package)
    {
        $package->delete();
        return $this->success(null, 'تم حذف الباقة بنجاح');
    }
}
