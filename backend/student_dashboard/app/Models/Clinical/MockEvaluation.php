<?php

namespace App\Models\Clinical;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;

class MockEvaluation extends Model
{
    use HasFactory;

    protected $fillable = [
        'student_id',
        'checklist_id',
        'percentage',
        'grade',
        'time_taken',
    ];

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function checklist()
    {
        return $this->belongsTo(EvaluationChecklist::class, 'checklist_id');
    }

    public function scores()
    {
        return $this->hasMany(MockScore::class, 'mock_evaluation_id');
    }

    // Accessors
    public function getGradeLabelAttribute()
    {
        return match ($this->grade) {
            'excellent' => 'ممتاز',
            'vgood' => 'جيد جداً',
            'good' => 'جيد',
            'pass' => 'مقبول',
            'fail' => 'راسب',
            default => 'غير محدد',
        };
    }

    public function getGradeColorAttribute()
    {
        return match ($this->grade) {
            'excellent' => '#059669', // Green
            'vgood' => '#2563eb',     // Blue
            'good' => '#eab308',      // Yellow
            'pass' => '#f97316',      // Orange
            'fail' => '#dc2626',      // Red
            default => '#64748b',     // Gray
        };
    }

    public function getFormattedTimeAttribute()
    {
        $minutes = floor($this->time_taken / 60);
        $seconds = $this->time_taken % 60;
        return sprintf('%02d:%02d', $minutes, $seconds);
    }
}
