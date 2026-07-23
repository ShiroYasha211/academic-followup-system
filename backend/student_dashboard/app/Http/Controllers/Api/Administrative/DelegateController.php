<?php

namespace App\Http\Controllers\Api\Administrative;

use App\Enums\UserRole;
use App\Models\Academic\Level;
use App\Models\Academic\Major;
use App\Models\ClinicalDelegate;
use App\Models\DelegatePermission;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DelegateController extends AdministrativeApiController
{
    public function index(Request $request)
    {
        $college = $this->college();

        $query = User::where('college_id', $college->id)
            ->whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE]);

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
            $query->where('major_id', $request->integer('major_id'));
        }

        if ($request->filled('level_id')) {
            $query->where('level_id', $request->integer('level_id'));
        }

        $users = $query->with(['major:id,name', 'level:id,name,major_id', 'delegatePermissions'])
            ->latest()
            ->paginate($request->integer('per_page', 25));

        $majors = Major::where('college_id', $college->id)->get(['id', 'name', 'has_clinical']);
        $levels = $request->filled('major_id')
            ? Level::where('major_id', $request->integer('major_id'))->get(['id', 'name', 'major_id'])
            : collect();

        return $this->success([
            'users' => $users->items(),
            'pagination' => [
                'current_page' => $users->currentPage(),
                'last_page' => $users->lastPage(),
                'per_page' => $users->perPage(),
                'total' => $users->total(),
            ],
            'stats' => [
                'total_students' => User::where('college_id', $college->id)->where('role', UserRole::STUDENT)->count(),
                'academic_delegates' => User::where('college_id', $college->id)->where('role', UserRole::DELEGATE)->count(),
                'practical_delegates' => User::where('college_id', $college->id)->where('role', UserRole::PRACTICAL_DELEGATE)->count(),
            ],
            'majors' => $majors,
            'levels' => $levels,
            'available_permissions' => [
                'resources' => DelegatePermission::RESOURCES,
                'actions' => DelegatePermission::ACTIONS,
            ],
        ]);
    }

    public function updateRole(Request $request, User $user)
    {
        $this->ensureCollegeUser($user, ['student', 'delegate', 'practical_delegate']);

        $validated = $request->validate([
            'role' => 'required|in:student,delegate,practical_delegate',
        ]);

        if ($validated['role'] === 'practical_delegate' && ! optional($user->major)->has_clinical) {
            return $this->error('لا يمكن تعيين مندوب عملي لطالب لا ينتمي إلى تخصص سريري.', 422);
        }

        $wasClinicalDelegate = $user->isClinicalDelegate();

        DB::transaction(function () use ($user, $validated, $wasClinicalDelegate) {
            $user->update(['role' => $validated['role']]);

            if (in_array($validated['role'], ['delegate', 'practical_delegate'], true)) {
                $user->grantAllDelegatePermissions($this->administrative()->id);
            }

            if ($validated['role'] === 'practical_delegate') {
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

            if ($validated['role'] === 'student') {
                $user->revokeDelegatePermissions();
            }
        });

        return $this->success($user->fresh()->load('delegatePermissions'), 'تم تحديث دور المستخدم بنجاح');
    }

    public function updatePermissions(Request $request, User $user)
    {
        $this->ensureCollegeUser($user, ['delegate', 'practical_delegate']);

        $validated = $request->validate([
            'permissions' => 'nullable|array',
            'permissions.*' => 'string',
        ]);

        $user->delegatePermissions()->delete();

        foreach ($validated['permissions'] ?? [] as $permKey) {
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
                'granted_by' => $this->administrative()->id,
            ]);
        }

        return $this->success($user->fresh()->load('delegatePermissions'), 'تم تحديث صلاحيات المندوب بنجاح');
    }
}
