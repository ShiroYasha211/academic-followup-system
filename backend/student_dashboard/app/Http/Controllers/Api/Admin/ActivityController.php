<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\ActivityLog;
use Illuminate\Http\Request;

class ActivityController extends AdminApiController
{
    public function index(Request $request)
    {
        $query = ActivityLog::with('user')->latest();

        if ($request->user_id) {
            $query->where('user_id', $request->user_id);
        }
        if ($request->action) {
            $query->where('action', $request->action);
        }
        if ($request->model_type) {
            $query->where('model_type', $request->model_type);
        }
        if ($request->from) {
            $query->whereDate('created_at', '>=', $request->from);
        }
        if ($request->to) {
            $query->whereDate('created_at', '<=', $request->to);
        }

        return $this->paginated($query->paginate($request->per_page ?? 20));
    }

    public function cleanup()
    {
        $count = ActivityLog::where('created_at', '<', now()->subDays(30))->delete();
        return $this->success(['deleted_count' => $count], "تم حذف {$count} سجل قديم بنجاح");
    }
}
