<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\Delegate\DelegateApiController;
use App\Models\ExamSchedule;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;

class ExamScheduleController extends DelegateApiController implements HasMiddleware
{
    /**
     * Get the middleware that should be assigned to the controller.
     */
    public static function middleware(): array
    {
        return [
            new Middleware('delegate.permission:exams,create', only: ['store']),
            new Middleware('delegate.permission:exams,update', only: ['update']),
            new Middleware('delegate.permission:exams,delete', only: ['destroy']),
        ];
    }
    /**
     * Display a listing of exam schedules for the delegate's batch.
     */
    public function index(Request $request)
    {
        $delegate = $request->user();

        $schedules = ExamSchedule::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->with(['items.subject:id,name,code', 'creator:id,name'])
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->success($schedules, 'تم جلب جداول الاختبارات بنجاح');
    }

    /**
     * Store a newly created exam schedule with its items.
     */
    public function store(Request $request)
    {
        $delegate = $request->user();

        $validator = Validator::make($request->all(), [
            'term_id' => 'required|exists:terms,id', 
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.subject_id' => 'required|exists:subjects,id',
            'items.*.exam_date' => 'required|date',
            'items.*.start_time' => 'required|date_format:H:i',
            'items.*.end_time' => 'required|date_format:H:i|after:items.*.start_time',
            'items.*.location' => 'nullable|string|max:255',
            'items.*.hall_name' => 'nullable|string|max:255',
            'items.*.exam_type' => 'required|in:midterm,final,practical,quiz,other',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        // 1. Subject Scope Validation
        foreach ($request->items as $item) {
            $subject = \App\Models\Academic\Subject::where('id', $item['subject_id'])
                ->where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)
                ->first();

            if (!$subject) {
                return $this->error("المادة ذات المعرف ({$item['subject_id']}) غير تابعة لتخصصك أو مستواك الدراسي.", 403);
            }
        }

        // 2. Overlap Validation
        $overlapError = $this->validateNoOverlap($request->items, $request->term_id, $delegate);
        if ($overlapError) {
            return $this->error($overlapError, 422);
        }

        try {
            DB::beginTransaction();

            $schedule = ExamSchedule::create([
                'major_id' => $delegate->major_id,
                'level_id' => $delegate->level_id,
                'term_id' => $request->term_id,
                'title' => $request->title,
                'description' => $request->description,
                'is_published' => true,
                'created_by' => $delegate->id,
            ]);

            foreach ($request->items as $item) {
                $schedule->items()->create([
                    'subject_id' => $item['subject_id'],
                    'exam_date' => $item['exam_date'],
                    'start_time' => $item['start_time'],
                    'end_time' => $item['end_time'],
                    'location' => $item['location'] ?? $item['hall_name'] ?? null,
                    'exam_type' => $item['exam_type'] ?? 'other',
                ]);
            }

            DB::commit();

            return $this->success($schedule->load('items.subject'), 'تم حفظ جدول الاختبارات بنجاح', 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->error('حدث خطأ أثناء حفظ الجدول: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Update the specified exam schedule.
     */
    public function update(Request $request, string $id)
    {
        $delegate = $request->user();

        $schedule = ExamSchedule::find($id);

        if (!$schedule || $schedule->major_id !== $delegate->major_id || $schedule->level_id !== $delegate->level_id) {
            return $this->error('الجدول غير موجود أو غير مصرح لك', 404);
        }

        $validator = Validator::make($request->all(), [
            'term_id' => 'required|exists:terms,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.subject_id' => 'required|exists:subjects,id',
            'items.*.exam_date' => 'required|date',
            'items.*.start_time' => 'required|date_format:H:i',
            'items.*.end_time' => 'required|date_format:H:i|after:items.*.start_time',
            'items.*.location' => 'nullable|string|max:255',
            'items.*.hall_name' => 'nullable|string|max:255',
            'items.*.exam_type' => 'required|in:midterm,final,practical,quiz,other',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        // 1. Subject Scope Validation
        foreach ($request->items as $item) {
            $subject = \App\Models\Academic\Subject::where('id', $item['subject_id'])
                ->where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)
                ->first();

            if (!$subject) {
                return $this->error("المادة ذات المعرف ({$item['subject_id']}) غير تابعة لتخصصك أو مستواك الدراسي.", 403);
            }
        }

        // 2. Overlap Validation
        $overlapError = $this->validateNoOverlap($request->items, $request->term_id, $delegate, $schedule->id);
        if ($overlapError) {
            return $this->error($overlapError, 422);
        }

        try {
            DB::beginTransaction();

            $schedule->update([
                'term_id' => $request->term_id,
                'title' => $request->title,
                'description' => $request->description,
            ]);

            // Sync items (Delete existing and recreate for simplicity)
            $schedule->items()->delete();

            foreach ($request->items as $item) {
                $schedule->items()->create([
                    'subject_id' => $item['subject_id'],
                    'exam_date' => $item['exam_date'],
                    'start_time' => $item['start_time'],
                    'end_time' => $item['end_time'],
                    'location' => $item['location'] ?? $item['hall_name'] ?? null,
                    'exam_type' => $item['exam_type'] ?? 'other',
                ]);
            }

            DB::commit();

            return $this->success($schedule->load('items.subject'), 'تم تحديث جدول الاختبارات بنجاح');
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->error('حدث خطأ أثناء تحديث الجدول: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Remove the specified exam schedule.
     */
    public function destroy(Request $request, string $id)
    {
        $delegate = $request->user();

        $schedule = ExamSchedule::find($id);

        if (!$schedule || $schedule->major_id !== $delegate->major_id || $schedule->level_id !== $delegate->level_id) {
            return $this->error('الجدول غير موجود أو غير مصرح لك', 404);
        }

        $schedule->delete();

        return $this->success(null, 'تم حذف جدول الاختبارات بنجاح');
    }

    /**
     * Validate that no exams overlap in date and time for the same major/level.
     */
    private function validateNoOverlap($items, $termId, $user, $ignoreScheduleId = null)
    {
        foreach ($items as $item) {
            $query = \App\Models\ExamScheduleItem::whereHas('schedule', function ($q) use ($user, $termId, $ignoreScheduleId) {
                $q->where('major_id', $user->major_id)
                    ->where('level_id', $user->level_id)
                    ->where('term_id', $termId);

                if ($ignoreScheduleId) {
                    $q->where('id', '!=', $ignoreScheduleId);
                }
            })
                ->where('exam_date', $item['exam_date'])
                ->where(function ($q) use ($item) {
                    // Check for time overlap
                    $q->whereBetween('start_time', [$item['start_time'], $item['end_time']])
                        ->orWhereBetween('end_time', [$item['start_time'], $item['end_time']])
                        ->orWhere(function ($subQ) use ($item) {
                            $subQ->where('start_time', '<=', $item['start_time'])
                                ->where('end_time', '>=', $item['end_time']);
                        });
                });

            if ($query->exists()) {
                $subject = \App\Models\Academic\Subject::find($item['subject_id']);
                return "يوجد تعارض في وقت الاختبار لمادة ({$subject->name}) في يوم {$item['exam_date']}. يرجى اختيار وقت آخر.";
            }
        }
        return null;
    }
}
