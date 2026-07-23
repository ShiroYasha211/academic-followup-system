<?php

namespace App\Http\Controllers\Api\Student\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Clinical\RareCase;

class RareCaseController extends Controller
{
    /**
     * Get active rare cases for mobile app.
     */
    public function index()
    {
        $cases = RareCase::with('doctor:id,name')
            ->where('is_active', true)
            ->where(function ($query) {
                $query->whereNull('status')->orWhere('status', 'published');
            })
            ->where(function ($query) {
                $query->whereNull('expires_at')->orWhere('expires_at', '>', now());
            })
            ->latest()
            ->paginate(15);
        $cases->getCollection()->transform(fn ($case) => $this->serializeCase($case));

        return response()->json([
            'status' => 'success',
            'data' => $cases
        ]);
    }

    /**
     * Get details of a single rare case.
     */
    public function show($id)
    {
        $case = RareCase::with('doctor:id,name')->find($id);

        if (
            !$case ||
            !$case->is_active ||
            ($case->status && $case->status !== 'published') ||
            ($case->expires_at && $case->expires_at->isPast())
        ) {
            return response()->json([
                'status' => 'error',
                'message' => 'الحالة غير متاحة حالياً.'
            ], 404);
        }

        $case->increment('views_count');

        return response()->json([
            'status' => 'success',
            'data' => $this->serializeCase($case)
        ]);
    }

    protected function serializeCase(RareCase $case): array
    {
        $data = $case->toArray();
        $data['attachment_url'] = $case->attachment_path
            ? url('storage/' . ltrim($case->attachment_path, '/'))
            : null;

        return $data;
    }
}
