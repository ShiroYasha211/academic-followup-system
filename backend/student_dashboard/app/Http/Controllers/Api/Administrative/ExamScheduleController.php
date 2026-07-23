<?php

namespace App\Http\Controllers\Api\Administrative;

use App\Models\Academic\Level;
use App\Models\Academic\Major;
use App\Models\Academic\Subject;
use App\Models\Academic\Term;
use App\Models\ExamSchedule;
use App\Models\ExamScheduleItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ExamScheduleController extends AdministrativeApiController
{
    public function index(Request $request)
    {
        $query = ExamSchedule::whereHas('major', fn ($q) => $q->where('college_id', $this->college()->id))
            ->with(['major:id,name', 'level:id,name', 'term:id,name', 'creator:id,name', 'items.subject:id,name']);

        if ($request->filled('major_id')) {
            $query->where('major_id', $request->integer('major_id'));
        }

        if ($request->filled('level_id')) {
            $query->where('level_id', $request->integer('level_id'));
        }

        if ($request->filled('search')) {
            $search = trim((string) $request->input('search'));
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%")
                    ->orWhereHas('major', fn ($major) => $major->where('name', 'like', "%{$search}%"))
                    ->orWhereHas('level', fn ($level) => $level->where('name', 'like', "%{$search}%"))
                    ->orWhereHas('term', fn ($term) => $term->where('name', 'like', "%{$search}%"))
                    ->orWhereHas('items.subject', fn ($subject) => $subject->where('name', 'like', "%{$search}%"));
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
                    ExamSchedule::selectRaw('count(*)')
                        ->whereColumn('exam_schedules.major_id', 'majors.id'),
                    'exam_schedules_count'
                )
                ->get(),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'major_id' => 'required|exists:majors,id',
            'level_id' => 'required|exists:levels,id',
            'term_id' => 'required|exists:terms,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'is_published' => 'nullable|boolean',
            'items' => 'required|array|min:1',
            'items.*.subject_id' => 'required|exists:subjects,id',
            'items.*.exam_date' => 'required|date',
            'items.*.start_time' => 'required',
            'items.*.end_time' => 'required|after:items.*.start_time',
            'items.*.location' => 'nullable|string|max:255',
        ]);

        $this->assertScheduleScope($validated);

        $schedule = null;
        DB::transaction(function () use ($validated, &$schedule) {
            $schedule = ExamSchedule::create([
                'major_id' => $validated['major_id'],
                'level_id' => $validated['level_id'],
                'term_id' => $validated['term_id'],
                'title' => $validated['title'],
                'description' => $validated['description'] ?? null,
                'is_published' => (bool) ($validated['is_published'] ?? false),
                'created_by' => $this->administrative()->id,
            ]);

            foreach ($validated['items'] as $item) {
                ExamScheduleItem::create([
                    'exam_schedule_id' => $schedule->id,
                    'subject_id' => $item['subject_id'],
                    'exam_date' => $item['exam_date'],
                    'start_time' => $item['start_time'],
                    'end_time' => $item['end_time'],
                    'location' => $item['location'] ?? null,
                ]);
            }
        });

        return $this->success($schedule->load(['items.subject:id,name', 'major:id,name', 'level:id,name', 'term:id,name']), 'تم إنشاء جدول الاختبارات بنجاح', 201);
    }

    public function show(ExamSchedule $exam)
    {
        $this->ensureExamBelongsToCollege($exam);
        return $this->success($exam->load(['items.subject:id,name', 'major:id,name', 'level:id,name', 'term:id,name', 'creator:id,name']));
    }

    public function update(Request $request, ExamSchedule $exam)
    {
        $this->ensureExamBelongsToCollege($exam);

        $validated = $request->validate([
            'major_id' => 'required|exists:majors,id',
            'level_id' => 'required|exists:levels,id',
            'term_id' => 'required|exists:terms,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'is_published' => 'nullable|boolean',
            'items' => 'required|array|min:1',
            'items.*.subject_id' => 'required|exists:subjects,id',
            'items.*.exam_date' => 'required|date',
            'items.*.start_time' => 'required',
            'items.*.end_time' => 'required|after:items.*.start_time',
            'items.*.location' => 'nullable|string|max:255',
        ]);

        $this->assertScheduleScope($validated);

        DB::transaction(function () use ($validated, $exam) {
            $exam->update([
                'major_id' => $validated['major_id'],
                'level_id' => $validated['level_id'],
                'term_id' => $validated['term_id'],
                'title' => $validated['title'],
                'description' => $validated['description'] ?? null,
                'is_published' => (bool) ($validated['is_published'] ?? false),
            ]);

            $exam->items()->delete();
            foreach ($validated['items'] as $item) {
                ExamScheduleItem::create([
                    'exam_schedule_id' => $exam->id,
                    'subject_id' => $item['subject_id'],
                    'exam_date' => $item['exam_date'],
                    'start_time' => $item['start_time'],
                    'end_time' => $item['end_time'],
                    'location' => $item['location'] ?? null,
                ]);
            }
        });

        return $this->success($exam->fresh()->load(['items.subject:id,name', 'major:id,name', 'level:id,name', 'term:id,name']), 'تم تحديث جدول الاختبارات بنجاح');
    }

    public function destroy(ExamSchedule $exam)
    {
        $this->ensureExamBelongsToCollege($exam);
        $exam->delete();
        return $this->success(null, 'تم حذف جدول الاختبارات بنجاح');
    }

    public function getLevels(Major $major)
    {
        $this->ensureCollegeMajor($major);
        return $this->success($major->levels()->get(['id', 'name', 'major_id']));
    }

    public function getSubjects(Level $level)
    {
        $this->ensureCollegeLevel($level);

        return $this->success([
            'subjects' => Subject::where('major_id', $level->major_id)->where('level_id', $level->id)->get(['id', 'name', 'major_id', 'level_id']),
            'terms' => Term::where('level_id', $level->id)->get(['id', 'name', 'level_id']),
        ]);
    }

    protected function ensureExamBelongsToCollege(ExamSchedule $exam): void
    {
        if ($exam->major?->college_id !== $this->college()->id) {
            $this->forbid('جدول الاختبارات لا ينتمي إلى كليتك.');
        }
    }

    protected function assertScheduleScope(array $validated): void
    {
        $major = Major::findOrFail($validated['major_id']);
        $level = Level::with('major')->findOrFail($validated['level_id']);
        $term = Term::findOrFail($validated['term_id']);

        $this->ensureCollegeMajor($major);
        $this->ensureCollegeLevel($level);

        if ((int) $level->major_id !== (int) $major->id) {
            $this->forbid('المستوى المحدد لا يتبع التخصص المحدد.', 422);
        }

        if ((int) $term->level_id !== (int) $level->id) {
            $this->forbid('الترم المحدد لا يتبع المستوى المحدد.', 422);
        }

        foreach ($validated['items'] as $item) {
            $subject = Subject::findOrFail($item['subject_id']);
            if ((int) $subject->major_id !== (int) $major->id || (int) $subject->level_id !== (int) $level->id) {
                $this->forbid('أحد المواد لا ينتمي إلى التخصص أو المستوى المحدد.', 422);
            }
        }
    }
}
