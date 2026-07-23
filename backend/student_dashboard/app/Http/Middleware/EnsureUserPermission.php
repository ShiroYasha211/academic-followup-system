<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserPermission
{
    /**
     * Enforce a granular permission on the current user.
     */
    public function handle(Request $request, Closure $next, string $permission): Response
    {
        $user = $request->user();

        if ($user && $user->hasPermission($permission)) {
            return $next($request);
        }

        if ($request->expectsJson() || $request->is('api/*')) {
            return response()->json([
                'success' => false,
                'message' => 'ليس لديك الصلاحية المطلوبة لتنفيذ هذه العملية.',
            ], 403);
        }

        abort(403, 'ليس لديك الصلاحية المطلوبة لتنفيذ هذه العملية.');
    }
}
