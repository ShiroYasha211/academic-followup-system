<?php

namespace App\Models\Quiz;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;
use App\Models\Academic\Subject;

class Quiz extends Model
{
    use HasFactory;

    protected $fillable = [
        'created_by',
        'creator_type',
        'subject_id',
        'title',
        'description',
        'time_limit_minutes',
        'timer_mode',
        'allow_question_backtracking',
        'shuffle_questions',
        'shuffle_options',
        'show_correct_answers',
        'show_correction_notes',
        'results_visibility',
        'is_competition',
        'scheduled_at',
        'closes_at',
        'status',
        'notify_students',
        'show_countdown',
    ];

    protected $casts = [
        'shuffle_questions'     => 'boolean',
        'shuffle_options'       => 'boolean',
        'show_correct_answers'  => 'boolean',
        'show_correction_notes' => 'boolean',
        'is_competition'        => 'boolean',
        'notify_students'       => 'boolean',
        'show_countdown'        => 'boolean',
        'allow_question_backtracking' => 'boolean',
        'scheduled_at'          => 'datetime',
        'closes_at'             => 'datetime',
    ];

    // ─── Helpers ───

    public function isUpcoming(): bool
    {
        return $this->status === 'scheduled' && $this->scheduled_at && $this->scheduled_at->isFuture();
    }

    /**
     * Check if a quiz is "effectively" published (status is published OR scheduled and time passed)
     */
    public function isEffectivelyPublished(): bool
    {
        if ($this->status === 'closed') return false;
        if ($this->status === 'published') {
            if ($this->closes_at && $this->closes_at->isPast()) {
                $this->update(['status' => 'closed']);
                return false;
            }
            return true;
        }

        if ($this->status === 'scheduled' && $this->scheduled_at && $this->scheduled_at->isPast()) {
            // Auto-update database status for convenience (since we found it expired)
            $this->update(['status' => 'published']);
            // Also check if it should be closed immediately
            if ($this->closes_at && $this->closes_at->isPast()) {
                $this->update(['status' => 'closed']);
                return false;
            }
            return true;
        }

        return false;
    }

    // ─── Relationships ───

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function subject()
    {
        return $this->belongsTo(Subject::class);
    }

    public function models()
    {
        return $this->hasMany(QuizModel::class);
    }

    public function attempts()
    {
        return $this->hasMany(QuizAttempt::class);
    }

    public function targets()
    {
        return $this->hasMany(QuizTarget::class);
    }

    // ─── Accessors ───

    public function getStatusLabelAttribute()
    {
        if ($this->status === 'scheduled' && $this->scheduled_at && $this->scheduled_at->isPast()) {
            return 'منشور (تلقائي)';
        }

        return match ($this->status) {
            'draft'     => 'مسودة',
            'scheduled' => 'مجدول',
            'published' => 'منشور',
            'closed'    => 'مغلق',
            default     => $this->status,
        };
    }

    public function getStatusColorAttribute()
    {
        if ($this->status === 'scheduled' && $this->scheduled_at && $this->scheduled_at->isPast()) {
            return '#10b981';
        }

        return match ($this->status) {
            'draft'     => '#94a3b8',
            'scheduled' => '#f59e0b',
            'published' => '#10b981',
            'closed'    => '#ef4444',
            default     => '#6366f1',
        };
    }

    public function getResultsVisibilityLabelAttribute()
    {
        return match ($this->results_visibility) {
            'hidden'     => 'مخفية',
            'individual' => 'للطالب فقط',
            'public'     => 'عامة للدفعة',
            default      => $this->results_visibility,
        };
    }

    public function getTotalQuestionsAttribute()
    {
        return $this->models()->withCount('questions')->get()->sum('questions_count');
    }

    public function getAttemptCountAttribute()
    {
        return $this->attempts()->count();
    }

    // ─── Scopes ───

    public function scopePublished($query)
    {
        return $query->where('status', 'published');
    }

    public function scopeScheduled($query)
    {
        return $query->where('status', 'scheduled');
    }

    public function scopeCompetitions($query)
    {
        return $query->where('is_competition', true);
    }

    public function scopeForDoctor($query, $doctorId)
    {
        return $query->where('created_by', $doctorId)->where('creator_type', 'doctor');
    }

    public function scopeForSubject($query, $subjectId)
    {
        return $query->where('subject_id', $subjectId);
    }

    // ─── Methods ───

    /**
     * Check if a student can access this quiz.
     */
    public function isAccessibleBy(User $student): bool
    {
        if (!$this->isEffectivelyPublished()) {
            return false;
        }

        if ($this->closes_at && now()->gt($this->closes_at)) {
            return false;
        }

        // Doctor quiz → student must be in same major/level as the subject
        if (!$this->is_competition && $this->subject_id) {
            $subject = $this->subject;
            return $student->major_id === $subject->major_id
                && $student->level_id === $subject->level_id;
        }

        // Competition → check quiz_targets
        if ($this->is_competition) {
            return $this->targets()
                ->where(function ($q) use ($student) {
                    $q->whereNull('university_id')->orWhere('university_id', $student->university_id);
                })
                ->where(function ($q) use ($student) {
                    $q->whereNull('college_id')->orWhere('college_id', $student->college_id);
                })
                ->where(function ($q) use ($student) {
                    $q->whereNull('major_id')->orWhere('major_id', $student->major_id);
                })
                ->where(function ($q) use ($student) {
                    $q->whereNull('level_id')->orWhere('level_id', $student->level_id);
                })
                ->exists();
        }

        return false;
    }

    /**
     * Check if a student has already attempted this quiz.
     */
    public function hasAttemptBy(User $student): bool
    {
        return $this->attempts()->where('student_id', $student->id)->exists();
    }

    /**
     * Get a student's attempt for this quiz.
     */
    public function attemptBy(User $student)
    {
        return $this->attempts()->where('student_id', $student->id)->first();
    }
}
