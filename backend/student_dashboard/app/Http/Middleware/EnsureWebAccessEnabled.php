<?php

namespace App\Http\Middleware;

use App\Support\WebAccessGate;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class EnsureWebAccessEnabled
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (WebAccessGate::canAccessWeb($user)) {
            return $next($request);
        }

        $message = WebAccessGate::closedMessage();

        if ($request->expectsJson()) {
            abort(403, $message);
        }

        Auth::logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()
            ->route('admin.login')
            ->withErrors(['email' => $message]);
    }
}
