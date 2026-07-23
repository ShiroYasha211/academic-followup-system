<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Http\Controllers\Api\Delegate\DelegateApiController;
use App\Models\User;
use App\Enums\UserRole;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;

class StudentController extends DelegateApiController implements HasMiddleware
{
    /**
     * Get the middleware that should be assigned to the controller.
     */
    public static function middleware(): array
    {
        return [
            new Middleware('delegate.permission:students,create', only: ['store', 'import']),
            new Middleware('delegate.permission:students,update', only: ['update']),
            new Middleware('delegate.permission:students,delete', only: ['destroy']),
        ];
    }
    /**
     * Display a listing of students in the delegate's batch.
     */
    public function index(Request $request)
    {
        $delegate = $request->user();
        $search = $request->query('query');

        $baseQuery = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id);

        $maleCount = (clone $baseQuery)->where('gender', 'male')->count();
        $activeCount = (clone $baseQuery)->where('status', 'active')->count();

        $query = $baseQuery->when($search, function ($q) use ($search) {
            $q->where(function ($sq) use ($search) {
                $sq->where('name', 'like', "%$search%")
                    ->orWhere('student_number', 'like', "%$search%")
                    ->orWhere('email', 'like', "%$search%");
            });
        })
            ->with(['university:id,name', 'college:id,name', 'major:id,name', 'level:id,name'])
            ->latest();

        if ($request->query('all')) {
            $data = $query->get();
            $response = ['data' => $data];
        } else {
            $response = $query->paginate(15)->toArray();
        }

        $response['male_count'] = $maleCount;
        $response['active_count'] = $activeCount;

        return $this->success($response, 'تم جلب قائمة الطلاب بنجاح');
    }

    /**
     * Store a newly created student in the delegate's batch.
     */
    public function store(Request $request)
    {
        $delegate = $request->user();

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
            'status' => 'active', // Since it's added by the delegate of the batch
        ]);

        return $this->success($user, 'تم إضافة الطالب بنجاح', 201);
    }

    /**
     * Update the specified student.
     */
    public function update(Request $request, User $student)
    {
        $delegate = $request->user();

        // Enforce Scope
        if ($student->major_id != $delegate->major_id || $student->level_id != $delegate->level_id) {
            return $this->error('غير مصرح لك بتعديل هذا الطالب', 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'gender' => ['required', Rule::in(['male', 'female'])],
            'student_number' => ['required', 'string', 'max:20', Rule::unique('users')->ignore($student->id)],
            'status' => ['nullable', Rule::in(['active', 'inactive', 'pending'])],
        ]);

        $data = [
            'name' => $validated['name'],
            'gender' => $validated['gender'],
            'student_number' => $validated['student_number'],
        ];

        if (str_ends_with((string) $student->email, '@students.moeen.local')) {
            $data['email'] = $this->generatedStudentEmail($validated['student_number']);
        }

        if (isset($validated['status'])) {
            $data['status'] = $validated['status'];
        }

        $student->update($data);

        return $this->success($student, 'تم تحديث بيانات الطالب بنجاح');
    }

    /**
     * Remove the specified student.
     */
    public function destroy(Request $request, User $student)
    {
        $delegate = $request->user();

        // Enforce Scope
        if ($student->major_id != $delegate->major_id || $student->level_id != $delegate->level_id) {
            return $this->error('غير مصرح لك بحذف هذا الطالب', 403);
        }

        $student->delete();

        return $this->success(null, 'تم حذف الطالب بنجاح');
    }

    /**
     * Import Students from CSV
     */
    public function import(Request $request)
    {
        $request->validate([
            'csv_file' => 'required|file|mimes:csv,txt|max:2048',
        ]);

        $delegate = $request->user();
        $file = $request->file('csv_file');

        $successCount = 0;
        $errors = [];

        if (($handle = fopen($file->getRealPath(), "r")) !== FALSE) {
            $header = fgetcsv($handle, 1000, ",");

            // Clean BOM
            if (isset($header[0])) {
                $header[0] = preg_replace('/[\x00-\x1F\x80-\xFF]/', '', $header[0]);
            }

            $rowNumber = 1;
            while (($data = fgetcsv($handle, 1000, ",")) !== FALSE) {
                $rowNumber++;

                if (empty(array_filter($data)))
                    continue;

                if (count($data) < 3) {
                    $errors[] = "السطر $rowNumber: أعمدة ناقصة.";
                    continue;
                }

                $name = trim($data[0]);
                $studentNumber = trim($data[1]);
                $gender = $this->normalizeGender($data[2] ?? '');

                if (empty($name) || empty($studentNumber) || empty($gender)) {
                    $errors[] = "السطر $rowNumber: بيانات ناقصة ($name).";
                    continue;
                }

                if (User::where('student_number', $studentNumber)->exists()) {
                    $errors[] = "السطر $rowNumber: رقم القيد مسجل مسبقاً ($studentNumber).";
                    continue;
                }

                try {
                    User::create([
                        'name' => $name,
                        'gender' => $gender,
                        'email' => $this->generatedStudentEmail($studentNumber),
                        'password' => Hash::make($studentNumber),
                        'role' => UserRole::STUDENT,
                        'student_number' => $studentNumber,
                        'university_id' => $delegate->university_id,
                        'college_id' => $delegate->college_id,
                        'major_id' => $delegate->major_id,
                        'level_id' => $delegate->level_id,
                        'status' => 'active',
                    ]);
                    $successCount++;
                } catch (\Exception $e) {
                    $errors[] = "السطر $rowNumber: خطأ ({$e->getMessage()}).";
                }
            }
            fclose($handle);
        }

        return $this->success([
            'success_count' => $successCount,
            'errors' => $errors,
        ], "اكتمل الاستيراد. تم إضافة $successCount طالب.");
    }

    /**
     * Get permission status for a student.
     */
    public function permissions(Request $request, User $student)
    {
        $delegate = $request->user();

        // Enforce Scope
        if ($student->major_id != $delegate->major_id || $student->level_id != $delegate->level_id) {
            return $this->error('غير مصرح لك بالوصول', 403);
        }

        return $this->success([
            'student_id' => $student->id,
            'student_name' => $student->name,
            'can_upload_library' => $student->hasPermission('upload_shared_library'),
            'available_permissions' => [
                [
                    'slug' => 'upload_shared_library',
                    'name' => 'الرفع للمكتبة المشتركة',
                    'description' => 'يسمح للطالب برفع ملفات ومحاضرات للمكتبة العامة للمواد.'
                ]
            ]
        ], 'تم جلب حالة الصلاحيات بنجاح');
    }

    /**
     * Update permissions for a specific student.
     * Restricted to library_upload only.
     */
    public function updatePermissions(Request $request, User $student)
    {
        $delegate = $request->user();

        // Enforce Scope
        if ($student->major_id != $delegate->major_id || $student->level_id != $delegate->level_id) {
            return $this->error('غير مصرح لك بتعديل هذا الطالب', 403);
        }

        $validated = $request->validate([
            'permissions' => 'array',
            'permissions.*' => 'string|in:upload_shared_library'
        ], [
            'permissions.*.in' => 'لا يمكنك منح هذه الصلاحية. المندوب مخول بمنح صلاحية الرفع للمكتبة فقط.'
        ]);

        // Sync (only for the allowed restricted set)
        $allowedSlugs = ['upload_shared_library'];

        // Remove currently held allowed permissions to refresh
        $student->permissions()->detach(\App\Models\Permission::whereIn('slug', $allowedSlugs)->pluck('id'));

        // Attach requested
        if (!empty($validated['permissions'])) {
            foreach ($validated['permissions'] as $slug) {
                $permission = \App\Models\Permission::where('slug', $slug)->first();
                if ($permission) {
                    $student->permissions()->syncWithoutDetaching([$permission->id]);
                }
            }
        }

        return $this->success(null, 'تم تحديث صلاحيات الطالب بنجاح');
    }

    /**
     * Download the student import template.
     */
    public function template()
    {
        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="students_template.csv"',
        ];

        $callback = function () {
            $file = fopen('php://output', 'w');
            // Write UTF-8 BOM for Excel compatibility
            fputs($file, chr(0xEF) . chr(0xBB) . chr(0xBF));
            fputcsv($file, ['Name', 'Student Number', 'Gender']);
            fputcsv($file, ['Ahmed Ali', '12345678', 'male']);
            fputcsv($file, ['Sara Ali', '12345679', 'female']);
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
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
