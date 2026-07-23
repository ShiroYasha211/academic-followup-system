<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;
use App\Models\Academic\Subject;

class Grade extends Model
{
    use HasFactory;

    protected $fillable = [
        'student_id',
        'subject_id',
        'type',
        'category',
        'category_id',
        'score',
        'max_score',
        'semester',
        'created_by',
        'status',
    ];

    protected $casts = [
        'score' => 'decimal:2',
        'max_score' => 'decimal:2',
    ];

    // Calculate percentage
    public function getPercentageAttribute()
    {
        if ($this->max_score > 0) {
            return round(($this->score / $this->max_score) * 100, 1);
        }
        return 0;
    }

    // Type label in Arabic
    public function getTypeLabelAttribute()
    {
        return $this->type === 'continuous' ? 'محصلة' : 'نهائي';
    }

    // Relationships
    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function subject()
    {
        return $this->belongsTo(Subject::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function gradeCategory()
    {
        return $this->belongsTo(GradeCategory::class, 'category_id');
    }

    // Scopes
    public function scopeOfSubject($query, $subjectId)
    {
        return $query->where('subject_id', $subjectId);
    }

    public function scopeOfType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeForStudent($query, $studentId)
    {
        return $query->where('student_id', $studentId);
    }
}
