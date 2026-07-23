<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\User;
use App\Models\ActivityLog;
use App\Enums\UserRole;
use Illuminate\Http\Request;

class UserController extends AdminApiController
{
    public function index(Request $request)
    {
        $query = User::with(['university', 'college', 'major', 'level'])->latest();

        if ($request->role && $request->role !== 'all') {
            $query->where('role', $request->role);
        }
        if ($request->status) {
            $query->where('status', $request->status);
        }
        if ($request->filled('university_id')) {
            $query->where('university_id', $request->integer('university_id'));
        }
        if ($request->filled('major_id')) {
            $query->where('major_id', $request->integer('major_id'));
        }
        if ($request->search) {
            $query->where(function ($q) use ($request) {
                $q->where('name', 'like', "%{$request->search}%")
                    ->orWhere('email', 'like', "%{$request->search}%");
            });
        }

        return $this->paginated($query->paginate($request->per_page ?? 15));
    }

    public function updateStatus(Request $request, User $user)
    {
        if ($user->id === auth()->id()) {
            return $this->error('لا يمكنك تغيير حالة حسابك الخاص.', 422);
        }

        $newStatus = $user->status === 'active' ? 'inactive' : 'active';
        $user->update(['status' => $newStatus]);

        ActivityLog::log(
            $newStatus === 'active' ? 'activate' : 'deactivate',
            'User',
            $user->id,
            $user->name,
            "تغيير حالة المستخدم إلى {$newStatus}"
        );

        return $this->success(['status' => $newStatus], 'تم تحديث حالة المستخدم بنجاح');
    }

    public function destroy(User $user)
    {
        if ($user->id === auth()->id()) {
            return $this->error('لا يمكنك حذف حسابك الخاص.', 422);
        }

        ActivityLog::log('delete', 'User', $user->id, $user->name, "حذف المستخدم: {$user->name}");
        $user->delete();

        return $this->success(null, 'تم حذف المستخدم بنجاح');
    }

    public function bulkActivate(Request $request)
    {
        $request->validate(['ids' => 'required|array', 'ids.*' => 'exists:users,id']);
        $ids = array_filter($request->ids, fn($id) => $id != auth()->id());
        $count = User::whereIn('id', $ids)->update(['status' => 'active']);
        return $this->success(['count' => $count], "تم تفعيل {$count} مستخدم بنجاح");
    }

    public function bulkDeactivate(Request $request)
    {
        $request->validate(['ids' => 'required|array', 'ids.*' => 'exists:users,id']);
        $ids = array_filter($request->ids, fn($id) => $id != auth()->id());
        $count = User::whereIn('id', $ids)->update(['status' => 'inactive']);
        return $this->success(['count' => $count], "تم تعطيل {$count} مستخدم بنجاح");
    }

    public function bulkDelete(Request $request)
    {
        $request->validate(['ids' => 'required|array', 'ids.*' => 'exists:users,id']);
        $ids = array_filter($request->ids, fn($id) => $id != auth()->id());
        $count = User::whereIn('id', $ids)->delete();
        return $this->success(['count' => $count], "تم حذف {$count} مستخدم بنجاح");
    }

    /**
     * إعادة تعيين كلمة المرور لمستخدم بواسطة الأدمن
     */
    public function resetPassword(Request $request, User $user)
    {
        $request->validate([
            'new_password' => 'required|string|min:8',
        ]);

        $user->update([
            'password' => \Illuminate\Support\Facades\Hash::make($request->new_password)
        ]);

        ActivityLog::log(
            'update',
            'User',
            $user->id,
            $user->name,
            "إعادة تعيين كلمة المرور بواسطة الإدارة للمستخدم: {$user->name}"
        );

        return $this->success(null, 'تم إعادة تعيين كلمة المرور بنجاح للمستخدم ' . $user->name);
    }

    /**
     * طرد المستخدم من الجلسة الحالية
     */
    public function kickSession(User $user)
    {
        if ($user->id === auth()->id()) {
            return $this->error('لا يمكنك طرد نفسك من الجلسة!', 422);
        }

        \Illuminate\Support\Facades\Cache::put('kick_user_' . $user->id, true, now()->addMinutes(120));
        
        $user->update(['remember_token' => null]);

        ActivityLog::log(
            'update',
            'User',
            $user->id,
            $user->name,
            "تم طرد المستخدم من الجلسة: {$user->name}"
        );

        return $this->success(null, 'تم طرد المستخدم ' . $user->name . ' من الجلسة بنجاح.');
    }

    /**
     * تفعيل الاشتراك يدوياً للمستخدم
     */
    public function activateSubscription(Request $request, User $user)
    {
        $request->validate([
            'days' => 'required|integer|min:1|max:3650'
        ]);

        $days = (int) $request->days;
        $expiry = now()->addDays($days);

        $user->update([
            'subscribed_until' => $expiry
        ]);

        ActivityLog::log(
            'update',
            'User',
            $user->id,
            $user->name,
            "تفعيل اشتراك يدوي عبر الـ API للمستخدم: {$user->name} لمدة {$days} أيام"
        );

        return $this->success([
            'subscribed_until' => $expiry->format('Y-m-d H:i:s')
        ], "تم تفعيل اشتراك المستخدم {$user->name} بنجاح لمدة {$days} أيام.");
    }

    /**
     * تصدير جميع المستخدمين إلى ملف CSV
     */
    public function export(Request $request)
    {
        $query = User::with(['university', 'college', 'major', 'level']);

        if ($request->role && $request->role !== 'all') {
            $query->where('role', $request->role);
        }
        if ($request->filled('university_id')) {
            $query->where('university_id', $request->integer('university_id'));
        }
        if ($request->filled('major_id')) {
            $query->where('major_id', $request->integer('major_id'));
        }

        $users = $query->get();
        $csvContent = chr(0xEF) . chr(0xBB) . chr(0xBF); // BOM for UTF-8
        $headers = ['الرقم', 'الاسم', 'البريد الإلكتروني', 'الدور', 'الحالة', 'الجامعة', 'الكلية', 'التخصص', 'المستوى', 'تاريخ التسجيل'];
        $csvContent .= implode(',', $headers) . "\n";

        foreach ($users as $index => $user) {
            $roleLabel = match ($user->role) {
                UserRole::ADMIN => 'مدير',
                UserRole::DOCTOR => 'دكتور',
                UserRole::DELEGATE => 'مندوب دفعة',
                UserRole::PRACTICAL_DELEGATE => 'مندوب عملي',
                UserRole::STUDENT => 'طالب',
                UserRole::ADMINISTRATIVE => 'مسؤول إداري',
                default => '-'
            };

            $statusLabel = $user->status === 'active' ? 'نشط' : 'معطل';

            $row = [
                $index + 1,
                '"' . str_replace('"', '""', $user->name) . '"',
                $user->email,
                $roleLabel,
                $statusLabel,
                '"' . str_replace('"', '""', $user->university->name ?? '-') . '"',
                '"' . str_replace('"', '""', $user->college->name ?? '-') . '"',
                '"' . str_replace('"', '""', $user->major->name ?? '-') . '"',
                '"' . str_replace('"', '""', $user->level->name ?? '-') . '"',
                $user->created_at ? $user->created_at->format('Y-m-d H:i') : '-'
            ];

            $csvContent .= implode(',', $row) . "\n";
        }

        $filename = 'users_export_' . date('Y-m-d_His') . '.csv';

        return response($csvContent)
            ->header('Content-Type', 'text/csv; charset=UTF-8')
            ->header('Content-Disposition', 'attachment; filename="' . $filename . '"');
    }

    /**
     * Get all permissions and user's current assignments.
     */
    public function getPermissions(User $user)
    {
        // Technical Permissions (Stored in permission_user)
        $permissions = \App\Models\Permission::all(['id', 'name', 'slug']);
        $userPermissions = $user->permissions->pluck('slug')->toArray();

        // Delegate Component Permissions (Stored in delegate_permissions)
        $delegateResources = \App\Models\DelegatePermission::RESOURCES;
        $delegateActions = \App\Models\DelegatePermission::ACTIONS;
        
        $userDelegatePermissions = $user->delegatePermissions()
            ->get(['resource', 'action'])
            ->map(fn($p) => "{$p->resource}.{$p->action}")
            ->toArray();

        return $this->success([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'role' => $user->role->value,
            ],
            'technical_permissions' => [
                'available' => $permissions,
                'current' => $userPermissions
            ],
            'delegate_permissions' => [
                'resources' => $delegateResources,
                'actions' => $delegateActions,
                'current' => $userDelegatePermissions
            ]
        ], 'تم جلب الصلاحيات بنجاح');
    }

    /**
     * Update permissions for a user (Admin Only).
     */
    public function updatePermissions(Request $request, User $user)
    {
        $request->validate([
            'permissions' => 'array',
            'permissions.*' => 'string|exists:permissions,slug',
            'delegate_permissions' => 'array',
            'delegate_permissions.*' => 'string' // Format: resource.action
        ]);

        // 1. Sync Technical Permissions
        $user->permissions()->detach();
        if ($request->has('permissions')) {
            foreach ($request->permissions as $slug) {
                $permission = \App\Models\Permission::where('slug', $slug)->first();
                if ($permission) {
                    $user->permissions()->attach($permission->id);
                }
            }
        }

        // 2. Sync Delegate Permissions
        $user->delegatePermissions()->delete();
        if ($request->has('delegate_permissions')) {
            foreach ($request->delegate_permissions as $permString) {
                if (str_contains($permString, '.')) {
                    [$resource, $action] = explode('.', $permString);
                    if (isset(\App\Models\DelegatePermission::RESOURCES[$resource]) && 
                        isset(\App\Models\DelegatePermission::ACTIONS[$action])) {
                        
                        \App\Models\DelegatePermission::create([
                            'user_id' => $user->id,
                            'resource' => $resource,
                            'action' => $action,
                            'granted_by' => auth()->id()
                        ]);
                    }
                }
            }
        }

        ActivityLog::log('update_permissions', 'User', $user->id, $user->name, "تحديث صلاحيات المستخدم: {$user->name}");

        return $this->success(null, 'تم تحديث الصلاحيات بنجاح');
    }
}
