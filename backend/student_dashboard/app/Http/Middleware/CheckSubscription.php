<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckSubscription
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = auth()->user();

        // 1. Allow Admins
        if ($user->role === \App\Enums\UserRole::ADMIN) {
            return $next($request);
        }

        // 2. Allow access to subscription, profile (for logout/password), and dashboard
        $allowedRoutes = [
            'student.subscription.*',
            'student.dashboard',
            'student.attendance.scan',
            'student.profile.password',
            'student.profile.password.update',
            'student.ledger',
            'student.ledger.export',
            'delegate.subscription.*',
            'delegate.dashboard',
            'delegate.profile.password',
            'delegate.profile.password.update',
            'delegate.ledger',
            'delegate.ledger.export',
            'doctor.subscription.*',
            'doctor.dashboard',
            'doctor.profile.password',
            'doctor.profile.password.update',
            'doctor.ledger',
            'doctor.ledger.export',
            'administrative.subscription.*',
            'administrative.dashboard',
            'administrative.profile.password',
            'administrative.profile.password.update',
            'administrative.ledger',
            'administrative.ledger.export',
            'logout',
            'admin.logout',
        ];

        if ($request->routeIs($allowedRoutes)) {
            return $next($request);
        }

        // 3. Check Subscription
        if (!$user->isSubscribed()) {
            if ($request->expectsJson() || $request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => 'يجب الاشتراك للوصول إلى هذه الميزة.',
                    'code' => 'subscription_required',
                ], 403);
            }

            $roleValue = $user->role instanceof \App\Enums\UserRole ? $user->role->value : $user->role;
            
            // Map roles to their subscription route prefixes
            $prefixMap = [
                'doctor' => 'doctor',
                'delegate' => 'delegate',
                'practical_delegate' => 'delegate',
                'student' => 'student',
                'administrative' => 'administrative',
            ];
            $prefix = $prefixMap[$roleValue] ?? 'student';

            return redirect()->route($prefix . '.subscription.index')
                ->with('warning', 'عذراً، يجب عليك الاشتراك لتتمكن من الوصول لهذه الميزة.');
        }

        return $next($request);
    }
}
