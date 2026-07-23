<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\BaseController;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class RegisterController extends BaseController
{
    /**
     * Handle an API registration request.
     */
    public function register(Request $request)
    {
        $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'role' => ['required', Rule::in(['student', 'doctor', 'delegate'])],
            'gender' => ['required_if:role,student,delegate', 'nullable', Rule::in(['male', 'female'])],
            
            // Required for student, delegate & doctor
            'university_id' => ['required_if:role,student,delegate,doctor', 'nullable', 'exists:universities,id'],
            'college_id' => ['required_if:role,student,delegate,doctor', 'nullable', 'exists:colleges,id'],
            
            // Required ONLY for student & delegate
            'student_number' => ['required_if:role,student,delegate', 'nullable', 'string', 'unique:users,student_number'],
            'major_id' => ['required_if:role,student,delegate', 'nullable', 'exists:majors,id'],
            'level_id' => ['required_if:role,student,delegate', 'nullable', 'exists:levels,id'],
        ], [
            'name.required' => 'حقل الاسم الكامل مطلوب.',
            'name.max' => 'الاسم يجب ألا يتجاوز 255 حرفاً.',
            'email.required' => 'حقل البريد الإلكتروني مطلوب.',
            'email.email' => 'يرجى إدخال بريد إلكتروني صحيح.',
            'email.unique' => 'البريد الإلكتروني هذا مسجل مسبقاً، يرجى الاسترجاع أو استخدام بريد آخر.',
            'password.required' => 'حقل كلمة المرور مطلوب.',
            'password.min' => 'كلمة المرور يجب أن تتكون من 8 أحرف على الأقل.',
            'password.confirmed' => 'تأكيد كلمة المرور غير متطابق.',
            
            'role.in' => 'حدد نوع حساب صالح.',
            'student_number.required_if' => 'رقم القيد الجامعي مطلوب للطلاب والمندوبين.',
            'student_number.unique' => 'رقم القيد الجامعي هذا مسجل مسبقاً.',
            'university_id.required_if' => 'حقل الجامعة مطلوب لجميع الرتب.',
            'college_id.required_if' => 'حقل الكلية مطلوب لجميع الرتب.',
            'major_id.required_if' => 'حقل التخصص مطلوب.',
            'level_id.required_if' => 'حقل المستوى مطلوب.',
        ]);

        $userData = [
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => $request->role,
            'status' => 'pending', // Account requires admin approval
        ];

        // Shared fields for all roles
        $userData['university_id'] = $request->university_id;
        $userData['college_id'] = $request->college_id;

        // Specific academic fields for learners
        if (in_array($request->role, ['student', 'delegate'])) {
            $userData['student_number'] = $request->student_number;
            $userData['major_id'] = $request->major_id;
            $userData['level_id'] = $request->level_id;
            $userData['gender'] = $request->gender;
        }

        $user = User::create($userData);

        return $this->success(null, 'تم إرسال طلب إنشاء الحساب بنجاح. حسابك الآن قيد المراجعة وسنقوم بإعلامك فور الموافقة عليه.', 201);
    }
}
