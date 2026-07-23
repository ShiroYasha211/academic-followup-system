<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Excuse extends Model
{
    use HasFactory;

    protected $fillable = [
        'attendance_id',
        'student_id',
        'receiver_type',
        'receiver_id',
        'reason',
        'attachment',
        'status',
        'resolution',
        'reviewed_by',
        'doctor_comment',
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function attendance()
    {
        return $this->belongsTo(Attendance::class);
    }

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function receiver()
    {
        return $this->belongsTo(User::class, 'receiver_id');
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function attachments(): HasMany
    {
        return $this->hasMany(ExcuseAttachment::class);
    }

    public function allAttachments()
    {
        $attachments = $this->relationLoaded('attachments')
            ? $this->attachments->values()
            : $this->attachments()->get();

        if ($this->attachment) {
            $legacy = new ExcuseAttachment([
                'file_path' => $this->attachment,
                'file_name' => basename($this->attachment),
            ]);
            $legacy->setRelation('excuse', $this);
            $attachments = $attachments->prepend($legacy);
        }

        return $attachments->unique('file_path')->values();
    }
}
