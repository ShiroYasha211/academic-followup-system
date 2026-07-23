<?php

namespace App\Models\Academic;

use Illuminate\Database\Eloquent\Model;


class Schedule extends Model
{
    protected $fillable = [
        'subject_id',
        'day_of_week', // 1=Monday, 7=Sunday
        'start_time',
        'end_time',
        'hall_name',
        'doctor_id',
        'created_by',
    ];

    public function subject()
    {
        return $this->belongsTo(\App\Models\Academic\Subject::class);
    }

    public function doctor()
    {
        return $this->belongsTo(\App\Models\User::class, 'doctor_id');
    }

    public function creator()
    {
        return $this->belongsTo(\App\Models\User::class, 'created_by');
    }
}
