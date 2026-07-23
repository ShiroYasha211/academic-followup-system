<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Enums\UserRole;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * يضيف مستخدم‑admin تجريبي لتستطيع اختبار
     * عملية الدخول إلى لوحة الإدارة.
     */
    public function run(): void
    {
        // إذا كان هناك حساب admin بنفس البريد، لا نعيد إنشائه
        $email = 'admin@example.com';

        if (User::where('email', $email)->exists()) {
            $this->command->info('Admin user already exists – skipping.');
            return;
        }

        User::create([
            'name'     => 'Admin User',
            'email'    => $email,
            // كلمة المرور:  secret123  (يمكنك تعديلها بعد الاختبار)
            'password' => Hash::make('secret123'),
            'role'     => UserRole::ADMIN,
        ]);

        $this->command->info('Admin user created (email: '.$email.', password: secret123).');
    }
}