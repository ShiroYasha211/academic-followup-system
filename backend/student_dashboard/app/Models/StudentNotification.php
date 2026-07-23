<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StudentNotification extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'college_id',
        'sender_id',
        'batch_id',
        'type',
        'title',
        'message',
        'attachment_path',
        'attachment_name',
        'data',
        'read_at',
    ];

    protected $casts = [
        'data' => 'array',
        'read_at' => 'datetime',
    ];

    /**
     * Get the full URL for the attachment.
     */
    public function getAttachmentUrlAttribute()
    {
        return $this->attachment_path ? asset('storage/' . $this->attachment_path) : null;
    }

    /**
     * Get the user that owns the notification.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the sender of the notification.
     */
    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    /**
     * Get the college.
     */
    public function college()
    {
        return $this->belongsTo(\App\Models\Academic\College::class);
    }

    /**
     * Scope for unread notifications.
     */
    public function scopeUnread($query)
    {
        return $query->whereNull('read_at');
    }

    /**
     * Scope for broadcast notifications shared with a batch.
     */
    public function scopeBroadcasts($query)
    {
        return $query->whereNotNull('batch_id')
            ->whereIn('type', ['announcement', 'exam', 'assignment', 'poll']);
    }

    /**
     * Scope for administrative broadcasts.
     */
    public function scopeAdministrativeBroadcasts($query)
    {
        return $query->broadcasts()
            ->whereHas('sender', function ($senderQuery) {
                $senderQuery->where(function ($roleQuery) {
                    $roleQuery->whereIn('role', ['admin', 'administrative'])
                        ->orWhere(function ($doctorQuery) {
                            $doctorQuery->where('role', 'doctor')
                                ->where('administrative_access', true);
                        });
                });
            });
    }

    /**
     * Mark as read.
     */
    public function markAsRead()
    {
        if (is_null($this->read_at)) {
            $this->update(['read_at' => now()]);
        }
    }

    /**
     * Get icon based on type.
     */
    public function getIconAttribute()
    {
        return match ($this->type) {
            'exam' => 'calendar-check',
            'assignment' => 'file-text',
            'flashcard_assignment' => 'bolt',
            'grade_delegation' => 'user-check',
            'stars' => 'star',
            'resource' => 'folder',
            'announcement' => 'megaphone',
            'attendance' => 'user-x',
            'attendance_confirmation' => 'user-check',
            'attendance_edit_request' => 'edit',
            default => 'bell',
        };
    }

    /**
     * Get color based on type.
     */
    public function getColorAttribute()
    {
        return match ($this->type) {
            'exam' => '#ef4444',
            'assignment' => '#f59e0b',
            'flashcard_assignment' => '#4f46e5',
            'grade_delegation' => '#2563eb',
            'stars' => '#f59e0b',
            'resource' => '#3b82f6',
            'announcement' => '#10b981',
            'attendance' => '#ef4444',
            'attendance_confirmation' => '#10b981',
            'attendance_edit_request' => '#f59e0b',
            default => '#6366f1',
        };
    }
}
