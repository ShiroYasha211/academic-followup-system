<?php

namespace App\Http\Controllers\Api\Delegate\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Clinical\ClinicalCase;
use App\Http\Controllers\Api\Delegate\DelegateApiController;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class ClinicalCaseController extends DelegateApiController
{
    /**
     * List all clinical cases specifically awaiting review (pending).
     */
    public function pending()
    {
        $user = Auth::user();

        $cases = ClinicalCase::with(['trainingCenter', 'clinicalDepartment', 'bodySystem', 'doctor'])
            ->where('approval_status', 'pending')
            ->whereHas('doctor', function ($query) use ($user) {
                $query->where('university_id', $user->university_id)
                    ->where('college_id', $user->college_id)
                    ->where('major_id', $user->major_id)
                    ->where('level_id', $user->level_id);
            })
            ->latest()
            ->paginate(15);

        return $this->success($cases, 'تم جلب الحالات بانتظار الاعتماد بنجاح');
    }

    /**
     * Approve a clinical case.
     */
    public function approve($id)
    {
        if (!Auth::user()->isClinicalDelegate()) {
            return $this->error('هذه العملية متاحة للمندوب العملي الرئيسي فقط.', 403);
        }

        $case = ClinicalCase::findOrFail($id);

        if ($case->approval_status !== 'pending') {
            return $this->error('هذه الحالة ليست في وضع الانتظار حالياً.', 400);
        }

        $case->update([
            'approval_status' => 'approved',
            'approved_by' => Auth::id()
        ]);

        return $this->success(null, 'تم اعتماد الحالة بنجاح وهي الآن متاحة للجميع.');
    }

    /**
     * Reject a clinical case with a reason.
     */
    public function reject(Request $request, $id)
    {
        if (!Auth::user()->isClinicalDelegate()) {
            return $this->error('هذه العملية متاحة للمندوب العملي الرئيسي فقط.', 403);
        }

        $case = ClinicalCase::findOrFail($id);

        if ($case->approval_status !== 'pending') {
            return $this->error('هذه الحالة ليست في وضع الانتظار حالياً.', 400);
        }

        $validator = Validator::make($request->all(), [
            'rejection_reason' => 'required|string|max:500',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        $case->update([
            'approval_status' => 'rejected',
            'rejection_reason' => $request->rejection_reason
        ]);

        return $this->success(null, 'تم رفض الحالة وإرسال الملاحظات إلى الطالب.');
    }
}
