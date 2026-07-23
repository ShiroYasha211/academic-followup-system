<?php

namespace App\Models;

use App\Models\Academic\Lecture;
use App\Models\Academic\Subject;
use Illuminate\Database\Eloquent\Model;

class AttendanceEditPermission extends Model
{
    protected $fillable = [
        'user_id',
        'granted_by',
        'attendance_edit_request_id',
        'subject_id',
        'lecture_id',
        'qr_attendance_session_id',
        'date',
        'reason',
        'expires_at',
        'revoked_at',
        'revoked_by',
    ];

    protected $casts = [
        'date' => 'date',
        'expires_at' => 'datetime',
        'revoked_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function grantedBy()
    {
        return $this->belongsTo(User::class, 'granted_by');
    }

    public function request()
    {
        return $this->belongsTo(AttendanceEditRequest::class, 'attendance_edit_request_id');
    }

    public function subject()
    {
        return $this->belongsTo(Subject::class);
    }

    public function lecture()
    {
        return $this->belongsTo(Lecture::class);
    }

    public function qrSession()
    {
        return $this->belongsTo(QrAttendanceSession::class, 'qr_attendance_session_id');
    }

    public function revokedBy()
    {
        return $this->belongsTo(User::class, 'revoked_by');
    }

    public function scopeActive($query)
    {
        return $query
            ->whereNull('revoked_at')
            ->where('expires_at', '>', now());
    }
}
