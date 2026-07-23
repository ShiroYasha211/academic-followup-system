<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Http\Controllers\Api\Delegate\DelegateApiController;
use App\Models\Academic\Subject;
use App\Models\Inquiry;
use App\Models\StudentNotification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class InquiryController extends DelegateApiController
{
    public function index(Request $request)
    {
        $delegate = $request->user();

        $subjectIds = Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->pluck('id');

        $query = Inquiry::whereIn('subject_id', $subjectIds)
            ->with(['student:id,name,student_number', 'subject:id,name', 'answeredBy:id,name,role', 'delegate:id,name,role'])
            ->orderByDesc('created_at');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $inquiries = $query->paginate(15);

        $stats = [
            'total' => Inquiry::whereIn('subject_id', $subjectIds)->count(),
            'pending' => Inquiry::whereIn('subject_id', $subjectIds)->where('status', 'pending')->count(),
            'forwarded' => Inquiry::whereIn('subject_id', $subjectIds)->where('status', 'forwarded')->count(),
            'answered' => Inquiry::whereIn('subject_id', $subjectIds)->where('status', 'answered')->count(),
            'closed' => Inquiry::whereIn('subject_id', $subjectIds)->where('status', 'closed')->count(),
        ];

        return $this->success([
            'stats' => $stats,
            'inquiries' => $inquiries,
        ], 'تم جلب الاستفسارات بنجاح.');
    }

    public function show(Request $request, string $id)
    {
        $delegate = $request->user();

        $inquiry = Inquiry::with(['student:id,name,student_number', 'subject:id,name', 'answeredBy:id,name,role', 'delegate:id,name,role'])
            ->find($id);

        if (!$inquiry) {
            return $this->error('الاستفسار غير موجود.', 404);
        }

        $subject = Subject::where('id', $inquiry->subject_id)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->first();

        if (!$subject) {
            return $this->error('غير مصرح لك بمشاهدة هذا الاستفسار.', 403);
        }

        return $this->success($inquiry, 'تم جلب بيانات الاستفسار بنجاح.');
    }

    public function forward(Request $request, string $id)
    {
        $delegate = $request->user();
        $inquiry = Inquiry::find($id);

        if (!$inquiry) {
            return $this->error('الاستفسار غير موجود.', 404);
        }

        $subject = Subject::where('id', $inquiry->subject_id)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->first();

        if (!$subject) {
            return $this->error('غير مصرح لك بتحويل هذا الاستفسار.', 403);
        }

        if ($inquiry->status !== 'pending') {
            return $this->error('لا يمكن تحويل هذا الاستفسار بعد الآن.', 422);
        }

        $inquiry->update([
            'status' => 'forwarded',
            'delegate_id' => $delegate->id,
        ]);

        StudentNotification::create([
            'user_id' => $inquiry->student_id,
            'type' => 'announcement',
            'title' => 'تحديث على استفسارك',
            'message' => "تم تحويل استفسارك حول مادة {$subject->name} إلى الدكتور للمراجعة.",
            'data' => ['inquiry_id' => $inquiry->id],
        ]);

        return $this->success($inquiry, 'تم تحويل الاستفسار إلى الدكتور بنجاح.');
    }

    public function storeReply(Request $request, string $id)
    {
        $delegate = $request->user();
        $inquiry = Inquiry::find($id);

        if (!$inquiry) {
            return $this->error('الاستفسار غير موجود.', 404);
        }

        $subject = Subject::where('id', $inquiry->subject_id)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->first();

        if (!$subject) {
            return $this->error('غير مصرح لك بالرد على هذا الاستفسار.', 403);
        }

        if ($inquiry->status !== 'pending') {
            return $this->error('لا يمكن الرد على استفسار تم تحويله أو إغلاقه.', 422);
        }

        $validator = Validator::make($request->all(), [
            'reply' => 'required|string',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة.', 422, $validator->errors());
        }

        $inquiry->update([
            'answer' => $request->reply,
            'status' => 'answered',
            'delegate_id' => $delegate->id,
            'answered_by' => $delegate->id,
            'answered_at' => now(),
        ]);

        StudentNotification::create([
            'user_id' => $inquiry->student_id,
            'type' => 'announcement',
            'title' => 'تم الرد على استفسارك',
            'message' => "تلقيت ردًا جديدًا على استفسارك حول مادة {$subject->name}.",
            'data' => ['inquiry_id' => $inquiry->id],
        ]);

        return $this->success($inquiry, 'تم الرد بنجاح.');
    }

    public function updateStatus(Request $request, string $id)
    {
        $delegate = $request->user();
        $inquiry = Inquiry::find($id);

        if (!$inquiry) {
            return $this->error('الاستفسار غير موجود.', 404);
        }

        $subject = Subject::where('id', $inquiry->subject_id)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->first();

        if (!$subject) {
            return $this->error('غير مصرح لك بتحديث هذا الاستفسار.', 403);
        }

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:pending,answered,closed',
            'is_public' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة.', 422, $validator->errors());
        }

        if (
            $inquiry->status === 'forwarded' ||
            ($inquiry->status === 'answered' && filled($inquiry->answered_by) && (int) $inquiry->answered_by !== (int) $delegate->id)
        ) {
            return $this->error('بعد تحويل الاستفسار إلى الدكتور أو الرد عليه من قبله لا يمكن للمندوب تعديل حالته.', 422);
        }

        $inquiry->update([
            'status' => $request->status,
            'is_public' => $request->has('is_public') ? $request->is_public : $inquiry->is_public,
        ]);

        return $this->success($inquiry, 'تم تحديث حالة الاستفسار بنجاح.');
    }
}
