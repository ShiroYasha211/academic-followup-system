<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Enums\UserRole;
use App\Http\Controllers\Api\Delegate\DelegateApiController;
use App\Models\Academic\Schedule;
use App\Models\Academic\Subject;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;

class ScheduleController extends DelegateApiController implements HasMiddleware
{
    /**
     * Get the middleware that should be assigned to the controller.
     */
    public static function middleware(): array
    {
        return [
            new Middleware('delegate.permission:schedules,create', only: ['store']),
            new Middleware('delegate.permission:schedules,update', only: ['update']),
            new Middleware('delegate.permission:schedules,delete', only: ['destroy']),
        ];
    }
    /**
     * Display a listing of schedules for the delegate's batch.
     */
    public function index(Request $request)
    {
        $delegate = $request->user();

        $subjectIds = Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->pluck('id');

        $schedules = Schedule::whereIn('subject_id', $subjectIds)
            ->with(['doctor:id,name', 'subject:id,name,code,doctor_id', 'subject.doctor:id,name'])
            ->orderBy('day_of_week')
            ->orderBy('start_time')
            ->get()
            ->map(fn (Schedule $schedule) => $this->withResolvedDoctor($schedule));

        return $this->success($schedules, 'تم جلب جدول المحاضرات بنجاح');
    }

    /**
     * Store a newly created schedule.
     */
    public function store(Request $request)
    {
        $delegate = $request->user();
        $this->normalizeSchedulePayload($request);

        $validator = Validator::make($request->all(), [
            'subject_id' => 'required|exists:subjects,id',
            'doctor_id' => 'nullable|exists:users,id',
            'day_of_week' => 'required|integer|between:1,7',
            'start_time' => 'required|date_format:H:i',
            'end_time' => 'required|date_format:H:i|after:start_time',
            'hall_name' => 'nullable|string|max:255',
        ], $this->validationMessages());

        if ($validator->fails()) {
            return $this->error($validator->errors()->first(), 422, $validator->errors());
        }

        $subject = Subject::where('id', $request->subject_id)
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->first();

        if (! $subject) {
            return $this->error('المادة غير موجودة أو غير مصرح لك', 403);
        }

        if (! $this->isValidDoctor($request->doctor_id)) {
            return $this->error('المستخدم المحدد ليس دكتوراً', 422);
        }

        $schedule = Schedule::create([
            'subject_id' => $request->subject_id,
            'doctor_id' => $request->filled('doctor_id') ? $request->doctor_id : null,
            'day_of_week' => $request->day_of_week,
            'start_time' => $request->start_time,
            'end_time' => $request->end_time,
            'hall_name' => $request->filled('hall_name') ? $request->hall_name : null,
            'created_by' => $delegate->id,
        ]);

        return $this->success(
            $this->withResolvedDoctor($schedule->load(['doctor:id,name', 'subject:id,name,code,doctor_id', 'subject.doctor:id,name'])),
            'تمت إضافة المحاضرة للجدول بنجاح',
            201
        );
    }

    /**
     * Update the specified schedule.
     */
    public function update(Request $request, string $id)
    {
        $delegate = $request->user();
        $this->normalizeSchedulePayload($request);

        $schedule = Schedule::with('subject')->find($id);

        if (! $schedule || $schedule->subject->major_id !== $delegate->major_id || $schedule->subject->level_id !== $delegate->level_id) {
            return $this->error('سجل الجدول غير موجود أو غير مصرح لك', 404);
        }

        $validator = Validator::make($request->all(), [
            'subject_id' => 'required|exists:subjects,id',
            'doctor_id' => 'nullable|exists:users,id',
            'day_of_week' => 'required|integer|between:1,7',
            'start_time' => 'required|date_format:H:i|string',
            'end_time' => 'required|date_format:H:i|string|after:start_time',
            'hall_name' => 'nullable|string|max:255',
        ], $this->validationMessages());

        if ($validator->fails()) {
            return $this->error($validator->errors()->first(), 422, $validator->errors());
        }

        if ($request->subject_id != $schedule->subject_id) {
            $newSubject = Subject::where('id', $request->subject_id)
                ->where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)
                ->first();

            if (! $newSubject) {
                return $this->error('المادة الجديدة غير مصرح بها', 403);
            }
        }

        if (! $this->isValidDoctor($request->doctor_id)) {
            return $this->error('المستخدم المحدد ليس دكتوراً', 422);
        }

        $schedule->update([
            'subject_id' => $request->subject_id,
            'doctor_id' => $request->filled('doctor_id') ? $request->doctor_id : null,
            'day_of_week' => $request->day_of_week,
            'start_time' => $request->start_time,
            'end_time' => $request->end_time,
            'hall_name' => $request->filled('hall_name') ? $request->hall_name : null,
        ]);

        return $this->success(
            $this->withResolvedDoctor($schedule->fresh(['doctor:id,name', 'subject:id,name,code,doctor_id', 'subject.doctor:id,name'])),
            'تم تحديث المحاضرة بنجاح'
        );
    }

    /**
     * Remove the specified schedule.
     */
    public function destroy(Request $request, string $id)
    {
        $delegate = $request->user();

        $schedule = Schedule::with('subject')->find($id);

        if (! $schedule || $schedule->subject->major_id !== $delegate->major_id || $schedule->subject->level_id !== $delegate->level_id) {
            return $this->error('سجل الجدول غير موجود أو غير مصرح لك', 404);
        }

        $schedule->delete();

        return $this->success(null, 'تم حذف المحاضرة من الجدول بنجاح');
    }

    private function isValidDoctor(?int $doctorId): bool
    {
        if (! $doctorId) {
            return true;
        }

        return User::where('id', $doctorId)
            ->where('role', UserRole::DOCTOR)
            ->exists();
    }

    private function normalizeSchedulePayload(Request $request): void
    {
        $data = [];

        if (! $request->filled('day_of_week') && $request->filled('day')) {
            $data['day_of_week'] = $request->input('day');
        }

        if (! $request->filled('hall_name') && $request->filled('hall')) {
            $data['hall_name'] = $request->input('hall');
        }

        foreach (['start_time', 'end_time'] as $field) {
            if ($request->filled($field)) {
                $data[$field] = $this->normalizeTime((string) $request->input($field));
            }
        }

        if ($data !== []) {
            $request->merge($data);
        }
    }

    private function normalizeTime(string $value): string
    {
        $value = trim($value);

        if (preg_match('/^(\d{1,2}):(\d{2})(?::\d{2})?$/', $value, $matches)) {
            $hour = (int) $matches[1];
            $minute = (int) $matches[2];

            if ($hour >= 0 && $hour <= 23 && $minute >= 0 && $minute <= 59) {
                return sprintf('%02d:%02d', $hour, $minute);
            }
        }

        try {
            return Carbon::parse($value)->format('H:i');
        } catch (\Throwable) {
            return $value;
        }
    }

    private function validationMessages(): array
    {
        return [
            'subject_id.required' => 'يرجى اختيار المادة الدراسية.',
            'subject_id.exists' => 'المادة الدراسية المختارة غير موجودة.',
            'doctor_id.exists' => 'الدكتور المختار غير موجود.',
            'day_of_week.required' => 'يرجى اختيار يوم المحاضرة.',
            'day_of_week.integer' => 'يوم المحاضرة غير صحيح.',
            'day_of_week.between' => 'يوم المحاضرة غير صحيح.',
            'start_time.required' => 'يرجى اختيار وقت بداية المحاضرة.',
            'start_time.date_format' => 'صيغة وقت بداية المحاضرة غير صحيحة.',
            'end_time.required' => 'يرجى اختيار وقت نهاية المحاضرة.',
            'end_time.date_format' => 'صيغة وقت نهاية المحاضرة غير صحيحة.',
            'end_time.after' => 'يجب أن يكون وقت نهاية المحاضرة بعد وقت البداية.',
            'hall_name.max' => 'اسم القاعة طويل جدًا.',
        ];
    }

    private function withResolvedDoctor(Schedule $schedule): Schedule
    {
        $doctor = $schedule->doctor ?: $schedule->subject?->doctor;

        $schedule->setRelation('doctor', $doctor);
        $schedule->doctor_id = $doctor?->id;
        $schedule->doctor_name = $doctor?->name;

        return $schedule;
    }
}
