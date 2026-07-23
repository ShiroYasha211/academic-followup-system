<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Package;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;

class PackageController extends Controller
{
    public function index()
    {
        $packages = Package::latest()->get();
        return view('admin.packages.index', compact('packages'));
    }

    public function create()
    {
        return view('admin.packages.create');
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
        ]);

        $package = new Package($validated);
        
        // Robust slug generation for Arabic or English
        $slug = Str::slug($request->name);
        if (empty($slug)) {
            // If Arabic, Str::slug might return empty, fallback to basic hex/random
            $slug = bin2hex(random_bytes(5));
        }
        
        // Ensure uniqueness
        if (Package::where('slug', $slug)->exists()) {
            $slug = $slug . '-' . time();
        }

        $package->slug = $slug;
        $package->is_active = $request->has('is_active');
        $package->save();

        return redirect()->route('admin.packages.index')->with('success', 'تم إنشاء الباقة بنجاح.');
    }

    public function edit(Package $package)
    {
        return view('admin.packages.create', compact('package'));
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
        ]);

        $package->fill($validated);
        $package->is_active = $request->has('is_active');
        $package->save();

        return redirect()->route('admin.packages.index')->with('success', 'تم تحديث الباقة بنجاح.');
    }

    public function toggleStatus(Package $package)
    {
        $package->is_active = !$package->is_active;
        $package->save();

        $status = $package->is_active ? 'تفعيل' : 'إلغاء تفعيل';
        return back()->with('success', "تم {$status} الباقة بنجاح.");
    }

    public function subscribers(Package $package)
    {
        // Get all subscriptions for this package, grouped by user to show stats
        $subscribers = \App\Models\Subscription::with('user')
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
            });

        return view('admin.packages.subscribers', compact('package', 'subscribers'));
    }

    public function cancelSubscription(Request $request, \App\Models\Subscription $subscription)
    {
        $user = $subscription->user;

        DB::transaction(function () use ($subscription, $user, $request) {
            // 1. Mark subscription as cancelled
            $subscription->update([
                'status' => 'cancelled',
                'canceled_at' => now(),
                'refunded' => $request->has('refund')
            ]);

            // 2. Clear user subscription until date
            $user->update([
                'subscribed_until' => now()
            ]);

            // 3. Refund if requested
            if ($request->has('refund')) {
                $user->recordTransaction(
                    $subscription->price_paid,
                    'refund',
                    'admin_refund',
                    "استرداد مبلغ اشتراك ملغي (باقة: [{$subscription->package->name}])",
                    $subscription
                );
            }
        });

        $message = "تم إلغاء الاشتراك بنجاح.";
        if ($request->has('refund')) {
            $message .= " وتم إرجاع مبلغ {$subscription->price_paid} ريال لرصيد المستخدم.";
        }

        return back()->with('success', $message);
    }

    public function destroy(Package $package)
    {
        $package->delete();
        return redirect()->route('admin.packages.index')->with('success', 'تم حذف الباقة بنجاح.');
    }
}
