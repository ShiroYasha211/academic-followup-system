<?php

namespace App\Services;

use App\Models\Clinical\StudentDailyLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;

class ClinicalLogbookPortfolioService
{
    public function studentsForDoctor(User $doctor, Request $request): LengthAwarePaginator
    {
        $query = User::query()
            ->with(['major:id,name', 'level:id,name'])
            ->whereHas('dailyLogsAsStudent', function (Builder $logs) use ($doctor, $request) {
                $this->scopeDoctorLogs($logs, $doctor, $request)
                    ->whereHas('activities', fn (Builder $activities) => $this->scopeApprovedActivities($activities));
            })
            ->when($request->filled('search'), function (Builder $query) use ($request) {
                $search = trim((string) $request->input('search'));
                $query->where(function (Builder $inner) use ($search) {
                    $inner->where('name', 'like', "%{$search}%")
                        ->orWhere('student_number', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%");
                });
            })
            ->when($request->filled('major_id'), fn (Builder $query) => $query->where('major_id', $request->integer('major_id')))
            ->when($request->filled('level_id'), fn (Builder $query) => $query->where('level_id', $request->integer('level_id')))
            ->orderBy('name');

        $paginator = $query->paginate((int) $request->input('per_page', 20))->withQueryString();
        $paginator->setCollection(
            $paginator->getCollection()->map(fn (User $student) => $this->studentListItem($doctor, $student, $request))
        );

        return $paginator;
    }

    public function portfolioForDoctor(User $doctor, User $student, Request $request): array
    {
        $logs = $this->logsQuery($doctor, $request)
            ->where('student_id', $student->id)
            ->get();

        $approvedActivities = $logs
            ->flatMap(fn (StudentDailyLog $log) => $log->activities->map(fn ($activity) => [
                'log' => $log,
                'activity' => $activity,
            ]))
            ->filter(fn (array $entry) => $this->isApprovedActivity($entry['activity']))
            ->values();

        $matrix = $this->buildMatrix($approvedActivities);
        $logsDetails = $this->buildLogDetails($logs);
        $activityTotals = $this->activityTotals($approvedActivities);

        return [
            'student' => $this->serializeStudent($student->loadMissing(['major:id,name', 'level:id,name'])),
            'summary' => [
                'approved_logs' => $logs->filter(fn (StudentDailyLog $log) => $log->activities->contains(fn ($activity) => $this->isApprovedActivity($activity)))->count(),
                'approved_activities' => $approvedActivities->count(),
                'history_taking' => $activityTotals['history_taking'] ?? 0,
                'clinical_examination' => $activityTotals['clinical_examination'] ?? 0,
                'round' => $activityTotals['round'] ?? 0,
                'body_systems_count' => count($matrix),
                'last_activity_at' => optional($approvedActivities->max(fn (array $entry) => $entry['activity']->confirmed_at ?? $entry['log']->confirmed_at ?? $entry['log']->log_date))?->toDateTimeString(),
            ],
            'matrix' => $matrix,
            'logs' => $logsDetails,
            'filters' => [
                'from' => $request->input('from'),
                'to' => $request->input('to'),
            ],
        ];
    }

    public function filtersForDoctor(User $doctor): array
    {
        $students = User::query()
            ->with(['major:id,name', 'level:id,name'])
            ->whereHas('dailyLogsAsStudent', fn (Builder $logs) => $logs->where('doctor_id', $doctor->id))
            ->get();

        return [
            'majors' => $students->pluck('major')->filter()->unique('id')->values()->map(fn ($major) => [
                'id' => $major->id,
                'name' => $major->name,
            ]),
            'levels' => $students->pluck('level')->filter()->unique('id')->values()->map(fn ($level) => [
                'id' => $level->id,
                'name' => $level->name,
            ]),
        ];
    }

    protected function logsQuery(User $doctor, Request $request): Builder
    {
        return StudentDailyLog::query()
            ->with([
                'student.major:id,name',
                'student.level:id,name',
                'trainingCenter:id,name',
                'department:id,name',
                'doctor:id,name',
                'confirmedBy:id,name',
                'caseAssignment.clinicalCase:id,patient_name,diagnosis_or_description',
                'activities.bodySystem:id,name',
                'activities.confirmedBy:id,name',
            ])
            ->where('doctor_id', $doctor->id)
            ->when($request->filled('from'), fn (Builder $query) => $query->whereDate('log_date', '>=', $request->input('from')))
            ->when($request->filled('to'), fn (Builder $query) => $query->whereDate('log_date', '<=', $request->input('to')))
            ->orderBy('log_date', 'desc')
            ->orderBy('id', 'desc');
    }

    protected function scopeDoctorLogs(Builder $logs, User $doctor, Request $request): Builder
    {
        return $logs
            ->where('doctor_id', $doctor->id)
            ->whereIn('status', ['confirmed', 'partially_confirmed'])
            ->when($request->filled('from'), fn (Builder $query) => $query->whereDate('log_date', '>=', $request->input('from')))
            ->when($request->filled('to'), fn (Builder $query) => $query->whereDate('log_date', '<=', $request->input('to')));
    }

    protected function scopeApprovedActivities(Builder $activities): Builder
    {
        return $activities->where(function (Builder $query) {
            $query->where('is_confirmed', true)
                ->orWhere('review_status', 'approved');
        });
    }

    protected function studentListItem(User $doctor, User $student, Request $request): array
    {
        $portfolio = $this->portfolioForDoctor($doctor, $student, $request);

        return [
            ...$this->serializeStudent($student),
            'summary' => $portfolio['summary'],
        ];
    }

    protected function buildMatrix(Collection $approvedActivities): array
    {
        return $approvedActivities
            ->groupBy(fn (array $entry) => $this->bodySystemName($entry['activity']))
            ->map(function (Collection $entries, string $bodySystem) {
                $history = $entries->where('activity.activity_type', 'history_taking')->count();
                $exam = $entries->where('activity.activity_type', 'clinical_examination')->count();
                $round = $entries->where('activity.activity_type', 'round')->count();

                return [
                    'body_system' => $bodySystem,
                    'history_taking' => $history,
                    'clinical_examination' => $exam,
                    'round' => $round,
                    'total' => $history + $exam + $round,
                ];
            })
            ->sortByDesc('total')
            ->values()
            ->all();
    }

    protected function buildLogDetails(Collection $logs): array
    {
        return $logs->map(function (StudentDailyLog $log) {
            $activities = $log->activities
                ->map(fn ($activity) => [
                    'id' => $activity->id,
                    'type' => $activity->activity_type,
                    'type_label' => $this->activityTypeLabel($activity->activity_type),
                    'body_system' => $this->bodySystemName($activity),
                    'case_name' => $activity->case_name,
                    'diagnosis' => $activity->diagnosis,
                    'confirmed_by' => $activity->confirmedBy?->name,
                    'confirmed_at' => optional($activity->confirmed_at)?->toIso8601String(),
                    'review_status' => $activity->is_confirmed ? 'approved' : ($activity->review_status ?: 'pending'),
                ])
                ->values();

            return [
                'id' => $log->id,
                'date' => optional($log->log_date)?->format('Y-m-d'),
                'time' => $log->log_time,
                'training_center' => $log->trainingCenter?->name,
                'department' => $log->department?->name,
                'doctor' => $log->doctor?->name,
                'status' => $log->status,
                'status_label' => $log->status_label,
                'doctor_notes' => $log->doctor_notes,
                'case_assignment' => $log->caseAssignment ? [
                    'id' => $log->caseAssignment->id,
                    'clinical_case' => $log->caseAssignment->clinicalCase?->patient_name
                        ?: $log->caseAssignment->clinicalCase?->diagnosis_or_description,
                ] : null,
                'activities' => $activities,
                'activities_count' => $activities->count(),
            ];
        })
            ->filter(fn (array $log) => $log['activities_count'] > 0)
            ->values()
            ->all();
    }

    protected function activityTotals(Collection $approvedActivities): array
    {
        return $approvedActivities
            ->groupBy(fn (array $entry) => $entry['activity']->activity_type)
            ->map(fn (Collection $items) => $items->count())
            ->all();
    }

    protected function serializeStudent(User $student): array
    {
        return [
            'id' => $student->id,
            'name' => $student->name,
            'student_number' => $student->student_number,
            'email' => $student->email,
            'major' => $student->major ? [
                'id' => $student->major->id,
                'name' => $student->major->name,
            ] : null,
            'level' => $student->level ? [
                'id' => $student->level->id,
                'name' => $student->level->name,
            ] : null,
        ];
    }

    protected function isApprovedActivity($activity): bool
    {
        return (bool) $activity->is_confirmed || $activity->review_status === 'approved';
    }

    protected function bodySystemName($activity): string
    {
        if ($activity->activity_type === 'round') {
            return $activity->case_name ?: 'المرور السريري';
        }

        return $activity->bodySystem?->name ?: 'غير مصنف';
    }

    protected function activityTypeLabel(string $type): string
    {
        return match ($type) {
            'history_taking' => 'قصة مرضية',
            'clinical_examination' => 'فحص سريري',
            'round' => 'مرور',
            default => $type,
        };
    }
}
