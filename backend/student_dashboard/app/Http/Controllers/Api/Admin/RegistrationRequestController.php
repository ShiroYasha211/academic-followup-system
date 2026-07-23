<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\User;
use Illuminate\Http\Request;

class RegistrationRequestController extends BaseController
{
    /**
     * Display a listing of the pending registration requests.
     */
    public function index(Request $request)
    {
        $query = User::where('status', 'pending');

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhere('student_number', 'like', "%{$search}%");
            });
        }

        $pendingRequests = $query->with([
                'university:id,name',
                'college:id,name',
                'major:id,name',
                'level:id,name'
            ])
            ->select('id', 'name', 'email', 'phone', 'student_number', 'role', 'status', 'created_at', 'university_id', 'college_id', 'major_id', 'level_id')
            ->latest()
            ->paginate($request->get('per_page', 15));

        return $this->success($pendingRequests, 'تم جلب الحسابات المعلقة بنجاح.');
    }

    /**
     * Approve multiple registration requests (Bulk Approve).
     */
    public function approve(Request $request)
    {
        $request->validate([
            'user_ids'   => 'required|array',
            'user_ids.*' => 'exists:users,id'
        ]);

        $approvedCount = User::whereIn('id', $request->user_ids)
            ->where('status', 'pending')
            ->update(['status' => 'active']);

        if ($approvedCount === 0) {
            return $this->error('لم يتم العثور على أي حسابات معلقة ضمن القائمة المختارة.', 404);
        }

        return $this->success(null, "تم اعتماد وتفعيل $approvedCount حسابات بنجاح.");
    }

    /**
     * Reject multiple registration requests by deleting them completely (Bulk Reject).
     */
    public function reject(Request $request)
    {
        $request->validate([
            'user_ids'   => 'required|array',
            'user_ids.*' => 'exists:users,id'
        ]);

        $usersToReject = User::whereIn('id', $request->user_ids)
            ->where('status', 'pending')
            ->get();

        $rejectedCount = 0;

        foreach ($usersToReject as $user) {
            $user->forceDelete();
            $rejectedCount++;
        }

        if ($rejectedCount === 0) {
            return $this->error('لم يتم العثور على أي حسابات معلقة ضمن القائمة المختارة لرفضها.', 404);
        }

        return $this->success(null, "تم رفض وحذف $rejectedCount طلبات بنجاح.");
    }
}
