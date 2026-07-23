<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckDelegatePermission
{
    /**
     * Handle an incoming request.
     *
     * Usage: ->middleware('delegate.permission:resource,action')
     * Example: ->middleware('delegate.permission:students,create')
     */
    public function handle(Request $request, Closure $next, string $resource, string $action): Response
    {
        $user = $request->user();

        if (!$user) {
            abort(403, 'غير مصرح بالوصول.');
        }

        // Only enforce on delegate roles
        if (in_array($user->role->value, ['delegate', 'practical_delegate'])) {
            if (!$user->hasDelegatePermission($resource, $action)) {
                abort(403, 'ليس لديك صلاحية لتنفيذ هذه العملية. تواصل مع مسؤول الكلية لتفعيل الصلاحية.');
            }
        }

        return $next($request);
    }
}
