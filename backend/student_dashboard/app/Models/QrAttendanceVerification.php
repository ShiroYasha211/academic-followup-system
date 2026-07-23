<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class QrAttendanceVerification extends Model
{
    protected $fillable = [
        'qr_attendance_session_id',
        'student_id',
        'verification_type',
        'verification_status',
        'reviewed_by',
        'reviewed_at',
        'notes',
    ];

    protected $casts = [
        'reviewed_at' => 'datetime',
    ];

    public function session()
    {
        return $this->belongsTo(QrAttendanceSession::class, 'qr_attendance_session_id');
    }

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }
}
