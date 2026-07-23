<?php

namespace App\Models;

use App\Models\Academic\Lecture;
use App\Models\Academic\Subject;
use Illuminate\Database\Eloquent\Model;

class AttendanceEditRequest extends Model
{
    public const STATUS_PENDING = 'pending';
    public const STATUS_APPROVED = 'approved';
    public const STATUS_REJECTED = 'rejected';
    public const STATUS_CANCELLED = 'cancelled';

    protected $fillable = [
        'requester_id',
        'subject_id',
        'lecture_id',
        'qr_attendance_session_id',
        'date',
        'title',
        'reason',
        'status',
        'reviewed_by',
        'reviewed_at',
        'admin_note',
        'granted_until',
    ];

    protected $casts = [
        'date' => 'date',
        'reviewed_at' => 'datetime',
        'granted_until' => 'datetime',
    ];

    public function requester()
    {
        return $this->belongsTo(User::class, 'requester_id');
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

    public function reviewedBy()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function permission()
    {
        return $this->hasOne(AttendanceEditPermission::class);
    }

    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }
}
