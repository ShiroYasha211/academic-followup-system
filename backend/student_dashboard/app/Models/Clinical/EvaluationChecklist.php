<?php

namespace App\Models\Clinical;

use Illuminate\Database\Eloquent\Model;
use App\Models\User;

class EvaluationChecklist extends Model
{
    protected $fillable = [
        'title',
        'description',
        'doctor_id',
        'source_checklist_id',
        'synced_admin_checklist_id',
        'tracks_admin_updates',
        'skill_type',
        'time_limit_minutes',
        'total_marks',
        'is_active',
        'is_practice_allowed',
        'creator_type',
        'creator_id',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'is_practice_allowed' => 'boolean',
        'tracks_admin_updates' => 'boolean',
    ];

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function sourceChecklist()
    {
        return $this->belongsTo(self::class, 'source_checklist_id');
    }

    public function syncedAdminChecklist()
    {
        return $this->belongsTo(self::class, 'synced_admin_checklist_id');
    }

    public function derivedChecklists()
    {
        return $this->hasMany(self::class, 'source_checklist_id');
    }

    public function items()
    {
        return $this->hasMany(ChecklistItem::class, 'checklist_id')->orderBy('sort_order');
    }

    public function evaluations()
    {
        return $this->hasMany(StudentEvaluation::class, 'checklist_id');
    }

    public function getSkillLabelAttribute(): string
    {
        return match ($this->skill_type) {
            'history_taking' => 'أخذ قصة مرضية',
            'clinical_examination' => 'فحص سريري',
            'procedure' => 'إجراء طبي',
            'communication' => 'مهارات تواصل',
            default => $this->skill_type,
        };
    }

    public function creator()
    {
        return $this->morphTo();
    }

    public function scopeForStudent($query, $studentId)
    {
        $student = $studentId instanceof User ? $studentId : User::find($studentId);

        if (!$student) {
            return $query->whereRaw('1 = 0');
        }

        return $query->where('is_active', true)->where(function ($q) use ($student) {
            $q->whereNull('doctor_id')
                ->orWhere(function ($studentOwned) use ($student) {
                    $studentOwned->where('creator_type', User::class)
                        ->where('creator_id', $student->id);
                })
                ->orWhere(function ($doctorPractice) use ($student) {
                    $doctorPractice->whereNotNull('doctor_id')
                        ->where('is_practice_allowed', true)
                        ->whereHas('doctor.subjects', function ($subjectQuery) use ($student) {
                            $subjectQuery->where('major_id', $student->major_id)
                                ->where('level_id', $student->level_id);
                        });
                });
        });
    }
}
