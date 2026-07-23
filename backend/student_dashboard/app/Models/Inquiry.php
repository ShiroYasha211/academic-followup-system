<?php

namespace App\Models;

use App\Models\Academic\Subject;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Inquiry extends Model
{
    use HasFactory;

    protected $appends = [
        'status_label',
        'status_color',
        'answered_by_actor_type',
        'answered_by_actor_label',
        'answered_by_actor_name',
    ];

    protected $fillable = [
        'student_id',
        'subject_id',
        'delegate_id',
        'answered_by',
        'title',
        'question',
        'answer',
        'status',
        'answered_at',
    ];

    protected $casts = [
        'answered_at' => 'datetime',
    ];

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function subject()
    {
        return $this->belongsTo(Subject::class);
    }

    public function delegate()
    {
        return $this->belongsTo(User::class, 'delegate_id');
    }

    public function answeredBy()
    {
        return $this->belongsTo(User::class, 'answered_by');
    }

    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeAnswered($query)
    {
        return $query->where('status', 'answered');
    }

    public function scopeVisibleToDoctor($query, int $doctorId)
    {
        return $query
            ->whereHas('subject', function ($subjectQuery) use ($doctorId) {
                $subjectQuery->where('doctor_id', $doctorId);
            })
            ->where(function ($statusQuery) use ($doctorId) {
                $statusQuery->where('status', 'forwarded')
                    ->orWhere(function ($resolvedQuery) use ($doctorId) {
                        $resolvedQuery->whereIn('status', ['answered', 'closed'])
                            ->where('answered_by', $doctorId);
                    });
            });
    }

    public function canBeAnsweredByDelegate(): bool
    {
        return $this->status === 'pending' && blank($this->answer);
    }

    public function wasForwardedToDoctor(): bool
    {
        return $this->status === 'forwarded';
    }

    public function getStatusLabelAttribute(): string
    {
        return match ($this->status) {
            'pending' => 'قيد الانتظار',
            'forwarded' => 'تم التحويل للدكتور',
            'answered' => 'تم الرد',
            'closed' => 'مغلق',
            default => (string) $this->status,
        };
    }

    public function getStatusColorAttribute(): string
    {
        return match ($this->status) {
            'pending' => '#f59e0b',
            'forwarded' => '#3b82f6',
            'answered' => '#10b981',
            'closed' => '#6b7280',
            default => '#64748b',
        };
    }

    public function getAnsweredByActorTypeAttribute(): ?string
    {
        $role = $this->answeredBy?->role;
        $roleValue = is_object($role) && isset($role->value) ? $role->value : $role;

        return match ($roleValue) {
            'delegate', 'practical_delegate' => 'delegate',
            'doctor' => 'doctor',
            default => null,
        };
    }

    public function getAnsweredByActorLabelAttribute(): ?string
    {
        return match ($this->answered_by_actor_type) {
            'delegate' => 'المندوب',
            'doctor' => 'الدكتور',
            default => null,
        };
    }

    public function getAnsweredByActorNameAttribute(): ?string
    {
        return $this->answeredBy?->name;
    }
}
