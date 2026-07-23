<?php

namespace App\Http\Controllers\Api\Student;

use App\Models\Academic\Assignment;
use App\Models\Academic\Lecture;
use App\Models\CourseResource;
use App\Models\Student\StudentScheduleItem;
use App\Models\Student\StudySessionColumn;
use App\Models\Student\StudySessionAction;
use App\Services\StudyReminderNotificationService;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Http\Request;

class StudentScheduleController extends StudentApiController
{
    public function __construct(private readonly StudyReminderNotificationService $studyReminderNotifications)
    {
    }

    public function index(Request $request)
    {
        $student = $request->user();
        $tab = $this->normalizeTab($request->get('tab', 'study'));

        $stats = [
            'today' => StudentScheduleItem::where('user_id', $student->id)->pending()->today()->count(),
            'overdue' => StudentScheduleItem::where('user_id', $student->id)->overdue()->count(),
            'completed' => StudentScheduleItem::where('user_id', $student->id)
                ->completed()
                ->where('completed_at', '>=', now()->startOfWeek())
                ->count(),
            'high_priority' => StudentScheduleItem::where('user_id', $student->id)->pending()->highPriority()->count(),
            'total_pending' => StudentScheduleItem::where('user_id', $student->id)->pending()->count(),
            'study_count' => StudentScheduleItem::where('user_id', $student->id)->studyItems()->pending()->count(),
            'reminders_count' => StudentScheduleItem::where('user_id', $student->id)->reminders()->pending()->count(),
            'assignments_count' => StudentScheduleItem::where('user_id', $student->id)->where('item_type', 'assignment')->pending()->count(),
            'resources_count' => StudentScheduleItem::where('user_id', $student->id)->myResources()->count(),
        ];

        $query = StudentScheduleItem::where('user_id', $student->id)
            ->with([
                'referenceable' => function (MorphTo $morphTo) {
                    $morphTo->morphWith([
                        Lecture::class => ['subject:id,name,doctor_id', 'subject.doctor:id,name'],
                        CourseResource::class => ['subject:id,name', 'uploader:id,name'],
                        Assignment::class => ['subject:id,name', 'creator:id,name'],
                    ]);
                },
            ]);

        switch ($tab) {
            case 'reminders':
                $query->reminders()
                    ->where('is_completed', false)
                    ->orderByRaw("scheduled_date < CURDATE() DESC")
                    ->orderBy('scheduled_date', 'asc')
                    ->orderBy('reminder_at', 'asc');
                break;

            case 'assignments':
                $query->where('item_type', 'assignment')
                    ->orderByRaw('is_completed ASC')
                    ->orderByRaw("scheduled_date < CURDATE() DESC")
                    ->orderBy('scheduled_date', 'asc');
                break;

            case 'resources':
                $query->myResources()
                    ->orderBy('sort_order', 'asc')
                    ->orderBy('created_at', 'desc');
                break;

            default:
                $query->studyItems()
                    ->orderByRaw('CASE WHEN is_completed = 1 THEN 1 ELSE 0 END ASC')
                    ->orderByRaw('scheduled_date IS NULL ASC')
                    ->orderBy('scheduled_date', 'asc')
                    ->orderBy('sort_order', 'asc')
                    ->orderByRaw("CASE priority WHEN 'high' THEN 0 WHEN 'medium' THEN 1 WHEN 'low' THEN 2 END ASC");
                break;
        }

        if ($request->filled('filter')) {
            switch ($request->filter) {
                case 'overdue':
                    $query->overdue();
                    break;
                case 'completed':
                    $query->completed();
                    break;
                case 'today':
                    $query->today();
                    break;
                case 'high':
                    $query->highPriority();
                    break;
            }
        }

        $items = $query->get();

        foreach ($items as $item) {
            if ($item->is_overdue && $item->status !== 'overdue') {
                $item->update(['status' => 'overdue']);
            }
        }

        return $this->success([
            'feature' => [
                'key' => 'study_center',
                'label' => 'Study Center',
                'description' => 'Personal study hub for tasks, reminders, saved resources, and tracked assignments.',
                'notes' => [
                    'Use /api/student/schedules for the official weekly timetable.',
                    'Use /api/student/study-center for the personal study center.',
                ],
            ],
            'stats' => $stats,
            'tab' => $tab,
            'tabs' => [
                ['key' => 'study', 'label' => 'Study Tasks'],
                ['key' => 'reminders', 'label' => 'Reminders'],
                ['key' => 'resources', 'label' => 'Saved Resources'],
                ['key' => 'assignments', 'label' => 'Tracked Assignments'],
            ],
            'items' => $items->map(fn (StudentScheduleItem $item) => $this->transformItem($item))->values(),
        ], 'Study center retrieved successfully.');
    }

    public function session(Request $request, int $id)
    {
        $item = $this->studentItem($request, $id);
        $item->ensureDefaultStudyColumn();

        return $this->success($this->transformSession($item->fresh([
            'referenceable',
            'studyColumns.actions',
            'studyActions',
        ])), 'Study session loaded successfully.');
    }

    public function storeColumn(Request $request, int $id)
    {
        $item = $this->studentItem($request, $id);

        $validated = $request->validate([
            'name' => 'required|string|max:80',
        ]);

        $item->studyColumns()->create([
            'name' => trim($validated['name']),
            'sort_order' => (int) $item->studyColumns()->max('sort_order') + 1,
        ]);

        return $this->success($this->transformSession($item->fresh([
            'referenceable',
            'studyColumns.actions',
            'studyActions',
        ])), 'Study session column created successfully.', 201);
    }

    public function updateColumn(Request $request, StudySessionColumn $column)
    {
        $this->authorizeColumn($request, $column);

        $validated = $request->validate([
            'name' => 'required|string|max:80',
        ]);

        $column->update(['name' => trim($validated['name'])]);

        return $this->success($this->transformSession($column->scheduleItem->fresh([
            'referenceable',
            'studyColumns.actions',
            'studyActions',
        ])), 'Study session column updated successfully.');
    }

    public function destroyColumn(Request $request, StudySessionColumn $column)
    {
        $this->authorizeColumn($request, $column);

        $item = $column->scheduleItem;
        if ($item->studyColumns()->count() <= 1) {
            return $this->error('At least one study column is required.', 422);
        }

        $column->delete();

        return $this->success($this->transformSession($item->fresh([
            'referenceable',
            'studyColumns.actions',
            'studyActions',
        ])), 'Study session column deleted successfully.');
    }

    public function incrementColumn(Request $request, StudySessionColumn $column)
    {
        $this->authorizeColumn($request, $column);

        $item = $column->scheduleItem;

        StudySessionAction::create([
            'student_schedule_item_id' => $item->id,
            'study_session_column_id' => $column->id,
            'user_id' => $request->user()->id,
            'action_type' => 'increment',
            'occurred_at' => now(),
        ]);

        if (! $item->is_completed && $item->status === 'pending') {
            $item->update(['status' => 'in_progress']);
        }

        return $this->success($this->transformSession($item->fresh([
            'referenceable',
            'studyColumns.actions',
            'studyActions',
        ])), 'Study action recorded successfully.');
    }

    public function undoLastAction(Request $request, int $id)
    {
        $item = $this->studentItem($request, $id);

        $lastAction = $item->studyActions()
            ->where('user_id', $request->user()->id)
            ->latest('occurred_at')
            ->latest('id')
            ->first();

        if (! $lastAction) {
            return $this->error('There is no study action to undo.', 422);
        }

        $lastAction->delete();

        if (! $item->is_completed && $item->studyActions()->count() === 0) {
            $item->update(['status' => 'pending']);
        }

        return $this->success($this->transformSession($item->fresh([
            'referenceable',
            'studyColumns.actions',
            'studyActions',
        ])), 'Last study action undone successfully.');
    }

    public function undoColumnLastAction(Request $request, StudySessionColumn $column)
    {
        $this->authorizeColumn($request, $column);

        $lastAction = $column->actions()
            ->where('user_id', $request->user()->id)
            ->latest('occurred_at')
            ->latest('id')
            ->first();

        if (! $lastAction) {
            return $this->error('There is no study action to undo in this column.', 422);
        }

        $item = $column->scheduleItem;
        $lastAction->delete();

        if (! $item->is_completed && $item->studyActions()->count() === 0) {
            $item->update(['status' => 'pending']);
        }

        return $this->success($this->transformSession($item->fresh([
            'referenceable',
            'studyColumns.actions',
            'studyActions',
        ])), 'Last column study action undone successfully.');
    }

    public function store(Request $request)
    {
        $request->validate([
            'referenceable_type' => 'nullable|string',
            'referenceable_id' => 'nullable|integer',
            'title' => 'nullable|string|max:255',
            'scheduled_date' => 'nullable|date',
            'note' => 'nullable|string',
            'priority' => 'nullable|in:high,medium,low',
            'item_type' => 'nullable|in:study,reminder,resource',
            'category_tag' => 'nullable|string|max:100',
            'repeat_type' => 'nullable|in:none,daily,weekly',
            'reminder_at' => 'nullable|date',
            ...$this->reminderScheduleValidationRules(),
        ]);

        $student = $request->user();
        $modelClass = null;

        if ($request->referenceable_type) {
            $typeMap = [
                'lecture' => Lecture::class,
                'resource' => CourseResource::class,
                'assignment' => Assignment::class,
            ];

            $modelClass = $typeMap[$request->referenceable_type] ?? $request->referenceable_type;

            if (!class_exists($modelClass)) {
                return $this->error('Invalid referenceable type.', 400);
            }

            if ($request->referenceable_id && !$modelClass::find($request->referenceable_id)) {
                return $this->error('Referenced content was not found.', 404);
            }

            $exists = StudentScheduleItem::where('user_id', $student->id)
                ->where('referenceable_type', $modelClass)
                ->where('referenceable_id', $request->referenceable_id)
                ->exists();

            if ($exists) {
                return $this->error('This source is already saved in the study center.', 400);
            }
        }

        $itemType = $request->item_type ?? 'study';

        if (!$request->item_type && $modelClass) {
            $itemType = match ($modelClass) {
                CourseResource::class => 'resource',
                Assignment::class => 'assignment',
                default => 'study',
            };
        }

        $item = StudentScheduleItem::create([
            'user_id' => $student->id,
            'referenceable_type' => $modelClass,
            'referenceable_id' => $request->referenceable_id,
            'title' => $request->title,
            'scheduled_date' => $request->scheduled_date,
            'note' => $request->note,
            'priority' => $request->priority ?? 'medium',
            'item_type' => $itemType,
            'category_tag' => $request->category_tag,
            'repeat_type' => $request->repeat_type ?? 'none',
            'reminder_at' => $request->reminder_at,
            'sort_order' => StudentScheduleItem::where('user_id', $student->id)->max('sort_order') + 1,
        ]);

        $item->configureReminderSchedule($this->reminderSchedulePayload($request));
        $item->save();
        $item->ensureDefaultStudyColumn();

        return $this->success([
            'item' => $this->transformItem($item->fresh('referenceable')),
        ], 'Item added to the study center successfully.', 201);
    }

    public function storeCustomTask(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'scheduled_date' => 'nullable|date',
            'note' => 'nullable|string',
            'priority' => 'nullable|in:high,medium,low',
            'item_type' => 'required|in:study,reminder,resource',
            'category_tag' => 'nullable|string|max:100',
            'repeat_type' => 'nullable|in:none,daily,weekly',
            'reminder_at' => 'nullable|date',
            ...$this->reminderScheduleValidationRules(),
        ]);

        $student = $request->user();

        $item = StudentScheduleItem::create([
            'user_id' => $student->id,
            'referenceable_type' => null,
            'referenceable_id' => null,
            'title' => $request->title,
            'scheduled_date' => $request->scheduled_date,
            'note' => $request->note,
            'priority' => $request->priority ?? 'medium',
            'item_type' => $request->item_type,
            'category_tag' => $request->category_tag,
            'repeat_type' => $request->repeat_type ?? 'none',
            'reminder_at' => $request->reminder_at,
            'sort_order' => StudentScheduleItem::where('user_id', $student->id)->max('sort_order') + 1,
        ]);

        $item->configureReminderSchedule($this->reminderSchedulePayload($request));
        $item->save();
        $item->ensureDefaultStudyColumn();

        return $this->success([
            'item' => $this->transformItem($item),
        ], 'Custom study center item added successfully.', 201);
    }

    public function update(Request $request, $id)
    {
        $student = $request->user();
        $item = StudentScheduleItem::where('user_id', $student->id)->findOrFail($id);
        $message = 'Study center item updated successfully.';

        $request->validate([
            'is_completed' => 'sometimes|boolean',
            'scheduled_date' => 'nullable|date',
            'note' => 'nullable|string',
            'title' => 'nullable|string|max:255',
            'priority' => 'nullable|in:high,medium,low',
            'status' => 'nullable|in:pending,in_progress,completed,overdue',
            'category_tag' => 'nullable|string|max:100',
            'reminder_at' => 'nullable|date',
            ...$this->reminderScheduleValidationRules(),
        ]);

        if (
            $request->has('is_completed')
            && $request->boolean('is_completed')
            && $item->repeat_type !== 'none'
            && ($item->reminder_schedule_type === null || $item->reminder_schedule_type === 'none')
        ) {
            $currentDate = $item->scheduled_date ? Carbon::parse($item->scheduled_date) : Carbon::today();
            $originalReminderTime = $item->reminder_at ? Carbon::parse($item->reminder_at)->format('H:i:s') : null;
            $nextDate = $currentDate->copy();

            if ($item->repeat_type === 'daily') {
                $nextDate = $currentDate->isPast() ? Carbon::tomorrow() : $currentDate->addDay();
            } elseif ($item->repeat_type === 'weekly') {
                $nextDate = $currentDate->isPast() ? Carbon::today()->addWeek() : $currentDate->addWeek();
            }

            $newItem = $item->replicate();
            $newItem->scheduled_date = $nextDate;
            $newItem->status = 'pending';
            $newItem->is_completed = false;
            $newItem->completed_at = null;
            $newItem->reminder_sent = false;

            if ($originalReminderTime) {
                $newItem->reminder_at = $nextDate->copy()->setTimeFromTimeString($originalReminderTime);
            }

            $newItem->save();
            $message = 'Recurring item completed and next occurrence scheduled successfully.';
        }

        if ($request->has('is_completed')) {
            $item->is_completed = $request->boolean('is_completed');
            $item->completed_at = $request->boolean('is_completed') ? now() : null;
            $item->status = $request->boolean('is_completed') ? 'completed' : 'pending';
        }

        if ($request->has('scheduled_date')) {
            $item->scheduled_date = $request->scheduled_date;
        }
        if ($request->has('note')) {
            $item->note = $request->note;
        }
        if ($request->has('title')) {
            $item->title = $request->title;
        }
        if ($request->has('priority')) {
            $item->priority = $request->priority;
        }
        if ($request->has('status')) {
            $item->status = $request->status;
        }
        if ($request->has('category_tag')) {
            $item->category_tag = $request->category_tag;
        }
        if ($request->has('reminder_at')) {
            $item->reminder_at = $request->reminder_at;
        }
        if ($this->requestHasReminderSchedule($request)) {
            $item->configureReminderSchedule($this->reminderSchedulePayload($request));
        }

        $item->save();

        return $this->success([
            'item' => $this->transformItem($item->fresh('referenceable')),
        ], $message);
    }

    public function destroy(Request $request, $id)
    {
        $student = $request->user();
        $item = StudentScheduleItem::where('user_id', $student->id)->findOrFail($id);
        $item->delete();

        return $this->success([], 'Study center item deleted successfully.');
    }

    public function reorder(Request $request)
    {
        $request->validate([
            'items' => 'required|array',
            'items.*.id' => 'required|integer',
            'items.*.order' => 'required|integer',
        ]);

        $student = $request->user();

        foreach ($request->items as $itemData) {
            StudentScheduleItem::where('user_id', $student->id)
                ->where('id', $itemData['id'])
                ->update(['sort_order' => $itemData['order']]);
        }

        return $this->success([], 'Study center items reordered successfully.');
    }

    public function checkReminders(Request $request)
    {
        $student = $request->user();

        $dueReminders = StudentScheduleItem::where('user_id', $student->id)
            ->where('is_completed', false)
            ->where(function ($query) {
                $query->where(function ($nextQuery) {
                    $nextQuery->whereNotNull('next_reminder_at')
                        ->where('next_reminder_at', '<=', now());
                })->orWhere(function ($legacyQuery) {
                    $legacyQuery->whereNull('next_reminder_at')
                        ->where('reminder_sent', false)
                        ->whereNotNull('reminder_at')
                        ->where('reminder_at', '<=', now());
                });
            })
            ->get();

        $results = [];

        foreach ($dueReminders as $reminder) {
            $notification = $this->studyReminderNotifications->notify(
                $reminder,
                'تذكير من مركز الدراسة',
                "حان وقت تنفيذ: {$reminder->display_title}"
            );
            $reminder->markReminderSentAndScheduleNext();
            $results[] = [
                'id' => $reminder->id,
                'title' => $reminder->display_title,
                'scheduled_date' => $reminder->scheduled_date?->format('Y-m-d'),
                'priority' => $reminder->priority,
                'priority_label' => $reminder->priority_label,
                'notification_id' => $notification->id,
            ];
        }

        return $this->success([
            'reminders' => $results,
            'count' => count($results),
        ], 'Due reminders checked successfully.');
    }

    private function normalizeTab(?string $tab): string
    {
        return in_array($tab, ['study', 'reminders', 'resources', 'assignments'], true)
            ? $tab
            : 'study';
    }

    private function reminderScheduleValidationRules(): array
    {
        return [
            'reminder_schedule_type' => 'nullable|in:none,daily,weekly,weekdays,dates',
            'reminder_time' => 'nullable|date_format:H:i',
            'reminder_weekdays' => 'nullable|array',
            'reminder_weekdays.*' => 'integer|min:0|max:6',
            'reminder_dates' => 'nullable|array',
            'reminder_dates.*' => 'date',
        ];
    }

    private function requestHasReminderSchedule(Request $request): bool
    {
        return $request->hasAny([
            'reminder_schedule_type',
            'reminder_time',
            'reminder_weekdays',
            'reminder_dates',
            'reminder_at',
        ]);
    }

    private function reminderSchedulePayload(Request $request): array
    {
        $payload = $request->only([
            'reminder_schedule_type',
            'reminder_time',
            'reminder_weekdays',
            'reminder_dates',
        ]);

        if ($request->filled('reminder_at') && empty($payload['reminder_schedule_type'])) {
            $reminderAt = Carbon::parse($request->reminder_at);
            $payload['reminder_schedule_type'] = 'dates';
            $payload['reminder_time'] = $reminderAt->format('H:i');
            $payload['reminder_dates'] = [$reminderAt->format('Y-m-d')];
        }

        if (($payload['reminder_schedule_type'] ?? null) === 'weekly' && empty($payload['reminder_weekdays'])) {
            $scheduledDate = $request->filled('scheduled_date') ? Carbon::parse($request->scheduled_date) : now();
            $payload['reminder_weekdays'] = [$scheduledDate->dayOfWeek];
        }

        return $payload;
    }

    private function transformItem(StudentScheduleItem $item): array
    {
        return [
            'id' => $item->id,
            'title' => $item->display_title,
            'custom_title' => $item->title,
            'item_type' => $item->item_type,
            'item_type_label' => $item->item_type_label,
            'priority' => $item->priority,
            'priority_label' => $item->priority_label,
            'priority_color' => $item->priority_color,
            'status' => $item->status,
            'status_label' => $item->status_label,
            'status_color' => $item->status_color,
            'is_completed' => $item->is_completed,
            'is_overdue' => $item->is_overdue,
            'scheduled_date' => $item->scheduled_date?->format('Y-m-d'),
            'completed_at' => $item->completed_at?->toIso8601String(),
            'reminder_at' => $item->reminder_at?->toIso8601String(),
            'repeat_type' => $item->repeat_type,
            'reminder_schedule' => [
                'type' => $item->reminder_schedule_type ?: 'none',
                'time' => $item->reminder_time ? Carbon::parse($item->reminder_time)->format('H:i') : null,
                'weekdays' => $item->reminder_weekdays ?? [],
                'dates' => $item->reminder_dates ?? [],
                'next_reminder_at' => $item->next_reminder_at?->toIso8601String(),
                'last_sent_at' => $item->last_reminder_sent_at?->toIso8601String(),
            ],
            'category_tag' => $item->category_tag,
            'note' => $item->note,
            'reference' => $this->transformReference($item->referenceable),
            'session_enabled' => true,
            'session_summary' => [
                'columns_count' => $item->studyColumns()->count(),
                'total_actions' => $item->studyActions()->count(),
            ],
        ];
    }

    private function transformSession(StudentScheduleItem $item): array
    {
        $item->loadMissing(['referenceable', 'studyColumns.actions', 'studyActions']);

        $lastAction = $item->studyActions()
            ->with('column:id,name')
            ->latest('occurred_at')
            ->latest('id')
            ->first();

        return [
            'item' => $this->transformItem($item),
            'columns' => $item->studyColumns->map(function (StudySessionColumn $column) {
                $actions = $column->actions->sortByDesc('occurred_at');

                return [
                    'id' => $column->id,
                    'name' => $column->name,
                    'sort_order' => $column->sort_order,
                    'actions_count' => $column->actions->count(),
                    'can_undo' => $column->actions->isNotEmpty(),
                    'last_action_at' => optional($actions->first())->occurred_at?->toIso8601String(),
                ];
            })->values(),
            'total_actions' => $item->studyActions->count(),
            'can_undo' => $lastAction !== null,
            'last_action' => $lastAction ? [
                'id' => $lastAction->id,
                'column_id' => $lastAction->study_session_column_id,
                'column_name' => $lastAction->column?->name,
                'occurred_at' => $lastAction->occurred_at?->toIso8601String(),
            ] : null,
        ];
    }

    private function studentItem(Request $request, int $id): StudentScheduleItem
    {
        return StudentScheduleItem::where('user_id', $request->user()->id)
            ->with([
                'referenceable' => function (MorphTo $morphTo) {
                    $morphTo->morphWith([
                        Lecture::class => ['subject:id,name,doctor_id', 'subject.doctor:id,name'],
                    ]);
                },
                'studyColumns.actions',
                'studyActions',
            ])
            ->findOrFail($id);
    }

    private function authorizeColumn(Request $request, StudySessionColumn $column): void
    {
        abort_if(
            (int) $column->scheduleItem->user_id !== (int) $request->user()->id,
            404
        );
    }

    private function transformReference($reference): ?array
    {
        if (!$reference) {
            return null;
        }

        if ($reference instanceof Lecture) {
            $reference->loadMissing(['subject:id,name,doctor_id', 'subject.doctor:id,name']);

            return [
                'type' => 'lecture',
                'type_label' => 'Lecture',
                'id' => $reference->id,
                'subject' => $reference->subject ? [
                    'id' => $reference->subject->id,
                    'name' => $reference->subject->name,
                ] : null,
                'owner' => $reference->subject?->doctor ? [
                    'id' => $reference->subject->doctor->id,
                    'name' => $reference->subject->doctor->name,
                ] : null,
                'meta' => [
                    'lecture_number' => $reference->lecture_number,
                    'lecture_type' => $reference->lecture_type,
                    'date' => $reference->date?->format('Y-m-d'),
                    'start_time' => $reference->start_time,
                    'end_time' => $reference->end_time,
                ],
            ];
        }

        if ($reference instanceof CourseResource) {
            $reference->loadMissing(['subject:id,name', 'uploader:id,name']);

            return [
                'type' => 'resource',
                'type_label' => 'Resource',
                'id' => $reference->id,
                'subject' => $reference->subject ? [
                    'id' => $reference->subject->id,
                    'name' => $reference->subject->name,
                ] : null,
                'owner' => $reference->uploader ? [
                    'id' => $reference->uploader->id,
                    'name' => $reference->uploader->name,
                ] : null,
                'meta' => [
                    'category' => $reference->category,
                    'sub_category' => $reference->sub_category,
                    'file_type' => $reference->file_type,
                    'semester_info' => $reference->semester_info,
                    'visibility' => $reference->visibility,
                ],
            ];
        }

        if ($reference instanceof Assignment) {
            $reference->loadMissing(['subject:id,name', 'creator:id,name']);

            return [
                'type' => 'assignment',
                'type_label' => 'Assignment',
                'id' => $reference->id,
                'subject' => $reference->subject ? [
                    'id' => $reference->subject->id,
                    'name' => $reference->subject->name,
                ] : null,
                'owner' => $reference->creator ? [
                    'id' => $reference->creator->id,
                    'name' => $reference->creator->name,
                ] : null,
                'meta' => [
                    'due_date' => $reference->due_date?->format('Y-m-d'),
                    'requires_submission' => $reference->requires_submission,
                ],
            ];
        }

        return [
            'type' => class_basename($reference),
            'type_label' => class_basename($reference),
            'id' => $reference->id ?? null,
            'subject' => null,
            'owner' => null,
            'meta' => [],
        ];
    }
}
