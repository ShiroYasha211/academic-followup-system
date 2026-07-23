<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Enums\UserRole;
use App\Models\Academic\Major;
use App\Traits\LogsActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class DelegateController extends Controller
{
    use LogsActivity;

    /**
     * Display a listing of delegates.
     */
    public function index()
    {
        $delegates = User::where('role', UserRole::DELEGATE)
            ->with(['university', 'college', 'major', 'level'])
            ->latest()
            ->paginate(10);

        $universities = \App\Models\Academic\University::with('colleges.majors.levels')->get();

        return view('admin.users.delegates.index', compact('delegates', 'universities'));
    }

    /**
     * Store a newly created delegate.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'student_number' => 'required|string|max:50|unique:users',
            'gender' => ['required', Rule::in(['male', 'female'])],
            'password' => 'required|string|min:8',
            'level_id' => 'required|exists:levels,id',
        ], [
            'level_id.required' => 'يرجى اختيار المستوى الدراسي.',
            'email.unique' => 'البريد الإلكتروني مسجل مسبقاً.',
            'student_number.unique' => 'رقم القيد مسجل مسبقاً.'
        ]);

        $level = \App\Models\Academic\Level::with('major.college.university')->findOrFail($request->level_id);

        $delegate = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'student_number' => $request->student_number,
            'gender' => $request->gender,
            'password' => Hash::make($request->password),
            'role' => UserRole::DELEGATE,
            'level_id' => $level->id,
            'major_id' => $level->major_id,
            'college_id' => $level->major->college_id,
            'university_id' => $level->major->college->university_id,
            'status' => 'active',
        ]);

        $this->logCreate('Delegate', $delegate, "تم إضافة المندوب: {$delegate->name}");

        return redirect()->route('admin.delegates.index')
            ->with('success', "تم إضافة المندوب بنجاح.");
    }

    /**
     * Update delegate data.
     */
    public function update(Request $request, User $delegate)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,' . $delegate->id,
            'student_number' => 'required|string|max:50|unique:users,student_number,' . $delegate->id,
            'gender' => ['required', Rule::in(['male', 'female'])],
            'level_id' => 'required|exists:levels,id',
        ], [
            'level_id.required' => 'يرجى تحديد المستوى الذي يديره المندوب.',
            'email.unique' => 'البريد الإلكتروني مسجل مسبقاً.',
            'student_number.unique' => 'رقم القيد مسجل مسبقاً.'
        ]);

        $level = \App\Models\Academic\Level::with('major.college.university')->findOrFail($request->level_id);

        $updateData = [
            'name' => $request->name,
            'email' => $request->email,
            'student_number' => $request->student_number,
            'gender' => $request->gender,
            'level_id' => $level->id,
            'major_id' => $level->major_id,
            'college_id' => $level->major->college_id,
            'university_id' => $level->major->college->university_id,
        ];

        if ($request->filled('password')) {
            $request->validate(['password' => 'string|min:8']);
            $updateData['password'] = Hash::make($request->password);
        }

        $delegate->update($updateData);

        $this->logUpdate('Delegate', $delegate, "تم تعديل بيانات المندوب: {$delegate->name}");

        return redirect()->route('admin.delegates.index')
            ->with('success', 'تم تحديث بيانات المندوب بنجاح.');
    }

    /**
     * Delete delegate.
     */
    public function destroy(User $delegate)
    {
        if ($delegate->role !== UserRole::DELEGATE) {
            return back()->with('error', 'لا يمكن حذف هذا المستخدم من هنا.');
        }

        $this->logDelete('Delegate', $delegate, "تم حذف المندوب: {$delegate->name}");

        $delegate->forceDelete();
        return redirect()->route('admin.delegates.index')
            ->with('success', 'تم حذف المندوب بنجاح.');
    }
}
