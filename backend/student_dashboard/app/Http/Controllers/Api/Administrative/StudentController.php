<?php

namespace App\Http\Controllers\Api\Administrative;

use App\Enums\UserRole;
use App\Models\Academic\Level;
use App\Models\Academic\Major;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class StudentController extends AdministrativeApiController
{
    public function index(Request $request)
    {
        $college = $this->college();

        $query = User::where('college_id', $college->id)
            ->whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->with(['major:id,name', 'level:id,name,major_id', 'permissions:id,slug']);

        if ($request->filled('search')) {
            $query->where(function ($q) use ($request) {
                $q->where('name', 'like', "%{$request->search}%")
                    ->orWhere('email', 'like', "%{$request->search}%")
                    ->orWhere('student_number', 'like', "%{$request->search}%");
            });
        }

        if ($request->filled('major_id')) {
            $query->where('major_id', $request->integer('major_id'));
        }

        if ($request->filled('level_id')) {
            $query->where('level_id', $request->integer('level_id'));
        }

        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }

        $students = $query->latest()->paginate($request->integer('per_page', 15));
        $majors = Major::where('college_id', $college->id)->with('levels:id,name,major_id')->get();

        return $this->success([
            'students' => $students->items(),
            'pagination' => [
                'current_page' => $students->currentPage(),
                'last_page' => $students->lastPage(),
                'per_page' => $students->perPage(),
                'total' => $students->total(),
            ],
            'majors' => $majors,
        ]);
    }

    public function store(Request $request)
    {
        $college = $this->college();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'gender' => ['required', Rule::in(['male', 'female'])],
            'email' => 'required|string|email|max:255|unique:users',
            'student_number' => 'required|string|unique:users,student_number|max:50',
            'password' => 'required|string|min:8',
            'level_id' => [
                'required',
                Rule::exists('levels', 'id')->where(function ($query) use ($college) {
                    $query->whereIn('major_id', Major::where('college_id', $college->id)->pluck('id'));
                }),
            ],
        ]);

        $level = Level::with('major')->findOrFail($validated['level_id']);

        $student = User::create([
            'name' => $validated['name'],
            'gender' => $validated['gender'],
            'email' => $validated['email'],
            'student_number' => $validated['student_number'],
            'password' => Hash::make($validated['password']),
            'role' => UserRole::STUDENT,
            'level_id' => $level->id,
            'major_id' => $level->major_id,
            'college_id' => $college->id,
            'university_id' => $college->university_id,
            'status' => 'active',
        ]);

        return $this->success($student->load(['major:id,name', 'level:id,name']), 'تم إضافة الطالب بنجاح', 201);
    }

    public function show(User $student)
    {
        $this->ensureCollegeUser($student, ['student', 'delegate']);
        return $this->success($student->load(['major:id,name', 'level:id,name,major_id', 'permissions:id,slug']));
    }

    public function update(Request $request, User $student)
    {
        $this->ensureCollegeUser($student, ['student', 'delegate']);
        $college = $this->college();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'gender' => ['required', Rule::in(['male', 'female'])],
            'email' => 'required|string|email|max:255|unique:users,email,' . $student->id,
            'student_number' => 'required|string|max:50|unique:users,student_number,' . $student->id,
            'level_id' => [
                'required',
                Rule::exists('levels', 'id')->where(function ($query) use ($college) {
                    $query->whereIn('major_id', Major::where('college_id', $college->id)->pluck('id'));
                }),
            ],
            'password' => 'nullable|string|min:8',
        ]);

        $level = Level::findOrFail($validated['level_id']);

        $updateData = [
            'name' => $validated['name'],
            'gender' => $validated['gender'],
            'email' => $validated['email'],
            'student_number' => $validated['student_number'],
            'level_id' => $level->id,
            'major_id' => $level->major_id,
        ];

        if (!empty($validated['password'])) {
            $updateData['password'] = Hash::make($validated['password']);
        }

        $student->update($updateData);

        return $this->success($student->fresh()->load(['major:id,name', 'level:id,name']), 'تم تحديث بيانات الطالب بنجاح');
    }

    public function destroy(User $student)
    {
        $this->ensureCollegeUser($student, ['student', 'delegate']);
        $student->delete();
        return $this->success(null, 'تم حذف الطالب بنجاح');
    }
}
