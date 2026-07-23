<?php

namespace App\Http\Controllers\Api\Delegate\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Clinical\ClinicalSubDelegation;
use App\Http\Controllers\Api\Delegate\DelegateApiController;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class SubDelegationController extends DelegateApiController
{
    /**
     * List active and recent delegations created by the current delegate.
     */
    public function index()
    {
        $delegator = Auth::user();

        if (! $delegator->isClinicalDelegate()) {
            return $this->error('هذه العملية متاحة للمندوب العملي الرئيسي فقط.', 403);
        }
        
        $subDelegations = ClinicalSubDelegation::with('student:id,name,university_id,major_id,level_id')
            ->where('delegator_id', $delegator->id)
            ->latest()
            ->paginate(15);

        return $this->success($subDelegations, 'تم جلب التفوِيضات بنجاح');
    }

    /**
     * Fetch students only from the same cohort as the delegator.
     */
    public function getStudents()
    {
        $delegator = Auth::user();

        if (! $delegator->isClinicalDelegate()) {
            return $this->error('هذه العملية متاحة للمندوب العملي الرئيسي فقط.', 403);
        }

        $students = User::where('role', 'student')
            ->where('id', '!=', $delegator->id)
            ->where('university_id', $delegator->university_id)
            ->where('college_id', $delegator->college_id)
            ->where('major_id', $delegator->major_id)
            ->where('level_id', $delegator->level_id)
            ->get(['id', 'name', 'university_id', 'major_id', 'level_id']);

        return $this->success($students, 'تم جلب قائمة الطلاب بنجاح');
    }

    /**
     * Create a new sub-delegation.
     */
    public function store(Request $request)
    {
        if (! Auth::user()->isClinicalDelegate()) {
            return $this->error('هذه العملية متاحة للمندوب العملي الرئيسي فقط.', 403);
        }

        $validator = Validator::make($request->all(), [
            'student_id' => 'required|exists:users,id',
            'duration_hours' => 'required|integer|min:1|max:168',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        $delegator = Auth::user();
        $student = User::findOrFail($request->student_id);

        // Security check: Student must be in the same cohort
        if (
            $student->university_id !== $delegator->university_id ||
            $student->college_id !== $delegator->college_id ||
            $student->major_id !== $delegator->major_id ||
            $student->level_id !== $delegator->level_id
        ) {
            return $this->error('عذراً لا يمكنك منح صلاحية لطالب من دفعة أو تخصص مختلف.', 403);
        }

        $exists = ClinicalSubDelegation::where('delegator_id', $delegator->id)
            ->where('student_id', $request->student_id)
            ->where('is_revoked', false)
            ->where(function ($query) {
                $query->whereNull('expires_at')
                      ->orWhere('expires_at', '>', now());
            })->exists();

        if ($exists) {
            return $this->error('هذا الطالب لديه صلاحية فعالة حالياً ولم تنتهي بعد.', 400);
        }

        $delegation = ClinicalSubDelegation::create([
            'delegator_id' => $delegator->id,
            'student_id' => $request->student_id,
            'expires_at' => now()->addHours((int) $request->duration_hours),
            'is_revoked' => false,
        ]);

        return $this->success($delegation->load('student'), 'تم منح الصلاحية كـ (مندوب فرعي) للطالب بنجاح.', 201);
    }

    /**
     * Revoke an active delegation.
     */
    public function revoke($id)
    {
        if (! Auth::user()->isClinicalDelegate()) {
            return $this->error('هذه العملية متاحة للمندوب العملي الرئيسي فقط.', 403);
        }

        $delegation = ClinicalSubDelegation::where('delegator_id', Auth::id())
            ->findOrFail($id);

        $delegation->update(['is_revoked' => true]);

        return $this->success(null, 'تم سحب الصلاحية من الطالب وإيقافه فوراً.');
    }
}
