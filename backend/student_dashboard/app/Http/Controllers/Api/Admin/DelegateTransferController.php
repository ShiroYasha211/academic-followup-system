<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\User;
use App\Models\Academic\Major;
use App\Models\Academic\Level;
use App\Models\CourseResource;
use App\Models\ActivityLog;
use App\Enums\UserRole;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DelegateTransferController extends AdminApiController
{
    /**
     * List all batches that have an assigned delegate.
     */
    public function index()
    {
        $delegates = User::where('role', UserRole::DELEGATE)
            ->with(['university', 'college', 'major', 'level'])
            ->get()
            ->groupBy(function($user) {
                return $user->major_id . '-' . $user->level_id;
            })
            ->map(function($group) {
                return [
                    'major' => $group->first()->major,
                    'level' => $group->first()->level,
                    'delegates' => $group->map(function($u) {
                        return [
                            'id' => $u->id,
                            'name' => $u->name,
                            'email' => $u->email,
                        ];
                    })
                ];
            })
            ->values();

        return $this->success($delegates);
    }

    /**
     * Show details for a specific batch transfer.
     */
    public function show(Major $major, Level $level)
    {
        $currentDelegate = User::where('role', UserRole::DELEGATE)
            ->where('major_id', $major->id)
            ->where('level_id', $level->id)
            ->first();

        if (!$currentDelegate) {
            return $this->error('لا يوجد مندوب حالي لهذه الدفعة.', 404);
        }

        $eligibleStudents = User::where('role', UserRole::STUDENT)
            ->where('major_id', $major->id)
            ->where('level_id', $level->id)
            ->where('status', 'active')
            ->get();

        return $this->success([
            'current_delegate' => $currentDelegate,
            'eligible_students' => $eligibleStudents,
            'major' => $major,
            'level' => $level
        ]);
    }

    /**
     * Perform the transfer.
     */
    public function transfer(Request $request)
    {
        $request->validate([
            'old_delegate_id' => 'required|exists:users,id',
            'new_delegate_id' => 'required|exists:users,id',
            'major_id' => 'required|exists:majors,id',
            'level_id' => 'required|exists:levels,id',
        ]);

        $oldDelegate = User::findOrFail($request->old_delegate_id);
        $newDelegate = User::findOrFail($request->new_delegate_id);

        if ($oldDelegate->role !== UserRole::DELEGATE || $newDelegate->role !== UserRole::STUDENT) {
            return $this->error('خطأ في تحديد الصلاحيات الحالية للمستخدمين.', 422);
        }

        if ($newDelegate->major_id != $request->major_id || $newDelegate->level_id != $request->level_id) {
            return $this->error('الطالب المختار لا ينتمي لنفس الدفعة.', 422);
        }

        DB::transaction(function () use ($oldDelegate, $newDelegate, $request) {
            // 1. Swap Roles
            $oldDelegate->update(['role' => UserRole::STUDENT]);
            $newDelegate->update(['role' => UserRole::DELEGATE]);

            // 2. Transfer Ownership of Resources
            CourseResource::where('created_by', $oldDelegate->id)
                ->update(['created_by' => $newDelegate->id]);

            // 3. Log Activity
            ActivityLog::log(
                'update',
                'User',
                $newDelegate->id,
                $newDelegate->name,
                "نقل منصب المندوبية عبر الـ API من [{$oldDelegate->name}] إلى [{$newDelegate->name}]"
            );
        });

        return $this->success(null, "تم نقل المندوبية بنجاح إلى {$newDelegate->name}.");
    }
}
