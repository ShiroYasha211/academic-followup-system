<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\User;
use Illuminate\Http\Request;

class ActivityController extends Controller
{
    /**
     * عرض سجل الأنشطة
     */
    public function index(Request $request)
    {
        $viewer = $request->user();
        $query = ActivityLog::with('user')
            ->when(!$viewer?->canManageSystemOwners(), function ($query) {
                $query->whereDoesntHave('user', function ($userQuery) {
                    $userQuery->where('is_system_owner', true);
                });
            })
            ->latest();

        // Filter by user
        if ($request->has('user_id') && $request->user_id) {
            $query->where('user_id', $request->user_id);
        }

        // Filter by action
        if ($request->has('action') && $request->action) {
            $query->where('action', $request->action);
        }

        // Filter by model type
        if ($request->has('model_type') && $request->model_type) {
            $query->where('model_type', $request->model_type);
        }

        // Filter by date range
        if ($request->has('date_from') && $request->date_from) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }
        if ($request->has('date_to') && $request->date_to) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        $activities = $query->paginate(20);

        // Get unique actions and model types for filters
        $actions = ActivityLog::distinct()->pluck('action');
        $modelTypes = ActivityLog::distinct()->pluck('model_type');
        $users = User::query()
            ->visibleToAdmin($viewer)
            ->select('id', 'name')
            ->orderBy('name')
            ->get();

        return view('admin.activities.index', compact('activities', 'actions', 'modelTypes', 'users'));
    }

    /**
     * مسح سجل الأنشطة القديمة (أكثر من 30 يوم)
     */
    public function cleanup()
    {
        $count = ActivityLog::where('created_at', '<', now()->subDays(30))->delete();

        return back()->with('success', "تم حذف {$count} سجل قديم.");
    }
}
