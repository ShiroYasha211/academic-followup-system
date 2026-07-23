<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__ . '/../routes/web.php',
        api: __DIR__ . '/../routes/api.php',
        commands: __DIR__ . '/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'role' => \App\Http\Middleware\CheckUserRole::class,
            'status' => \App\Http\Middleware\CheckUserStatus::class,
            'clinical_delegate' => \App\Http\Middleware\EnsureClinicalDelegate::class,
            'clinical.major' => \App\Http\Middleware\EnsureClinicalMajor::class,
            'desktop.token' => \App\Http\Middleware\EnsureDesktopToken::class,
            'permission' => \App\Http\Middleware\EnsureUserPermission::class,
            'subscribed' => \App\Http\Middleware\CheckSubscription::class,
            'administrative' => \App\Http\Middleware\AdministrativeMiddleware::class,
            'delegate.permission' => \App\Http\Middleware\CheckDelegatePermission::class,
            'device.validate' => \App\Http\Middleware\ValidateDeviceBinding::class,
            'device.primary' => \App\Http\Middleware\EnsurePrimaryStudentDevice::class,
            'web.access' => \App\Http\Middleware\EnsureWebAccessEnabled::class,
        ]);
        $middleware->redirectGuestsTo(function ($request) {
            if ($request->expectsJson() || $request->is('api/*')) {
                return null;
            }
            return route('admin.login');
        });
        $middleware->redirectUsersTo(function () {
            $user = \Illuminate\Support\Facades\Auth::user();
            if ($user && $user->role) {
                return match ($user->preferredWorkspace()) {
                    \App\Enums\UserRole::ADMIN->value => route('admin.dashboard'),
                    \App\Enums\UserRole::ADMINISTRATIVE->value => route('administrative.dashboard'),
                    \App\Enums\UserRole::DOCTOR->value => route('doctor.dashboard'),
                    \App\Enums\UserRole::DELEGATE->value, \App\Enums\UserRole::PRACTICAL_DELEGATE->value => route('delegate.dashboard'),
                    \App\Enums\UserRole::STUDENT->value => route('student.dashboard'),
                    default => route('admin.login'),
                };
            }
            return route('admin.login');
        });
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })->create();
