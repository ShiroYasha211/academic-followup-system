<?php

namespace App\Http\Controllers\Api\Student;

use App\Enums\UserRole;
use App\Exceptions\StarGiftException;
use App\Models\StarTransaction;
use App\Models\User;
use App\Services\StudentStarGiftService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class StarController extends StudentApiController
{
    /**
     * Get the student's balance, transactions, honor board, and gifting limit.
     */
    public function index(StudentStarGiftService $giftService)
    {
        $student = Auth::user();

        $transactions = StarTransaction::query()
            ->where('user_id', $student->id)
            ->with('grantedBy:id,name')
            ->latest()
            ->paginate(15);

        $honorBoard = User::query()
            ->where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->where('stars_balance', '>', 0)
            ->orderByDesc('stars_balance')
            ->limit(10)
            ->get(['id', 'name', 'student_number', 'stars_balance', 'total_stars_earned']);

        return $this->success([
            'balance' => [
                'current' => (int) $student->stars_balance,
                'total_earned' => (int) $student->total_stars_earned,
            ],
            'transactions' => $transactions,
            'honor_board' => $honorBoard,
            'gift_limit' => $giftService->limitStatus($student),
        ], 'تم جلب بيانات النجوم بنجاح.');
    }

    /**
     * Search eligible student accounts to receive stars.
     */
    public function searchUsers(Request $request)
    {
        $query = trim((string) $request->query('query'));
        if (mb_strlen($query) < 2) {
            return $this->success([], 'أدخل حرفين على الأقل للبحث.');
        }

        $users = User::query()
            ->where('id', '!=', Auth::id())
            ->whereIn('role', [
                UserRole::STUDENT->value,
                UserRole::DELEGATE->value,
                UserRole::PRACTICAL_DELEGATE->value,
            ])
            ->where('status', 'active')
            ->where(function ($builder) use ($query) {
                $builder->where('name', 'like', "%{$query}%")
                    ->orWhere('student_number', 'like', "%{$query}%");
            })
            ->limit(15)
            ->get(['id', 'name', 'student_number']);

        return $this->success($users, 'نتائج البحث.');
    }

    /**
     * Gift stars to another eligible student account.
     */
    public function gift(Request $request, StudentStarGiftService $giftService)
    {
        $student = Auth::user();
        $validated = $request->validate([
            'recipient_id' => ['required', 'integer', 'exists:users,id', 'different:' . $student->id],
            'amount' => ['required', 'integer', 'min:1'],
            'message' => ['nullable', 'string', 'max:200'],
        ]);

        $recipient = User::findOrFail($validated['recipient_id']);

        try {
            $result = $giftService->gift(
                $student,
                $recipient,
                (int) $validated['amount'],
                $validated['message'] ?? null,
            );
        } catch (StarGiftException $exception) {
            return response()->json([
                'success' => false,
                'message' => $exception->getMessage(),
                'code' => $exception->errorCode,
            ], $exception->status);
        }

        return $this->success([
            'new_balance' => (int) $result['sender']->stars_balance,
            'gift_limit' => $result['limit'],
        ], "تم إرسال {$validated['amount']} نجمة إلى {$recipient->name} بنجاح.");
    }
}
