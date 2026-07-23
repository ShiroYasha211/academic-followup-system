<?php

namespace App\Models\Academic;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;

class StudentLectureStatus extends Model
{
    use HasFactory;

    protected $fillable = [
        'lecture_id',
        'student_id',
        'is_studied',
        'studied_at',
    ];

    protected $casts = [
        'is_studied' => 'boolean',
        'studied_at' => 'datetime',
    ];

    public function lecture()
    {
        return $this->belongsTo(Lecture::class);
    }

    public function student()
    {
        return $this->belongsTo(User::class);
    }
}
