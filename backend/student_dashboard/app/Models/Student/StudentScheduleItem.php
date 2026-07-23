<?php

namespace App\Models\Student;

use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Model;

class StudentScheduleItem extends Model
{
    protected $fillable = [
        'user_id',
        'referenceable_type',
        'referenceable_id',
        'title',
        'scheduled_date',
        'is_completed',
        'completed_at',
        'sort_order',
        'note',
        'priority',
        'status',
        'item_type',
        'category_tag',
        'repeat_type',
        'reminder_at',
        'reminder_sent',
        'reminder_schedule_type',
        'reminder_time',
        'reminder_weekdays',
        'reminder_dates',
        'next_reminder_at',
        'last_reminder_sent_at',
    ];

    protected $casts = [
        'scheduled_date' => 'date',
        'is_completed' => 'boolean',
        'completed_at' => 'datetime',
        'reminder_at' => 'datetime',
        'reminder_sent' => 'boolean',
        'reminder_weekdays' => 'array',
        'reminder_dates' => 'array',
        'next_reminder_at' => 'datetime',
        'last_reminder_sent_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function referenceable()
    {
        return $this->morphTo();
    }

    public function studyColumns()
    {
        return $this->hasMany(StudySessionColumn::class)->orderBy('sort_order')->orderBy('id');
    }

    public function studyActions()
    {
        return $this->hasMany(StudySessionAction::class);
    }

    public function ensureDefaultStudyColumn(): StudySessionColumn
    {
        $column = $this->studyColumns()->first();

        if ($column) {
            return $column;
        }

        return $this->studyColumns()->create([
            'name' => 'مذاكرة',
            'sort_order' => 0,
        ]);
    }

    public function configureReminderSchedule(array $data): void
    {
        $scheduleType = $data['reminder_schedule_type']
            ?? $this->reminder_schedule_type
            ?? $this->legacyReminderScheduleType();

        $this->reminder_schedule_type = $scheduleType ?: 'none';
        $this->reminder_time = $data['reminder_time']
            ?? $this->reminder_time
            ?? $this->legacyReminderTime();
        $this->reminder_weekdays = $this->normalizeWeekdays(
            $data['reminder_weekdays'] ?? $this->reminder_weekdays ?? []
        );
        $this->reminder_dates = $this->normalizeReminderDates(
            $data['reminder_dates'] ?? $this->reminder_dates ?? []
        );
        $this->repeat_type = $this->legacyRepeatTypeFromSchedule($this->reminder_schedule_type);
        $this->next_reminder_at = $this->calculateNextReminderAt();
        $this->reminder_at = $this->next_reminder_at;
        $this->reminder_sent = $this->next_reminder_at === null;
    }

    public function markReminderSentAndScheduleNext(): void
    {
        $this->last_reminder_sent_at = now();
        $this->next_reminder_at = $this->calculateNextReminderAt(now()->addSecond());
        $this->reminder_at = $this->next_reminder_at;
        $this->reminder_sent = $this->next_reminder_at === null;
        $this->save();
    }

    public function calculateNextReminderAt(?Carbon $from = null): ?Carbon
    {
        $from ??= now();
        $type = $this->reminder_schedule_type ?: $this->legacyReminderScheduleType();

        if ($type === 'none') {
            return null;
        }

        $time = $this->normalizedReminderTime();

        return match ($type) {
            'daily' => $this->nextDailyReminder($from, $time),
            'weekly' => $this->nextWeeklyReminder($from, $time),
            'weekdays' => $this->nextWeekdayReminder($from, $time),
            'dates' => $this->nextDateReminder($from, $time),
            default => null,
        };
    }

    private function nextDailyReminder(Carbon $from, string $time): Carbon
    {
        $candidate = $from->copy()->setTimeFromTimeString($time);

        return $candidate->greaterThan($from) ? $candidate : $candidate->addDay();
    }

    private function nextWeeklyReminder(Carbon $from, string $time): Carbon
    {
        $weekday = $this->scheduled_date?->dayOfWeek ?? $from->dayOfWeek;

        return $this->nextForWeekdays($from, $time, [$weekday]);
    }

    private function nextWeekdayReminder(Carbon $from, string $time): ?Carbon
    {
        $weekdays = $this->normalizeWeekdays($this->reminder_weekdays ?? []);

        return empty($weekdays) ? null : $this->nextForWeekdays($from, $time, $weekdays);
    }

    private function nextForWeekdays(Carbon $from, string $time, array $weekdays): ?Carbon
    {
        $weekdays = $this->normalizeWeekdays($weekdays);

        for ($i = 0; $i < 14; $i++) {
            $candidate = $from->copy()->startOfDay()->addDays($i)->setTimeFromTimeString($time);
            if (in_array($candidate->dayOfWeek, $weekdays, true) && $candidate->greaterThan($from)) {
                return $candidate;
            }
        }

        return null;
    }

    private function nextDateReminder(Carbon $from, string $time): ?Carbon
    {
        foreach ($this->normalizeReminderDates($this->reminder_dates ?? []) as $date) {
            $candidate = Carbon::parse($date)->setTimeFromTimeString($time);
            if ($candidate->greaterThan($from)) {
                return $candidate;
            }
        }

        return null;
    }

    private function legacyReminderScheduleType(): string
    {
        if (($this->repeat_type ?? 'none') === 'daily') {
            return 'daily';
        }
        if (($this->repeat_type ?? 'none') === 'weekly') {
            return 'weekly';
        }

        return $this->reminder_at ? 'dates' : 'none';
    }

    private function legacyReminderTime(): ?string
    {
        return $this->reminder_at?->format('H:i:s');
    }

    private function normalizedReminderTime(): string
    {
        if ($this->reminder_time) {
            return Carbon::parse($this->reminder_time)->format('H:i:s');
        }

        return $this->legacyReminderTime() ?: '08:00:00';
    }

    private function legacyRepeatTypeFromSchedule(string $scheduleType): string
    {
        return match ($scheduleType) {
            'daily' => 'daily',
            'weekly', 'weekdays' => 'weekly',
            default => 'none',
        };
    }

    private function normalizeWeekdays(array $weekdays): array
    {
        return collect($weekdays)
            ->map(fn ($day) => is_numeric($day) ? (int) $day : null)
            ->filter(fn ($day) => $day !== null && $day >= 0 && $day <= 6)
            ->unique()
            ->sort()
            ->values()
            ->all();
    }

    private function normalizeReminderDates(array $dates): array
    {
        return collect($dates)
            ->map(function ($date) {
                try {
                    return Carbon::parse($date)->format('Y-m-d');
                } catch (\Throwable) {
                    return null;
                }
            })
            ->filter()
            ->unique()
            ->sort()
            ->values()
            ->all();
    }

    public function scopeStudyItems($query)
    {
        return $query->where('item_type', 'study');
    }

    public function scopeReminders($query)
    {
        return $query->where('item_type', 'reminder');
    }

    public function scopeMyResources($query)
    {
        return $query->where('item_type', 'resource');
    }

    public function scopeToday($query)
    {
        return $query->whereDate('scheduled_date', Carbon::today());
    }

    public function scopeOverdue($query)
    {
        return $query->where('is_completed', false)
            ->whereNotNull('scheduled_date')
            ->whereDate('scheduled_date', '<', Carbon::today());
    }

    public function scopeHighPriority($query)
    {
        return $query->where('priority', 'high');
    }

    public function scopePending($query)
    {
        return $query->where('is_completed', false);
    }

    public function scopeCompleted($query)
    {
        return $query->where('is_completed', true);
    }

    public function getIsOverdueAttribute(): bool
    {
        return !$this->is_completed
            && $this->scheduled_date
            && $this->scheduled_date->lt(Carbon::today());
    }

    public function getPriorityLabelAttribute(): string
    {
        return match ($this->priority) {
            'high' => 'Urgent',
            'medium' => 'Important',
            'low' => 'Normal',
            default => 'Normal',
        };
    }

    public function getPriorityColorAttribute(): string
    {
        return match ($this->priority) {
            'high' => '#ef4444',
            'medium' => '#f59e0b',
            'low' => '#10b981',
            default => '#64748b',
        };
    }

    public function getStatusColorAttribute(): string
    {
        if ($this->is_overdue) {
            return '#ef4444';
        }

        return match ($this->status) {
            'in_progress' => '#3b82f6',
            'completed' => '#10b981',
            'overdue' => '#ef4444',
            default => '#64748b',
        };
    }

    public function getStatusLabelAttribute(): string
    {
        if ($this->is_overdue) {
            return 'Overdue';
        }

        return match ($this->status) {
            'in_progress' => 'In Progress',
            'completed' => 'Completed',
            'overdue' => 'Overdue',
            default => 'Pending',
        };
    }

    public function getItemTypeLabelAttribute(): string
    {
        return match ($this->item_type) {
            'study' => 'Study Task',
            'reminder' => 'Reminder',
            'resource' => 'Saved Resource',
            'assignment' => 'Assignment',
            default => 'Study Task',
        };
    }

    public function getDisplayTitleAttribute(): string
    {
        if ($this->title) {
            return $this->title;
        }

        if ($this->referenceable) {
            return $this->referenceable->title ?? 'Untitled Item';
        }

        return 'Deleted Item';
    }
}
