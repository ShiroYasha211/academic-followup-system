<?php

namespace App\Http\Controllers\Administrative;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Enums\UserRole;
use App\Models\Academic\Major;
use App\Models\Academic\Level;
use App\Traits\LogsActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class StudentController extends Controller
{
    use LogsActivity;

    /**
     * Display a listing of students within the admin's college.
     */
    public function index()
    {
        $college = auth()->user()->college;
        
        if (!$college) {
            abort(403, 'حسابك غير مرتبط بكلية. يرجى التواصل مع مدير النظام.');
        }

        $students = User::where('college_id', $college->id)
            ->whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->with(['major', 'level.terms.subjects.doctor', 'permissions'])
            ->latest()
            ->paginate(15);

        // Fetch majors for the college to populate level selection in UI
        $majors = Major::where('college_id', $college->id)
            ->with('levels')
            ->get();

        return view('administrative.students.index', compact('students', 'majors', 'college'));
    }

    /**
     * Store a newly created student.
     */
    public function store(Request $request)
    {
        $college = auth()->user()->college;

        $request->validate([
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
        ], [
            'student_number.unique' => 'الرقم الجامعي مسجل مسبقاً.',
            'level_id.required' => 'يرجى تحديد المستوى الدراسي.',
            'level_id.exists' => 'المستوى الدراسي المحدد غير صالح أو لا ينتمي لكليتك.',
            'email.unique' => 'البريد الإلكتروني مسجل مسبقاً.'
        ]);

        $level = Level::with('major')->findOrFail($request->level_id);

        $student = User::create([
            'name' => $request->name,
            'gender' => $request->gender,
            'email' => $request->email,
            'student_number' => $request->student_number,
            'password' => Hash::make($request->password),
            'role' => UserRole::STUDENT,
            'level_id' => $level->id,
            'major_id' => $level->major_id,
            'college_id' => $college->id,
            'university_id' => $college->university_id,
            'status' => 'active', // Default to active for direct admin creation
        ]);

        $this->logCreate('Student', $student, "تم تسجيل الطالب: {$student->name} بواسطة مسؤول الكلية");

        return redirect()->route('administrative.students.index')
            ->with('success', 'تم تسجيل الطالب بنجاح.');
    }

    /**
     * Update the specified student.
     */
    public function update(Request $request, User $student)
    {
        $college = auth()->user()->college;

        // Ensure student belongs to this college
        if ($student->college_id !== $college->id) {
            abort(403);
        }

        $request->validate([
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
        ]);

        $level = Level::findOrFail($request->level_id);

        $updateData = [
            'name' => $request->name,
            'gender' => $request->gender,
            'email' => $request->email,
            'student_number' => $request->student_number,
            'level_id' => $level->id,
            'major_id' => $level->major_id,
        ];

        if ($request->filled('password')) {
            $request->validate(['password' => 'string|min:8']);
            $updateData['password'] = Hash::make($request->password);
        }

        $student->update($updateData);

        $this->logUpdate('Student', $student, "تم تعديل بيانات الطالب: {$student->name} بواسطة مسؤول الكلية");

        return redirect()->route('administrative.students.index')
            ->with('success', 'تم تحديث بيانات الطالب بنجاح.');
    }

    /**
     * Remove the specified student.
     */
    public function destroy(User $student)
    {
        $college = auth()->user()->college;

        if ($student->college_id !== $college->id || !in_array($student->role->value, ['student', 'delegate'])) {
            return back()->with('error', 'لا يمكن حذف هذا المستخدم.');
        }

        $this->logDelete('Student', $student, "تم حذف الطالب: {$student->name} بواسطة مسؤول الكلية");

        $student::where('id', $student->id)->delete(); // Use where to ensure soft delete if active
        
        return redirect()->route('administrative.students.index')
            ->with('success', 'تم حذف الطالب بنجاح.');
    }

}
