<?php

namespace App\Http\Controllers\Api\Administrative;

use App\Http\Controllers\Api\BaseController;
use App\Models\Academic\College;
use App\Models\Academic\Level;
use App\Models\Academic\Major;
use App\Models\Academic\Subject;
use App\Models\User;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\JsonResponse;
use Illuminate\Pagination\LengthAwarePaginator;

class AdministrativeApiController extends BaseController
{
    protected function administrative(): User
    {
        /** @var User $user */
        $user = request()->user();
        return $user;
    }

    protected function college(): College
    {
        $college = $this->administrative()->college;

        if (!$college) {
            $this->forbid('حسابك غير مرتبط بكلية.');
        }

        return $college;
    }

    protected function collegeMajorIds()
    {
        return Major::where('college_id', $this->college()->id)->pluck('id');
    }

    protected function ensureCollegeUser(User $user, array $roles = []): void
    {
        if ($user->college_id !== $this->college()->id) {
            $this->forbid('المستخدم لا ينتمي إلى كليتك.');
        }

        if ($roles !== []) {
            $roleValue = $user->role?->value ?? $user->role;
            if (!in_array($roleValue, $roles, true)) {
                $this->forbid('المستخدم لا ينتمي إلى الفئة المطلظˆبة.', 422);
            }
        }
    }

    protected function ensureCollegeMajor(Major $major): void
    {
        if ($major->college_id !== $this->college()->id) {
            $this->forbid('التخصص لا ينتمي إلى كليتك.');
        }
    }

    protected function ensureCollegeLevel(Level $level): void
    {
        if ($level->major?->college_id !== $this->college()->id) {
            $this->forbid('المستوى لا ينتمي إلى كليتك.');
        }
    }

    protected function ensureCollegeSubject(Subject $subject): void
    {
        if (!in_array($subject->major_id, $this->collegeMajorIds()->all(), true)) {
            $this->forbid('المادة لا تنتمي إلى كليتك.');
        }
    }

    protected function forbid(string $message = 'غير مصرح لك بالوصول إلى هذا المورد.', int $code = 403): never
    {
        throw new HttpResponseException($this->error($message, $code));
    }

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
