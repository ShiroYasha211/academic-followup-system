<?php

namespace App\Http\Controllers\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Enums\UserRole;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;

class StudentController extends Controller implements HasMiddleware
{
    /**
     * Get the middleware that should be assigned to the controller.
     */
    public static function middleware(): array
    {
        return [
            new Middleware('delegate.permission:students,create', only: ['create', 'store']),
            new Middleware('delegate.permission:students,update', only: ['edit', 'update']),
            new Middleware('delegate.permission:students,delete', only: ['destroy']),
        ];
    }

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $delegate = Auth::user();

        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->with(['university', 'college', 'major', 'level.terms.subjects.doctor'])
            ->latest()
            ->paginate(10);

        return view('delegate.students.index', compact('students'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        return view('delegate.students.create');
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $delegate = Auth::user();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'gender' => ['required', Rule::in(['male', 'female'])],
            'student_number' => 'required|string|max:20|unique:users',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'gender' => $validated['gender'],
            'email' => $this->generatedStudentEmail($validated['student_number']),
            'password' => Hash::make($validated['student_number']),
            'role' => UserRole::STUDENT,
            'student_number' => $validated['student_number'],
            'university_id' => $delegate->university_id,
            'college_id' => $delegate->college_id,
            'major_id' => $delegate->major_id,
            'level_id' => $delegate->level_id,
        ]);

        return redirect()->route('delegate.students.index')
            ->with('success', 'تم إضافة الطالب بنجاح.');
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(User $student)
    {
        $delegate = Auth::user();

        // Enforce Scope
        if ($student->major_id != $delegate->major_id || $student->level_id != $delegate->level_id) {
            abort(403);
        }

        return view('delegate.students.edit', compact('student'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, User $student)
    {
        $delegate = Auth::user();
        if ($student->major_id != $delegate->major_id || $student->level_id != $delegate->level_id) {
            abort(403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'gender' => ['required', Rule::in(['male', 'female'])],
            'student_number' => ['required', 'string', 'max:20', Rule::unique('users')->ignore($student->id)],
        ]);

        $data = [
            'name' => $validated['name'],
            'gender' => $validated['gender'],
            'student_number' => $validated['student_number'],
        ];

        if (str_ends_with((string) $student->email, '@students.moeen.local')) {
            $data['email'] = $this->generatedStudentEmail($validated['student_number']);
        }

        $student->update($data);

        return redirect()->route('delegate.students.index')
            ->with('success', 'تم تحديث بيانات الطالب بنجاح.');
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(User $student)
    {
        $delegate = Auth::user();
        if ($student->major_id != $delegate->major_id || $student->level_id != $delegate->level_id) {
            abort(403);
        }

        $student->delete();

        return redirect()->route('delegate.students.index')
            ->with('success', 'تم حذف الطالب بنجاح.');
    }

    /**
     * Download CSV Template for Bulk Import
     */
    public function downloadTemplate()
    {
        $headers = [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="students_template.csv"',
        ];

        $callback = function () {
            $file = fopen('php://output', 'w');
            // Add BOM for UTF-8 Arabic support in Excel
            fprintf($file, chr(0xEF) . chr(0xBB) . chr(0xBF));
            fputcsv($file, ['Name', 'Student Number', 'Gender']);
            fputcsv($file, ['Ahmed Ali', '2023001', 'male']);
            fputcsv($file, ['Sara Ali', '2023002', 'female']);
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    /**
     * Import Students from CSV
     */
    public function import(Request $request)
    {
        $request->validate([
            'csv_file' => 'required|file|mimes:csv,txt|max:2048',
        ]);

        $delegate = Auth::user();
        $file = $request->file('csv_file');

        $successCount = 0;
        $errors = [];

        if (($handle = fopen($file->getRealPath(), "r")) !== FALSE) {
            // Read header to skip it
            $header = fgetcsv($handle, 1000, ",");

            // Clean BOM if exists from the first column header
            if (isset($header[0])) {
                $header[0] = preg_replace('/[\x00-\x1F\x80-\xFF]/', '', $header[0]);
            }

            $rowNumber = 1;
            while (($data = fgetcsv($handle, 1000, ",")) !== FALSE) {
                $rowNumber++;

                // Skip completely empty rows
                if (empty(array_filter($data))) {
                    continue;
                }

                // Ensure we have exactly 3 columns (Name, Student Number, Gender)
                if (count($data) < 3) {
                    $errors[] = "السطر $rowNumber: أعمدة ناقصة (مطلوب: الاسم، الإيميل، رقم القيد).";
                    continue;
                }

                $name = trim($data[0]);
                $studentNumber = trim($data[1]);
                $gender = $this->normalizeGender($data[2] ?? '');

                // Validate empty fields
                if (empty($name) || empty($studentNumber) || empty($gender)) {
                    $errors[] = "السطر $rowNumber: بيانات ناقصة للجندي ($name / $studentNumber).";
                    continue;
                }

                // Validate Email uniqueness
                // Validate Student Number uniqueness
                if (User::where('student_number', $studentNumber)->exists()) {
                    $errors[] = "السطر $rowNumber: رقم القيد مكرر ($studentNumber).";
                    continue;
                }

                try {
                    User::create([
                        'name' => $name,
                        'gender' => $gender,
                        'email' => $this->generatedStudentEmail($studentNumber),
                        'password' => Hash::make($studentNumber), // Default password is student number
                        'role' => UserRole::STUDENT,
                        'student_number' => $studentNumber,
                        'university_id' => $delegate->university_id,
                        'college_id' => $delegate->college_id,
                        'major_id' => $delegate->major_id,
                        'level_id' => $delegate->level_id,
                    ]);
                    $successCount++;
                } catch (\Exception $e) {
                    $errors[] = "السطر $rowNumber: خطأ غير متوقع أثناء الحفظ ({$e->getMessage()}).";
                }
            }
            fclose($handle);
        }

        $report = [
            'success_count' => $successCount,
            'errors' => $errors,
        ];

        return redirect()->route('delegate.students.index')
            ->with('import_report', $report)
            ->with('success', "اكتملت عملية الاستيراد. تم إضافة $successCount طالب.");
    }

    /**
     * Update permissions for a specific student.
     */
    public function updatePermissions(Request $request, User $student)
    {
        $delegate = Auth::user();
        if ($student->major_id != $delegate->major_id || $student->level_id != $delegate->level_id) {
            abort(403);
        }

        // Validate permissions exists
        $request->validate([
            'permissions' => 'array',
            'permissions.*' => 'string|exists:permissions,slug'
        ]);

        // Sync permissions
        $student->permissions()->detach();
        if ($request->has('permissions')) {
            foreach ($request->permissions as $slug) {
                $permission = \App\Models\Permission::where('slug', $slug)->first();
                if ($permission) {
                    $student->permissions()->attach($permission->id);
                }
            }
        }

        return back()->with('success', 'تم تحديث صلاحيات الطالب بنجاح.');
    }

    private function generatedStudentEmail(string $studentNumber): string
    {
        $safeNumber = trim(preg_replace('/[^A-Za-z0-9._-]+/', '-', $studentNumber), '-');
        return 'student-' . strtolower($safeNumber ?: uniqid()) . '@students.moeen.local';
    }

    private function normalizeGender(string $gender): ?string
    {
        $value = trim(mb_strtolower($gender));
        return match ($value) {
            'male', 'm', 'ذكر' => 'male',
            'female', 'f', 'أنثى', 'انثى' => 'female',
            default => null,
        };
    }
}
