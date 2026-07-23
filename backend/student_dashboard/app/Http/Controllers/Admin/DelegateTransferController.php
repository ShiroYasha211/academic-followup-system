<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Academic\Major;
use App\Models\Academic\Level;
use App\Models\CourseResource;
use App\Models\ActivityLog;
use App\Enums\UserRole;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DelegateTransferController extends Controller
{
    /**
     * List all batches that have an assigned delegate.
     */
    public function index()
    {
        // Get all users who are delegates and group them by batch
        $delegates = User::where('role', UserRole::DELEGATE)
            ->with(['major', 'level'])
            ->get()
            ->groupBy(function($user) {
                return $user->major_id . '-' . $user->level_id;
            });

        return view('admin.delegates.transfer.index', compact('delegates'));
    }

    /**
     * Show the transfer interface for a specific batch.
     */
    public function show(Major $major, Level $level)
    {
        $currentDelegate = User::where('role', UserRole::DELEGATE)
            ->where('major_id', $major->id)
            ->where('level_id', $level->id)
            ->first();

        if (!$currentDelegate) {
            return redirect()->route('admin.delegates.transfer.index')
                ->with('error', 'لا يوجد مندوب حالي لهذه الدفعة.');
        }

        $eligibleStudents = User::where('role', UserRole::STUDENT)
            ->where('major_id', $major->id)
            ->where('level_id', $level->id)
            ->where('status', 'active')
            ->get();

        return view('admin.delegates.transfer.show', compact('major', 'level', 'currentDelegate', 'eligibleStudents'));
    }

    /**
     * Perform the transfer between old delegate and new student.
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
            return back()->with('error', 'خطأ في تحديد الصلاحيات الحالية للمستخدمين.');
        }

        if ($newDelegate->major_id != $request->major_id || $newDelegate->level_id != $request->level_id) {
            return back()->with('error', 'الطالب المختار لا ينتمي لنفس الدفعة.');
        }

        DB::transaction(function () use ($oldDelegate, $newDelegate, $request) {
            // 1. Swap Roles
            $oldDelegate->update(['role' => UserRole::STUDENT]);
            $newDelegate->update(['role' => UserRole::DELEGATE]);

            // 2. Transfer Ownership of Resources
            // We transfer files uploaded by the old delegate to the new one so they can manage them
            CourseResource::where('created_by', $oldDelegate->id)
                ->update([
                    'created_by' => $newDelegate->id
                ]);

            // 3. Log Activity
            ActivityLog::log(
                'update',
                'User',
                $newDelegate->id,
                $newDelegate->name,
                "نقل منصب المندوبية من [{$oldDelegate->name}] إلى [{$newDelegate->name}] للدفعة: " . ($oldDelegate->major->name ?? '') . " - " . ($oldDelegate->level->name ?? '')
            );
        });

        return redirect()->route('admin.delegates.transfer.index')
            ->with('success', "تم نقل المندوبية بنجاح إلى {$newDelegate->name}.");
    }
}
