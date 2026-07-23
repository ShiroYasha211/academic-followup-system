<?php

namespace App\Models\Clinical;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class DailyLogActivity extends Model
{
    protected $fillable = [
        'daily_log_id',
        'activity_type',
        'body_system_id',
        'case_name',
        'notes',
        'is_confirmed',
        'review_status',
        'diagnosis',
        'review_notes',
        'confirmed_by',
        'confirmed_at',
    ];

    protected $casts = [
        'is_confirmed' => 'boolean',
        'confirmed_at' => 'datetime',
    ];

    public function getReviewStatusLabelAttribute(): string
    {
        return match ($this->review_status) {
            'approved' => 'معتمد',
            'rejected' => 'مرفوض',
            default => 'بانتظار المراجعة',
        };
    }

    public function dailyLog()
    {
        return $this->belongsTo(StudentDailyLog::class, 'daily_log_id');
    }

    public function bodySystem()
    {
        return $this->belongsTo(BodySystem::class, 'body_system_id');
    }

    public function confirmedBy()
    {
        return $this->belongsTo(User::class, 'confirmed_by');
    }

    public function getCategoryKeyAttribute(): string
    {
        return match ($this->activity_type) {
            'history_taking' => 'history',
            'clinical_examination' => 'فحص سريري',
            'round' => 'مرور',
            default => $this->activity_type,
        };
    }

    public function getTypeLabelAttribute(): string
    {
        return match ($this->activity_type) {
            'history_taking' => 'قصة مرضية',
            'clinical_examination' => 'فحص سريري',
            'round' => 'مرور',
            default => $this->activity_type,
        };
    }
}
