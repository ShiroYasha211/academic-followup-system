<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\ActivityLog;
use App\Models\Academic\Major;
use App\Models\Academic\University;
use Illuminate\Http\Request;
use App\Enums\UserRole;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $query = User::with(['university', 'college', 'major', 'level'])
            ->visibleToAdmin($request->user())
            ->latest();

        if ($request->has('role') && $request->role != 'all') {
            $query->where('role', $request->role);
        }

        if ($request->filled('university_id')) {
            $query->where('university_id', $request->integer('university_id'));
        }

        if ($request->filled('major_id')) {
            $query->where('major_id', $request->integer('major_id'));
        }

        if ($request->has('search') && $request->search != '') {
            $query->where(function ($q) use ($request) {
                $q->where('name', 'like', "%{$request->search}%")
                    ->orWhere('email', 'like', "%{$request->search}%");
            });
        }

        $users = $query->paginate(10);
        $universities = University::orderBy('name')->get(['id', 'name']);
        $majors = Major::with('college')->orderBy('name')->get(['id', 'name', 'college_id']);

        return view('admin.users.index', compact('users', 'universities', 'majors'));
    }

    public function updateStatus(Request $request, User $user)
    {
        $this->abortIfProtected($user);

        // Don't allow suspending self
        if ($user->id === auth()->id()) {
            return back()->with('error', 'لا يمكنك إيقاف حسابك الخاص.');
        }

        $oldStatus = $user->status;
        $newStatus = $user->status === 'active' ? 'inactive' : 'active';

        $user->update(['status' => $newStatus]);

        // Log activity
        ActivityLog::log(
            $newStatus === 'active' ? 'activate' : 'deactivate',
            'User',
            $user->id,
            $user->name,
            "تغيير حالة المستخدم من {$oldStatus} إلى {$newStatus}"
        );

        return back()->with('success', 'تم تحديث حالة المستخدم بنجاح.');
    }

    public function destroy(User $user)
    {
        $this->abortIfProtected($user);

        if ($user->id === auth()->id()) {
            return back()->with('error', 'لا يمكنك حذف حسابك الخاص.');
        }

        $userName = $user->name;
        $userId = $user->id;

        $user->delete(); // Soft delete

        // Log activity
        ActivityLog::log(
            'delete',
            'User',
            $userId,
            $userName,
            "حذف المستخدم: {$userName}"
        );

        return back()->with('success', 'تم حذف المستخدم بنجاح.');
    }

    /**
     * تصدير جميع المستخدمين إلى ملف Excel/CSV
     */
    public function export(Request $request)
    {
        $query = User::with(['university', 'college', 'major', 'level'])
            ->visibleToAdmin($request->user());

        // Apply filters if any
        if ($request->has('role') && $request->role != 'all') {
            $query->where('role', $request->role);
        }

        if ($request->filled('university_id')) {
            $query->where('university_id', $request->integer('university_id'));
        }

        if ($request->filled('major_id')) {
            $query->where('major_id', $request->integer('major_id'));
        }

        $users = $query->get();

        // Build CSV content
        $csvContent = chr(0xEF) . chr(0xBB) . chr(0xBF); // BOM for UTF-8

        // Header row
        $headers = ['الرقم', 'الاسم', 'البريد الإلكتروني', 'الدور', 'الحالة', 'الجامعة', 'الكلية', 'التخصص', 'المستوى', 'تاريخ التسجيل'];
        $csvContent .= implode(',', $headers) . "\n";

        // Data rows
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
     * تفعيل مجموعة من المستخدمين
     */
    public function bulkActivate(Request $request)
    {
        $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'exists:users,id'
        ]);

        $currentUserId = auth()->id();
        $ids = array_filter($request->ids, fn($id) => $id != $currentUserId);

        $count = User::whereIn('id', $ids)
            ->visibleToAdmin($request->user())
            ->update(['status' => 'active']);

        return back()->with('success', "تم تفعيل {$count} مستخدم بنجاح.");
    }

    /**
     * تعطيل مجموعة من المستخدمين
     */
    public function bulkDeactivate(Request $request)
    {
        $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'exists:users,id'
        ]);

        $currentUserId = auth()->id();
        $ids = array_filter($request->ids, fn($id) => $id != $currentUserId);

        $count = User::whereIn('id', $ids)
            ->visibleToAdmin($request->user())
            ->update(['status' => 'inactive']);

        return back()->with('success', "تم تعطيل {$count} مستخدم بنجاح.");
    }

    /**
     * حذف مجموعة من المستخدمين
     */
    public function bulkDelete(Request $request)
    {
        $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'exists:users,id'
        ]);

        $currentUserId = auth()->id();
        $ids = array_filter($request->ids, fn($id) => $id != $currentUserId);

        $count = User::whereIn('id', $ids)
            ->visibleToAdmin($request->user())
            ->delete();

        return back()->with('success', "تم حذف {$count} مستخدم بنجاح.");
    }

    /**
     * إعادة تعيين كلمة المرور بواسطة الإدارة
     */
    public function resetPassword(Request $request, User $user)
    {
        $this->abortIfProtected($user);

        $request->validate([
            'new_password' => 'required|min:8'
        ]);

        $user->update([
            'password' => \Illuminate\Support\Facades\Hash::make($request->new_password)
        ]);

        // Log activity
        ActivityLog::log(
            'update',
            'User',
            $user->id,
            $user->name,
            "إعادة تعيين كلمة المرور للمستخدم: {$user->name}"
        );

        return back()->with('success', 'تم إعادة تعيين كلمة المرور بنجاح للمستخدم ' . $user->name);
    }

    /**
     * طرد المستخدم من الجلسة الحالية
     */
    public function kickSession(User $user)
    {
        $this->abortIfProtected($user);

        if ($user->id === auth()->id()) {
            return back()->with('error', 'لا يمكنك طرد نفسك من الجلسة!');
        }

        // Store a flag in the cache for 2 hours
        \Illuminate\Support\Facades\Cache::put('kick_user_' . $user->id, true, now()->addMinutes(120));

        // Clear remember token to prevent auto-login
        $user->update(['remember_token' => null]);

        // Log activity
        ActivityLog::log(
            'update',
            'User',
            $user->id,
            $user->name,
            "تم طرد المستخدم من الجلسة: {$user->name}"
        );

        return back()->with('success', 'تم طرد المستخدم ' . $user->name . ' من الجلسة بنجاح.');
    }

    /**
     * تفعيل الاشتراك يدوياً للمستخدم
     */
    public function activateSubscription(Request $request, User $user)
    {
        $this->abortIfProtected($user);

        $request->validate([
            'days' => 'required|integer|min:1|max:3650'
        ]);

        $days = (int) $request->days;
        $expiry = now()->addDays($days);

        $user->update([
            'subscribed_until' => $expiry
        ]);

        // Log activity
        ActivityLog::log(
            'update',
            'User',
            $user->id,
            $user->name,
            "تفعيل اشتراك يدوي للمستخدم: {$user->name} لمدة {$days} أيام (ينتهي في: " . $expiry->format('Y-m-d') . ")"
        );

        return back()->with('success', "تم تفعيل اشتراك المستخدم {$user->name} بنجاح لمدة {$days} أيام.");
    }

    protected function abortIfProtected(User $user): void
    {
        if ($user->isProtectedFrom(auth()->user())) {
            abort(404);
        }
    }
}
