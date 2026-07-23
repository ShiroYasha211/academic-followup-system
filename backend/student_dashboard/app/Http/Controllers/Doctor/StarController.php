<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Controller;
use App\Models\Academic\Subject;
use App\Models\User;
use App\Services\DoctorStarWalletService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class StarController extends Controller
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

    public function index()
    {
        $doctor = Auth::user();
        $subjects = Subject::where('doctor_id', $doctor->id)->with('level')->get();
        $students = $this->eligibleStudentsQuery()
            ->orderBy('name')
            ->get(['id', 'name', 'student_number', 'stars_balance', 'major_id', 'level_id']);
        $wallet = $this->wallets->initialize($doctor);

        return view('doctor.stars.index', compact('subjects', 'students', 'wallet'));
    }

    public function grant(Request $request)
    {
        $doctor = Auth::user();
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
            return back()->with('error', 'أحد الطلاب المحددين خارج نطاق المواد التابعة لك.');
        }

        $result = $this->wallets->grant(
            $doctor,
            $students,
            $validated['amount'],
            $validated['description'] ?? null,
        );

        return back()->with(
            'success',
            "تم منح {$validated['amount']} نجمة لـ {$result['recipient_count']} طالب. الرصيد المتبقي: {$result['wallet']->balance} نجمة.",
        );
    }
}
