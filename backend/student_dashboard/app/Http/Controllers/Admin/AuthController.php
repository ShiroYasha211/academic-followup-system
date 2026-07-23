<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Support\WebAccessGate;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AuthController extends Controller
{
    /**
     * إظهار نموذج تسجيل الدخول للمدير.
     */
    public function showLoginForm()
    {
        // نستخدم view باسم admin.login (سننشئه لاحقاً)
        return view('admin.login');
    }

    /**
     * معالجة طلب تسجيل الدخول.
     */
    public function login(Request $request)
    {
        // التحقق من البيانات المدخلة
        $credentials = $request->validate([
            'email'    => ['required', 'email'],
            'password' => ['required'],
        ], [
            'email.required' => 'حقل البريد الإلكتروني مطلوب.',
            'email.email' => 'يرجى إدخال بريد إلكتروني صحيح.',
            'password.required' => 'حقل كلمة المرور مطلوب.',
        ]);

        // Rate limiting: 5 محاولات كل دقيقة
        $throttleKey = 'login|' . $request->ip();
        if (\Illuminate\Support\Facades\RateLimiter::tooManyAttempts($throttleKey, 5)) {
            $seconds = \Illuminate\Support\Facades\RateLimiter::availableIn($throttleKey);
            return back()->withErrors([
                'email' => "محاولات كثيرة جداً. حاول مرة أخرى بعد {$seconds} ثانية.",
            ])->withInput($request->only('email'));
        }

        // محاولة تسجيل الدخول
        $remember = $request->boolean('remember');
        if (Auth::attempt($credentials, $remember)) {
            $user = Auth::user();

            // التحقق من حالة الحساب (يمنع الدخول إذا كان قيد المراجعة أو غير نشط)
            if ($user->status === 'pending') {
                Auth::logout();
                return back()->withErrors([
                    'email' => 'حسابك قيد المراجعة. يرجى الانتظار حتى يتم اعتماده من الإدارة.',
                ])->withInput($request->only('email'));
            }

            if ($user->status === 'inactive') {
                Auth::logout();
                return back()->withErrors([
                    'email' => 'حسابك غير نشط. يرجى مراجعة إدارة النظام.',
                ])->withInput($request->only('email'));
            }

            if (! WebAccessGate::canAccessWeb($user)) {
                $message = WebAccessGate::closedMessage();

                Auth::logout();

                $request->session()->invalidate();
                $request->session()->regenerateToken();

                return back()->withErrors([
                    'email' => $message,
                ])->withInput($request->only('email'));
            }

            \Illuminate\Support\Facades\RateLimiter::clear($throttleKey);
            $request->session()->regenerate();

            // تسجيل نشاط تسجيل الدخول
            ActivityLog::log(
                action: 'login',
                modelType: 'User',
                modelId: $user->id,
                modelName: $user->name,
                description: "تسجيل دخول: {$user->name} ({$user->role->value})"
            );

            return match ($user->preferredWorkspace()) {
                'admin' => redirect()->intended(route('admin.dashboard')),
                'doctor' => redirect()->intended(route('doctor.dashboard')),
                'delegate' => redirect()->intended(route('delegate.dashboard')),
                'practical_delegate' => redirect()->intended(route('delegate.dashboard')),
                'student' => redirect()->intended(route('student.dashboard')),
                'administrative' => redirect()->intended(route('administrative.dashboard')),
            };
        }

        // تسجيل المحاولة الفاشلة
        \Illuminate\Support\Facades\RateLimiter::hit($throttleKey, 60);

        // فشل المصادقة
        return back()->withErrors([
            'email' => 'بيانات الدخول غير صحيحة.',
        ])->withInput($request->only('email'));
    }

    /**
     * تسجيل الخروج للمدير.
     */
    public function logout(Request $request)
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        if ($user) {
            // تسجيل نشاط تسجيل الخروج
            ActivityLog::log(
                action: 'logout',
                modelType: 'User',
                modelId: $user->id,
                modelName: $user->name,
                description: "تسجيل خروج: {$user->name}"
            );
        }

        Auth::logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login');
    }
}
