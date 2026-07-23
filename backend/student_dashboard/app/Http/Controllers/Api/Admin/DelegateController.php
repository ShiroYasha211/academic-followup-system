<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\User;
use App\Enums\UserRole;
use App\Traits\LogsActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class DelegateController extends AdminApiController
{
    use LogsActivity;

    public function index(Request $request)
    {
        $query = User::where('role', UserRole::DELEGATE)
            ->with(['university', 'college', 'major', 'level'])
            ->latest();

        if ($request->search) {
            $query->where('name', 'like', "%{$request->search}%");
        }

        return $this->paginated($query->paginate($request->per_page ?? 15));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'student_number' => 'required|string|max:50|unique:users',
            'gender' => ['required', Rule::in(['male', 'female'])],
            'password' => 'required|string|min:8',
            'level_id' => 'required|exists:levels,id',
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
        ]);

        $this->logCreate('Delegate', $delegate, "تم إضافة المندوب: {$delegate->name}");
        return $this->success($delegate, 'تم إضافة المندوب بنجاح', 201);
    }

    public function update(Request $request, User $delegate)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $delegate->id,
            'student_number' => 'required|string|max:50|unique:users,student_number,' . $delegate->id,
            'gender' => ['required', Rule::in(['male', 'female'])],
            'level_id' => 'required|exists:levels,id',
        ]);

        $level = \App\Models\Academic\Level::with('major.college.university')->findOrFail($request->level_id);

        $data = [
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
            $data['password'] = Hash::make($request->password);
        }

        $delegate->update($data);
        $this->logUpdate('Delegate', $delegate, "تم تعديل بيانات المندوب: {$delegate->name}");
        return $this->success($delegate->fresh(), 'تم تحديث بيانات المندوب بنجاح');
    }

    public function show(User $delegate)
    {
        if ($delegate->role !== UserRole::DELEGATE) {
            return $this->error('المستخدم ليس مندوباً.', 404);
        }
        return $this->success($delegate->load(['university', 'college', 'major', 'level']));
    }

    public function destroy(User $delegate)
    {
        if ($delegate->role !== UserRole::DELEGATE) {
            return $this->error('المستخدم ليس مندوباً.', 404);
        }
        $this->logDelete('Delegate', $delegate, "تم حذف المندوب نهائياً عبر الـ API: {$delegate->name}");
        $delegate->forceDelete();
        return $this->success(null, 'تم حذف المندوب بنجاح واستئصال بياناته');
    }
}
