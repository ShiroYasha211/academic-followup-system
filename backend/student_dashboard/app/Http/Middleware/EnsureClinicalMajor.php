<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureClinicalMajor
{
    /**
     * Allow access only for users whose major supports clinical features.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && method_exists($user, 'canAccessClinicalWorkspace') && $user->canAccessClinicalWorkspace()) {
            return $next($request);
        }

        if ($request->expectsJson() || $request->is('api/*')) {
            return response()->json([
                'success' => false,
                'message' => 'This section is available only for clinical majors.',
            ], 403);
        }

        abort(403, 'Unauthorized action. This section is available only for clinical majors.');
    }
}
