<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\Delegate\DelegateApiController;
use App\Models\Reminder;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class ReminderController extends DelegateApiController
{
    /**
     * Display a listing of reminders for the delegate's batch.
     */
    public function index(Request $request)
    {
        $delegate = $request->user();

        $remindersQuery = Reminder::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->with('creator:id,name');

        if ($request->has('filter') && $request->filter === 'past') {
            $remindersQuery->where('notify_at', '<', Carbon::now())
                ->orderBy('event_date', 'desc');
        } else {
            // Default to upcoming (notify_at is in the future)
            $remindersQuery->where('notify_at', '>=', Carbon::now())
                ->orderBy('event_date', 'asc');
        }

        $reminders = $remindersQuery->get();

        $stats = [
            'total' => Reminder::where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)->count(),
            'upcoming' => Reminder::where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)
                ->where('notify_at', '>=', Carbon::now())->count(),
            'past' => Reminder::where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)
                ->where('notify_at', '<', Carbon::now())->count(),
        ];

        return $this->success([
            'stats' => $stats,
            'reminders' => $reminders
        ], 'تم جلب التذكيرات بنجاح');
    }

    /**
     * Store a newly created reminder.
     */
    public function store(Request $request)
    {
        $delegate = $request->user();

        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'event_date' => 'required|date|after:yesterday',
            'notify_at' => 'required|date|before_or_equal:event_date',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        $reminder = Reminder::create([
            'major_id' => $delegate->major_id,
            'level_id' => $delegate->level_id,
            'created_by' => $delegate->id,
            'title' => $request->title,
            'description' => $request->description,
            'event_date' => $request->event_date,
            'notify_at' => $request->notify_at,
        ]);

        return $this->success($reminder->load('creator'), 'تمت إضافة التذكير بنجاح', 201);
    }

    /**
     * Update the specified reminder.
     */
    public function update(Request $request, string $id)
    {
        $delegate = $request->user();

        $reminder = Reminder::find($id);

        if (!$reminder || $reminder->major_id !== $delegate->major_id || $reminder->level_id !== $delegate->level_id) {
            return $this->error('التذكير غير موجود أو غير مصرح لك', 404);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'event_date' => 'required|date|after:yesterday',
            'notify_at' => 'required|date|before_or_equal:event_date',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        $reminder->update([
            'title' => $request->title,
            'description' => $request->description,
            'event_date' => $request->event_date,
            'notify_at' => $request->notify_at,
        ]);

        return $this->success($reminder->load('creator'), 'تم تحديث التذكير بنجاح');
    }

    /**
     * Remove the specified reminder.
     */
    public function destroy(Request $request, string $id)
    {
        $delegate = $request->user();

        $reminder = Reminder::find($id);

        if (!$reminder || $reminder->major_id !== $delegate->major_id || $reminder->level_id !== $delegate->level_id) {
            return $this->error('التذكير غير موجود أو غير مصرح لك', 404);
        }

        $reminder->delete();

        return $this->success(null, 'تم حذف التذكير بنجاح');
    }
}
