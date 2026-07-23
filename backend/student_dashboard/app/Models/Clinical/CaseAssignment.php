<?php

namespace App\Models\Clinical;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class CaseAssignment extends Model
{
    protected $fillable = [
        'student_id',
        'clinical_case_id',
        'assigned_by',
        'task_type',
        'instructions',
        'due_at',
        'attachment_path',
        'attachment_name',
        'attachment_type',
        'status',
        'student_completion_message',
        'submitted_at',
        'reviewed_at',
        'reviewed_by',
        'review_notes',
        'review_rating',
        'is_completed',
        'completed_at',
    ];

    protected $casts = [
        'is_completed' => 'boolean',
        'due_at' => 'datetime',
        'completed_at' => 'datetime',
        'submitted_at' => 'datetime',
        'reviewed_at' => 'datetime',
    ];

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function clinicalCase()
    {
        return $this->belongsTo(ClinicalCase::class, 'clinical_case_id');
    }

    public function assigner()
    {
        return $this->belongsTo(User::class, 'assigned_by');
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function dailyLogs()
    {
        return $this->hasMany(StudentDailyLog::class, 'case_assignment_id')->latest();
    }

    public function getStatusLabelAttribute(): string
    {
        if ($this->is_overdue) {
            return 'متأخر';
        }

        return match ($this->status ?: ($this->is_completed ? 'approved' : 'assigned')) {
            'assigned' => 'مكلف',
            'submitted_for_review' => 'قيد المراجعة',
            'approved' => 'تم الاعتماد',
            'rejected' => 'مرفوض',
            default => $this->status,
        };
    }

    public function getTaskTypeLabelAttribute(): string
    {
        return match ($this->task_type) {
            'history_taking' => 'قصة مرضية',
            'clinical_examination' => 'فحص سريري',
            'follow_up' => 'متابعة ومرور',
            default => $this->task_type,
        };
    }

    public function getReviewRatingLabelAttribute(): ?string
    {
        return match ($this->review_rating) {
            'excellent' => 'ممتاز',
            'good' => 'جيد',
            'needs_improvement' => 'يحتاج تحسين',
            default => null,
        };
    }

    public function getIsOverdueAttribute(): bool
    {
        return $this->due_at !== null
            && $this->due_at->isPast()
            && ! in_array($this->status, ['approved', 'rejected'], true);
    }
}
