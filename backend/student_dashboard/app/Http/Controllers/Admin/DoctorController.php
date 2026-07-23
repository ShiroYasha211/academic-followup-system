<?php

namespace App\Http\Controllers\Admin;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Academic\College;
use App\Models\User;
use App\Services\AdministrativeAccessNotificationService;
use App\Traits\LogsActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class DoctorController extends Controller
{
    use LogsActivity;

    /**
     * Display the doctors list.
     */
    public function index(Request $request)
    {
        $query = User::where('role', UserRole::DOCTOR)
            ->with(['university', 'college', 'subjects.term.level.major'])
            ->withCount('subjects');

        $search = trim((string) $request->query('search', ''));
        if ($search !== '') {
            $query->where(function ($doctorQuery) use ($search) {
                $doctorQuery
                    ->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");

                if (ctype_digit($search)) {
                    $doctorQuery->orWhereKey((int) $search);
                }
            });
        }

        if ($request->filled('university_id')) {
            $query->where('university_id', (int) $request->query('university_id'));
        }

        if ($request->filled('college_id')) {
            $query->where('college_id', (int) $request->query('college_id'));
        }

        $status = (string) $request->query('status', '');
        if (in_array($status, ['active', 'inactive', 'pending'], true)) {
            $query->where('status', $status);
        }

        $rank = (string) $request->query('rank', '');
        if ($rank === 'administrative') {
            $query->where('administrative_access', true);
        } elseif ($rank === 'doctor') {
            $query->where('administrative_access', false);
        }

        $doctors = $query
            ->latest()
            ->paginate(10)
            ->withQueryString();

        $universities = \App\Models\Academic\University::with('colleges')->get();
        $totalDoctors = User::where('role', UserRole::DOCTOR)->count();

        return view('admin.users.doctors.index', compact(
            'doctors',
            'universities',
            'totalDoctors',
        ));
    }

    /**
     * Store a newly created doctor.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'college_id' => 'required|exists:colleges,id',
            'administrative_access' => 'nullable|boolean',
        ], [
            'college_id.required' => 'يرجى تحديد الكلية التابعة لها.',
            'email.unique' => 'البريد الإلكتروني مسجل مسبقاً.',
        ]);

        $college = College::findOrFail($request->college_id);

        $doctor = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => UserRole::DOCTOR,
            'college_id' => $college->id,
            'university_id' => $college->university_id,
            'administrative_access' => $request->boolean('administrative_access'),
        ]);

        $this->logCreate('Doctor', $doctor, "تم إضافة الدكتور: {$doctor->name}");

        if ($doctor->administrative_access) {
            app(AdministrativeAccessNotificationService::class)
                ->notify($doctor, true, auth()->id());
        }

        return redirect()->route('admin.doctors.index')
            ->with('success', 'تم إضافة الدكتور بنجاح.');
    }

    /**
     * Update doctor information.
     */
    public function update(Request $request, User $doctor)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,' . $doctor->id,
            'college_id' => 'required|exists:colleges,id',
            'administrative_access' => 'nullable|boolean',
        ]);

        $college = College::findOrFail($request->college_id);

        $updateData = [
            'name' => $request->name,
            'email' => $request->email,
            'college_id' => $college->id,
            'university_id' => $college->university_id,
            'administrative_access' => $request->boolean('administrative_access'),
        ];

        if ($request->filled('password')) {
            $request->validate(['password' => 'string|min:8']);
            $updateData['password'] = Hash::make($request->password);
        }

        $hadAdministrativeAccess = (bool) $doctor->administrative_access;
        $doctor->update($updateData);
        $hasAdministrativeAccess = (bool) $doctor->administrative_access;

        $this->logUpdate('Doctor', $doctor, "تم تعديل بيانات الدكتور: {$doctor->name}");

        if ($hadAdministrativeAccess !== $hasAdministrativeAccess) {
            app(AdministrativeAccessNotificationService::class)
                ->notify($doctor, $hasAdministrativeAccess, auth()->id());
        }

        return redirect()->route('admin.doctors.index')
            ->with('success', 'تم تحديث بيانات الدكتور بنجاح.');
    }

    /**
     * Update only administrative rank for the doctor.
     */
    public function updateAdministrativeAccess(Request $request, User $doctor)
    {
        if ($doctor->role !== UserRole::DOCTOR) {
            return back()->with('error', 'لا يمكن تعديل الرتبة لهذا المستخدم من هنا.');
        }

        $request->validate([
            'administrative_access' => 'nullable|boolean',
        ]);

        $hadAdministrativeAccess = (bool) $doctor->administrative_access;
        $hasAdministrativeAccess = $request->boolean('administrative_access');

        $doctor->update(['administrative_access' => $hasAdministrativeAccess]);

        $action = $hasAdministrativeAccess ? 'منح' : 'سحب';
        $this->logUpdate(
            'Doctor',
            $doctor,
            "تم {$action} صلاحية المسؤول الإداري للدكتور: {$doctor->name}"
        );

        if ($hadAdministrativeAccess !== $hasAdministrativeAccess) {
            app(AdministrativeAccessNotificationService::class)
                ->notify($doctor, $hasAdministrativeAccess, auth()->id());
        }

        return redirect()->route('admin.doctors.index')
            ->with(
                'success',
                $hasAdministrativeAccess
                    ? 'تم منح الرتبة الإدارية وإشعار الدكتور بنجاح.'
                    : 'تم سحب الرتبة الإدارية وإشعار الدكتور بنجاح.'
            );
    }

    /**
     * Delete a doctor.
     */
    public function destroy(User $doctor)
    {
        if ($doctor->role !== UserRole::DOCTOR) {
            return back()->with('error', 'لا يمكن حذف هذا المستخدم من قائمة الدكاترة.');
        }

        $this->logDelete('Doctor', $doctor, "تم حذف الدكتور: {$doctor->name}");

        $doctor->forceDelete();

        return redirect()->route('admin.doctors.index')
            ->with('success', 'تم حذف الدكتور بنجاح.');
    }
}
