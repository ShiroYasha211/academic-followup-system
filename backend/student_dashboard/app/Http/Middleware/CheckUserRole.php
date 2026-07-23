<?php

namespace App\Http\Middleware;

use App\Enums\UserRole;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class CheckUserRole
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next, string $role): Response
    {
        if (!Auth::check()) {
            abort(403, 'غير مصرح لك بالوصول لهذه الصفحة.');
        }

        $user = Auth::user();
        $userRole = $user->role->value;

        if ($role === 'delegate' && $user->canAccessDelegateWorkspace()) {
            return $next($request);
        }

        if ($role === 'student' && $user->canAccessStudentWorkspace()) {
            return $next($request);
        }

        if ($role === 'doctor' && $user->canAccessDoctorWorkspace()) {
            return $next($request);
        }

        if ($role === 'administrative' && $user->canAccessAdministrativeWorkspace()) {
            return $next($request);
        }

        if ($userRole !== $role) {
            abort(403, 'غير مصرح لك بالوصول لهذه الصفحة.');
        }

        return $next($request);
    }
}
