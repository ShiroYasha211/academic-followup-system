<?php

namespace App\Services;

use App\Models\Clinical\EvaluationChecklist;
use App\Models\Clinical\StudentEvaluation;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;

class ClinicalEvaluationPortfolioService
{
    public function studentsForDoctor(User $doctor, Request $request): LengthAwarePaginator
    {
        $aggregate = $this->evaluationQuery($doctor, $request)
            ->select('student_id')
            ->selectRaw('COUNT(*) as attempts_count')
            ->selectRaw('COUNT(DISTINCT checklist_id) as checklists_count')
            ->selectRaw('COUNT(DISTINCT doctor_id) as doctors_count')
            ->selectRaw('ROUND(AVG(percentage), 1) as average_percentage')
            ->selectRaw('MAX(percentage) as highest_percentage')
            ->selectRaw('MIN(percentage) as lowest_percentage')
            ->selectRaw('COALESCE(SUM(time_taken_seconds), 0) as total_time_seconds')
            ->selectRaw("SUM(CASE WHEN grade IN ('excellent', 'good', 'acceptable') THEN 1 ELSE 0 END) as passed_count")
            ->selectRaw('MAX(created_at) as last_evaluation_at')
            ->groupBy('student_id');

        $query = User::query()
            ->with(['major:id,name', 'level:id,name'])
            ->joinSub($aggregate->toBase(), 'evaluation_summary', function ($join) {
                $join->on('users.id', '=', 'evaluation_summary.student_id');
            })
            ->select([
                'users.*',
                'evaluation_summary.attempts_count',
                'evaluation_summary.checklists_count',
                'evaluation_summary.doctors_count',
                'evaluation_summary.average_percentage',
                'evaluation_summary.highest_percentage',
                'evaluation_summary.lowest_percentage',
                'evaluation_summary.total_time_seconds',
                'evaluation_summary.passed_count',
                'evaluation_summary.last_evaluation_at',
            ])
            ->when($request->filled('search'), function (Builder $query) use ($request) {
                $search = trim((string) $request->input('search'));
                $query->where(function (Builder $inner) use ($search) {
                    $inner->where('users.name', 'like', "%{$search}%")
                        ->orWhere('users.student_number', 'like', "%{$search}%")
                        ->orWhere('users.email', 'like', "%{$search}%");
                });
            })
            ->when(
                $request->filled('major_id'),
                fn (Builder $query) => $query->where('users.major_id', $request->integer('major_id'))
            )
            ->when(
                $request->filled('level_id'),
                fn (Builder $query) => $query->where('users.level_id', $request->integer('level_id'))
            );

        match ($request->input('sort', 'latest')) {
            'name' => $query->orderBy('users.name'),
            'average' => $query->orderByDesc('evaluation_summary.average_percentage'),
            'attempts' => $query->orderByDesc('evaluation_summary.attempts_count'),
            default => $query->orderByDesc('evaluation_summary.last_evaluation_at'),
        };

        $paginator = $query
            ->paginate(min(max((int) $request->input('per_page', 20), 1), 100))
            ->withQueryString();

        $paginator->setCollection(
            $paginator->getCollection()->map(fn (User $student) => $this->studentListItem($student))
        );

        return $paginator;
    }

    public function portfolioForDoctor(User $doctor, User $student, Request $request): array
    {
        $this->ensureStudentInCollege($doctor, $student);

        $evaluations = $this->evaluationQuery($doctor, $request)
            ->with([
                'doctor:id,name,email',
                'checklist:id,title,skill_type,total_marks',
                'bodySystem:id,name',
                'clinicalCase:id,patient_name,diagnosis_or_description',
            ])
            ->where('student_id', $student->id)
            ->latest()
            ->get();

        return [
            'student' => $this->serializeStudent(
                $student->loadMissing(['major:id,name', 'level:id,name'])
            ),
            'summary' => $this->summary($evaluations),
            'checklists' => $this->checklistMatrix($evaluations),
            'attempts' => $evaluations
                ->map(fn (StudentEvaluation $evaluation) => $this->serializeAttempt($evaluation))
                ->values()
                ->all(),
            'filters' => [
                'date_from' => $request->input('date_from'),
                'date_to' => $request->input('date_to'),
                'checklist_id' => $request->input('checklist_id'),
                'doctor_id' => $request->input('doctor_id'),
            ],
        ];
    }

    public function filtersForDoctor(User $doctor): array
    {
        $query = $this->evaluationQuery($doctor, new Request());
        $students = User::query()
            ->with(['major:id,name', 'level:id,name'])
            ->whereIn('id', (clone $query)->select('student_id')->distinct())
            ->get();

        return [
            'majors' => $students->pluck('major')->filter()->unique('id')->values()->map(fn ($major) => [
                'id' => $major->id,
                'name' => $major->name,
            ])->all(),
            'levels' => $students->pluck('level')->filter()->unique('id')->values()->map(fn ($level) => [
                'id' => $level->id,
                'name' => $level->name,
            ])->all(),
            'checklists' => EvaluationChecklist::query()
                ->whereIn('id', (clone $query)->select('checklist_id')->distinct())
                ->orderBy('title')
                ->get(['id', 'title', 'skill_type'])
                ->map(fn ($checklist) => [
                    'id' => $checklist->id,
                    'title' => $checklist->title,
                    'skill_type' => $checklist->skill_type,
                    'skill_label' => $this->skillLabel($checklist->skill_type),
                ])->all(),
            'doctors' => User::query()
                ->whereIn('id', (clone $query)->select('doctor_id')->distinct())
                ->orderBy('name')
                ->get(['id', 'name'])
                ->all(),
        ];
    }

    protected function evaluationQuery(User $doctor, Request $request): Builder
    {
        $query = StudentEvaluation::query();

        if ($doctor->college_id) {
            $query
                ->whereHas('doctor', fn (Builder $doctorQuery) => $doctorQuery
                    ->where('college_id', $doctor->college_id))
                ->whereHas('student', fn (Builder $studentQuery) => $studentQuery
                    ->where('college_id', $doctor->college_id));
        } else {
            $query->where('doctor_id', $doctor->id);
        }

        return $query
            ->when(
                $request->filled('date_from'),
                fn (Builder $query) => $query->whereDate('created_at', '>=', $request->input('date_from'))
            )
            ->when(
                $request->filled('date_to'),
                fn (Builder $query) => $query->whereDate('created_at', '<=', $request->input('date_to'))
            )
            ->when(
                $request->filled('checklist_id'),
                fn (Builder $query) => $query->where('checklist_id', $request->integer('checklist_id'))
            )
            ->when(
                $request->filled('doctor_id'),
                fn (Builder $query) => $query->where('doctor_id', $request->integer('doctor_id'))
            );
    }

    protected function ensureStudentInCollege(User $doctor, User $student): void
    {
        if ($doctor->college_id) {
            abort_unless((int) $student->college_id === (int) $doctor->college_id, 403);
        }
    }

    protected function studentListItem(User $student): array
    {
        $attempts = (int) $student->getAttribute('attempts_count');
        $passed = (int) $student->getAttribute('passed_count');

        return [
            ...$this->serializeStudent($student),
            'summary' => [
                'attempts_count' => $attempts,
                'checklists_count' => (int) $student->getAttribute('checklists_count'),
                'doctors_count' => (int) $student->getAttribute('doctors_count'),
                'average_percentage' => (float) $student->getAttribute('average_percentage'),
                'highest_percentage' => (float) $student->getAttribute('highest_percentage'),
                'lowest_percentage' => (float) $student->getAttribute('lowest_percentage'),
                'passed_count' => $passed,
                'failed_count' => max(0, $attempts - $passed),
                'pass_rate' => $attempts > 0 ? round(($passed / $attempts) * 100, 1) : 0,
                'total_time_seconds' => (int) $student->getAttribute('total_time_seconds'),
                'formatted_total_time' => $this->formatSeconds(
                    (int) $student->getAttribute('total_time_seconds')
                ),
                'last_evaluation_at' => $student->getAttribute('last_evaluation_at'),
            ],
        ];
    }

    protected function summary(Collection $evaluations): array
    {
        $total = $evaluations->count();
        $passed = $evaluations->whereIn('grade', ['excellent', 'good', 'acceptable'])->count();
        $totalTime = (int) $evaluations->sum('time_taken_seconds');

        return [
            'attempts_count' => $total,
            'checklists_count' => $evaluations->pluck('checklist_id')->filter()->unique()->count(),
            'doctors_count' => $evaluations->pluck('doctor_id')->filter()->unique()->count(),
            'average_percentage' => round((float) $evaluations->avg('percentage'), 1),
            'highest_percentage' => (float) ($evaluations->max('percentage') ?? 0),
            'lowest_percentage' => (float) ($evaluations->min('percentage') ?? 0),
            'passed_count' => $passed,
            'failed_count' => max(0, $total - $passed),
            'pass_rate' => $total > 0 ? round(($passed / $total) * 100, 1) : 0,
            'total_time_seconds' => $totalTime,
            'formatted_total_time' => $this->formatSeconds($totalTime),
            'last_evaluation_at' => optional($evaluations->max('created_at'))?->toIso8601String(),
        ];
    }

    protected function checklistMatrix(Collection $evaluations): array
    {
        return $evaluations
            ->groupBy('checklist_id')
            ->map(function (Collection $attempts) {
                /** @var StudentEvaluation $latest */
                $latest = $attempts->sortByDesc('created_at')->first();

                return [
                    'checklist_id' => $latest->checklist_id,
                    'title' => $latest->checklist?->title ?? 'قائمة محذوفة',
                    'skill_type' => $latest->checklist?->skill_type,
                    'skill_label' => $this->skillLabel($latest->checklist?->skill_type),
                    'attempts_count' => $attempts->count(),
                    'doctors' => $attempts
                        ->pluck('doctor')
                        ->filter()
                        ->unique('id')
                        ->values()
                        ->map(fn (User $doctor) => ['id' => $doctor->id, 'name' => $doctor->name])
                        ->all(),
                    'average_percentage' => round((float) $attempts->avg('percentage'), 1),
                    'highest_percentage' => (float) ($attempts->max('percentage') ?? 0),
                    'lowest_percentage' => (float) ($attempts->min('percentage') ?? 0),
                    'last_evaluation_at' => optional($latest->created_at)?->toIso8601String(),
                    'latest_grade' => $latest->grade,
                    'latest_grade_label' => $this->gradeLabel($latest->grade),
                ];
            })
            ->sortByDesc('last_evaluation_at')
            ->values()
            ->all();
    }

    protected function serializeAttempt(StudentEvaluation $evaluation): array
    {
        return [
            'id' => $evaluation->id,
            'checklist' => $evaluation->checklist ? [
                'id' => $evaluation->checklist->id,
                'title' => $evaluation->checklist->title,
                'skill_type' => $evaluation->checklist->skill_type,
                'skill_label' => $this->skillLabel($evaluation->checklist->skill_type),
            ] : null,
            'doctor' => $evaluation->doctor ? [
                'id' => $evaluation->doctor->id,
                'name' => $evaluation->doctor->name,
            ] : null,
            'body_system' => $evaluation->bodySystem ? [
                'id' => $evaluation->bodySystem->id,
                'name' => $evaluation->bodySystem->name,
            ] : null,
            'clinical_case' => $evaluation->clinicalCase ? [
                'id' => $evaluation->clinicalCase->id,
                'name' => $evaluation->clinicalCase->patient_name
                    ?: $evaluation->clinicalCase->diagnosis_or_description,
            ] : null,
            'total_score' => (float) $evaluation->total_score,
            'max_score' => (float) $evaluation->max_score,
            'percentage' => (float) $evaluation->percentage,
            'grade' => $evaluation->grade,
            'grade_label' => $this->gradeLabel($evaluation->grade),
            'time_taken_seconds' => (int) $evaluation->time_taken_seconds,
            'formatted_time' => $this->formatSeconds((int) $evaluation->time_taken_seconds),
            'doctor_feedback' => $evaluation->doctor_feedback,
            'created_at' => optional($evaluation->created_at)?->toIso8601String(),
            'display_date' => optional($evaluation->created_at)?->format('Y-m-d H:i'),
        ];
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

    public function gradeLabel(?string $grade): string
    {
        return match ($grade) {
            'excellent' => 'ممتاز',
            'good' => 'جيد جدًا',
            'acceptable' => 'مقبول',
            'weak' => 'ضعيف',
            'fail' => 'راسب',
            default => '-',
        };
    }

    public function skillLabel(?string $skill): string
    {
        return match ($skill) {
            'history_taking' => 'أخذ قصة مرضية',
            'clinical_examination' => 'فحص سريري',
            'procedure' => 'إجراء سريري',
            'communication' => 'مهارات تواصل',
            default => 'مهارة سريرية',
        };
    }

    public function formatSeconds(int $seconds): string
    {
        $seconds = max(0, $seconds);
        $hours = intdiv($seconds, 3600);
        $minutes = intdiv($seconds % 3600, 60);
        $remaining = $seconds % 60;

        return $hours > 0
            ? sprintf('%d:%02d:%02d', $hours, $minutes, $remaining)
            : sprintf('%d:%02d', $minutes, $remaining);
    }
}
