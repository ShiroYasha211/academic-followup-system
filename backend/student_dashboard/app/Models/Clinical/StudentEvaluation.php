<?php

namespace App\Models\Clinical;

use Illuminate\Database\Eloquent\Model;
use App\Models\User;
use App\Models\Clinical\BodySystem;

class StudentEvaluation extends Model
{
    protected $fillable = [
        'student_id',
        'doctor_id',
        'checklist_id',
        'clinical_case_id',
        'body_system_id',
        'procedure_type',
        'timer_type',
        'time_limit_seconds',
        'total_score',
        'max_score',
        'percentage',
        'grade',
        'time_taken_seconds',
        'doctor_feedback',
    ];

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function checklist()
    {
        return $this->belongsTo(EvaluationChecklist::class, 'checklist_id');
    }

    public function clinicalCase()
    {
        return $this->belongsTo(ClinicalCase::class, 'clinical_case_id');
    }

    public function bodySystem()
    {
        return $this->belongsTo(BodySystem::class, 'body_system_id');
    }

    public function scores()
    {
        return $this->hasMany(EvaluationScore::class, 'evaluation_id');
    }

    public function getGradeLabelAttribute(): string
    {
        return match ($this->grade) {
            'excellent' => 'ممتاز',
            'good' => 'جيد جداً',
            'acceptable' => 'مقبول',
            'weak' => 'ضعيف',
            'fail' => 'راسب',
            default => '-',
        };
    }

    public function getGradeColorAttribute(): string
    {
        return match ($this->grade) {
            'excellent' => '#059669',
            'good' => '#3b82f6',
            'acceptable' => '#f59e0b',
            'weak' => '#ef4444',
            'fail' => '#991b1b',
            default => '#64748b',
        };
    }

    public function getFormattedTimeAttribute(): string
    {
        if (!$this->time_taken_seconds) return '-';
        $m = floor($this->time_taken_seconds / 60);
        $s = $this->time_taken_seconds % 60;
        return sprintf('%d:%02d', $m, $s);
    }
}
