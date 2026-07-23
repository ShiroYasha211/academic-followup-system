<?php

namespace App\Models\Academic;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Models\User;
use App\Models\AssignmentSubmission;

class Assignment extends Model
{
    use HasFactory;

    protected $fillable = [
        'subject_id',
        'title',
        'description',
        'due_date',
        'requires_submission',
        'created_by',
    ];

    protected $casts = [
        'due_date' => 'date',
        'requires_submission' => 'boolean',
    ];

    public function subject()
    {
        return $this->belongsTo(Subject::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function submissions()
    {
        return $this->hasMany(AssignmentSubmission::class, 'assignment_id');
    }

    /**
     * Check if assignment is overdue.
     */
    public function isOverdue()
    {
        return $this->due_date->isPast();
    }

    /**
     * Check if assignment is upcoming (within 3 days).
     */
    public function isUpcoming()
    {
        return !$this->isOverdue() && $this->due_date->diffInDays(now()) <= 3;
    }

    /**
     * Get submission by student.
     */
    public function submissionByStudent($studentId)
    {
        return $this->submissions()->where('student_id', $studentId)->first();
    }
}
