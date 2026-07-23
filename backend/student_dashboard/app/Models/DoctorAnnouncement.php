<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\Academic\Subject;
use Illuminate\Support\Facades\Storage;

class DoctorAnnouncement extends Model
{
    use HasFactory;

    protected $fillable = [
        'doctor_id',
        'subject_id',
        'type',
        'title',
        'content',
        'attachment_path',
        'attachment_name',
        'published_at',
        'is_published',
    ];

    protected $casts = [
        'is_published' => 'boolean',
        'published_at' => 'datetime',
    ];

    // ─── Relationships ───

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function subject()
    {
        return $this->belongsTo(Subject::class);
    }

    // ─── Accessors ───

    public function getAttachmentUrlAttribute()
    {
        return $this->attachment_path ? asset('storage/' . $this->attachment_path) : null;
    }

    public function getTypeLabelAttribute()
    {
        return match ($this->type) {
            'announcement' => 'إعلان',
            'warning'      => 'إنذار',
            'quiz_alert'   => 'تنبيه كويز',
            default        => 'إعلان',
        };
    }

    public function getTypeColorAttribute()
    {
        return match ($this->type) {
            'announcement' => '#4f46e5',
            'warning'      => '#ef4444',
            'quiz_alert'   => '#f59e0b',
            default        => '#6366f1',
        };
    }

    public function getTypeIconAttribute()
    {
        return match ($this->type) {
            'announcement' => 'fa-bullhorn',
            'warning'      => 'fa-triangle-exclamation',
            'quiz_alert'   => 'fa-clipboard-question',
            default        => 'fa-bell',
        };
    }

    // ─── Scopes ───

    public function scopePublished($query)
    {
        return $query->where(function ($q) {
            $q->whereNull('published_at')
              ->orWhere('published_at', '<=', now());
        });
    }

    public function scopeOfType($query, $type)
    {
        if ($type && $type !== 'all') {
            return $query->where('type', $type);
        }
        return $query;
    }

    public function scopeForDoctor($query, $doctorId)
    {
        return $query->where('doctor_id', $doctorId);
    }
}
