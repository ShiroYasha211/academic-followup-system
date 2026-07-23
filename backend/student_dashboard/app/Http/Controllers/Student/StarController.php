<?php

namespace App\Http\Controllers\Student;

use App\Enums\UserRole;
use App\Exceptions\StarGiftException;
use App\Http\Controllers\Controller;
use App\Models\StarTransaction;
use App\Models\User;
use App\Services\StudentStarGiftService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class StarController extends Controller
{
    /**
     * Show the student's stars dashboard.
     */
    public function index(StudentStarGiftService $giftService)
    {
        $student = Auth::user();

        $transactions = StarTransaction::forUser($student->id)
            ->with('grantedBy:id,name')
            ->latest()
            ->paginate(20);

        $honorBoard = User::query()
            ->where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->where('stars_balance', '>', 0)
            ->orderByDesc('stars_balance')
            ->limit(10)
            ->get(['id', 'name', 'student_number', 'stars_balance', 'total_stars_earned']);

        $giftLimit = $giftService->limitStatus($student);
        $peers = User::query()
            ->where('id', '!=', $student->id)
            ->whereIn('role', [
                UserRole::STUDENT->value,
                UserRole::DELEGATE->value,
                UserRole::PRACTICAL_DELEGATE->value,
            ])
            ->where('status', 'active')
            ->where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->orderBy('name')
            ->get(['id', 'name', 'student_number']);

        return view('student.stars.index', compact(
            'student',
            'transactions',
            'honorBoard',
            'giftLimit',
            'peers',
        ));
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
            $giftService->gift(
                $student,
                $recipient,
                (int) $validated['amount'],
                $validated['message'] ?? null,
            );
        } catch (StarGiftException $exception) {
            return back()->withInput()->with('error', $exception->getMessage());
        }

        return back()->with(
            'success',
            "تم إرسال {$validated['amount']} نجمة إلى {$recipient->name} بنجاح.",
        );
    }
}
