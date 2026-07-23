<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\User;
use App\Enums\UserRole;
use App\Traits\LogsActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class StudentController extends AdminApiController
{
    use LogsActivity;

    public function index(Request $request)
    {
        $query = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->with([
                'university',
                'college',
                'major',
                'level',
                'studentDevices' => fn ($query) => $query->latest('last_login_at')->latest(),
            ])
            ->latest();

        if ($request->search) {
            $query->where(function ($q) use ($request) {
                $q->where('name', 'like', "%{$request->search}%")
                    ->orWhere('student_number', 'like', "%{$request->search}%")
                    ->orWhere('email', 'like', "%{$request->search}%");
            });
        }
        if ($request->major_id) {
            $query->where('major_id', $request->major_id);
        }

        return $this->paginated($query->paginate($request->per_page ?? 15));
    }

    public function show(User $student)
    {
        return $this->success($student->load([
            'university',
            'college',
            'major',
            'level',
            'studentDevices' => fn ($query) => $query->latest('last_login_at')->latest(),
            'studentDeviceRequests' => fn ($query) => $query->latest(),
        ]));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'gender' => ['required', Rule::in(['male', 'female'])],
            'email' => 'required|email|unique:users',
            'student_number' => 'required|string|unique:users,student_number|max:50',
            'password' => 'required|string|min:8',
            'level_id' => 'required|exists:levels,id',
        ]);

        $level = \App\Models\Academic\Level::with('major.college.university')->findOrFail($request->level_id);

        $student = User::create([
            'name' => $request->name,
            'gender' => $request->gender,
            'email' => $request->email,
            'student_number' => $request->student_number,
            'password' => Hash::make($request->password),
            'role' => UserRole::STUDENT,
            'level_id' => $level->id,
            'major_id' => $level->major_id,
            'college_id' => $level->major->college_id,
            'university_id' => $level->major->college->university_id,
        ]);

        $this->logCreate('Student', $student, "تم تسجيل الطالب: {$student->name}");

        return $this->success($student, 'تم تسجيل الطالب بنجاح', 201);
    }

    public function update(Request $request, User $student)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'gender' => ['required', Rule::in(['male', 'female'])],
            'email' => 'required|email|unique:users,email,' . $student->id,
            'student_number' => 'required|string|max:50|unique:users,student_number,' . $student->id,
            'level_id' => 'required|exists:levels,id',
        ]);

        $level = \App\Models\Academic\Level::with('major.college.university')->findOrFail($request->level_id);

        $data = [
            'name' => $request->name,
            'gender' => $request->gender,
            'email' => $request->email,
            'student_number' => $request->student_number,
            'level_id' => $level->id,
            'major_id' => $level->major_id,
            'college_id' => $level->major->college_id,
            'university_id' => $level->major->college->university_id,
        ];

        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
        }

        $student->update($data);
        $this->logUpdate('Student', $student, "تم تعديل بيانات الطالب: {$student->name}");

        return $this->success($student->fresh(), 'تم تحديث بيانات الطالب بنجاح');
    }

    public function destroy(User $student)
    {
        if (!in_array($student->role, [UserRole::STUDENT, UserRole::DELEGATE])) {
            return $this->error('المستخدم ليس طالباً.', 422);
        }
        $this->logDelete('Student', $student, "تم حذف الطالب نهائياً من الـ API: {$student->name}");
        $student->forceDelete();
        return $this->success(null, 'تم حذف الطالب بنجاح واستئصال بياناته');
    }

    public function updatePermissions(Request $request, User $student)
    {
        if (!in_array($student->role, [UserRole::STUDENT, UserRole::DELEGATE])) {
            return $this->error('المستخدم ليس طالباً.', 422);
        }

        $request->validate([
            'permissions' => 'array',
            'permissions.*' => 'string|exists:permissions,slug'
        ]);

        $student->permissions()->detach();
        if ($request->has('permissions')) {
            $permissionIds = \App\Models\Permission::whereIn('slug', $request->permissions)->pluck('id');
            $student->permissions()->attach($permissionIds);
        }

        $this->logUpdate('StudentPermissions', $student, "تم تحديث صلاحيات الطالب عبر الـ API: {$student->name}");

        return $this->success($student->load('permissions'), 'تم تحديث صلاحيات الطالب بنجاح');
    }
}
