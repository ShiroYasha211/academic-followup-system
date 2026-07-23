<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureDesktopToken
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        $token = $user?->currentAccessToken();

        if (!$user || !$token || !$user->tokenCan('desktop')) {
            return response()->json([
                'success' => false,
                'message' => 'Desktop token is required.',
            ], 403);
        }

        return $next($request);
    }
}
