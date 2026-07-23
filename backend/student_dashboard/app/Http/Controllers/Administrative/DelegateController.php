<?php

namespace App\Http\Controllers\Administrative;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Academic\Level;
use App\Models\Academic\Major;
use App\Models\ActivityLog;
use App\Models\ClinicalDelegate;
use App\Models\DelegatePermission;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DelegateController extends Controller
{
    /**
     * Display college students and delegate promotions.
     */
    public function index(Request $request)
    {
        $college = auth()->user()->college;

        if (! $college) {
            abort(403, 'حسابك غير مرتبط بكلية.');
        }

        $query = User::where('college_id', $college->id)
            ->whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE]);

        $has_clinical_major = $request->filled('major_id')
            ? Major::where('id', $request->major_id)->where('has_clinical', true)->exists()
            : Major::where('college_id', $college->id)->where('has_clinical', true)->exists();

        $stats = [
            'total_students' => (clone $query)->where('role', UserRole::STUDENT)->count(),
            'academic_delegates' => (clone $query)->where('role', UserRole::DELEGATE)->count(),
            'practical_delegates' => (clone $query)->where('role', UserRole::PRACTICAL_DELEGATE)->count(),
        ];

        if ($request->filled('search')) {
            $query->where(function ($q) use ($request) {
                $q->where('name', 'like', "%{$request->search}%")
                    ->orWhere('email', 'like', "%{$request->search}%")
                    ->orWhere('student_number', 'like', "%{$request->search}%");
            });
        }

        if ($request->filled('role') && $request->role !== 'all') {
            $query->where('role', $request->role);
        }

        if ($request->filled('major_id')) {
            $query->where('major_id', $request->major_id);
        }

        if ($request->filled('level_id')) {
            $query->where('level_id', $request->level_id);
        }

        $users = $query->with(['major', 'level', 'delegatePermissions'])->latest()->paginate(25);

        $majors = Major::where('college_id', $college->id)->get();
        $levels = collect();

        if ($request->filled('major_id')) {
            $levels = Level::where('major_id', $request->major_id)->get();
        }

        return view('administrative.delegates.index', compact('users', 'majors', 'levels', 'stats', 'has_clinical_major'));
    }

    /**
     * Update the role of a student/delegate.
     */
    public function updateRole(Request $request, User $user)
    {
        $college = auth()->user()->college;

        if ($user->college_id !== $college->id) {
            abort(403);
        }

        $request->validate([
            'role' => 'required|in:student,delegate,practical_delegate',
        ]);

        $newRoleValue = $request->role;

        if ($newRoleValue === 'practical_delegate' && ! optional($user->major)->has_clinical) {
            return back()->with('error', 'لا يمكن تعيين مندوب عملي لطالب لا ينتمي إلى تخصص سريري.');
        }

        $oldRole = $user->role->label();
        $wasClinicalDelegate = $user->isClinicalDelegate();

        DB::transaction(function () use ($user, $newRoleValue, $wasClinicalDelegate) {
            $user->update(['role' => $newRoleValue]);

            if (in_array($newRoleValue, ['delegate', 'practical_delegate'], true)) {
                $user->grantAllDelegatePermissions(auth()->id());
            }

            if ($newRoleValue === 'practical_delegate') {
                ClinicalDelegate::updateOrCreate(
                    ['student_id' => $user->id],
                    [
                        'major_id' => $user->major_id,
                        'level_id' => $user->level_id,
                    ]
                );
            } elseif ($wasClinicalDelegate) {
                ClinicalDelegate::where('student_id', $user->id)->delete();
            }

            if ($newRoleValue === 'student') {
                $user->revokeDelegatePermissions();
            }
        });

        $user->refresh();
        $newRole = $user->role->label();

        ActivityLog::log(
            'update',
            'User',
            $user->id,
            $user->name,
            "تغيير دور المستخدم من ({$oldRole}) إلى ({$newRole}) بواسطة مسؤول الكلية"
        );

        return back()->with('success', 'تم تحديث دور المستخدم بنجاح.');
    }

    /**
     * Update delegate permissions (granular CRUD per resource).
     */
    public function updatePermissions(Request $request, User $user)
    {
        $college = auth()->user()->college;

        if ($user->college_id !== $college->id) {
            abort(403);
        }

        if (! in_array($user->role->value, ['delegate', 'practical_delegate'], true)) {
            return back()->with('error', 'يمكن إدارة صلاحيات المندوبين فقط.');
        }

        $request->validate([
            'permissions' => 'nullable|array',
            'permissions.*' => 'string',
        ]);

        $submittedPermissions = $request->input('permissions', []);

        $user->delegatePermissions()->delete();

        foreach ($submittedPermissions as $permKey) {
            $parts = explode('.', $permKey);
            if (count($parts) !== 2) {
                continue;
            }

            [$resource, $action] = $parts;

            if (! array_key_exists($resource, DelegatePermission::RESOURCES) || ! array_key_exists($action, DelegatePermission::ACTIONS)) {
                continue;
            }

            DelegatePermission::create([
                'user_id' => $user->id,
                'resource' => $resource,
                'action' => $action,
                'granted_by' => auth()->id(),
            ]);
        }

        ActivityLog::log(
            'update',
            'User',
            $user->id,
            $user->name,
            'تحديث صلاحيات المندوب بواسطة مسؤول الكلية'
        );

        return back()->with('success', "تم تحديث صلاحيات المندوب ({$user->name}) بنجاح.");
    }
}
