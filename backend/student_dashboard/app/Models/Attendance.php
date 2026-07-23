<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Models\Academic\Subject;

class Attendance extends Model
{
    public const STATUS_PRESENT = 'present';
    public const STATUS_ABSENT = 'absent';
    public const STATUS_LATE = 'late';
    public const STATUS_EXCUSED = 'excused';
    public const STATUS_PERMITTED = 'permitted';
    public const STATUS_EXEMPTED = 'exempted';

    protected $fillable = [
        'student_id',
        'subject_id',
        'lecture_id',
        'status',
        'date',
        'recorded_by',
        'attendance_method',
        'qr_attendance_session_id',
    ];

    protected $casts = [
        'date' => 'date',
    ];

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function subject()
    {
        return $this->belongsTo(Subject::class);
    }

    public function lecture()
    {
        return $this->belongsTo(\App\Models\Academic\Lecture::class);
    }

    public function recorder()
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }

    public function qrSession()
    {
        return $this->belongsTo(QrAttendanceSession::class, 'qr_attendance_session_id');
    }

    public function excuse()
    {
        return $this->hasOne(Excuse::class);
    }
}
