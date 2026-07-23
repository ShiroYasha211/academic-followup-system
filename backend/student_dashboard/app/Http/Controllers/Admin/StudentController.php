<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Enums\UserRole;
use App\Models\Academic\Major;
use App\Models\StudentDevice;
use App\Models\StudentDeviceRequest;
use App\Traits\LogsActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class StudentController extends Controller
{
    use LogsActivity;

    /**
     * عرض قائمة الطلاب.
     */
    public function index(Request $request)
    {
        $search = $request->query('search');
        $deviceStatus = $request->query('device_status');

        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])
            ->when($search, function ($query) use ($search) {
                $query->where(function ($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('email', 'like', "%{$search}%")
                      ->orWhere('student_number', 'like', "%{$search}%");
                });
            })
            ->when($deviceStatus === 'has_devices', fn ($query) => $query->whereHas('studentDevices'))
            ->when($deviceStatus === 'no_devices', fn ($query) => $query->whereDoesntHave('studentDevices'))
            ->with([
                'university',
                'college',
                'major',
                'level.terms.subjects.doctor',
                'permissions',
                'studentDevices' => fn ($query) => $query->latest('last_login_at')->latest(),
            ])
            ->latest()
            ->paginate(10)
            ->withQueryString();

        // Fetch Universities for the Create Form dropdown
        $universities = \App\Models\Academic\University::with('colleges.majors.levels')->get();

        // Fetch Delegates keyed by level_id to easily find the delegate for a student's level
        $delegates = User::where('role', UserRole::DELEGATE)->get()->keyBy('level_id');

        return view('admin.users.students.index', compact('students', 'universities', 'delegates'));
    }

    /**
     * عرض صفحة إضافـة طالب.
     */
    public function create()
    {
        $majors = Major::with(['college', 'levels'])->get();
        return view('admin.users.students.create', compact('majors'));
    }

    /**
     * تخزين طالب جديد.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'gender' => ['required', Rule::in(['male', 'female'])],
            'email' => 'required|string|email|max:255|unique:users',
            'student_number' => 'required|string|unique:users,student_number|max:50',
            'password' => 'required|string|min:8',
            'level_id' => 'required|exists:levels,id',
        ], [
            'student_number.unique' => 'الرقم الجامعي مسجل مسبقاً.',
            'level_id.required' => 'يرجى تحديد المستوى الدراسي.',
            'email.unique' => 'البريد الإلكتروني مسجل مسبقاً.'
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

        return redirect()->route('admin.students.index')
            ->with('success', 'تم تسجيل الطالب بنجاح.');
    }

    /**
     * تحديث بيانات الطالب.
     */
    public function update(Request $request, User $student)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'gender' => ['required', Rule::in(['male', 'female'])],
            'email' => 'required|string|email|max:255|unique:users,email,' . $student->id,
            'student_number' => 'required|string|max:50|unique:users,student_number,' . $student->id,
            'level_id' => 'required|exists:levels,id',
        ]);

        $level = \App\Models\Academic\Level::with('major.college.university')->findOrFail($request->level_id);

        $updateData = [
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
            $request->validate(['password' => 'string|min:8']);
            $updateData['password'] = Hash::make($request->password);
        }

        $student->update($updateData);

        $this->logUpdate('Student', $student, "تم تعديل بيانات الطالب: {$student->name}");

        return redirect()->route('admin.students.index')
            ->with('success', 'تم تحديث بيانات الطالب بنجاح.');
    }

    /**
     * حذف طالب.
     */
    public function destroy(User $student)
    {
        if (!in_array($student->role, [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])) {
            return back()->with('error', 'لا يمكن حذف هذا المستخدم من قائمة الطلاب.');
        }

        $this->logDelete('Student', $student, "تم حذف الطالب: {$student->name}");

        $student->forceDelete();
        return redirect()->route('admin.students.index')
            ->with('success', 'تم حذف الطالب بنجاح.');
    }

    /**
     * تحديث صلاحيات الطالب.
     */
    public function updatePermissions(Request $request, User $student)
    {
        $request->validate([
            'permissions' => 'array',
            'permissions.*' => 'string|exists:permissions,slug'
        ]);

        $student->permissions()->detach();
        if ($request->has('permissions')) {
            foreach ($request->permissions as $slug) {
                $permission = \App\Models\Permission::where('slug', $slug)->first();
                if ($permission) {
                    $student->permissions()->attach($permission->id);
                }
            }
        }

        $this->logUpdate('StudentPermissions', $student, "تم تحديث صلاحيات الطالب: {$student->name}");

        return back()->with('success', 'تم تحديث صلاحيات الطالب بنجاح.');
    }

    /**
     * إعادة تعيين أجهزة مجموعة من الطلاب.
     */
    public function bulkResetDevices(Request $request)
    {
        $validated = $request->validate([
            'student_ids' => 'required|array|min:1',
            'student_ids.*' => 'integer|exists:users,id',
        ]);

        $students = User::whereIn('id', $validated['student_ids'])
            ->whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])
            ->withCount('studentDevices')
            ->get();

        if ($students->isEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'لم يتم العثور على طلاب صالحين لإعادة تعيين أجهزتهم.',
            ], 422);
        }

        $studentIds = $students->pluck('id');
        $deletedDevicesCount = StudentDevice::whereIn('student_id', $studentIds)->count();
        StudentDevice::whereIn('student_id', $studentIds)->delete();

        foreach ($students as $student) {
            $this->logUpdate('StudentDevices', $student, "تم إعادة تعيين أجهزة الطالب ضمن إجراء جماعي: {$student->name}");
        }

        return response()->json([
            'success' => true,
            'message' => "تم إلغاء ربط الأجهزة لـ {$students->count()} حساب، وعدد الأجهزة المحذوفة {$deletedDevicesCount}.",
            'students_count' => $students->count(),
            'deleted_devices_count' => $deletedDevicesCount,
        ]);
    }

    /**
     * إعادة تعيين أجهزة الطالب (حذف الأجهزة المرتبطة).
     */
    public function resetDevices(User $student)
    {
        if (!in_array($student->role, [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])) {
            if (request()->expectsJson() || request()->ajax()) {
                return response()->json(['success' => false, 'message' => 'لا يمكن تعديل أجهزة هذا المستخدم.']);
            }
            return back()->with('error', 'لا يمكن تعديل أجهزة هذا المستخدم.');
        }

        $student->studentDevices()->delete();

        $this->logUpdate('StudentDevices', $student, "تم إعادة تعيين أجهزة الطالب: {$student->name}");

        if (request()->expectsJson() || request()->ajax()) {
            return response()->json([
                'success' => true,
                'message' => 'تم إعادة تعيين أجهزة الطالب بنجاح، ويمكنه الآن تسجيل الدخول من جهاز جديد.',
                'allowed_secondary_devices' => $student->allowed_secondary_devices,
                'secondary_devices_count' => 0,
                'devices' => [],
            ]);
        }

        return back()->with('success', 'تم إعادة تعيين أجهزة الطالب بنجاح، ويمكنه الآن تسجيل الدخول من جهاز جديد.');
    }

    /**
     * فتح مساحة لجهاز فرعي جديد.
     */
    public function openDeviceSlot(User $student)
    {
        if (!in_array($student->role, [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])) {
            if (request()->expectsJson() || request()->ajax()) {
                return response()->json(['success' => false, 'message' => 'لا يمكن تعديل هذا المستخدم.']);
            }
            return back()->with('error', 'لا يمكن تعديل هذا المستخدم.');
        }

        $student->increment('allowed_secondary_devices');

        $this->logUpdate('StudentDevices', $student, "تم فتح مساحة لجهاز فرعي جديد للطالب: {$student->name}");

        if (request()->expectsJson() || request()->ajax()) {
            return response()->json([
                'success' => true,
                'message' => 'تم فتح مساحة للجهاز الفرعي بنجاح.',
                'allowed_secondary_devices' => $student->allowed_secondary_devices,
                'secondary_devices_count' => $student->studentDevices()->where('device_type', StudentDevice::TYPE_SECONDARY)->count(),
                'devices' => $this->getStudentDevicesArray($student),
            ]);
        }

        return back()->with('success', 'تم فتح مساحة للجهاز الفرعي بنجاح، يمكن للطالب الآن ربطه بمجرد تسجيل الدخول منه.');
    }

    /**
     * إلغاء مساحة جهاز فرعي غير مستخدمة.
     */
    public function closeDeviceSlot(User $student)
    {
        if (!in_array($student->role, [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])) {
            if (request()->expectsJson() || request()->ajax()) {
                return response()->json(['success' => false, 'message' => 'لا يمكن تعديل هذا المستخدم.']);
            }
            return back()->with('error', 'لا يمكن تعديل هذا المستخدم.');
        }

        $secondaryDevicesCount = $student->studentDevices()->where('device_type', StudentDevice::TYPE_SECONDARY)->count();

        if ($student->allowed_secondary_devices <= $secondaryDevicesCount) {
            if (request()->expectsJson() || request()->ajax()) {
                return response()->json(['success' => false, 'message' => 'لا يمكن إلغاء مساحة فرعية مستخدمة بالفعل. يرجى حذف الجهاز أولاً.']);
            }
            return back()->with('error', 'لا يمكن إلغاء مساحة فرعية مستخدمة بالفعل. يرجى حذف الجهاز أولاً.');
        }

        if ($student->allowed_secondary_devices > 0) {
            $student->decrement('allowed_secondary_devices');
        }

        $this->logUpdate('StudentDevices', $student, "تم إلغاء مساحة جهاز فرعي غير مستخدمة للطالب: {$student->name}");

        if (request()->expectsJson() || request()->ajax()) {
            return response()->json([
                'success' => true,
                'message' => 'تم إلغاء المساحة الفرعية الشاغرة بنجاح.',
                'allowed_secondary_devices' => $student->allowed_secondary_devices,
                'secondary_devices_count' => $student->studentDevices()->where('device_type', StudentDevice::TYPE_SECONDARY)->count(),
                'devices' => $this->getStudentDevicesArray($student),
            ]);
        }

        return back()->with('success', 'تم إلغاء المساحة الفرعية الشاغرة بنجاح.');
    }

    /**
     * تعديل بيانات وصلاحية جهاز الطالب.
     */
    public function updateDevice(Request $request, StudentDevice $device)
    {
        $request->validate([
            'is_active' => 'required|boolean',
            'device_type' => 'required|in:primary,secondary',
            'is_temporary' => 'required|boolean',
            'expires_at' => 'nullable|date',
        ]);

        $student = $device->student;

        // If setting this device to primary, demote any other primary device for this user
        if ($request->device_type === StudentDevice::TYPE_PRIMARY) {
            $student->studentDevices()
                ->where('id', '!=', $device->id)
                ->where('device_type', StudentDevice::TYPE_PRIMARY)
                ->update([
                    'device_type' => StudentDevice::TYPE_SECONDARY,
                    'is_primary' => false,
                ]);
        }

        $device->update([
            'is_active' => (bool)$request->is_active,
            'device_type' => $request->device_type,
            'is_primary' => $request->device_type === StudentDevice::TYPE_PRIMARY,
            'is_temporary' => (bool)$request->is_temporary,
            'expires_at' => $request->is_temporary ? $request->expires_at : null,
        ]);

        $this->logUpdate('StudentDevices', $student, "تم تعديل إعدادات الجهاز ({$device->device_name}) للطالب: {$student->name}");

        if ($request->expectsJson() || $request->ajax()) {
            return response()->json([
                'success' => true,
                'message' => 'تم تحديث إعدادات وصلاحية الجهاز بنجاح.',
                'allowed_secondary_devices' => $student->allowed_secondary_devices,
                'secondary_devices_count' => $student->studentDevices()->where('device_type', StudentDevice::TYPE_SECONDARY)->count(),
                'devices' => $this->getStudentDevicesArray($student),
            ]);
        }

        return back()->with('success', 'تم تحديث إعدادات وصلاحية الجهاز بنجاح.');
    }

    /**
     * حذف وإلغاء ربط جهاز الطالب.
     */
    public function destroyDevice(StudentDevice $device)
    {
        $student = $device->student;

        $this->logDelete('StudentDevices', $device, "تم إلغاء ربط وحذف الجهاز ({$device->device_name}) للطالب: {$student->name}");

        $device->delete();

        if (request()->expectsJson() || request()->ajax()) {
            return response()->json([
                'success' => true,
                'message' => 'تم حذف وإلغاء ربط الجهاز بنجاح.',
                'allowed_secondary_devices' => $student->allowed_secondary_devices,
                'secondary_devices_count' => $student->studentDevices()->where('device_type', StudentDevice::TYPE_SECONDARY)->count(),
                'devices' => $this->getStudentDevicesArray($student),
            ]);
        }

        return back()->with('success', 'تم حذف وإلغاء ربط الجهاز بنجاح.');
    }

    /**
     * Get the formatted devices list for a student.
     */
    private function getStudentDevicesArray(User $student)
    {
        return $student->studentDevices()->latest('last_login_at')->latest()->get()->map(function($device) {
            return [
                'id' => $device->id,
                'device_id' => $device->device_id,
                'device_name' => $device->device_name ?: 'جهاز غير مسمى',
                'platform' => $device->platform ?: '-',
                'app_version' => $device->app_version ?: '-',
                'device_type' => $device->device_type,
                'device_type_label' => $device->is_primary ? 'أساسي' : 'فرعي',
                'is_primary' => (bool) $device->is_primary,
                'is_active' => (bool) $device->is_active,
                'is_temporary' => (bool) $device->is_temporary,
                'expires_at' => $device->expires_at ? $device->expires_at->format('Y-m-d\TH:i') : null,
                'expires_at_label' => $device->expires_at ? $device->expires_at->format('Y-m-d H:i') : null,
                'status_label' => $device->is_active ? ($device->isExpired() ? 'منتهي الصلاحية' : 'مفعل') : 'غير مفعل',
                'is_expired' => $device->isExpired(),
                'approved_at' => $device->approved_at ? $device->approved_at->format('Y-m-d H:i') : null,
                'last_login_at' => $device->last_login_at ? $device->last_login_at->format('Y-m-d H:i') : null,
                'created_at' => $device->created_at ? $device->created_at->format('Y-m-d H:i') : null,
            ];
        })->values()->all();
    }

    /**
     * Get pending device requests.
     */
    public function pendingDeviceRequests()
    {
        $requests = StudentDeviceRequest::pending()
            ->with(['student.college', 'student.major', 'student.level'])
            ->latest()
            ->get()
            ->map(fn($r) => [
                'id' => $r->id,
                'student_name' => $r->student->name,
                'student_number' => $r->student->student_number,
                'college_name' => $r->student->college->name ?? '-',
                'major_name' => $r->student->major->name ?? '-',
                'level_name' => $r->student->level->name ?? '-',
                'requested_device_name' => $r->requested_device_name,
                'platform' => $r->platform,
                'reason' => $r->reason,
                'created_at' => $r->created_at->format('Y-m-d H:i'),
            ]);

        return response()->json([
            'success' => true,
            'requests' => $requests,
        ]);
    }

    /**
     * Approve device request.
     */
    public function approveDeviceRequest(Request $request, $id)
    {
        $deviceRequest = StudentDeviceRequest::findOrFail($id);

        if ($deviceRequest->status !== StudentDeviceRequest::STATUS_PENDING) {
            return response()->json([
                'success' => false,
                'message' => 'هذا الطلب ليس معلقاً.',
            ], 400);
        }

        $deviceRequest->update([
            'status' => StudentDeviceRequest::STATUS_APPROVED,
            'reviewed_by' => auth()->id(),
            'reviewed_at' => now(),
            'admin_note' => $request->input('admin_note'),
        ]);

        $student = $deviceRequest->student;
        $student->increment('allowed_secondary_devices');

        $this->logUpdate('StudentDeviceRequest', $deviceRequest, "تم قبول طلب الجهاز الفرعي ومنح مساحة للطالب: {$student->name}");

        // Create student notification
        \App\Models\StudentNotification::create([
            'user_id' => $student->id,
            'type' => 'device_request',
            'title' => 'تم قبول طلب الجهاز الفرعي',
            'message' => "تم قبول طلبك لاستخدام جهاز فرعي إضافي ({$deviceRequest->requested_device_name}) وتم فتح مساحة جهاز فرعي جديدة لك.",
            'data' => [
                'request_id' => $deviceRequest->id,
                'status' => 'approved',
                'action_url' => '/student/profile',
            ],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'تم قبول طلب الجهاز الفرعي وفتح مساحة إضافية للطالب بنجاح.',
        ]);
    }

    /**
     * Reject device request.
     */
    public function rejectDeviceRequest(Request $request, $id)
    {
        $deviceRequest = StudentDeviceRequest::findOrFail($id);

        if ($deviceRequest->status !== StudentDeviceRequest::STATUS_PENDING) {
            return response()->json([
                'success' => false,
                'message' => 'هذا الطلب ليس معلقاً.',
            ], 400);
        }

        $deviceRequest->update([
            'status' => StudentDeviceRequest::STATUS_REJECTED,
            'reviewed_by' => auth()->id(),
            'reviewed_at' => now(),
            'admin_note' => $request->input('admin_note'),
        ]);

        $student = $deviceRequest->student;
        $adminNote = $deviceRequest->admin_note ? "\nالسبب: " . $deviceRequest->admin_note : '';

        $this->logUpdate('StudentDeviceRequest', $deviceRequest, "تم رفض طلب الجهاز الفرعي للطالب: {$student->name}");

        // Create student notification
        \App\Models\StudentNotification::create([
            'user_id' => $student->id,
            'type' => 'device_request',
            'title' => 'تم رفض طلب الجهاز الفرعي',
            'message' => "نأسف، تم رفض طلبك لاستخدام جهاز فرعي إضافي ({$deviceRequest->requested_device_name}).{$adminNote}",
            'data' => [
                'request_id' => $deviceRequest->id,
                'status' => 'rejected',
                'action_url' => '/student/profile',
            ],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'تم رفض طلب الجهاز الفرعي بنجاح.',
        ]);
    }
}
