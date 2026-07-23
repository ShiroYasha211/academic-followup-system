<?php

namespace App\Models\Academic;

use Illuminate\Database\Eloquent\Model;
use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Subject extends Model
{
    protected $fillable = [
        'name',
        'code',
        'description',
        'major_id',
        'level_id',
        'term_id',
        'semester_id',
        'doctor_id',
        'max_absences',
        'lecture_count',
        'allow_delegate_attendance',
        'inquiries_enabled',
        'inquiries_closed_reason',
        'grade_total_max_score',
        'grade_continuous_max_score',
        'grade_final_max_score',
        'grade_passing_score',
    ];

    protected $casts = [
        'allow_delegate_attendance' => 'boolean',
        'inquiries_enabled' => 'boolean',
        'grade_total_max_score' => 'decimal:2',
        'grade_continuous_max_score' => 'decimal:2',
        'grade_final_max_score' => 'decimal:2',
        'grade_passing_score' => 'decimal:2',
    ];

    public function gradeTotalMaxScore(): float
    {
        return (float) ($this->grade_total_max_score ?? 100);
    }

    public function gradeContinuousMaxScore(): float
    {
        return (float) ($this->grade_continuous_max_score ?? 40);
    }

    public function gradeFinalMaxScore(): float
    {
        return (float) ($this->grade_final_max_score ?? 60);
    }

    public function gradePassingScore(): float
    {
        return (float) ($this->grade_passing_score ?? 50);
    }

    public function gradeSettingsPayload(): array
    {
        return [
            'total_max_score' => $this->gradeTotalMaxScore(),
            'continuous_max_score' => $this->gradeContinuousMaxScore(),
            'final_max_score' => $this->gradeFinalMaxScore(),
            'passing_score' => $this->gradePassingScore(),
        ];
    }

    public function major(): BelongsTo
    {
        return $this->belongsTo(Major::class);
    }

    public function level(): BelongsTo
    {
        return $this->belongsTo(Level::class);
    }

    public function term(): BelongsTo
    {
        return $this->belongsTo(Term::class);
    }

    public function semester(): BelongsTo
    {
        return $this->belongsTo(Semester::class);
    }

    public function doctor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function resources(): HasMany
    {
        return $this->hasMany(\App\Models\CourseResource::class);
    }

    public function grades(): HasMany
    {
        return $this->hasMany(\App\Models\Grade::class);
    }

    public function gradeCategories(): HasMany
    {
        return $this->hasMany(\App\Models\GradeCategory::class);
    }

    public function attendances(): HasMany
    {
        return $this->hasMany(\App\Models\Attendance::class);
    }
}
