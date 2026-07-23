<?php

namespace App\Models\Clinical;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class StudentDailyLog extends Model
{
    protected $fillable = [
        'student_id',
        'case_assignment_id',
        'training_center_id',
        'department_id',
        'doctor_id',
        'history_count',
        'exam_count',
        'did_round',
        'round_notes',
        'qr_token',
        'qr_generated_at',
        'status',
        'confirmed_by',
        'confirmed_at',
        'doctor_notes',
        'log_date',
        'log_time',
    ];

    protected $casts = [
        'did_round' => 'boolean',
        'qr_generated_at' => 'datetime',
        'confirmed_at' => 'datetime',
        'log_date' => 'date',
    ];

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function caseAssignment()
    {
        return $this->belongsTo(CaseAssignment::class, 'case_assignment_id');
    }

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function confirmedBy()
    {
        return $this->belongsTo(User::class, 'confirmed_by');
    }

    public function trainingCenter()
    {
        return $this->belongsTo(TrainingCenter::class, 'training_center_id');
    }

    public function department()
    {
        return $this->belongsTo(ClinicalDepartment::class, 'department_id');
    }

    public function activities()
    {
        return $this->hasMany(DailyLogActivity::class, 'daily_log_id');
    }

    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeConfirmed($query)
    {
        return $query->where('status', 'confirmed');
    }

    public function scopeReviewable($query)
    {
        return $query->whereIn('status', ['pending', 'partially_confirmed']);
    }

    public static function generateToken(): string
    {
        return 'DL-' . strtoupper(Str::random(32));
    }

    public function isExpired(): bool
    {
        $generatedAt = $this->qr_generated_at ?? $this->created_at;

        return $generatedAt ? $generatedAt->diffInMinutes(now()) > 30 : false;
    }

    public function getStatusLabelAttribute(): string
    {
        return match ($this->status) {
            'pending' => 'بانتظار التأكيد',
            'partially_confirmed' => 'اعتماد جزئي',
            'confirmed' => 'مؤكد',
            'rejected' => 'مرفوض',
            default => $this->status,
        };
    }

    public function groupedActivities(): array
    {
        $groups = [
            'history' => [
                'key' => 'history',
                'label' => 'القصص المرضية',
                'activity_type' => 'history_taking',
                'items' => $this->activities->where('activity_type', 'history_taking')->values(),
            ],
            'exam' => [
                'key' => 'exam',
                'label' => 'الفحوصات السريرية',
                'activity_type' => 'clinical_examination',
                'items' => $this->activities->where('activity_type', 'clinical_examination')->values(),
            ],
            'round' => [
                'key' => 'round',
                'label' => 'المرور',
                'activity_type' => 'round',
                'items' => $this->activities->where('activity_type', 'round')->values(),
            ],
        ];

        return array_filter($groups, fn ($group) => $group['items']->isNotEmpty());
    }
    public function syncApprovalStatus(): string
    {
        $activities = $this->activities;
        if ($activities->isEmpty()) {
            return $this->status;
        }

        $confirmedCount = $activities->where('is_confirmed', true)->count();
        $rejectedCount = $activities->where('review_status', 'rejected')->count();
        $newStatus = match (true) {
            $confirmedCount === 0 && $rejectedCount > 0 => 'rejected',
            $confirmedCount === 0 => 'pending',
            $confirmedCount === $activities->count() => 'confirmed',
            default => 'partially_confirmed',
        };

        $this->status = $newStatus;
        $this->save();

        return $newStatus;
    }
}
