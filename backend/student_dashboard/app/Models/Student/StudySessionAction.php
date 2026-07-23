<?php

namespace App\Models\Student;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class StudySessionAction extends Model
{
    protected $fillable = [
        'student_schedule_item_id',
        'study_session_column_id',
        'user_id',
        'action_type',
        'occurred_at',
    ];

    protected $casts = [
        'occurred_at' => 'datetime',
    ];

    public function scheduleItem()
    {
        return $this->belongsTo(StudentScheduleItem::class, 'student_schedule_item_id');
    }

    public function column()
    {
        return $this->belongsTo(StudySessionColumn::class, 'study_session_column_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
