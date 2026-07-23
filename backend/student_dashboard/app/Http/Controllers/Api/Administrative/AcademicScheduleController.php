<?php

namespace App\Http\Controllers\Api\Administrative;

use App\Models\Academic\Level;
use App\Models\Academic\Major;
use App\Models\Academic\Schedule;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;

class AcademicScheduleController extends AdministrativeApiController
{
    public function index(Request $request)
    {
        $query = Schedule::whereHas('subject.major', fn ($q) => $q->where('college_id', $this->college()->id))
            ->with(['subject.major:id,name', 'subject.level:id,name', 'subject.doctor:id,name', 'creator:id,name']);

        if ($request->filled('major_id')) {
            $query->whereHas('subject', fn ($q) => $q->where('major_id', $request->integer('major_id')));
        }

        if ($request->filled('level_id')) {
            $query->whereHas('subject', fn ($q) => $q->where('level_id', $request->integer('level_id')));
        }

        if ($request->filled('search')) {
            $search = trim((string) $request->input('search'));
            $query->where(function ($q) use ($search) {
                $q->where('hall_name', 'like', "%{$search}%")
                    ->orWhereHas('subject', fn ($subject) => $subject->where('name', 'like', "%{$search}%"))
                    ->orWhereHas('subject.major', fn ($major) => $major->where('name', 'like', "%{$search}%"))
                    ->orWhereHas('subject.level', fn ($level) => $level->where('name', 'like', "%{$search}%"))
                    ->orWhereHas('subject.doctor', fn ($doctor) => $doctor->where('name', 'like', "%{$search}%"));
            });
        }

        $schedules = $query->latest()->paginate($request->integer('per_page', 15));

        return $this->success([
            'schedules' => $schedules->items(),
            'pagination' => [
                'current_page' => $schedules->currentPage(),
                'last_page' => $schedules->lastPage(),
                'per_page' => $schedules->perPage(),
                'total' => $schedules->total(),
            ],
        ]);
    }

    public function createData()
    {
        return $this->success([
            'majors' => Major::where('college_id', $this->college()->id)
                ->with('levels:id,name,major_id')
                ->select(['id', 'name'])
                ->selectSub(
                    Schedule::selectRaw('count(*)')
                        ->join('subjects', 'schedules.subject_id', '=', 'subjects.id')
                        ->whereColumn('subjects.major_id', 'majors.id'),
                    'lecture_schedules_count'
                )
                ->get(),
        ]);
    }

    public function show(Schedule $schedule)
    {
        $this->ensureScheduleBelongsToCollege($schedule);

        $majorId = $schedule->subject->major_id;
        $levelId = $schedule->subject->level_id;

        $grouped = Schedule::whereHas('subject', fn ($q) => $q->where('major_id', $majorId)->where('level_id', $levelId))
            ->with(['subject.doctor:id,name', 'subject:id,name,doctor_id,major_id,level_id', 'creator:id,name'])
            ->get();

        return $this->success([
            'schedule' => $schedule->load(['subject.major:id,name', 'subject.level:id,name', 'subject.doctor:id,name', 'creator:id,name']),
            'grouped_schedules' => $grouped,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'day_of_week' => 'required|integer|between:1,7',
            'start_time' => 'required',
            'end_time' => 'required|after:start_time',
            'hall_name' => 'nullable|string|max:255',
        ]);

        $subject = Subject::findOrFail($validated['subject_id']);
        $this->ensureCollegeSubject($subject);

        $schedule = Schedule::create([
            'subject_id' => $subject->id,
            'day_of_week' => $validated['day_of_week'],
            'start_time' => $validated['start_time'],
            'end_time' => $validated['end_time'],
            'hall_name' => $validated['hall_name'] ?? null,
            'created_by' => $this->administrative()->id,
        ]);

        return $this->success($schedule->load(['subject.major:id,name', 'subject.level:id,name', 'subject.doctor:id,name']), 'تم إضافة الجدول بنجاح', 201);
    }

    public function update(Request $request, Schedule $schedule)
    {
        $this->ensureScheduleBelongsToCollege($schedule);

        $validated = $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'day_of_week' => 'required|integer|between:1,7',
            'start_time' => 'required',
            'end_time' => 'required|after:start_time',
            'hall_name' => 'nullable|string|max:255',
        ]);

        $subject = Subject::findOrFail($validated['subject_id']);
        $this->ensureCollegeSubject($subject);

        $schedule->update([
            'subject_id' => $subject->id,
            'day_of_week' => $validated['day_of_week'],
            'start_time' => $validated['start_time'],
            'end_time' => $validated['end_time'],
            'hall_name' => $validated['hall_name'] ?? null,
        ]);

        return $this->success($schedule->fresh()->load(['subject.major:id,name', 'subject.level:id,name', 'subject.doctor:id,name']), 'تم تحديث الجدول بنجاح');
    }

    public function destroy(Schedule $schedule)
    {
        $this->ensureScheduleBelongsToCollege($schedule);
        $schedule->delete();
        return $this->success(null, 'تم حذف الجدول بنجاح');
    }

    public function getSubjectsWithDoctors(Level $level)
    {
        $this->ensureCollegeLevel($level);

        $subjects = Subject::where('major_id', $level->major_id)
            ->where('level_id', $level->id)
            ->with('doctor:id,name')
            ->get(['id', 'name', 'doctor_id', 'major_id', 'level_id']);

        return $this->success($subjects);
    }

    protected function ensureScheduleBelongsToCollege(Schedule $schedule): void
    {
        if ($schedule->subject?->major?->college_id !== $this->college()->id) {
            $this->forbid('الجدول لا ينتمي إلى كليتك.');
        }
    }
}
