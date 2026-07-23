<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ExamScheduleItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'exam_schedule_id',
        'subject_id',
        'exam_date',
        'start_time',
        'end_time',
        'location',
    ];

    protected $casts = [
        'exam_date' => 'date',
    ];

    public function schedule()
    {
        return $this->belongsTo(ExamSchedule::class, 'exam_schedule_id');
    }

    public function subject()
    {
        return $this->belongsTo(\App\Models\Academic\Subject::class);
    }
}
