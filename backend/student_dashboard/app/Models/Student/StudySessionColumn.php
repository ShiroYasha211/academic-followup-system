<?php

namespace App\Models\Student;

use Illuminate\Database\Eloquent\Model;

class StudySessionColumn extends Model
{
    protected $fillable = [
        'student_schedule_item_id',
        'name',
        'sort_order',
    ];

    public function scheduleItem()
    {
        return $this->belongsTo(StudentScheduleItem::class, 'student_schedule_item_id');
    }

    public function actions()
    {
        return $this->hasMany(StudySessionAction::class);
    }
}
