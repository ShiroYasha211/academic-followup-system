<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Api\BaseController;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Http\JsonResponse;

class StudentApiController extends BaseController
{
    /**
     * Return a paginated JSON response.
     */
    protected function paginated(LengthAwarePaginator $paginator, string $message = 'تم جلب البيانات بنجاح'): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $paginator->items(),
            'pagination' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
            ],
        ]);
    }
}
