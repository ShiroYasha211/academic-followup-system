<?php

namespace App\Http\Controllers\Api\Doctor;

use App\Models\Academic\Subject;
use App\Models\User;
use App\Services\DoctorStarWalletService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class StarController extends DoctorApiController
{
    public function __construct(private readonly DoctorStarWalletService $wallets)
    {
    }

    protected function eligibleStudentsQuery()
    {
        $doctor = Auth::user();
        $subjectScopes = Subject::where('doctor_id', $doctor->id)
            ->get(['major_id', 'level_id']);

        if ($subjectScopes->isEmpty()) {
            return User::whereRaw('1 = 0');
        }

        return User::whereIn('role', ['student', 'delegate', 'practical_delegate'])
            ->where(function ($query) use ($subjectScopes) {
                foreach ($subjectScopes as $scope) {
                    $query->orWhere(function ($inner) use ($scope) {
                        $inner->where('major_id', $scope->major_id)
                            ->where('level_id', $scope->level_id);
                    });
                }
            });
    }

    public function index(Request $request)
    {
        $wallet = $this->wallets->initialize(Auth::user());
        $subjects = Subject::where('doctor_id', Auth::id())
            ->with(['major:id,name', 'level:id,name'])
            ->get(['id', 'name', 'level_id', 'major_id']);

        $students = $this->eligibleStudentsQuery()
            ->with(['major:id,name', 'level:id,name'])
            ->when($request->filled('subject_id'), function ($query) use ($request, $subjects) {
                $subject = $subjects->firstWhere('id', (int) $request->subject_id);
                if ($subject) {
                    $query->where('major_id', $subject->major_id)
                        ->where('level_id', $subject->level_id);
                }
            })
            ->when($request->filled('major_id'), fn ($query) => $query->where('major_id', $request->integer('major_id')))
            ->when($request->filled('level_id'), fn ($query) => $query->where('level_id', $request->integer('level_id')))
            ->when($request->filled('search'), function ($query) use ($request) {
                $search = $request->search;
                $query->where(function ($inner) use ($search) {
                    $inner->where('name', 'like', "%{$search}%")
                        ->orWhere('student_number', 'like', "%{$search}%");
                });
            })
            ->orderBy('name')
            ->paginate($request->integer('per_page', 25), [
                'id',
                'name',
                'student_number',
                'stars_balance',
                'major_id',
                'level_id',
            ]);

        return $this->success([
            'subjects' => $subjects,
            'majors' => $subjects->pluck('major')->filter()->unique('id')->values(),
            'levels' => $subjects->pluck('level')->filter()->unique('id')->values(),
            'students' => $students,
            'wallet' => [
                'balance' => $wallet->balance,
                'total_allocated' => $wallet->total_allocated,
                'total_spent' => $wallet->total_spent,
            ],
        ]);
    }

    public function grant(Request $request)
    {
        $validated = $request->validate([
            'student_ids' => 'required|array|min:1',
            'student_ids.*' => 'integer|exists:users,id',
            'amount' => 'required|integer|min:1|max:100',
            'description' => 'nullable|string|max:200',
        ]);

        $requestedIds = array_values(array_unique(array_map('intval', $validated['student_ids'])));
        $students = $this->eligibleStudentsQuery()
            ->whereIn('id', $requestedIds)
            ->get();

        if ($students->count() !== count($requestedIds)) {
            return $this->error('أحد الطلاب المحددين خارج نطاق المواد التابعة لك.', 403);
        }

        $result = $this->wallets->grant(
            $request->user(),
            $students,
            $validated['amount'],
            $validated['description'] ?? null,
        );

        return $this->success([
            'granted_count' => $result['recipient_count'],
            'amount' => $result['stars_per_student'],
            'total_cost' => $result['total_cost'],
            'remaining_balance' => $result['wallet']->balance,
        ], "تم منح {$validated['amount']} نجمة لـ {$result['recipient_count']} طالب بنجاح.");
    }
}
