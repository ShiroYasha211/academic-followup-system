<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\User;
use App\Enums\UserRole;
use App\Services\AdministrativeAccessNotificationService;
use App\Traits\LogsActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class DoctorController extends AdminApiController
{
    use LogsActivity;

    public function index(Request $request)
    {
        $query = User::where('role', UserRole::DOCTOR)
            ->with(['university', 'college', 'major'])
            ->latest();

        if ($request->search) {
            $query->where(function ($q) use ($request) {
                $q->where('name', 'like', "%{$request->search}%")
                    ->orWhere('email', 'like', "%{$request->search}%");
            });
        }

        return $this->paginated($query->paginate($request->per_page ?? 15));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|string|min:8',
            'university_id' => 'required|exists:universities,id',
            'college_id' => 'required|exists:colleges,id',
            'administrative_access' => 'nullable|boolean',
        ]);

        $doctor = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => UserRole::DOCTOR,
            'university_id' => $request->university_id,
            'college_id' => $request->college_id,
            'administrative_access' => $request->boolean('administrative_access'),
        ]);

        $this->logCreate('Doctor', $doctor, "تم إضافة الدكتور: {$doctor->name}");
        if ($doctor->administrative_access) {
            app(AdministrativeAccessNotificationService::class)
                ->notify($doctor, true, $request->user()?->id);
        }
        return $this->success($doctor, 'تم إضافة الدكتور بنجاح', 201);
    }

    public function update(Request $request, User $doctor)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $doctor->id,
            'university_id' => 'required|exists:universities,id',
            'college_id' => 'required|exists:colleges,id',
            'administrative_access' => 'nullable|boolean',
        ]);

        $hadAdministrativeAccess = (bool) $doctor->administrative_access;
        $data = $request->only('name', 'email', 'university_id', 'college_id');
        $data['administrative_access'] = $request->boolean('administrative_access');
        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
        }

        $doctor->update($data);
        $hasAdministrativeAccess = (bool) $doctor->administrative_access;
        $this->logUpdate('Doctor', $doctor, "تم تعديل بيانات الدكتور: {$doctor->name}");
        if ($hadAdministrativeAccess !== $hasAdministrativeAccess) {
            app(AdministrativeAccessNotificationService::class)
                ->notify($doctor, $hasAdministrativeAccess, $request->user()?->id);
        }
        return $this->success($doctor->fresh(), 'تم تحديث بيانات الدكتور بنجاح');
    }

    public function show(User $doctor)
    {
        if ($doctor->role !== UserRole::DOCTOR) {
            return $this->error('المستخدم ليس دكتوراً.', 404);
        }
        return $this->success($doctor->load(['university', 'college', 'subjects.term.level.major']));
    }

    public function destroy(User $doctor)
    {
        if ($doctor->role !== UserRole::DOCTOR) {
            return $this->error('المستخدم ليس دكتوراً.', 404);
        }
        $this->logDelete('Doctor', $doctor, "تم حذف الدكتور نهائياً: {$doctor->name}");
        $doctor->forceDelete();
        return $this->success(null, 'تم حذف الدكتور بنجاح واستئصال بياناته');
    }
}
