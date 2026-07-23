<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class CheckUserStatus
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (Auth::check() && Auth::user()->status !== 'active') {
            Auth::logout();

            if ($request->expectsJson() || $request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => 'تم إيقاف حسابك. يرجى مراجعة إدارة النظام.',
                ], 403);
            }

            return redirect()->route('admin.login')->withErrors([
                'email' => 'تم إيقاف حسابك. يرجى مراجعة إدارة النظام.',
            ]);
        }

        // Check if user was kicked by Admin
        if (Auth::check() && \Illuminate\Support\Facades\Cache::has('kick_user_' . Auth::id())) {
            \Illuminate\Support\Facades\Cache::forget('kick_user_' . Auth::id());
            Auth::logout();

            if ($request->expectsJson() || $request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => 'تم تسجيل خروجك من النظام بواسطة مسؤول النظام.',
                ], 401);
            }

            return redirect()->route('admin.login')->withErrors([
                'email' => 'تم تسجيل خروجك من النظام بواسطة مسؤول النظام.',
            ]);
        }

        return $next($request);
    }
}
