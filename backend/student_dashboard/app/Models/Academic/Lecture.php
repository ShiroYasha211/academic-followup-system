<?php

namespace App\Models\Academic;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\Academic\Subject;

class Lecture extends Model
{
    use HasFactory;

    protected $fillable = [
        'subject_id',
        'date',
        'lecture_number',
        'lecture_type',
        'title',
        'description',
        'start_time',
        'end_time',
    ];

    protected $casts = [
        'date' => 'date',
    ];

    public function isSpecial(): bool
    {
        return $this->lecture_type === 'special';
    }

    public function subject()
    {
        return $this->belongsTo(Subject::class);
    }

    public function statuses()
    {
        return $this->hasMany(StudentLectureStatus::class);
    }

    // Scope to order by date descending
    public function scopeOrdered($query)
    {
        return $query->orderBy('date', 'desc');
    }
}
