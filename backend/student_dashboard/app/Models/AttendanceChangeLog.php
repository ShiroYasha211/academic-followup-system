<?php

namespace App\Models;

use App\Models\Academic\Lecture;
use App\Models\Academic\Subject;
use Illuminate\Database\Eloquent\Model;

class AttendanceChangeLog extends Model
{
    protected $fillable = [
        'attendance_id',
        'changed_by',
        'attendance_edit_permission_id',
        'attendance_edit_request_id',
        'student_id',
        'subject_id',
        'lecture_id',
        'qr_attendance_session_id',
        'date',
        'old_status',
        'new_status',
        'changes',
    ];

    protected $casts = [
        'date' => 'date',
        'changes' => 'array',
    ];

    public function attendance()
    {
        return $this->belongsTo(Attendance::class);
    }

    public function changedBy()
    {
        return $this->belongsTo(User::class, 'changed_by');
    }

    public function permission()
    {
        return $this->belongsTo(AttendanceEditPermission::class, 'attendance_edit_permission_id');
    }

    public function request()
    {
        return $this->belongsTo(AttendanceEditRequest::class, 'attendance_edit_request_id');
    }

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
        return $this->belongsTo(Lecture::class);
    }
}
